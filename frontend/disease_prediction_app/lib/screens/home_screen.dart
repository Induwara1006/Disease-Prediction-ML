import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/guidance_section.dart';
import '../widgets/symptom_search_bar.dart';
import '../widgets/selected_symptoms_list.dart';
import '../widgets/available_symptoms_card.dart';
import '../constants.dart';
import 'result_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> allSymptoms = [];
  List<String> displaySymptoms = []; // To handle showing common vs all
  List<String> selectedSymptoms = [];
  bool isLoading = false;
  bool showAllSymptoms = false;
  final firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    loadSymptoms();
  }

  Future<void> loadSymptoms() async {
    final String response = await rootBundle.loadString('assets/symptoms.json');
    final List<dynamic> data = json.decode(response);
    
    setState(() {
      allSymptoms = data.cast<String>();
      _updateDisplaySymptoms();
    });
  }

  void _updateDisplaySymptoms() {
      if (showAllSymptoms) {
        displaySymptoms = allSymptoms;
      } else {
        displaySymptoms = allSymptoms.where((s) => AppConstants.commonSymptoms.contains(s)).toList();
      }
  }

  // Normalize backend response to a consistent shape used by UI and Firestore
  Map<String, dynamic> _normalizePrediction(Map<String, dynamic> raw) {
    final predictedDisease =
        (raw['predicted_disease'] ?? raw['disease'] ?? 'Unknown').toString();

    final confidencePercent =
        double.tryParse(
          (raw['confidence_percent'] ?? raw['confidence'] ?? 0).toString(),
        ) ??
        0.0;

    final top3Names = _extractTop3Names(raw);
    final top3Maps = _extractTop3Maps(raw, top3Names);

    return {
      'predicted_disease': predictedDisease,
      'confidence_percent': confidencePercent,
      'top_3_diseases': top3Names,
      'top3_maps': top3Maps,
    };
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  List<String> _extractTop3Names(Map<String, dynamic> raw) {
    final dynamic top3 =
        raw['top_3_diseases'] ?? raw['top_3'] ?? raw['top3'] ?? [];

    if (top3 is! List) return [];

    return top3
        .map((item) {
          if (item is String) return item;
          if (item is Map && item['disease'] != null) {
            return item['disease'].toString();
          }
          return item.toString();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _extractTop3Maps(
    Map<String, dynamic> raw,
    List<String> fallbackNames,
  ) {
    final dynamic top3 = raw['top_3'] ?? raw['top3'] ?? raw['top_3_diseases'];

    if (top3 is List && top3.isNotEmpty) {
      return top3.map<Map<String, dynamic>>((item) {
        if (item is Map) {
          return {
            'disease': item['disease']?.toString() ?? '',
            'confidence': _toDouble(item['confidence']),
          };
        }
        return {'disease': item.toString(), 'confidence': 0.0};
      }).toList();
    }

    // Fallback: build map entries from names when only strings are provided
    return fallbackNames
        .map((name) => {'disease': name, 'confidence': 0.0})
        .toList();
  }

  Future<void> _handlePrediction() async {
    setState(() {
      isLoading = true;
    });

    try {
      final rawResult = await ApiService.predictDisease(selectedSymptoms);
      final normalizedResult = _normalizePrediction(rawResult);

      // Save to Firestore
      await firestoreService.savePrediction(
        symptoms: selectedSymptoms,
        predictedDisease: normalizedResult['predicted_disease'],
        confidence: normalizedResult['confidence_percent'],
        top3: List<Map<String, dynamic>>.from(
          normalizedResult['top3_maps'] ?? [],
        ),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(result: normalizedResult),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Unable to connect. Please check internet."),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure display symptoms are up to date
    _updateDisplaySymptoms();

    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Prediction'),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: allSymptoms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GuidanceSection(selectedCount: selectedSymptoms.length),
                SymptomSearchBar(
                  allSymptoms: allSymptoms,
                  selectedSymptoms: selectedSymptoms,
                  onSymptomSelected: (selection) {
                    setState(() {
                       if (!selectedSymptoms.contains(selection)) {
                        selectedSymptoms.add(selection);
                       }
                    });
                  },
                ),
                const SizedBox(height: 16),
                SelectedSymptomsList(
                  selectedSymptoms: selectedSymptoms,
                  onClearAll: () {
                    setState(() {
                      selectedSymptoms.clear();
                    });
                  },
                  onRemoveSymptom: (symptom) {
                    setState(() {
                      selectedSymptoms.remove(symptom);
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: AvailableSymptomsCard(
                    displaySymptoms: displaySymptoms,
                    selectedSymptoms: selectedSymptoms,
                    showAllSymptoms: showAllSymptoms,
                    onToggleShowAll: () {
                      setState(() {
                        showAllSymptoms = true;
                      });
                    },
                    onSymptomToggle: (symptom, isSelected) {
                      setState(() {
                        if (isSelected) {
                          selectedSymptoms.add(symptom);
                        } else {
                          selectedSymptoms.remove(symptom);
                        }
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (selectedSymptoms.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "This tool supports awareness, not replace a doctor's diagnosis",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onTertiaryContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (selectedSymptoms.isEmpty || isLoading)
                              ? null
                              : _handlePrediction,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.psychology_rounded),
                          label: Text(
                            isLoading
                                ? "Analyzing symptoms..."
                                : "Predict Disease",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
