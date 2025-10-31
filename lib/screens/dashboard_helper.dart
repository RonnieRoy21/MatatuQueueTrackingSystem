import 'package:flutter/material.dart';

Widget buildDashboard(String title, List<Map<String, dynamic>> items, BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        return Card(
          color: items[i]['color'] ?? Colors.blueGrey,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(items[i]['icon'], color: Colors.white),
            title: Text(
              items[i]['title'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
            // Pass context to the onTap if provided
            onTap: () {
              if (items[i]['onTap'] != null) {
                items[i]['onTap'](context);
              }
            },
          ),
        );
      },
    ),
  );
}
