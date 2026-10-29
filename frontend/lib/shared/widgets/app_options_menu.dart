import 'package:flutter/material.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/shared/services/pwa_service.dart';
import 'package:gastos_claros/shared/services/auth_session.dart';
import 'package:gastos_claros/features/auth/auth_gate.dart';

enum _AppAction { install, notifications, refresh, about, logout }

class AppOptionsMenu extends StatelessWidget {
  const AppOptionsMenu({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleAction(BuildContext context, _AppAction action) async {
    switch (action) {
      case _AppAction.install:
        try {
          final message = await PwaService.install();
          if (!context.mounted) return;
          _showMessage(context, message);
        } catch (_) {
          if (!context.mounted) return;
          _showMessage(context, 'No se pudo abrir la instalación. Usa el menú del navegador.');
        }
        return;
      case _AppAction.notifications:
        try {
          final permission = await PwaService.requestNotifications();
          if (!context.mounted) return;
          _showMessage(context, switch (permission) {
            'granted' => 'Avisos activados para futuros registros en este dispositivo.',
            'denied' => 'Los avisos están bloqueados. Actívalos en la configuración del navegador.',
            'push-unavailable' => 'Permiso concedido, pero falta configurar Web Push en Netlify o este navegador no lo admite.',
            _ => 'Este navegador no permite avisos, o no se concedió el permiso.',
          });
        } catch (_) {
          if (!context.mounted) return;
          _showMessage(context, 'No se pudo activar el permiso de avisos.');
        }
        return;
      case _AppAction.refresh:
        onRefresh();
        _showMessage(context, 'Datos actualizados.');
        return;
      case _AppAction.about:
        showAboutDialog(
          context: context,
          applicationName: 'GastosClaros',
          applicationVersion: '1.0.1',
          children: const [Text('Control personal de ingresos y gastos.')],
        );
        return;
      case _AppAction.logout:
        await AuthSession.logout();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AuthGate()),
          (_) => false,
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AppAction>(
      key: const ValueKey('app-options-menu'),
      tooltip: 'Opciones',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.mutedText),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => [
        if (PwaService.isAvailable)
          const PopupMenuItem(
            value: _AppAction.install,
            child: ListTile(
              leading: Icon(Icons.download_rounded),
              title: Text('Descargar app'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (PwaService.isAvailable)
          PopupMenuItem(
            value: _AppAction.notifications,
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(PwaService.notificationPermission == 'granted'
                  ? 'Avisos activados' : 'Activar avisos'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: _AppAction.refresh,
          child: ListTile(
            leading: Icon(Icons.refresh_rounded),
            title: Text('Actualizar datos'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: _AppAction.about,
          child: ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Acerca de'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: _AppAction.logout,
          child: ListTile(
            leading: Icon(Icons.logout_rounded),
            title: Text('Cerrar sesión'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
