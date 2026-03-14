import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/types/enums.dart';
import '../../../core/types/models.dart';
import '../data/case_repository.dart';

// Providers
final _caseRepositoryProvider = Provider<CaseRepository>(
  (ref) => createCaseRepository(),
);

final _casesProvider = FutureProvider.family<List<CaseSummary>, UserRole>(
  (ref, role) async {
    final repo = ref.watch(_caseRepositoryProvider);
    return repo.getCasesForRole(role);
  },
);

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _selectedFilterProvider = StateProvider<CaseState?>((ref) => null);

class CaseListScreen extends ConsumerWidget {
  const CaseListScreen({
    super.key,
    required this.role,
  });

  final UserRole role;

  String _getAppBarTitle() {
    switch (role) {
      case UserRole.police:
        return 'My Cases';
      case UserRole.sho:
        return 'All Cases';
      case UserRole.courtClerk:
        return 'Court Cases';
      case UserRole.judge:
        return 'Cases on Bench';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCases = ref.watch(_casesProvider(role));
    final searchQuery = ref.watch(_searchQueryProvider);
    final selectedFilter = ref.watch(_selectedFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchBottomSheet(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context, ref);
            },
          ),
        ],
      ),
      body: asyncCases.when(
        data: (cases) {
          // Apply filters
          var filteredCases = cases;
          
          if (searchQuery.isNotEmpty) {
            filteredCases = filteredCases.where((c) =>
              c.caseNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
              c.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (c.sectionsApplied?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
            ).toList();
          }
          
          if (selectedFilter != null) {
            filteredCases = filteredCases.where((c) =>
              c.state == selectedFilter || c.status == selectedFilter.backendValue
            ).toList();
          }

          if (filteredCases.isEmpty) {
            return _buildEmptyState(context, searchQuery.isNotEmpty || selectedFilter != null);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(_casesProvider(role));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final caseItem = filteredCases[index];
                return CaseCard(
                  caseSummary: caseItem,
                  onTap: () {
                    // TODO: Navigate to case detail
                    _showCaseDetailBottomSheet(context, caseItem);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget? _buildFAB() {
    // Only show FAB for roles that can create cases
    if (role == UserRole.police || role == UserRole.sho) {
      return FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to register FIR
        },
        icon: const Icon(Icons.add),
        label: const Text('New FIR'),
      );
    }
    return null;
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off : Icons.folder_open,
            size: 64,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No cases match your filters' : 'No cases found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Clear filters
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load cases',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(_casesProvider(role));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Cases',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by case number, title, or sections...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  ref.read(_searchQueryProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(context, ref, null, 'All'),
                ...CaseState.values.map((state) => 
                  _buildFilterChip(context, ref, state, state.displayName)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, CaseState? state, String label) {
    final selectedFilter = ref.watch(_selectedFilterProvider);
    final isSelected = selectedFilter == state;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        ref.read(_selectedFilterProvider.notifier).state = selected ? state : null;
        Navigator.pop(context);
      },
    );
  }

  void _showCaseDetailBottomSheet(BuildContext context, CaseSummary caseItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        caseItem.caseNumber,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    CaseStatusBadge(status: caseItem.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  caseItem.title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (caseItem.sectionsApplied != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sections: ${caseItem.sectionsApplied}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionChip(Icons.visibility, 'View Details'),
                    if (role == UserRole.police || role == UserRole.sho) ...[
                      _buildActionChip(Icons.upload_file, 'Add Evidence'),
                      _buildActionChip(Icons.person_add, 'Add Witness'),
                    ],
                    if (role == UserRole.sho)
                      _buildActionChip(Icons.send, 'Submit to Court'),
                    if (role == UserRole.courtClerk)
                      _buildActionChip(Icons.check_circle, 'Accept'),
                    if (role == UserRole.judge)
                      _buildActionChip(Icons.gavel, 'Add Action'),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to full case detail
                    },
                    child: const Text('View Full Details'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        // TODO: Implement action
      },
    );
  }
}

class CaseCard extends StatelessWidget {
  final CaseSummary caseSummary;
  final VoidCallback onTap;

  const CaseCard({
    super.key,
    required this.caseSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caseSummary.caseNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  CaseStatusBadge(status: caseSummary.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                caseSummary.title,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (caseSummary.sectionsApplied != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    caseSummary.sectionsApplied!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated ${_formatDate(caseSummary.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class CaseStatusBadge extends StatelessWidget {
  final String status;

  const CaseStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatStatus(status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _getStatusColor() {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('completed') || 
        statusLower.contains('accepted') ||
        statusLower.contains('disposed')) {
      return AppColors.success;
    } else if (statusLower.contains('pending') || 
               statusLower.contains('submitted')) {
      return AppColors.warning;
    } else if (statusLower.contains('rejected') || 
               statusLower.contains('returned')) {
      return AppColors.error;
    } else if (statusLower.contains('investigation') ||
               statusLower.contains('trial')) {
      return AppColors.stateInProgress;
    }
    return AppColors.info;
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
            : '')
        .join(' ');
  }
}
