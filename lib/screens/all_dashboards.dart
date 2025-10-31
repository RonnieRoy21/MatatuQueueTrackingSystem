import 'package:flutter/material.dart';
import 'driver_dashboard.dart';
import 'conductor_dashboard.dart';
import 'stage_marshal_dashboard.dart';
import 'sacco_official_dashboard.dart';
import 'matatu_owner_dashboard.dart';

import 'dashboard_helper.dart';

Widget getDashboard(String role) {
  switch (role) {
    case 'driver':
      return DriverDashboard();
    case 'conductor':
      return  ConductorDashboard();
    case 'stageMarshal':
      return  StageMarshalDashboard();
    case 'saccoOfficial':
      return  SaccoOfficialDashboard();
    case 'matatuOwner':
      return MatatuOwnerDashboard();
    default:
      return Scaffold(
        body: Center(child: Text('Unknown role: $role')),
      );
  }
}
