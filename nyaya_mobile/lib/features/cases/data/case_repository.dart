import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/types/enums.dart';
import '../../../core/types/models.dart';

class CaseRepository {
  CaseRepository(this._dio);

  final Dio _dio;

  /// GET /api/cases/my   → Police (only their assigned cases)
  /// GET /api/cases/all  → SHO / CourtClerk / Judge (all cases)
  Future<List<CaseSummary>> getCasesForRole(UserRole role) async {
    final endpoint = switch (role) {
      UserRole.police => '/cases/my',
      UserRole.sho => '/cases/all',
      UserRole.courtClerk => '/cases/all',
      UserRole.judge => '/cases/all',
    };

    final response = await _dio.get<Map<String, dynamic>>(endpoint);

    final body = response.data ?? {};
    // Backend wraps list in { success, data: [...] }
    final raw = body['data'];
    if (raw == null) return [];

    final list = raw is List ? raw : (raw['cases'] ?? []) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(CaseSummary.fromJson)
        .toList();
  }

  /// There is no public /cases endpoint in the backend.
  /// For public resolved cases we fetch all and filter by state.
  Future<List<CaseSummary>> getPublicResolvedCases() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cases/all',
        queryParameters: {'state': 'DISPOSED'},
      );
      final body = response.data ?? {};
      final raw = body['data'];
      if (raw == null) return [];
      final list = raw is List ? raw : (raw['cases'] ?? []) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CaseSummary.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Case> getCaseById(String caseId) async {
    final response = await _dio.get<Map<String, dynamic>>('/cases/$caseId');
    final data = response.data?['data'] ?? response.data;
    return Case.fromJson(data as Map<String, dynamic>);
  }
}

CaseRepository createCaseRepository() {
  final client = ApiClient();
  return CaseRepository(client.dio);
}
