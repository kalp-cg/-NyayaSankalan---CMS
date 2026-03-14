import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cases/data/case_repository.dart';
import '../../../core/types/models.dart';

final _publicCasesRepositoryProvider = Provider<CaseRepository>(
  (ref) => createCaseRepository(),
);

final _publicResolvedCasesProvider =
    FutureProvider<List<CaseSummary>>((ref) async {
  final repo = ref.watch(_publicCasesRepositoryProvider);
  return repo.getPublicResolvedCases();
});

class PublicResolvedCasesScreen extends ConsumerWidget {
  const PublicResolvedCasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCases = ref.watch(_publicResolvedCasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolved Cases - Public View'),
      ),
      body: asyncCases.when(
        data: (cases) {
          if (cases.isEmpty) {
            return const Center(
              child: Text('No resolved cases available for public view.'),
            );
          }

          return ListView.builder(
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final item = cases[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.caseNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${item.status}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${item.lastUpdated.toLocal()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Failed to load resolved cases.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // ignore: unused_result
                      ref.refresh(_publicResolvedCasesProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

