import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_event.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:crop_damage_app/widgets/loading_indicator.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  String? _verificationId;
  bool _isOtpSent = false;
  bool _isNewUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _phoneController.text = '+91'; // Prepend +91 for Indian numbers
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _aadharController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthCodeSent) {
            setState(() {
              _verificationId = state.verificationId;
              _isOtpSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('otp_sent_message'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('login_success_message'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const LoadingIndicator();
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                  Colors.green.shade800,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(),
                  
                  // Main Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: _isOtpSent ? _buildOtpVerification() : _buildPhoneInput(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // App Logo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.agriculture,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // App Title
          Text(
            'Crop Damage App',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Secure your crops with digital claims',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Welcome Text
          Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your phone number to continue',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          
          // Phone Number Input
          Text(
            'phone_number_label'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.phone,
                  color: Colors.green.shade600,
                ),
                hintText: '+91 98765 43210',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Send OTP Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'send_otp_button'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Terms and Privacy
          Center(
            child: Text(
              'By continuing, you agree to our Terms & Privacy Policy',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerification() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Back Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isOtpSent = false;
                _verificationId = null;
                _otpController.clear();
              });
            },
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Verification Text
          Text(
            'Verify Phone Number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to ${_phoneController.text}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          
          // OTP Input
          Text(
            'otp_label'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            child: TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              maxLength: 6,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: '000000',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'verify_otp_button'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Resend OTP
          Center(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state is AuthLoading ? null : () {
                    setState(() {
                      _isOtpSent = false;
                      _verificationId = null;
                      _otpController.clear();
                    });
                    _sendOtp();
                  },
                  child: Text(
                    state is AuthLoading ? 'Sending...' : 'Resend OTP',
                    style: TextStyle(
                      color: state is AuthLoading
                          ? Colors.grey.shade400
                          : Colors.green.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Test Code Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Not receiving SMS?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'If your number is added as a test number in Firebase Console, use the test verification code instead of waiting for SMS.',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendOtp() {
    String phoneNumber = _phoneController.text.trim();

    // Validate phone number format
    if (phoneNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
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

    context.read<AuthBloc>().add(PhoneNumberSubmitted(phoneNumber));
  }

  void _verifyOtp() {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(OTPSubmitted(_otpController.text));
  }
}
