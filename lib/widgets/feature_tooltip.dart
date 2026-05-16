import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';

class FeatureTooltip extends StatefulWidget {
  final String title;
  final String description;
  final String featureKey;
  final Widget child;
  final Alignment tooltipAlignment;

  const FeatureTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.featureKey,
    required this.child,
    required this.tooltipAlignment,
  });

  @override
  State<FeatureTooltip> createState() => _FeatureTooltipState();
}

class _FeatureTooltipState extends State<FeatureTooltip> {
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    final shouldShow = await OnboardingService.shouldShow(widget.featureKey);
    if (shouldShow && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _shouldShow = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Container(
            color: const Color(0x88000000),
          ),
        ),
        Align(
          alignment: widget.tooltipAlignment,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF154212)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        await OnboardingService.markShown(widget.featureKey);
                        if (mounted) setState(() => _shouldShow = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154212),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got it! 🌿',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
