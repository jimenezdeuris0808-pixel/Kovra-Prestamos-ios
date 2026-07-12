import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../../domain/models/cobros_hoy.dart';
import '../../../domain/models/dashboard_resumen.dart';

final dashboardResumenProvider =
    FutureProvider.autoDispose<DashboardResumen>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  try {
    return await repo.obtenerResumen();
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

/// Snapshot ejecutivo de cartera (`GET /dashboard/resumen_general`) para la
/// sección de resumen denso del dashboard.
final dashboardResumenGeneralProvider =
    FutureProvider.autoDispose<DashboardResumenGeneral>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  try {
    return await repo.obtenerResumenGeneral();
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

/// Cuotas atrasadas y pagos cobrados hoy (`GET /dashboard/cobros_hoy`) para
/// la pantalla "Cobrar" del bottom nav.
final dashboardCobrosHoyProvider =
    FutureProvider.autoDispose<DashboardCobrosHoy>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  try {
    return await repo.obtenerCobrosHoy();
  } catch (e) {
    throw extractErrorMessage(e);
  }
});
