import 'package:flutter/material.dart';

class AvailableSymptomsCard extends StatelessWidget {
  final List<String> displaySymptoms;
  final List<String> selectedSymptoms;
  final bool showAllSymptoms;
  final VoidCallback onToggleShowAll;
  final Function(String, bool) onSymptomToggle;

  const AvailableSymptomsCard({
    super.key,
    required this.displaySymptoms,
    required this.selectedSymptoms,
    required this.showAllSymptoms,
    required this.onToggleShowAll,
    required this.onSymptomToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  showAllSymptoms ? Icons.list_rounded : Icons.star_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  showAllSymptoms
                      ? 'All Symptoms (${displaySymptoms.length})'
                      : 'Common Symptoms (${displaySymptoms.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: displaySymptoms.length,
              itemBuilder: (context, index) {
                final symptom = displaySymptoms[index];
                final isSelected = selectedSymptoms.contains(symptom);
                return CheckboxListTile(
                  title: Text(symptom.replaceAll("_", " ")),
                  value: isSelected,
                  onChanged: (value) {
                    if (value != null) {
                      onSymptomToggle(symptom, value);
                    }
                  },
                );
              },
            ),
          ),
          if (!showAllSymptoms)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onToggleShowAll,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Show All Symptoms'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
