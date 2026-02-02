import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/api_service.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'services/firestore_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Disease Prediction',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0891B2),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0891B2),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      // Temporarily bypass login - go directly to symptom screen
      home: SymptomScreen(onToggleTheme: _toggleTheme, themeMode: _themeMode),
      // TODO: Re-enable authentication after fixing Google Sign-In
      // home: StreamBuilder<User?>(
      //   stream: AuthService().authStateChanges,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Scaffold(
      //         body: Center(child: CircularProgressIndicator()),
      //       );
      //     }
      //     if (snapshot.hasData) {
      //       return const SymptomScreen();
      //     }
      //     return const LoginScreen();
      //   },
      // ),
    );
  }
}

class SymptomScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const SymptomScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> {
  List<String> allSymptoms = [];
  List<String> commonSymptoms = [];
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

    // Define common symptoms
    final common = [
      'fever',
      'headache',
      'cough',
      'fatigue',
      'skin_rash',
      'chills',
      'joint_pain',
      'vomiting',
      'nausea',
      'diarrhoea',
      'chest_pain',
      'breathlessness',
      'muscle_pain',
      'loss_of_appetite',
      'abdominal_pain',
    ];

    setState(() {
      allSymptoms = data.cast<String>();
      commonSymptoms = allSymptoms.where((s) => common.contains(s)).toList();
    });
  }

  String getGuidanceText() {
    final count = selectedSymptoms.length;
    if (count == 0) return 'Tap symptoms below or use search to begin';
    if (count < 4)
      return '$count symptom${count > 1 ? "s" : ""} selected • Add ${4 - count} more for better accuracy';
    return '✓ $count symptoms selected • Great! Ready to predict';
  }

  Color getGuidanceColor() {
    final count = selectedSymptoms.length;
    if (count == 0) return Colors.grey;
    if (count < 4) return Colors.orange;
    return Colors.green;
  }

  IconData getGuidanceIcon() {
    final count = selectedSymptoms.length;
    if (count == 0) return Icons.touch_app_rounded;
    if (count < 4) return Icons.add_circle_outline;
    return Icons.check_circle;
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

  @override
  Widget build(BuildContext context) {
    final displaySymptoms = showAllSymptoms ? allSymptoms : commonSymptoms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Prediction'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: widget.themeMode == ThemeMode.light
                ? 'Switch to Dark Mode'
                : 'Switch to Light Mode',
            onPressed: widget.onToggleTheme,
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
          // Temporarily disabled user menu (login not working)
          // TODO: Re-enable after fixing Google Sign-In
          // PopupMenuButton<String>(
          //   icon: CircleAvatar(
          //     backgroundColor: Theme.of(context).colorScheme.primary,
          //     child: Text(
          //       (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
          //       style: const TextStyle(color: Colors.white),
          //     ),
          //   ),
          //   itemBuilder: (context) => <PopupMenuEntry<String>>[
          //     PopupMenuItem<String>(
          //       enabled: false,
          //       child: ListTile(
          //         leading: const Icon(Icons.person),
          //         title: Text(user?.displayName ?? 'User'),
          //         subtitle: Text(user?.email ?? ''),
          //         contentPadding: EdgeInsets.zero,
          //       ),
          //     ),
          //     const PopupMenuDivider(),
          //     PopupMenuItem<String>(
          //       value: 'signout',
          //       child: const ListTile(
          //         leading: Icon(Icons.logout),
          //         title: Text('Sign Out'),
          //         contentPadding: EdgeInsets.zero,
          //       ),
          //     ),
          //   ],
          //   onSelected: (value) async {
          //     if (value == 'signout') {
          //       await AuthService().signOut();
          //     }
          //   },
          // ),
        ],
      ),
      body: allSymptoms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Guidance Section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        getGuidanceColor().withOpacity(0.15),
                        getGuidanceColor().withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: getGuidanceColor().withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: getGuidanceColor().withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getGuidanceIcon(),
                          color: getGuidanceColor(),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          getGuidanceText(),
                          style: TextStyle(
                            color: getGuidanceColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Search',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return allSymptoms.where((symptom) {
                            return symptom.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                ) &&
                                !selectedSymptoms.contains(symptom);
                          });
                        },
                        displayStringForOption: (option) =>
                            option.replaceAll("_", " "),
                        onSelected: (String selection) {
                          setState(() {
                            selectedSymptoms.add(selection);
                          });
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: "Search for symptoms",
                                  hintText: "Type: fever, cough, headache...",
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  suffixIcon:
                                      textEditingController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            textEditingController.clear();
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Selected Symptoms
                if (selectedSymptoms.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.playlist_add_check_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Symptoms',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${selectedSymptoms.length}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (selectedSymptoms.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    selectedSymptoms.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Clear All'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedSymptoms.map((symptom) {
                            return Chip(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              label: Text(
                                symptom.replaceAll("_", " "),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  selectedSymptoms.remove(symptom);
                                });
                              },
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Available Symptoms List
                Expanded(
                  child: Card(
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
                                showAllSymptoms
                                    ? Icons.list_rounded
                                    : Icons.star_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                showAllSymptoms
                                    ? 'All Symptoms (${displaySymptoms.length})'
                                    : 'Common Symptoms (${displaySymptoms.length})',
                                style: Theme.of(context).textTheme.titleMedium
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
                              final isSelected = selectedSymptoms.contains(
                                symptom,
                              );
                              return CheckboxListTile(
                                title: Text(symptom.replaceAll("_", " ")),
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedSymptoms.add(symptom);
                                    } else {
                                      selectedSymptoms.remove(symptom);
                                    }
                                  });
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
                                onPressed: () {
                                  setState(() {
                                    showAllSymptoms = true;
                                  });
                                },
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Show All Symptoms'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Section
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
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiaryContainer.withOpacity(0.3),
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiaryContainer,
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
                              : () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  try {
                                    final rawResult =
                                        await ApiService.predictDisease(
                                          selectedSymptoms,
                                        );
                                    final normalizedResult =
                                        _normalizePrediction(rawResult);

                                    // Save to Firestore
                                    await firestoreService.savePrediction(
                                      symptoms: selectedSymptoms,
                                      predictedDisease:
                                          normalizedResult['predicted_disease'],
                                      confidence:
                                          normalizedResult['confidence_percent'],
                                      top3: List<Map<String, dynamic>>.from(
                                        normalizedResult['top3_maps'] ?? [],
                                      ),
                                    );

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ResultScreen(
                                            result: normalizedResult,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "Unable to connect. Please check internet.",
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.error,
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
                                },
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
