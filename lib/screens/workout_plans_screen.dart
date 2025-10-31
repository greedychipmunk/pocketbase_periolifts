import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../providers/workout_plan_providers.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

// State provider for the current filter
final _currentFilterProvider = StateProvider<WorkoutPlansFilter>((ref) {
  return const WorkoutPlansFilter(activeOnly: true);
});

class WorkoutPlansScreen extends ConsumerWidget {
  const WorkoutPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_currentFilterProvider);
    final plansAsync = ref.watch(workoutPlansProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plans'),
        actions: [
          IconButton(
            icon: Icon(
              filter.activeOnly ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              final newFilter = filter.copyWith(activeOnly: !filter.activeOnly);
              ref.read(_currentFilterProvider.notifier).state = newFilter;
            },
            tooltip: filter.activeOnly ? 'Show All Plans' : 'Show Active Only',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(workoutPlansProvider(filter));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search workout plans...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final newFilter = filter.copyWith(
                  searchQuery: value.isEmpty ? null : value,
                );
                ref.read(_currentFilterProvider.notifier).state = newFilter;
              },
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Active'),
                  selected: filter.activeOnly,
                  onSelected: (selected) {
                    final newFilter = filter.copyWith(activeOnly: selected);
                    ref.read(_currentFilterProvider.notifier).state = newFilter;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Plans list
          Expanded(
            child: plansAsync.when(
              data: (plans) => _buildPlansList(context, ref, plans),
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorMessage(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(workoutPlansProvider(filter));
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePlanDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Create New Plan',
      ),
    );
  }

  Widget _buildPlansList(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutPlan> plans,
  ) {
    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No workout plans found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first workout plan to get started',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, ref, plan);
      },
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, WorkoutPlan plan) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          plan.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.description.isNotEmpty)
              Text(
                plan.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Starts: ${_formatDate(plan.startDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(
                  plan.isActive ? Icons.play_circle : Icons.pause_circle,
                  size: 16,
                  color: plan.isActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  plan.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: plan.isActive ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePlanAction(context, ref, value, plan),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: plan.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(plan.isActive ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(plan.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openPlanDetails(context, plan),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handlePlanAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    WorkoutPlan plan,
  ) async {
    final filter = ref.read(_currentFilterProvider);
    final notifier = ref.read(workoutPlansProvider(filter).notifier);

    switch (action) {
      case 'activate':
      case 'deactivate':
        final updatedPlan = plan.copyWith(isActive: !plan.isActive);
        await notifier.updatePlan(updatedPlan);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                plan.isActive
                    ? 'Plan deactivated successfully'
                    : 'Plan activated successfully',
              ),
            ),
          );
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Plan'),
            content: Text('Are you sure you want to delete "${plan.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await notifier.deletePlan(plan.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan deleted successfully')),
            );
          }
        }
        break;
    }
  }

  void _openPlanDetails(BuildContext context, WorkoutPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening details for: ${plan.name}')),
    );
  }

  void _showCreatePlanDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => const _PlanCreationDialog(),
    );
  }
}

class _PlanCreationDialog extends ConsumerStatefulWidget {
  const _PlanCreationDialog();

  @override
  ConsumerState<_PlanCreationDialog> createState() =>
      _PlanCreationDialogState();
}

class _PlanCreationDialogState extends ConsumerState<_PlanCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(planCreationFormProvider);

    return AlertDialog(
      title: const Text('Create Workout Plan'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  hintText: 'Enter plan name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a plan name';
                  }
                  if (value.trim().length < 2) {
                    return 'Plan name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(planCreationFormProvider.notifier).updateName(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter plan description',
                ),
                maxLines: 3,
                onChanged: (value) {
                  ref
                      .read(planCreationFormProvider.notifier)
                      .updateDescription(value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: formState.isActive,
                    onChanged: (value) {
                      ref
                          .read(planCreationFormProvider.notifier)
                          .updateIsActive(value ?? true);
                    },
                  ),
                  const Text('Start plan immediately'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: formState.isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: formState.isLoading || !formState.isValid
              ? null
              : () => _createPlan(),
          child: formState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(planCreationFormProvider);
    final userId = 'test-user-id'; // TODO: Get from auth service

    final plan = formState.toPlan(userId);

    // Create the plan using the service directly since there's no createPlan in form notifier
    final filter = ref.read(_currentFilterProvider);
    final notifier = ref.read(workoutPlansProvider(filter).notifier);

    await notifier.createPlan(plan);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan created successfully')),
      );
    }
  }
}
