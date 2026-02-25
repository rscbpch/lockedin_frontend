import 'package:flutter/material.dart';

class ClarificationCard extends StatelessWidget {
  final String? question;

  const ClarificationCard({super.key, this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFFF59E0B), size: 16),
              SizedBox(width: 6),
              Text(
                'Clarification Needed',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question ?? 'Could you provide more details?',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontFamily: 'Nunito',
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}