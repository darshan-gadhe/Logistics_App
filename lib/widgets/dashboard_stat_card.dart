// lib/widgets/dashboard_stat_card.dart
import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // MainAxisAlignment.spaceBetween will push the icon to the top
          // and the text block to the bottom, preventing overflow.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon at the top
            Icon(icon, size: 30, color: iconColor),

            // Text block at the bottom
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use a FittedBox to ensure the value scales down if needed,
                // which is a very robust way to prevent overflows.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26, color: theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}