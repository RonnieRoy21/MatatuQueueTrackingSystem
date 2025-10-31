import 'package:flutter/material.dart';
import 'dashboard_helper.dart';
import 'view_queue_status.dart';

class ConductorDashboard extends StatelessWidget {
  const ConductorDashboard({super.key});

  @override
  Widget build(BuildContext context) => buildDashboard(
        'Conductor Dashboard',
        [
          {
                      'title': 'View Queue Status',
                      'icon': Icons.queue,
                      'color': Colors.green,
                      'onTap': (BuildContext ctx) {
                                    Navigator.push(
                                      ctx,
                                      MaterialPageRoute(builder: (_) => const ViewQueueStatus()),
                                    );
                                  }
                    },
        ],
        context,
      );
}
