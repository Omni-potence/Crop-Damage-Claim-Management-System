import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:crop_damage_app/firebase_options.dart';
import 'package:crop_damage_app/services/firebase_service.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_event.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';
import 'package:crop_damage_app/screens/new_auth_screen.dart';
import 'package:crop_damage_app/screens/language_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crop_damage_app/screens/profile_setup_screen.dart';
import 'package:crop_damage_app/screens/home_screen.dart';
import 'package:crop_damage_app/screens/new_claim_form_screen.dart';
import 'package:crop_damage_app/screens/claim_status_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
      path: 'lib/l10n', // <-- change the path of the translation files
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkLanguageSelection() async {
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getBool('language_selected') ?? false;
    return true; // Always return true to bypass language selection
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => FirebaseService(),
      child: BlocProvider(
        create: (context) =>
            AuthBloc(context.read<FirebaseService>())..add(AppStarted()),
        child: MaterialApp(
          title: 'Crop Damage App',
          theme: ThemeData(
            primarySwatch: Colors.green,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: FutureBuilder<bool>(
            future: _checkLanguageSelection(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final languageSelected = snapshot.data ?? false;
              if (!languageSelected) {
                return const LanguageSelectionScreen();
              }

              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    return const HomeScreen();
                  } else if (state is AuthProfileSetupRequired) {
                    return const ProfileSetupScreen();
                  }
                  return const NewAuthScreen();
                },
              );
            },
          ),
          routes: {
            '/language_selection': (context) => const LanguageSelectionScreen(),
            '/auth': (context) => const NewAuthScreen(),
            '/profile_setup': (context) => const ProfileSetupScreen(),
            '/home': (context) => const HomeScreen(),
            '/claim_form': (context) => const NewClaimFormScreen(),
            '/claim_status': (context) => const ClaimStatusScreen(),
          },
        ),
      ),
    );
  }
}
