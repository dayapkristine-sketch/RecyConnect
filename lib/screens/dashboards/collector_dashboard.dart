import 'package:flutter/material.dart';

import '../shared/provider_dashboard.dart';

class CollectorDashboard extends StatelessWidget {
  const CollectorDashboard({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderDashboard(isJunkShop: false);
}
