import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

/// Resultado de comprobar la versión contra el backend.
class VersionCheck {
  /// La versión instalada es menor que la mínima soportada: hay que forzar
  /// la actualización antes de seguir usando la app.
  final bool mustUpdate;

  /// URL de la tienda correspondiente a la plataforma actual.
  final String storeUrl;

  const VersionCheck({required this.mustUpdate, required this.storeUrl});
}

/// Consulta `GET /version` y decide si la versión instalada quedó obsoleta.
class VersionService {
  static const _timeout = Duration(seconds: 8);

  /// Devuelve el resultado de la comprobación, o `null` si no se pudo
  /// determinar (sin red, error del servidor, etc.). Nunca lanza: una caída
  /// de red no debe bloquear el arranque de la app.
  Future<VersionCheck?> check() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/version'))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final minSupported = data['minSupported'] as String?;
      if (minSupported == null) return null;

      final info = await PackageInfo.fromPlatform();
      final installed = info.version; // ej. "1.0.3" (sin el build number)

      final storeUrl = Platform.isIOS
          ? (data['storeUrlIos'] as String? ?? '')
          : (data['storeUrlAndroid'] as String? ?? '');

      return VersionCheck(
        mustUpdate: _isLower(installed, minSupported),
        storeUrl: storeUrl,
      );
    } catch (e) {
      debugPrint('VersionService.check fallo: $e');
      return null;
    }
  }

  /// `true` si [a] es una versión semver estrictamente menor que [b].
  /// Compara por segmentos numéricos (1.0.10 > 1.0.9). Ignora sufijos.
  static bool _isLower(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final na = i < pa.length ? pa[i] : 0;
      final nb = i < pb.length ? pb[i] : 0;
      if (na != nb) return na < nb;
    }
    return false; // iguales
  }

  static List<int> _parts(String v) => v
      .split('+')
      .first // descarta el build number "+6" si viniera incluido
      .split('.')
      .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
