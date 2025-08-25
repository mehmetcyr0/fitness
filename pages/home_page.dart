import 'package:fitness/models/auth_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fitness/models/workout_model.dart';
import 'package:fitness/services/api_service.dart';
import 'dart:developer' as developer;
import 'package:fitness/pages/create_workout_page.dart';
import 'workout_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedTab = 0;
  User? _user;
  DecodedToken? _decodedToken;
  List<WorkOut> _workouts = [];
  bool _isLoadingWorkouts = true;

  String get displayName {
    if (_user?.fullName.isNotEmpty == true) {
      return _user!.fullName;
    } else if (_decodedToken?.name.isNotEmpty == true) {
      return _decodedToken!.name;
    }
    return 'Kullanıcı';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchWorkouts();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // auth_data -> User model
    final userData = prefs.getString('auth_data');
    if (userData != null) {
      setState(() {
        _user = User.fromJson(jsonDecode(userData));
      });
    }

    // decoded_token -> DecodedToken model
    final decodedData = prefs.getString('decoded_token');
    if (decodedData != null) {
      setState(() {
        _decodedToken = DecodedToken.fromJson(jsonDecode(decodedData));
      });
    }
  }

  Future<void> _fetchWorkouts() async {
    try {
      final workouts = await ApiService.getWorkouts();
      setState(() {
        _workouts = workouts
            .where((workout) => workout.isDeleted != true)
            .toList();
        _isLoadingWorkouts = false;
      });
    } catch (e) {
      developer.log('Error fetching workouts: $e', name: 'HomePage');
      setState(() {
        _isLoadingWorkouts = false;
      });
    }
  }

  String get selamlama {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Günaydın';
    } else if (hour >= 12 && hour < 18) {
      return 'Tünaydın';
    } else {
      return 'İyi akşamlar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
          onPressed: () {},
        ),
        title: Text(
          'Ana Sayfa',
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
                Icons.notifications_outlined,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWorkouts,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$selamlama, $displayName',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildTab('Öne Çıkan', 0),
                    _buildTab('Antrenman', 1),
                    _buildTab('Planlar', 2),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Create Workout Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateWorkoutPage(),
                      ),
                    );
                    if (result == true) {
                      _fetchWorkouts(); // Refresh workouts after creation
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Antrenman Oluştur'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // My Workouts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Antrenmanlarım',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  if (_workouts.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/Antrenmanlar');
                      },
                      child: const Text('Tümünü Gör'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Workouts List
              if (_isLoadingWorkouts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_workouts.isEmpty)
                Center(
                  child: Column(
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
                        'Henüz antrenman oluşturmadınız',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İlk antrenmanınızı oluşturmak için yukarıdaki butona tıklayın',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final workout = _workouts[index];
                      return _buildWorkoutCard(workout);
                    },
                  ),
                ),

              const SizedBox(height: 32),
              // Quick Trainings
              Text(
                'Hızlı Antrenmanlar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickTrainingCard(
                    '5 Dakika Karın',
                    Icons.accessibility_new,
                  ),
                  _buildQuickTrainingCard('Sabah Yoga', Icons.self_improvement),
                  _buildQuickTrainingCard('HIIT Cardio', Icons.directions_run),
                  _buildQuickTrainingCard('Esneme', Icons.accessibility),
                  _buildQuickTrainingCard(
                    'Egzersizler',
                    Icons.list_alt,
                    () => Navigator.pushNamed(context, '/exercises'),
                  ),
                  _buildQuickTrainingCard(
                    'Üyelik Planları',
                    Icons.card_membership,
                    () => Navigator.pushNamed(context, '/subscription'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              // Ana sayfa - zaten buradayız
              break;
            case 1:
              Navigator.pushNamed(context, '/workouts');
              break;
            case 2:
              Navigator.pushNamed(context, '/Antrenmanlar');
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/nfc-entry');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.nfc, color: Colors.white),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkOut workout) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailPage(workout: workout),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFE8F5E8)
              : Colors.grey[700],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (workout.image != null && workout.image!.isNotEmpty)
                Container(
                  height: 80,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(workout.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(
                workout.name ?? 'İsimsiz Antrenman',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${workout.duration.toInt()} dakika',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              if (workout.workOutItems != null &&
                  workout.workOutItems!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${workout.workOutItems!.length} egzersiz',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Keep the existing _buildTab and _buildQuickTrainingCard methods unchanged
  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTrainingCard(
    String title,
    IconData icon, [
    VoidCallback? onTap,
  ]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
