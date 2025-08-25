import 'package:flutter/material.dart';

class WeightInputPage extends StatefulWidget {
  const WeightInputPage({super.key});

  @override
  State<WeightInputPage> createState() => _WeightInputPageState();
}

class _WeightInputPageState extends State<WeightInputPage> {
  double _weight = 130.0;
  bool _isLbs = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ağırlık Ekle'),
        actions: [
          IconButton(
            icon:
                Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Text(
              'HARIKA BAŞLANGIÇ!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Mevcut ağırlığınız nedir?',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vivamus pellentesque, risus eu condimentum aliquet, velit nibh efficitur dui, quis laoreet arcu nisl dignissim.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Unit Toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLbs = true;
                          _weight = _weight * 2.20462; // kg to lbs
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isLbs
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'lbs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isLbs
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight:
                                _isLbs ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLbs = false;
                          _weight = _weight / 2.20462; // lbs to kg
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isLbs
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Kg',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isLbs
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight:
                                !_isLbs ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Weight Display
            Text(
              _weight.toInt().toString(),
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w300,
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
            Text(
              _isLbs ? 'lbs' : 'kg',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 32),
            // Weight Slider
            SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Scale marks
                  CustomPaint(
                    size: const Size(double.infinity, 60),
                    painter: ScalePainter(
                        lineColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[300]!
                                : Colors.grey[600]!),
                  ),
                  // Slider
                  Slider(
                    value: _weight,
                    min: _isLbs ? 80 : 40,
                    max: _isLbs ? 300 : 150,
                    divisions: _isLbs ? 220 : 110,
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[300]
                            : Colors.grey[700],
                    onChanged: (value) {
                      setState(() {
                        _weight = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Continue Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
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
              child: const Text(
                'DEVAM ET',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScalePainter extends CustomPainter {
  final Color lineColor;

  ScalePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final centerY = size.height / 2;
    final step = size.width / 20;

    for (int i = 0; i <= 20; i++) {
      final x = i * step;
      final height = i % 5 == 0 ? 20.0 : 10.0;
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScalePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
