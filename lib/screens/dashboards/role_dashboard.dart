import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import 'collector_dashboard.dart';
import 'household_dashboard.dart';
import 'junkshop_dashboard.dart';

class RoleDashboard extends StatelessWidget {
  const RoleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final role = app.currentUser?.role;
    if (role == UserRole.household) return const HouseholdDashboard();
    if (role == UserRole.collector) return const CollectorDashboard();
    return const JunkShopDashboard();
  }
}
