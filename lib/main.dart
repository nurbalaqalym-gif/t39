import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const EchoPendulumApp());
}

class EchoPendulumApp extends StatelessWidget {
  const EchoPendulumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Эхо-маятник',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1017),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB703),
          secondary: Color(0xFF2EC4B6),
        ),
      ),
      home: const PendulumScreen(),
    );
  }
}

class PendulumScreen extends StatefulWidget {
  const PendulumScreen({super.key});

  @override
  State<PendulumScreen> createState() => _PendulumScreenState();
}

class _PendulumScreenState extends State<PendulumScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int _combo = 0;
  int _bestCombo = 0;
  String _feedback = 'Попади в центр, когда маятник пройдёт через метку';
  Color _feedbackColor = Colors.white70;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Значение от -1.0 (левый край) до +1.0 (правый край); 0.0 — строгий центр
  double _currentNormalizedX() {
    final curved = Curves.easeInOut.transform(_controller.value);
    return (curved * 2.0) - 1.0;
  }

  void _updateSpeedForCombo() {
    final clampedCombo = _combo.clamp(0, 20);
    final ms = (1400 - clampedCombo * 35).clamp(650, 1400);
    _controller.duration = Duration(milliseconds: ms);
    if (_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  void _onStrike() {
    final pos = _currentNormalizedX();
    final distance = pos.abs();

    setState(() {
      if (distance <= 0.14) {
        _combo++;
        if (_combo > _bestCombo) {
          _bestCombo = _combo;
        }
        _feedback = distance <= 0.05
            ? 'ИДЕАЛЬНО! Ритм пойман'
            : 'В такт! Серия растёт';
        _feedbackColor = const Color(0xFF2EC4B6);
        _updateSpeedForCombo();
      } else {
        _combo = 0;
        _feedback = pos < 0
            ? 'Рановато — маятник ещё не дошёл до центра'
            : 'Чуть поздно — центр уже позади';
        _feedbackColor = const Color(0xFFFF595E);
        _updateSpeedForCombo();
      }
    });
  }

  void _resetStats() {
    setState(() {
      _combo = 0;
      _bestCombo = 0;
      _feedback = 'Счётчик сброшен. Лови центр!';
      _feedbackColor = Colors.white70;
      _updateSpeedForCombo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Эхо-маятник'),
        actions: [
          IconButton(
            onPressed: _resetStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Сбросить статистику',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricBox(
                    title: 'Серия',
                    value: '$_combo',
                    color: const Color(0xFFFFB703),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBox(
                    title: 'Рекорд',
                    value: '$_bestCombo',
                    color: const Color(0xFF2EC4B6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _feedbackColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _PendulumPainter(
                      normalizedX: _currentNormalizedX(),
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _onStrike,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB703),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'УДАР В ТАКТ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double normalizedX;

  const _PendulumPainter({required this.normalizedX});

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, 24);
    final armLength = min(
      size.height - 70,
      size.width * 0.65,
    ).clamp(120.0, 260.0);
    const maxAngle = 0.72; // радианы
    final angle = normalizedX * maxAngle;

    // Центральная метка резонанса внизу дуги
    final centerTarget = Offset(
      pivot.dx + armLength * sin(0),
      pivot.dy + armLength * cos(0),
    );

    final targetPaint = Paint()
      ..color = const Color(0xFF2EC4B6).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(centerTarget, 24, targetPaint);

    // Текущее положение груза
    final bob = Offset(
      pivot.dx + armLength * sin(angle),
      pivot.dy + armLength * cos(angle),
    );

    final rodPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 3;
    canvas.drawLine(pivot, bob, rodPaint);

    final pivotPaint = Paint()..color = Colors.white70;
    canvas.drawCircle(pivot, 6, pivotPaint);

    final bobPaint = Paint()..color = const Color(0xFFFFB703);
    canvas.drawCircle(bob, 18, bobPaint);
  }

  @override
  bool shouldRepaint(covariant _PendulumPainter oldDelegate) {
    return oldDelegate.normalizedX != normalizedX;
  }
}

class _MetricBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
