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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.85),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.75),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    showAllSymptoms ? Icons.list_rounded : Icons.star_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  showAllSymptoms
                      ? 'All Symptoms (${displaySymptoms.length})'
                      : 'Common Symptoms (${displaySymptoms.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
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
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      symptom.replaceAll("_", " "),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    value: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        onSymptomToggle(symptom, value);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          if (!showAllSymptoms)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onToggleShowAll,
                  icon: const Icon(Icons.expand_more, size: 20),
                  label: const Text(
                    'Show All Symptoms',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
