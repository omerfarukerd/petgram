import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pet_gram/presentation/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/post_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/message_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'PetGram',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isAuthenticated 
                ? const HomeScreen() 
                : const LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}