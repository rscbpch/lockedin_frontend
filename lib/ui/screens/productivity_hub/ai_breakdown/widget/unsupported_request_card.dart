import 'package:flutter/material.dart';

class UnsupportedRequestCard extends StatelessWidget {
  const UnsupportedRequestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.block, color: Color(0xFFEF4444), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This request isn\'t related to task breakdown. Please describe a goal or task.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontFamily: 'Nunito',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}