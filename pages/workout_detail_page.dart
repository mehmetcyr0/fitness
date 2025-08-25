import 'package:fitness/models/html.dart';
import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../models/workoutitem_model.dart';
import '../models/exercise_model.dart';
import '../services/api_service.dart'; // Added import for API service

import 'dart:developer' as developer; // Added import for logging

class WorkoutDetailPage extends StatefulWidget {
  final WorkOut workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late WorkOut workout;
  final bool _isLoading = false;
  List<WorkOutItem> _workoutItems = [];
  bool _isLoadingWorkoutItems = true;
  String? _workoutItemsError;
  final Map<String, Exercise> _exercisesCache = {};

  @override
  void initState() {
    super.initState();
    workout = widget.workout;
    _loadWorkoutItems(); // Load workout items on init
  }

  Future<void> _loadWorkoutItems() async {
    try {
      setState(() {
        _isLoadingWorkoutItems = true;
        _workoutItemsError = null;
      });

      developer.log('=== WORKOUT DEBUG INFO ===', name: 'WorkoutDetailPage');
      developer.log('Workout ID: ${workout.id}', name: 'WorkoutDetailPage');
      developer.log('Workout Name: ${workout.name}', name: 'WorkoutDetailPage');
      developer.log(
        'Loading workout items for workout: ${workout.id}',
        name: 'WorkoutDetailPage',
      );

      final allWorkoutItems = await ApiService.getWorkoutItems(workout.id);

      final workoutItems = allWorkoutItems
          .where((item) => item.workOutId == workout.id && !(item.isDeleted))
          .toList();

      developer.log('=== WORKOUT ITEMS DEBUG ===', name: 'WorkoutDetailPage');
      developer.log(
        'Total workout items returned from API: ${allWorkoutItems.length}',
        name: 'WorkoutDetailPage',
      );
      developer.log(
        'Filtered workout items for this workout: ${workoutItems.length}',
        name: 'WorkoutDetailPage',
      );

      for (int i = 0; i < workoutItems.length; i++) {
        final item = workoutItems[i];
        developer.log(
          'WorkoutItem $i: ID=${item.id}, workOutId=${item.workOutId}, exerciseId=${item.exerciseId}',
          name: 'WorkoutDetailPage',
        );
      }

      List<WorkOutItem> filteredWorkoutItems = [];

      for (final workoutItem in workoutItems) {
        if (workoutItem.exerciseId.isNotEmpty &&
            !_exercisesCache.containsKey(workoutItem.exerciseId)) {
          try {
            final exercise = await ApiService.getExerciseById(
              workoutItem.exerciseId,
            );
            if (exercise != null) {
              _exercisesCache[workoutItem.exerciseId] = exercise;
              developer.log(
                'Fetched exercise: ${exercise.name} for ID: ${workoutItem.exerciseId}',
                name: 'WorkoutDetailPage',
              );
            }
          } catch (e) {
            developer.log(
              'Error fetching exercise ${workoutItem.exerciseId}: $e',
              name: 'WorkoutDetailPage',
            );
          }
        }

        // Check if exercise exists and is not deleted
        final exercise = _exercisesCache[workoutItem.exerciseId];
        if (exercise != null && !(exercise.isDeleted)) {
          filteredWorkoutItems.add(workoutItem);
        }
      }

      setState(() {
        _workoutItems = filteredWorkoutItems;
        _isLoadingWorkoutItems = false;
      });

      developer.log('=== FINAL RESULTS ===', name: 'WorkoutDetailPage');
      developer.log(
        'Loaded ${filteredWorkoutItems.length} workout items with ${_exercisesCache.length} exercises',
        name: 'WorkoutDetailPage',
      );
    } catch (e) {
      developer.log(
        'Error loading workout items: $e',
        name: 'WorkoutDetailPage',
      );
      setState(() {
        _workoutItemsError = e.toString();
        _isLoadingWorkoutItems = false;
      });
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

  int _calculateTotalCalories() {
    // Basit kalori hesaplama - gerçek uygulamada daha karmaşık olabilir
    if (_workoutItems.isEmpty) {
      return (workout.duration * 6).toInt(); // Dakika başına ~6 kalori
    }

    int totalCalories = 0;
    for (final item in _workoutItems) {
      // Her set için yaklaşık kalori hesaplama
      int caloriesPerSet = 0;

      totalCalories += caloriesPerSet * item.set;
    }
    return totalCalories;
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _calculateTotalCalories();
    final workoutItems = _workoutItems;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.light
                        ? [const Color(0xFFE8F5E8), const Color(0xFFD4F4D4)]
                        : [Colors.grey[900]!, Colors.grey[800]!],
                  ),
                ),
                child: workout.image != null && workout.image!.isNotEmpty
                    ? Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.network(
                              workout.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFFE8F5E8)
                                      : Colors.grey[800],
                                  child: Center(
                                    child: Icon(
                                      Icons.fitness_center,
                                      size: 64,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Text(
                              workout.name ?? 'İsimsiz Antrenman',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              workout.name ?? 'İsimsiz Antrenman',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(
                    children: [
                      _buildStatCard(
                        Icons.fitness_center,
                        '${workoutItems.length} egzersiz',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        Icons.local_fire_department,
                        '$totalCalories kcal',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        Icons.access_time,
                        '${workout.duration.toInt()} dk',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (workout.description != null &&
                      workout.description!.isNotEmpty) ...[
                    Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      HtmlUtils.stripHtmlTags(
                        workout.description!,
                      ), // Strip HTML tags from workout description
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Workout Items/Exercises
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Egzersizler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      if (workoutItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${workoutItems.length} egzersiz',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingWorkoutItems)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Egzersizler yükleniyor...'),
                          ],
                        ),
                      ),
                    )
                  else if (_workoutItemsError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Egzersizler yüklenirken hata oluştu',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _workoutItemsError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadWorkoutItems,
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (workoutItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
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
                              'Bu antrenman için henüz egzersiz eklenmemiş',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: workoutItems.length,
                      itemBuilder: (context, index) {
                        final workoutItem = workoutItems[index];
                        return _buildWorkoutItemCard(workoutItem, index + 1);
                      },
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.transparent,
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    // TODO: Start workout functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Antrenman başlatma özelliği yakında eklenecek',
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .elevatedButtonTheme
                  .style
                  ?.backgroundColor
                  ?.resolve({MaterialState.pressed}),
              foregroundColor: Theme.of(context)
                  .elevatedButtonTheme
                  .style
                  ?.foregroundColor
                  ?.resolve({MaterialState.pressed}),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'ANTRENMAN BAŞLAT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.transparent,
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleSmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutItemCard(WorkOutItem workoutItem, int number) {
    final exercise = _exercisesCache[workoutItem.exerciseId];
    final unitText = _getUnitDisplayText(workoutItem.unit);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: Theme.of(context).brightness == Brightness.light ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showExerciseDetails(exercise, workoutItem),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Number
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Exercise Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: exercise?.image != null && exercise!.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            exercise.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.fitness_center,
                                color: Theme.of(context).primaryColor,
                                size: 30,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.fitness_center,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),

                // Exercise Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise?.name ?? 'Bilinmeyen Egzersiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workoutItem.set} set × ${workoutItem.quantity} $unitText',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (exercise?.description != null &&
                          exercise!.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          HtmlUtils.stripHtmlTags(
                            exercise.description!,
                          ), // Strip HTML tags from exercise description
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Exercise Features
                      Row(
                        children: [
                          if (exercise?.video != null &&
                              exercise!.video!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Video',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //     horizontal: 8,
                          //     vertical: 4,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     color: Theme.of(
                          //       context,
                          //     ).primaryColor.withOpacity(0.1),
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          //   child: Text(
                          //     unitText.toUpperCase(),
                          //     style: TextStyle(
                          //       fontSize: 10,
                          //       color: Theme.of(context).primaryColor,
                          //       fontWeight: FontWeight.w600,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExerciseDetails(Exercise? exercise, WorkOutItem workoutItem) {
    if (exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Egzersiz bilgileri yüklenemedi')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Image
                    if (exercise.image != null && exercise.image!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            exercise.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 64,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Exercise Name
                    Text(
                      exercise.name ?? 'İsimsiz Egzersiz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Workout Item Details
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: Theme.of(context).primaryColor.withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(
                    //         Icons.fitness_center,
                    //         color: Theme.of(context).primaryColor,
                    //         size: 24,
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Text(
                    //         '${workoutItem.set} set × ${workoutItem.quantity} $unitText',
                    //         style: TextStyle(
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.bold,
                    //           color: Theme.of(context).primaryColor,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 16),

                    // Description
                    if (exercise.description != null &&
                        exercise.description!.isNotEmpty) ...[
                      Text(
                        'Açıklama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        HtmlUtils.stripHtmlTags(exercise.description!),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Video Button
                    if (exercise.video != null && exercise.video!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Open video player
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Video oynatıcı yakında eklenecek',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Videoyu İzle'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
