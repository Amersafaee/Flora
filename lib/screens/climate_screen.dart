import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'global_search_screen.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _humController = TextEditingController();

  String _currentTemp = '--';
  String _currentHum = '--';
  
  List<Map<String, dynamic>> _tempReadings = [];
  List<Map<String, dynamic>> _humReadings = [];

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _humController.dispose();
    super.dispose();
  }

  void _loadReadings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('zones')
        .doc('main_zone')
        .collection('readings');

    // Listen to temp
    ref.where('type', isEqualTo: 'temperature')
       .orderBy('timestamp', descending: true)
       .limit(24)
       .snapshots()
       .listen((snap) {
         if (!mounted) return;
         final docs = snap.docs;
         setState(() {
           if (docs.isNotEmpty) {
             _currentTemp = docs.first['value'].toString();
           } else {
             _currentTemp = '--';
           }
           _tempReadings = docs.map((d) => d.data()).toList().reversed.toList();
         });
       });

    // Listen to humidity
    ref.where('type', isEqualTo: 'humidity')
       .orderBy('timestamp', descending: true)
       .limit(24)
       .snapshots()
       .listen((snap) {
         if (!mounted) return;
         final docs = snap.docs;
         setState(() {
           if (docs.isNotEmpty) {
             _currentHum = docs.first['value'].toString();
           } else {
             _currentHum = '--';
           }
           _humReadings = docs.map((d) => d.data()).toList().reversed.toList();
         });
       });
  }

  Future<void> _saveReading(String type, String valueStr) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final value = double.tryParse(valueStr);
    if (value == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('zones')
        .doc('main_zone')
        .collection('readings')
        .doc(DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      'type': type,
      'value': value,
      'timestamp': Timestamp.now(),
    });
    
    if (mounted) {
      if (type == 'temperature') {
        _tempController.clear();
      } else {
        _humController.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading saved'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const Color terracotta = Color(0xFF8D3220);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Digital Conservatory',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: primaryColor),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));
                      },
                    ),
                  ],
                ),
              ),
              
              // Title and Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Living Room Climate',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Monitoring your plant's environment",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Input Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(child: _buildInputCard(
                      label: 'TEMPERATURE',
                      icon: Icons.thermostat,
                      iconColor: terracotta,
                      currentValue: _currentTemp,
                      unit: '°C',
                      controller: _tempController,
                      onSave: () => _saveReading('temperature', _tempController.text),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInputCard(
                      label: 'HUMIDITY',
                      icon: Icons.water_drop,
                      iconColor: primaryColor,
                      currentValue: _currentHum,
                      unit: '%',
                      controller: _humController,
                      onSave: () => _saveReading('humidity', _humController.text),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Chart Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Readings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              _buildLegendDot('Temp', primaryColor),
                              const SizedBox(width: 12),
                              _buildLegendDot('Humidity', Colors.redAccent),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Chart area
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            // Y-axis
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Max', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                                const Spacer(),
                                Text('Min', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Graph Lines
                            Expanded(
                              child: Stack(
                                children: [
                                  // Grid lines
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Divider(color: Colors.grey.shade200),
                                      const Spacer(),
                                      Divider(color: Colors.grey.shade200),
                                    ],
                                  ),
                                  // Real Data Paint
                                  CustomPaint(
                                    size: const Size(double.infinity, 200),
                                    painter: RealChartPainter(
                                      tempColor: primaryColor,
                                      humidityColor: Colors.redAccent,
                                      tempReadings: _tempReadings,
                                      humReadings: _humReadings,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String currentValue,
    required String unit,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currentValue $unit',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter',
                    suffixText: unit,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class RealChartPainter extends CustomPainter {
  final Color tempColor;
  final Color humidityColor;
  final List<Map<String, dynamic>> tempReadings;
  final List<Map<String, dynamic>> humReadings;

  RealChartPainter({
    required this.tempColor, 
    required this.humidityColor,
    required this.tempReadings,
    required this.humReadings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawPath(canvas, size, tempReadings, tempColor, 0, 50); // Temp min 0 max 50
    _drawPath(canvas, size, humReadings, humidityColor, 0, 100); // Hum min 0 max 100
  }

  void _drawPath(Canvas canvas, Size size, List<Map<String, dynamic>> readings, Color color, double minVal, double maxVal) {
    if (readings.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    if (readings.length == 1) {
      double val = (readings[0]['value'] as num).toDouble();
      double y = size.height - ((val - minVal) / (maxVal - minVal) * size.height).clamp(0.0, size.height);
      path.moveTo(0, y);
      path.lineTo(size.width, y);
      canvas.drawPath(path, paint);
      return;
    }

    final double xStep = size.width / (readings.length - 1);
    
    for (int i = 0; i < readings.length; i++) {
      double val = (readings[i]['value'] as num).toDouble();
      double x = i * xStep;
      double y = size.height - ((val - minVal) / (maxVal - minVal) * size.height).clamp(0.0, size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RealChartPainter oldDelegate) {
    return oldDelegate.tempReadings != tempReadings || oldDelegate.humReadings != humReadings;
  }
}



