import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:typed_data';
import 'dashboard_helper.dart';
import 'dart:io';
import 'vehicle_master_list.dart';




class SaccoOfficialDashboard extends StatelessWidget {
  const SaccoOfficialDashboard({super.key});

  final String stageId = 'main_stage';

  // -------------------- UTILITIES --------------------
  String formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('d/M/yyyy  h:mm a').format(date);
  }

  String timeAgo(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
  }

  // -------------------- ACTIVE QUEUE --------------------
  void _viewActiveQueue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Active Queue")),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('queues')
                .doc(stageId)
                .collection('vehicles')
                .where('status', isEqualTo: 'waiting')
                .orderBy('position')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No active vehicles in queue"));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['driverName'] ?? 'Unknown';
                  final pos = data['position'] ?? index + 1;
                  final checkedInAt = data['checkedInAt'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text('$pos', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        checkedInAt != null
                            ? "Checked in: ${formatDate(checkedInAt)} (${timeAgo(checkedInAt)})"
                            : "Checked in: N/A",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------- DEPARTED LOGS --------------------
  void _viewDepartedLogs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Departed Vehicles Log")),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('queues')
                .doc(stageId)
                .collection('vehicles')
                .where('status', isEqualTo: 'departed')
                .orderBy('departedAt', descending: true)
                .snapshots()
                .handleError((e) => debugPrint("⚠️ Firestore stream error: $e")),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text("Error loading departed logs. Check Firestore index."));
              }
              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No departed records yet"));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['driverName'] ?? 'Unknown';
                  final departedAt = data['departedAt'];
                  final checkedInAt = data['checkedInAt'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blueGrey.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus, color: Colors.teal),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "Checked in: ${formatDate(checkedInAt)}\n"
                        "Departed: ${formatDate(departedAt)} (${timeAgo(departedAt)})",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------- DAILY SUMMARY --------------------
  Future<void> _showDailySummary(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final checkIns = await firestore
        .collection('queues')
        .doc(stageId)
        .collection('vehicles')
        .where('checkedInAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkedInAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final departures = await firestore
        .collection('queues')
        .doc(stageId)
        .collection('vehicles')
        .where('departedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('departedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Today's Summary"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Checked-ins today: ${checkIns.size}"),
            Text("Departures today: ${departures.size}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  // -------------------- GENERATE & EMAIL PDF --------------------
  Future<void> _generateDailyPdf(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final vehiclesSnapshot = await firestore
        .collection('queues')
        .doc(stageId)
        .collection('vehicles')
        .where('checkedInAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkedInAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (vehiclesSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records for today")),
      );
      return;
    }

    final pdf = pw.Document();
    final formatter = DateFormat('d/M/yyyy  h:mm a');

    num totalWaitMinutes = 0;
    int countWithWait = 0;
    final Map<int, int> hourlyDepartures = {};

    for (var doc in vehiclesSnapshot.docs) {
      final data = doc.data();
      final checkedInAt = data['checkedInAt'];
      final departedAt = data['departedAt'];

      if (checkedInAt != null && departedAt != null) {
        final diff = departedAt.toDate().difference(checkedInAt.toDate()).inMinutes;
        totalWaitMinutes += diff;
        countWithWait++;
        final depHour = departedAt.toDate().hour;
        hourlyDepartures[depHour] = (hourlyDepartures[depHour] ?? 0) + 1;
      }
    }

    final avgWait = countWithWait > 0
        ? (totalWaitMinutes / countWithWait).toStringAsFixed(1)
        : 'N/A';
    final peakHour = hourlyDepartures.isNotEmpty
        ? hourlyDepartures.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              "Daily Queue Report - ${DateFormat('d MMM yyyy').format(now)}",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text("Total vehicles checked in: ${vehiclesSnapshot.size}"),
          pw.Text("Vehicles with departure records: $countWithWait"),
          pw.Text("Average waiting time: $avgWait minutes"),
          pw.Text(peakHour != null
              ? "Peak hour: ${peakHour.toString().padLeft(2, '0')}:00 - ${peakHour + 1}:00"
              : "Peak hour: N/A"),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: ["Driver", "Position", "Checked In", "Departed", "Status"],
            data: vehiclesSnapshot.docs.map((doc) {
              final data = doc.data();
              final driver = data['driverName'] ?? 'Unknown';
              final pos = data['position']?.toString() ?? '-';
              final checked = data['checkedInAt'] != null
                  ? formatter.format((data['checkedInAt'] as Timestamp).toDate())
                  : 'N/A';
              final departed = data['departedAt'] != null
                  ? formatter.format((data['departedAt'] as Timestamp).toDate())
                  : 'N/A';
              final status = data['status'] ?? '-';
              return [driver, pos, checked, departed, status];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "Daily_Report_${DateFormat('yyyyMMdd').format(now)}.pdf",
    );
    await _sendPdfByEmail(context, await pdf.save());



    // Ask user if they want to send the email
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send PDF Report?"),
        content: const Text("Would you like to email this report to the SACCO office?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendPdfByEmail(context, await pdf.save());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("📧 Report emailed successfully")),
              );
            },
            child: const Text("Yes, Send"),
          ),
        ],
      ),
    );
  }

  // -------------------- EMAIL REPORT --------------------
Future<void> _sendPdfByEmail(BuildContext context, Uint8List pdfBytes) async {
  try {
    final username = 'nduruhu.nyambura22@students.dkut.ac.ke'; // replace with your email
    final password = 'nyamburanduruhu@8180';    // use Gmail app password

    final smtpServer = gmail('queuetrack2@gmail.com','zcckysyooeahmjcr');

    final tempDir = Directory.systemTemp;
    final filePath = '${tempDir.path}/Daily_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes); // save the PDF locally first

    final message = Message()
      ..from = Address('queuetrack2@gmail.com', 'Sacco Report System')
      ..recipients.add('queuetrack2@gmail.com') // change this
      ..subject = 'Daily Queue Report - ${DateFormat('d MMM yyyy').format(DateTime.now())}'
      ..text = 'Attached is the daily queue report in PDF format.'
      ..attachments = [
        FileAttachment(file)
          ..fileName = 'Daily_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf'
          ..contentType = 'application/pdf'
      ];

    await send(message, smtpServer);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Email sent successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to send email: $e')),
    );
  }
}




  // -------------------- DASHBOARD --------------------
  @override
  Widget build(BuildContext context) => buildDashboard(
        'Sacco Official Dashboard',
        [
          {
            'title': 'View Active Queue',
            'icon': Icons.queue,
            'color': Colors.teal,
            'onTap': (ctx) => _viewActiveQueue(ctx),
          },
          {
            'title': 'View Departed Logs',
            'icon': Icons.history,
            'color': Colors.blue,
            'onTap': (ctx) => _viewDepartedLogs(ctx),
          },
          {
            'title': 'Daily Summary Report',
            'icon': Icons.analytics,
            'color': Colors.orange,
            'onTap': (ctx) => _showDailySummary(ctx),
          },
          {
            'title': 'Download / Email PDF Report',
            'icon': Icons.picture_as_pdf,
            'color': Colors.redAccent,
            'onTap': (ctx) => _generateDailyPdf(ctx),
          },
          {
            'title': 'Vehicle Master List',
            'icon': Icons.directions_car,
            'color': Colors.purple,
            'onTap': (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const VehicleMasterList()),
            ),
          },

        ],
        context,
      );
}
