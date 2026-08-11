import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({super.key, required this.userName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $userName',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          "Here's how today looks",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}