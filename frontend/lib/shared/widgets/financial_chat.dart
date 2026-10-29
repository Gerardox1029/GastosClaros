import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/services/api_service.dart';

final _messagesProvider = StateProvider<List<Map<String, String>>>((ref) => []);
final _periodProvider = StateProvider<String>((ref) => '1M');

class FinancialChat extends ConsumerStatefulWidget {
  const FinancialChat({super.key});
  @override
  ConsumerState<FinancialChat> createState() => _FinancialChatState();
}

class _FinancialChatState extends ConsumerState<FinancialChat> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;
  String? _error;
  String? _loadingMessage;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? query]) async {
    final text = (query ?? _input.text).trim();
    if (_busy || text.isEmpty) return;
    final history = ref.read(_messagesProvider);
    final period = ref.read(_periodProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    ref.read(_messagesProvider.notifier).state = [
      ...history,
      {'role': 'user', 'text': text}
    ];
    _input.clear();
    _scrollDown();
    try {
      String? answer;
      Object? lastError;
      for (var attempt = 0; attempt < 4; attempt++) {
        if (!mounted) return;
        setState(() => _loadingMessage = switch (attempt) {
              0 => 'Analizando tus ingresos y gastos...',
              1 => 'La API tardó en responder. Reintentando en 10 segundos...',
              2 => 'Haciendo cálculos con tus movimientos...',
              _ =>
                'Gemini sigue sin responder. Último intento en 10 segundos...',
            });
        if (attempt > 0) {
          await Future.delayed(const Duration(seconds: 10));
          if (!mounted) return;
          setState(() => _loadingMessage = 'Consultando de nuevo a Gemini...');
        }
        try {
          answer = await ref.read(apiServiceProvider).askAssistant(
              message: text,
              period: period,
              history: history.length > 20
                  ? history.sublist(history.length - 20)
                  : history);
          break;
        } catch (error) {
          lastError = error;
          if (!_isTransient(error)) break;
        }
      }
      if (answer == null) throw lastError ?? Exception('Error desconocido');
      if (!mounted) return;
      ref.read(_messagesProvider.notifier).state = [
        ...ref.read(_messagesProvider),
        {'role': 'model', 'text': answer}
      ];
      setState(() => _loadingMessage = null);
      _scrollDown();
    } catch (error) {
      if (mounted) {
        ref.read(_messagesProvider.notifier).state = history;
        _input.text = text;
        final message = error.toString();
        setState(() {
          _error = error is ApiException
              ? '$message${_isTransient(error) ? ' (después de varios intentos).' : ''}'
              : error is ClientException || error is TimeoutException
                  ? 'Sin conexión con el servidor de GastosClaros. Verifica internet e inténtalo de nuevo.'
                  : 'Falló el servidor de GastosClaros. Intenta nuevamente más tarde.';
          _loadingMessage = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isTransient(Object error) {
    if (error is ClientException || error is TimeoutException) return true;
    if (error is ApiException) {
      if ((error.statusCode == 503 || error.statusCode == 502) &&
          error.body != null) {
        try {
          final code =
              (jsonDecode(error.body!) as Map<String, dynamic>)['code'];
          return code == 'gemini_unavailable' ||
              code == 'gemini_rate_limited' ||
              code == 'financial_data_unavailable' ||
              code == 'gemini_error';
        } catch (_) {
          return false;
        }
      }
      return error.statusCode == 503;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(_messagesProvider);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * .8,
        decoration: const BoxDecoration(
            color: AppColors.surfacePurple,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              const Expanded(
                  child: Text('Asistente financiero',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600))),
              IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            DropdownButtonFormField<String>(
              initialValue: ref.watch(_periodProvider),
              decoration:
                  const InputDecoration(labelText: 'Período (hora de Perú)'),
              items: const [
                DropdownMenuItem(value: '1D', child: Text('Hoy')),
                DropdownMenuItem(value: '7D', child: Text('Últimos 7 días')),
                DropdownMenuItem(value: '1M', child: Text('Últimos 30 días'))
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      ref.read(_periodProvider.notifier).state = value!;
                      ref.read(_messagesProvider.notifier).state = [];
                      setState(() => _error = null);
                    },
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _send(
                            'Genera un reporte financiero del período seleccionado.'),
                    icon: const Icon(Icons.summarize_outlined),
                    label: const Text('Generar reporte'))),
            Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                            'Consulta tus ingresos, gastos y saldo del período seleccionado.',
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final user = message['role'] == 'user';
                          return Align(
                              alignment: user
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                decoration: BoxDecoration(
                                    color: user
                                        ? AppColors.accentPurple
                                            .withValues(alpha: .2)
                                        : AppColors.deepPurpleBg,
                                    borderRadius: BorderRadius.circular(16)),
                                child: SelectableText(message['text']!),
                              ));
                        })),
            if (_busy)
              Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Flexible(
                        child:
                            Text(_loadingMessage ?? 'Preparando consulta...')),
                  ])),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.dangerRed)),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _input,
                      enabled: !_busy,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Escribe tu consulta...', counterText: ''),
                      onSubmitted: (_) => _send())),
              IconButton(
                  tooltip: 'Enviar',
                  onPressed: _busy ? null : () => _send(),
                  icon: const Icon(Icons.send_rounded))
            ]),
          ]),
        )),
      ),
    );
  }
}
