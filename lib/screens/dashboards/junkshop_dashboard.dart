import 'package:flutter/material.dart';

import '../shared/provider_dashboard.dart';

class JunkShopDashboard extends StatelessWidget {
  const JunkShopDashboard({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderDashboard(isJunkShop: true);
}
