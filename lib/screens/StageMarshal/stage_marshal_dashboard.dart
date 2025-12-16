import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../QueueModel/queue_model.dart';

class StageMarshalDashboard extends StatefulWidget {
  const StageMarshalDashboard({super.key});

  @override
  State<StageMarshalDashboard> createState() => _StageMarshalDashboardState();
}

class _StageMarshalDashboardState extends State<StageMarshalDashboard> {
  int currentIndex=0;
  final queueModel=QueueModel();
  final List<BottomNavigationBarItem> navigationButtons = [
    BottomNavigationBarItem(icon: Icon(Icons.view_agenda),label: 'view queue'),
    BottomNavigationBarItem(icon: Icon(Icons.person),label: 'A'),
    BottomNavigationBarItem(icon: Icon(Icons.settings),label: 'B'),
  ];
late List <Widget> pages=[
    buildQueue(context),
   Center(child: Text("A")),
   Center(child: Text("B")),
];

Widget buildQueue(BuildContext context){
  return StreamBuilder(
      stream: queueModel.fetchQueue(),
      builder: (context,snapshot){
        if(snapshot.hasError){
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if(snapshot.connectionState==ConnectionState.waiting && !snapshot.hasData){
          return const Center(child: CircularProgressIndicator());
        }
        final docs=snapshot.data!;
        print("Docs Stream : ${docs}");
        return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context,index){
              final doc=docs[index];
              print("Doc : ${doc}");
              return (doc['status']=='departed')?null:Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Text(index.toString()),
                      title: Text('${doc['vehicleNumber']}'),
                      subtitle: Text('${doc['driverName']}'),
                      trailing: Text('${doc['createdAt']}')
                    ),
                    ListTile(
                        title: Text('${doc['status']}'),
                        trailing: TextButton(onPressed: () async {
                          try {
                            await queueModel.approveDriver(
                                driverName: doc['driverName'],
                                stamp: DateTime.now().toString(),
                                vehicleNumber: doc['vehicleNumber']
                            );
                          } catch (err) {
                            print('Error :${err.toString()}');
                            Fluttertoast.showToast(msg: "${err.toString()}");
                          }
                        }, child: Text('Approve'))
                    ),
                    TextButton(onPressed: () async {
                        await queueModel.departDriver(
                            driverName: doc['driverName'],
                            stamp: DateTime.now().toString(),
                            vehicleNumber: doc['vehicleNumber']
                        );
                    }, child: Text('Depart')),
                  ],
                ),
              );
            }
        );
      });
}

@override
  void initState() {
    super.initState();
    pages;
  }







  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Stage Marshal Dashboard")),
        body: pages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: navigationButtons,
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex=index;
            });
          }
        )
      ),
    );
  }
}
