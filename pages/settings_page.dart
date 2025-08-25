import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import '../models/auth_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tema Ayarları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Görünüm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text('Açık Tema'),
                            subtitle: const Text('Varsayılan açık renk teması'),
                            value: false,
                            groupValue: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.setTheme(value!);
                            },
                            activeColor: const Color(0xFF2ECC71),
                          ),
                          RadioListTile<bool>(
                            title: const Text('Koyu Tema'),
                            subtitle: const Text('Gözlerinizi koruyun'),
                            value: true,
                            groupValue: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.setTheme(value!);
                            },
                            activeColor: const Color(0xFF2ECC71),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Diğer Ayarlar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Bildirimler'),
                    subtitle: const Text('Bildirim ayarlarını yönet'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Dil'),
                    subtitle: const Text('Türkçe'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.card_membership),
                    title: const Text('Üyelik Planları'),
                    subtitle: const Text('Plan yönetimi ve satın alma'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Gizlilik'),
                    subtitle: const Text('Gizlilik ayarları'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hesap Ayarları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hesap',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Yardım'),
                    subtitle: const Text('SSS ve destek'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Hakkında'),
                    subtitle: const Text('Uygulama bilgileri'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Çıkış Yap',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      // Show confirmation dialog
                      bool? shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Çıkış Yap'),
                            content: const Text(
                              'Çıkış yapmak istediğinizden emin misiniz?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  'Çıkış Yap',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldLogout == true) {
                        await AuthHelper.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
