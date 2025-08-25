import 'package:fitness/models/auth_model.dart';
import 'package:fitness/services/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // For testing, you can pre-fill credentials
    // _emailController.text = 'test@example.com';
    // _passwordController.text = 'password';
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Lütfen e-posta ve şifre girin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      developer.log('Attempting login with email: $email', name: 'LoginPage');

      AuthResponse response = await ApiService.login(email, password);
      developer.log(
        'Login response - Success: ${response.success}, Token: ${response.token.isNotEmpty}',
        name: 'LoginPage',
      );

      if (response.success && response.token.isNotEmpty) {
        // Save JWT token and user data to SharedPreferences
        developer.log('Saving auth data...', name: 'LoginPage');
        await AuthHelper.saveAuthData(response);

        // Verify data was saved
        await Future.delayed(const Duration(milliseconds: 200));
        bool isLoggedIn = await AuthHelper.isLoggedIn();
        developer.log(
          'Verification after save - isLoggedIn: $isLoggedIn',
          name: 'LoginPage',
        );

        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showError(
          response.message.isNotEmpty ? response.message : 'Giriş başarısız',
        );
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'LoginPage');
      _showError('Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.fitness_center,
                size: 80,
                color: Color(0xFF2ECC71),
              ),
              const SizedBox(height: 32),
              const Text(
                'Hoş Geldiniz',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fitness yolculuğunuza devam edin',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text(
                  'Hesabınız yok mu? Kayıt olun',
                  style: TextStyle(color: Color(0xFF2ECC71)),
                ),
              ),

              // Debug button (remove in production)
            ],
          ),
        ),
      ),
    );
  }
}
