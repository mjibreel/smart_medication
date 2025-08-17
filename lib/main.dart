import 'package:flutter/material.dart';
import 'package:smart_medication/pages/home_page.dart';
import 'package:smart_medication/pages/auth/signin_page.dart' as sign_in;
import 'package:smart_medication/pages/auth/signup_page.dart' as sign_up;
import 'package:smart_medication/services/notification_service.dart';
// import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_medication/pages/scheduling.dart';
import 'package:smart_medication/pages/medication_reminders.dart';
import 'package:smart_medication/pages/ProfileDisplayPage.dart';
import 'package:smart_medication/pages/ProfileSetupPage.dart';
import 'package:smart_medication/pages/health_page.dart';
import 'package:smart_medication/pages/checkup_page.dart';
import 'firebase_options.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:smart_medication/widgets/app_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService.init();
  await requestNotificationPermissions();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Appointment Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home',
      routes: {
        '/signin': (context) => const sign_in.SignInPage(),
        '/signup': (context) => const sign_up.SignUpPage(),
        '/home': (context) => const AppScaffold(body: HomePage()),
        '/scheduling': (context) => const AppScaffold(body: MedicationTrackerPage()),
        '/medicine': (context) => const AppScaffold(body: MedicationReminderPage()),
        '/health': (context) => const AppScaffold(body: HealthPage()),
        '/checkup': (context) => const AppScaffold(body: CheckupPage()),
        '/ProfileDisplayPage': (context) => const AppScaffold(body: ProfileDisplayPage()),
        '/ProfileSetupPage': (context) => const AppScaffold(body: ProfileSetupPage()),
      },
    );
  }
}

Future<void> requestNotificationPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
