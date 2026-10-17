import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';

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
      final answer = await ref.read(apiServiceProvider).askAssistant(
          message: text,
          period: period,
          history: history.length > 20
              ? history.sublist(history.length - 20)
              : history);
      if (!mounted) return;
      ref.read(_messagesProvider.notifier).state = [
        ...ref.read(_messagesProvider),
        {'role': 'model', 'text': answer}
      ];
      _scrollDown();
    } catch (error) {
      if (mounted) {
        ref.read(_messagesProvider.notifier).state = history;
        _input.text = text;
        setState(() =>
            _error = 'No se pudo obtener una respuesta. Intenta nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))),
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
