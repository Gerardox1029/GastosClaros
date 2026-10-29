import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/features/splash/splash_screen.dart';
import 'package:gastos_claros/shared/services/auth_session.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _pin = TextEditingController();
  bool _checking = true;
  bool _busy = false;
  bool _authenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AuthSession.restore().then((ok) {
      if (mounted) setState(() { _authenticated = ok; _checking = false; });
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_pin.text.length < 6) {
      setState(() => _error = 'Ingresa un PIN de 6 a 12 dígitos.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final error = await AuthSession.login(_pin.text);
    if (!mounted) return;
    _pin.clear();
    setState(() { _busy = false; _error = error; _authenticated = error == null; });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_authenticated) return const SplashScreen();
    return Scaffold(
      backgroundColor: AppColors.deepPurpleBg,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.accentPurple),
            const SizedBox(height: AppSpacing.lg),
            Text('GastosClaros', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('Ingresa tu PIN para ver tus movimientos.'),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 12,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'PIN numérico',
                prefixIcon: Icon(Icons.pin_outlined)),
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(_error!, style: const TextStyle(color: AppColors.dangerRed)),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Ingresar'),
            )),
          ]),
        ),
      ))),
    );
  }
}
