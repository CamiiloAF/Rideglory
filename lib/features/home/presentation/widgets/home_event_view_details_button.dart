import 'package:flutter/material.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';

class HomeEventViewDetailsButton extends StatelessWidget {
  const HomeEventViewDetailsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            HomeStrings.viewDetails,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 12, color: Colors.black87),
        ],
      ),
    );
  }
}
