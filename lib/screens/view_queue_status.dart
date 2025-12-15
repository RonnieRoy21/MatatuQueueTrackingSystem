import 'package:flutter/material.dart';
import 'package:queuetrack/QueueModel/queue_model.dart';



class ViewQueueStatus extends StatelessWidget {
   ViewQueueStatus({super.key});
final QueueModel queuemodel =QueueModel();
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Queue Status")),
      body: StreamBuilder(
        stream: queuemodel.fetchQueue(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ) {
            return const Center(child: Text("🚐 No drivers in the queue yet"));
          }

          final drivers = snapshot.data!;

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
             final driver = drivers[index];
             print("Driver : $driver");
              return  Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Text(driver['status']),
                  title: Text("${driver['vehicleNumber']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${driver['driverName']}'),
                  trailing: Text('${driver['createdAt']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
