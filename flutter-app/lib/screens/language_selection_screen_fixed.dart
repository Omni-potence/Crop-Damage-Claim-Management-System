import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3C72),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.agriculture,
                  size: 60,
                  color: Color(0xFF1E3C72),
                ),
              ),
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Crop Damage Assessment',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'Select your preferred language',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              // Language Options
              _buildLanguageOption(
                'English',
                'en',
                '🇺🇸',
                'Continue in English',
              ),
              const SizedBox(height: 16),
              
              _buildLanguageOption(
                'हिंदी',
                'hi',
                '🇮🇳',
                'हिंदी में जारी रखें',
              ),
              const SizedBox(height: 16),
              
              _buildLanguageOption(
                'मराठी',
                'mr',
                '🇮🇳',
                'मराठीत सुरू ठेवा',
              ),
              
              const SizedBox(height: 40),
              
              // Continue Button
              if (selectedLanguage != null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _selectLanguage(selectedLanguage!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3C72),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String code, String flag, String subtitle) {
    final isSelected = selectedLanguage == code;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage = code;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF1E3C72) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? const Color(0xFF1E3C72).withOpacity(0.7) 
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1E3C72),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  // FIXED: Language selection method with proper navigation handling
  Future<void> _selectLanguage(String languageCode) async {
    try {
      // Set the locale first
      await context.setLocale(Locale(languageCode));
      
      // Add a small delay to ensure locale is set
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Check if widget is still mounted before navigation
      if (!mounted) return;
      
      // Use WidgetsBinding to ensure navigation happens after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Use pushReplacementNamed to avoid back navigation
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      });
    } catch (e) {
      print('Error setting language: $e');
      // Fallback: just set locale without navigation
      if (mounted) {
        try {
          await context.setLocale(Locale(languageCode));
          // Try navigation again after a longer delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        } catch (fallbackError) {
          print('Fallback error: $fallbackError');
        }
      }
    }
  }
}
