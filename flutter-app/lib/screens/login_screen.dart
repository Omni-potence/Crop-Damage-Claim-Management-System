import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_event.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:crop_damage_app/widgets/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+91'; // Prepend +91 for Indian numbers

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('login_title'.tr()),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          print('🔥 UI: Auth state changed to: ${state.runtimeType}');
          if (state is AuthCodeSent) {
            print('🔥 UI: Setting verificationId: ${state.verificationId}');
            _verificationId = state.verificationId;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('otp_sent_message'.tr())),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('login_success_message'.tr())),
            );
            // Navigate to home screen or dashboard
            // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          print('🔥 UI: Building with state: ${state.runtimeType}');
          if (state is AuthLoading) {
            print('🔥 UI: Showing loading indicator');
            return const LoadingIndicator();
          }
          return FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Title
                      Icon(
                        Icons.agriculture,
                        size: 100,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Crop Damage App',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'phone_number_label'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            String phoneNumber = _phoneController.text.trim();

                            // Validate phone number format
                            if (phoneNumber.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid phone number')),
                              );
                              return;
                            }

                            // Ensure proper format for Indian numbers
                            if (!phoneNumber.startsWith('+91')) {
                              if (phoneNumber.startsWith('91')) {
                                phoneNumber = '+$phoneNumber';
                              } else if (phoneNumber.length == 10) {
                                phoneNumber = '+91$phoneNumber';
                              }
                            }

                            print('🔥 Submitting phone number: $phoneNumber');
                            context.read<AuthBloc>().add(
                                  PhoneNumberSubmitted(phoneNumber),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text('send_otp_button'.tr()),
                        ),
                      ),
                      if (_verificationId != null) ...[
                        const SizedBox(height: 30),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'otp_label'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                    OTPSubmitted(_otpController.text),
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: Text('verify_otp_button'.tr()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
