import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/payment/data/payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RentalOptionsSheet extends ConsumerStatefulWidget {
  final String contentId;
  final PricingTier pricing;

  const RentalOptionsSheet({
    super.key,
    required this.contentId,
    required this.pricing,
  });

  @override
  ConsumerState<RentalOptionsSheet> createState() => _RentalOptionsSheetState();
}

class _RentalOptionsSheetState extends ConsumerState<RentalOptionsSheet> {
  late int _currentDays;
  late double _currentPrice;
  late AdditionalTier? _incrementTier;

  @override
  void initState() {
    super.initState();
    // Start with Base
    _currentDays = widget.pricing.baseDurationDays;
    _currentPrice = widget.pricing.basePrice;

    // Use first additional tier as the increment unit (e.g., +3 days for +1 ETB)
    if (widget.pricing.additionalTiers.isNotEmpty) {
      _incrementTier = widget.pricing.additionalTiers.first;
    } else {
      _incrementTier = null;
    }
  }

  void _increaseDuration() {
    if (_incrementTier == null) return;
    setState(() {
      _currentDays += _incrementTier!.days;
      _currentPrice += _incrementTier!.price;
    });
  }

  void _decreaseDuration() {
    if (_incrementTier == null) return;
    // Do not allow going below base duration
    if (_currentDays > widget.pricing.baseDurationDays) {
      setState(() {
        _currentDays -= _incrementTier!.days;
        _currentPrice -= _incrementTier!.price;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentControllerProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF151E32),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text(
            "Select Rental Duration",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),

          // --- PLUS / MINUS CONTROLS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircleBtn(
                icon: Icons.remove,
                onTap: _currentDays > widget.pricing.baseDurationDays
                    ? _decreaseDuration
                    : null,
              ),
              const SizedBox(width: 32),
              Column(
                children: [
                  Text(
                    "$_currentDays Days",
                    style: const TextStyle(
                      color: Color(0xFFCFB56C),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_currentPrice.toStringAsFixed(0)} ETB",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              _buildCircleBtn(
                icon: Icons.add,
                onTap: _incrementTier != null ? _increaseDuration : null,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // --- PAY BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: paymentState.isLoading
                  ? null
                  : () {
                      // Return selected duration to parent to initiate payment
                      Navigator.pop(context, {
                        'days': _currentDays,
                        'initiate': true,
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCFB56C),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Confirm & Pay",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn({required IconData icon, VoidCallback? onTap}) {
    final bool isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isEnabled ? Colors.white38 : Colors.white10,
              width: 1.5,
            ),
            color: isEnabled ? Colors.white10 : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.white24,
            size: 28,
          ),
        ),
      ),
    );
  }
}
