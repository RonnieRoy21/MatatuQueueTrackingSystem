import 'package:flutter/material.dart';
import 'Driver/driver_dashboard.dart';
import 'StageMarshal/stage_marshal_dashboard.dart';
import 'SaccoOfficial/sacco_official_dashboard.dart';
import 'MatatuOwner/matatu_owner_dashboard.dart';


Widget getDashboard(String role,String vehicle) {
  switch (role) {
    case 'driver':
      return DriverDashboard();
    case 'stage_marshal':
      return  StageMarshalDashboard();
    case 'sacco_official':
      return  SaccoOfficialDashboard();
    case 'matatu_owner':
      return MatatuOwnerDashboard();
    default:
      return Scaffold(
        body: Center(child: Text('Unknown role: $role')),
      );
  }
}
