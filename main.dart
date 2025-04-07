
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/home.dart';
import 'screens/auction_host.dart';
import 'screens/auction_viewer.dart';
import 'screens/storefront.dart';
import 'screens/payment_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(NeighborNestApp());
}

class NeighborNestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeighborNest',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => LoginScreen(),
        '/signup': (_) => SignupScreen(),
        '/home': (_) => HomeScreen(),
        '/auction-viewer': (_) => AuctionViewerScreen(),
        '/auction-host': (_) => AuctionHostScreen(),
        '/storefront': (_) => StorefrontScreen(),
        '/payment-info': (_) => PaymentInfoScreen(),
      },
    );
  }
}
