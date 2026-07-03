import 'package:cbfapp/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';



class MyApp extends App {
  const MyApp({super.key});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
  DependencyInjection.init();
}
