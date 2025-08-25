import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise_model.dart';
import '../models/workoutitem_model.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class CreateWorkoutPage extends StatefulWidget {
  const CreateWorkoutPage({super.key});

  @override
  State<CreateWorkoutPage> createState() => _CreateWorkoutPageState();
}

class _CreateWorkoutPageState extends State<CreateWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();

  // Focus nodes for better keyboard navigation
  final _nameFocusNode = FocusNode();
  final _durationFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  List<Exercise> _exercises = [];
  List<WorkoutItemData> _workoutItems = [];
  bool _isLoading = false;
  bool _isLoadingExercises = true;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
    _durationController.text = '30';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _nameFocusNode.dispose();
    _durationFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    try {
      final exercises = await ApiService.getExercises();
      setState(() {
        _exercises = exercises;
        _isLoadingExercises = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingExercises = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Egzersizler yüklenemedi: $e')));
      }
    }
  }

  Future<void> _createWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workoutItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir egzersiz eklemelisiniz')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.createWorkoutWithItems(
        name: _nameController.text.trim(),
        duration: double.parse(_durationController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? ''
            : _descriptionController.text.trim(),
        image: _imageController.text.trim().isEmpty
            ? ''
            : _imageController.text.trim(),
        workoutItems: _workoutItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Antrenman başarıyla oluşturuldu!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      developer.log('Error creating workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Antrenman oluşturulamadı: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addWorkoutItem() {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddWorkoutItemSheet(),
    );
  }

  void _removeWorkoutItem(int index) {
    setState(() {
      _workoutItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Antrenman Oluştur'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: _createWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('KAYDET'),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrenman Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Workout Name
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Antrenman Adı *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: const Icon(Icons.fitness_center),
                          ),
                          style: const TextStyle(fontSize: 16),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_durationFocusNode);
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Antrenman adı gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Duration Input
                        TextFormField(
                          controller: _durationController,
                          focusNode: _durationFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Süre (dakika) *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: const Icon(Icons.access_time),
                            suffixText: 'dk',
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_descriptionFocusNode);
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Süre gerekli';
                            }
                            final duration = int.tryParse(value.trim());
                            if (duration == null) {
                              return 'Geçerli bir sayı girin';
                            }
                            if (duration < 5 || duration > 180) {
                              return 'Süre 5-180 dakika arasında olmalı';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Açıklama',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: const Icon(Icons.description),
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Workout Items
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Egzersizler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                            ),
                            Container(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingExercises
                                    ? null
                                    : _addWorkoutItem,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Egzersiz Ekle'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_workoutItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 64,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Henüz egzersiz eklenmedi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _workoutItems.length,
                            itemBuilder: (context, index) {
                              final item = _workoutItems[index];
                              final exercise = _exercises.firstWhere(
                                (e) => e.id == item.exerciseId,
                                orElse: () => Exercise(
                                  id: '',
                                  createdAt: DateTime.now(),
                                  isDeleted: false,
                                  consumerId: '',
                                  consumer: '',
                                  name: 'Bilinmeyen Egzersiz',
                                ),
                              );
                              return _buildWorkoutItemCard(
                                item,
                                exercise,
                                index,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutItemCard(
    WorkoutItemData item,
    Exercise exercise,
    int index,
  ) {
    String unitText = _getUnitDisplayText(item.unit);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name ?? 'Bilinmeyen Egzersiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.set} set × ${item.quantity} $unitText',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                  onPressed: () => _removeWorkoutItem(index),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddWorkoutItemSheet() {
    Exercise? selectedExercise;
    Unit selectedUnit = Unit.reps;
    final setsController = TextEditingController(text: '3');
    final quantityController = TextEditingController(text: '10');

    final setsFocusNode = FocusNode();
    final quantityFocusNode = FocusNode();

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[300]
                          : Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Egzersiz Ekle',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                        ),
                        Container(
                          height: 40,
                          child: ElevatedButton(
                            onPressed:
                                selectedExercise != null &&
                                    setsController.text.isNotEmpty &&
                                    quantityController.text.isNotEmpty &&
                                    int.tryParse(setsController.text) != null &&
                                    int.tryParse(quantityController.text) !=
                                        null &&
                                    int.parse(setsController.text) > 0 &&
                                    int.parse(quantityController.text) > 0
                                ? () {
                                    FocusScope.of(context).unfocus();

                                    setState(() {
                                      _workoutItems.add(
                                        WorkoutItemData(
                                          exerciseId: selectedExercise!.id,
                                          unit: selectedUnit,
                                          set: int.parse(setsController.text),
                                          quantity: int.parse(
                                            quantityController.text,
                                          ),
                                        ),
                                      );
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('EKLE'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exercise Selection
                          Text(
                            'Egzersiz',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[300]!
                                    : Colors.grey[600]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Exercise>(
                                value: selectedExercise,
                                hint: const Text('Egzersiz seçin'),
                                isExpanded: true,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                                items: _exercises.map((exercise) {
                                  return DropdownMenuItem<Exercise>(
                                    value: exercise,
                                    child: Text(
                                      exercise.name ?? 'İsimsiz Egzersiz',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Exercise? value) {
                                  setSheetState(() {
                                    selectedExercise = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Unit Selection
                          Text(
                            'Birim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: Unit.values.map((unit) {
                              String unitText = '';
                              IconData unitIcon = Icons.fitness_center;

                              switch (unit) {
                                case Unit.reps:
                                  unitText = 'Tekrar';
                                  unitIcon = Icons.repeat;
                                  break;
                                case Unit.distance:
                                  unitText = 'Mesafe';
                                  unitIcon = Icons.straighten;
                                  break;
                                case Unit.sec:
                                  unitText = 'Süre';
                                  unitIcon = Icons.timer;
                                  break;
                              }

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();

                                    setSheetState(() {
                                      selectedUnit = unit;
                                      switch (unit) {
                                        case Unit.reps:
                                          quantityController.text = '10';
                                          break;
                                        case Unit.distance:
                                          quantityController.text = '5';
                                          break;
                                        case Unit.sec:
                                          quantityController.text = '60';
                                          break;
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: unit != Unit.values.last ? 8 : 0,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selectedUnit == unit
                                          ? Theme.of(context).primaryColor
                                          : (Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.grey[100]
                                                : Colors.grey[700]),
                                      borderRadius: BorderRadius.circular(12),
                                      border: selectedUnit == unit
                                          ? null
                                          : Border.all(
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.light
                                                  ? Colors.grey[300]!
                                                  : Colors.grey[600]!,
                                            ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          unitIcon,
                                          size: 24,
                                          color: selectedUnit == unit
                                              ? Colors.white
                                              : (Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.grey[600]
                                                    : Colors.grey[400]),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          unitText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: selectedUnit == unit
                                                ? Colors.white
                                                : Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Sets and Quantity
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: setsController,
                                  focusNode: setsFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Set',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(quantityFocusNode);
                                  },
                                  onChanged: (value) {
                                    setSheetState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: quantityController,
                                  focusNode: quantityFocusNode,
                                  decoration: InputDecoration(
                                    labelText: _getQuantityLabel(selectedUnit),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    suffixText: _getQuantitySuffix(
                                      selectedUnit,
                                    ),
                                  ),
                                  keyboardType: selectedUnit == Unit.distance
                                      ? const TextInputType.numberWithOptions(
                                          decimal: true,
                                        )
                                      : TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: selectedUnit == Unit.distance
                                      ? [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d{0,2}'),
                                          ),
                                          LengthLimitingTextInputFormatter(5),
                                        ]
                                      : [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  onChanged: (value) {
                                    setSheetState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getQuantityLabel(Unit unit) {
    switch (unit) {
      case Unit.reps:
        return 'Tekrar';
      case Unit.distance:
        return 'Mesafe';
      case Unit.sec:
        return 'Süre';
    }
  }

  String _getQuantitySuffix(Unit unit) {
    switch (unit) {
      case Unit.reps:
        return 'tekrar';
      case Unit.distance:
        return 'km';
      case Unit.sec:
        return 'saniye';
    }
  }

  String _getUnitDisplayText(Unit unit) {
    switch (unit) {
      case Unit.reps:
        return 'tekrar';
      case Unit.distance:
        return 'km';
      case Unit.sec:
        return 'saniye';
    }
  }
}

class WorkoutItemData {
  final String exerciseId;
  final Unit unit;
  final int set;
  final int quantity;

  WorkoutItemData({
    required this.exerciseId,
    required this.unit,
    required this.set,
    required this.quantity,
  });
}
