import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;
import 'workout_detail_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedPeriod = 0; // 0: Haftalık, 1: Aylık, 2: Yıllık
  int _selectedCategory = 0; // 0: Tüm Antrenmanlar, 1: Kardiyo, 2: Güç

  List<WorkOut> _workouts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Stats data
  int _totalWorkouts = 0;
  double _totalHours = 0;
  int _totalCalories = 0;
  double _averageMinutes = 0;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      developer.log(
        'Fetching workouts for workout page...',
        name: 'WorkoutPage',
      );
      final workouts = await ApiService.getWorkouts();

      setState(() {
        _workouts = workouts;
        _calculateStats();
        _isLoading = false;
      });

      developer.log('Loaded ${workouts.length} workouts', name: 'WorkoutPage');
    } catch (e) {
      developer.log('Error fetching workouts: $e', name: 'WorkoutPage');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    List<WorkOut> nonDeletedWorkouts = _workouts
        .where((workout) => !workout.isDeleted)
        .toList();

    _totalWorkouts = nonDeletedWorkouts.length;
    _totalHours =
        nonDeletedWorkouts.fold(0.0, (sum, workout) => sum + workout.duration) /
        60;
    _totalCalories = nonDeletedWorkouts.fold(
      0,
      (sum, workout) => sum + _calculateWorkoutCalories(workout),
    );
    _averageMinutes = nonDeletedWorkouts.isNotEmpty
        ? nonDeletedWorkouts.fold(
                0.0,
                (sum, workout) => sum + workout.duration,
              ) /
              nonDeletedWorkouts.length
        : 0;
  }

  List<WorkOut> get _filteredWorkouts {
    List<WorkOut> nonDeletedWorkouts = _workouts
        .where((workout) => !workout.isDeleted)
        .toList();

    if (_selectedCategory == 0) return nonDeletedWorkouts;

    // Filter by category - this would need more sophisticated filtering
    // based on workout types when that data is available
    return nonDeletedWorkouts;
  }

  int _calculateWorkoutCalories(WorkOut workout) {
    // Simple calorie calculation - can be improved with more complex logic
    return (workout.duration * 6).toInt(); // ~6 calories per minute
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.fitness_center,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () {},
        ),
        title: Text(
          'Antrenmanlar',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFE8F5E8)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: _fetchWorkouts,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _fetchWorkouts, child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/workouts');
              break;
            case 2:
              // Antrenmanlar sayfası - zaten buradayız
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.unselectedItemColor,
        backgroundColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.backgroundColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Ara'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Antrenmanlar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Antrenmanlar yükleniyor...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Hata Oluştu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchWorkouts,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredWorkouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 64,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz antrenman yok',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İlk antrenmanınızı oluşturmak için ana sayfaya gidin',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/create-workout');
                },
                icon: const Icon(Icons.add),
                label: const Text('Antrenman Oluştur'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selection
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildPeriodTab('Haftalık', 0),
                _buildPeriodTab('Aylık', 1),
                _buildPeriodTab('Yıllık', 2),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Overview
          Row(
            children: [
              _buildStatCard(
                'Toplam Antrenman',
                _totalWorkouts.toString(),
                'Bu ay',
                Icons.fitness_center,
                Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Toplam Süre',
                _totalHours.toStringAsFixed(1),
                'saat',
                Icons.access_time,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Yakılan Kalori',
                _totalCalories.toString(),
                'kcal',
                Icons.local_fire_department,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Ortalama/Antrenman',
                _averageMinutes.toStringAsFixed(0),
                'dakika',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Weekly Progress Chart
          Text(
            'Haftalık İlerleme',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildProgressBar('Pzt', 0.6, '45dk'),
                _buildProgressBar('Sal', 0.8, '60dk'),
                _buildProgressBar('Çar', 0.4, '30dk'),
                _buildProgressBar('Per', 1.0, '75dk'),
                _buildProgressBar('Cum', 0.7, '50dk'),
                _buildProgressBar('Cmt', 0.3, '20dk'),
                _buildProgressBar('Paz', 0.5, '35dk'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Category Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Antrenman Geçmişi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCategory,
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(
                          'Tümü',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          'Kardiyo',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(
                          'Güç',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 0;
                      });
                    },
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    iconEnabledColor: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Workout History List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredWorkouts.length,
            itemBuilder: (context, index) {
              final workout = _filteredWorkouts[index];
              return _buildWorkoutHistoryItem(workout);
            },
          ),
          const SizedBox(height: 32),

          // Achievement Section
          Text(
            'Bu Ay Başarılar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAchievementCard(
                '🔥',
                'Ateş Serisi',
                '${_workouts.length} antrenman',
              ),
              const SizedBox(width: 12),
              _buildAchievementCard(
                '💪',
                'Güç Ustası',
                '${_totalHours.toInt()} saat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String text, int index) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2ECC71) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String day, double progress, String duration) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          duration,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleSmall?.color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 20,
          height: progress * 120,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutHistoryItem(WorkOut workout) {
    final calories = _calculateWorkoutCalories(workout);
    final formattedDate = _formatDate(workout.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: Theme.of(context).brightness == Brightness.light ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailPage(workout: workout),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name ?? 'İsimsiz Antrenman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.duration.toInt()} dk',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$calories kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (workout.workOutItems != null &&
                    workout.workOutItems!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${workout.workOutItems!.length} egzersiz',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
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

  Widget _buildAchievementCard(String emoji, String title, String description) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
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
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleSmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else if (difference < 7) {
      return '$difference gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
