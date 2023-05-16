import 'package:flutter/material.dart';
import 'package:rideglory/features/home/presentation/pages/home_page.dart';
import 'package:rideglory/shared/theme/theme.dart';
import 'shared/routes/route_generator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/config/.env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const HomePage(),
    );
  }
}