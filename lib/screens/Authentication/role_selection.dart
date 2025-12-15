import 'package:flutter/material.dart';

import 'login_page.dart';
class RoleSelection extends StatefulWidget {
  const RoleSelection({super.key});

  @override
  State<RoleSelection> createState() => _RoleSelectionState();
}

class _RoleSelectionState extends State<RoleSelection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: Text('What is your role?'),
      ),
      backgroundColor: Colors.lightBlue[300],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              ListTile(
                leading: Icon(Icons.badge),
                title: Text('Sacco Official'),
                onTap: (){
                  //aende login page as sacco official
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(selectedRole: 'sacco_official',)));
                }
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Stage Marshal'),
                onTap: (){
                  //aende login page as stage marshal
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(selectedRole: 'stage_marshal',)));
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.handshake),
                title: Text('Matatu Owner'),
                onTap: (){
                  //aende login page as matatu owner
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(selectedRole: 'matatu_owner',)));
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('Driver'),
                onTap: (){
                  //aende login page as driver
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(selectedRole: 'driver',)));

                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
