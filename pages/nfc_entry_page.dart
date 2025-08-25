import 'package:flutter/material.dart';

class NFCEntryPage extends StatefulWidget {
  const NFCEntryPage({super.key});

  @override
  State<NFCEntryPage> createState() => _NFCEntryPageState();
}

class _NFCEntryPageState extends State<NFCEntryPage>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  bool _isSuccess = false;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _successAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _startNFCScanning() async {
    setState(() {
      _isScanning = true;
      _isSuccess = false;
    });

    _pulseController.repeat(reverse: true);

    // Simulate NFC scanning
    await Future.delayed(const Duration(seconds: 3));

    _pulseController.stop();
    _successController.forward();

    setState(() {
      _isScanning = false;
      _isSuccess = true;
    });

    // Auto navigate back after success
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('NFC Salon Girişi'),
        centerTitle: true,
        backgroundColor: isDarkMode
            ? Colors.grey[900]
            : Colors.green, // Adjust app bar color based on theme
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // NFC Icon and Animation
            Center(
              child: AnimatedBuilder(
                animation: _isScanning ? _pulseAnimation : _successAnimation,
                builder: (context, child) {
                  if (_isSuccess) {
                    return Transform.scale(
                      scale: _successAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.green
                              : const Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  } else {
                    return Transform.scale(
                      scale: _isScanning ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: _isScanning
                              ? (isDarkMode
                                  ? Colors.green
                                  : const Color(0xFF2ECC71))
                              : (isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200]),
                          shape: BoxShape.circle,
                          boxShadow: _isScanning
                              ? [
                                  BoxShadow(
                                    color: (isDarkMode
                                            ? Colors.green
                                            : const Color(0xFF2ECC71))
                                        .withOpacity(0.3),
                                    spreadRadius: 10,
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.nfc,
                          size: 80,
                          color: _isScanning
                              ? Colors.white
                              : (isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            // Status Text
            Center(
              child: Text(
                _isSuccess
                    ? 'Giriş Başarılı!'
                    : _isScanning
                        ? 'NFC Kartınızı Okutun'
                        : 'Salon Girişi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess
                      ? (isDarkMode ? Colors.green : const Color(0xFF2ECC71))
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSuccess
                  ? 'Spor salonuna hoş geldiniz!'
                  : _isScanning
                      ? 'Lütfen NFC kartınızı telefonunuzun arkasına yaklaştırın'
                      : 'NFC kartınızı okutarak spor salonuna giriş yapabilirsiniz',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Action Button
            if (!_isScanning && !_isSuccess)
              ElevatedButton(
                onPressed: _startNFCScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Colors.green : const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'NFC TARAMA BAŞLAT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              )
            else if (_isScanning)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(isDarkMode
                            ? Colors.green
                            : const Color(0xFF2ECC71)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Taranıyor...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Info Cards
            if (!_isScanning && !_isSuccess) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      Icons.access_time,
                      'Açılış Saatleri',
                      '06:00 - 23:00',
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      Icons.people,
                      'Aktif Üyeler',
                      '127 kişi',
                      isDarkMode,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.grey.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 24,
              color: isDarkMode ? Colors.green : const Color(0xFF2ECC71)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
