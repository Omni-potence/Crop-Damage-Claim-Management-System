import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo and Title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/app_logo.jpeg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.agriculture,
                              size: 40,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Crop Damage App',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'फसल नुकसान ऐप',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'पीक नुकसान अॅप',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Language Selection Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Choose Your Language\nअपनी भाषा चुनें\nतुमची भाषा निवडा',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Language Options
                        _buildLanguageOption(
                          'English',
                          'English',
                          Icons.language,
                          Colors.blue,
                          const Locale('en'),
                        ),
                        const SizedBox(height: 16),

                        _buildLanguageOption(
                          'हिंदी',
                          'Hindi',
                          Icons.language,
                          Colors.orange,
                          const Locale('hi'),
                        ),
                        const SizedBox(height: 16),

                        _buildLanguageOption(
                          'मराठी',
                          'Marathi',
                          Icons.language,
                          Colors.purple,
                          const Locale('mr'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'You can change this later in settings',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Locale locale,
  ) {
    return InkWell(
      onTap: () => _selectLanguage(locale),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Language selection method with proper navigation handling
  Future<void> _selectLanguage(Locale locale) async {
    try {
      // Set the selected locale
      await context.setLocale(locale);
      
      // Add a small delay to ensure locale is set
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Mark language as selected
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('language_selected', true);
      
      // Check if widget is still mounted before navigation
      if (!mounted) return;
      
      // Use WidgetsBinding to ensure navigation happens after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });
    } catch (e) {
      print('Error setting language: $e');
      // Fallback: just set locale without navigation
      if (mounted) {
        try {
          await context.setLocale(locale);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('language_selected', true);
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } catch (fallbackError) {
          print('Fallback error: $fallbackError');
        }
      }
    }
  }
}
