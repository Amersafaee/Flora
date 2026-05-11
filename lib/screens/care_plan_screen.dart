import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class CarePlanScreen extends StatelessWidget {
  final String carePlanText;

  const CarePlanScreen({super.key, required this.carePlanText});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF154212);
    const Color backgroundColor = Color(0xFFF8FAF8);
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Care Plan',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: primaryColor),
            onPressed: () {
              // ignore: deprecated_member_use
              Share.share(carePlanText);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            carePlanText,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}



