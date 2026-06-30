import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Diálogo de actualización obligatoria. No se puede cerrar: el único camino
/// es ir a la tienda. Se muestra cuando el backend indica que la versión
/// instalada quedó por debajo de la mínima soportada.
class ForceUpdateDialog extends StatelessWidget {
  final String storeUrl;
  const ForceUpdateDialog({super.key, required this.storeUrl});

  Future<void> _openStore() async {
    final uri = Uri.parse(storeUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // canPop: false bloquea el botón "atrás" de Android; barrierDismissible
    // false (en el showDialog) bloquea el toque fuera del diálogo.
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.system_update, size: 36),
        title: Text(t.updateRequiredTitle),
        content: Text(t.updateRequiredBody),
        actions: [
          FilledButton(
            onPressed: storeUrl.isEmpty ? null : _openStore,
            child: Text(t.updateNow),
          ),
        ],
      ),
    );
  }
}
