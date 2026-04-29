import 'package:flutter/material.dart';

import 'app_router.dart';
import 'app_theme.dart';

class HouseRentApp extends StatelessWidget {
  const HouseRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HouseRent Pro',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
