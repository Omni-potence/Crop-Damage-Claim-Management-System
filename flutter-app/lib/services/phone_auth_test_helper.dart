import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthTestHelper {
  static void enableTestMode() {
    // Enable test mode for development
    FirebaseAuth.instance.firebaseAuthSettings
        .setAppVerificationDisabledForTesting();
    
    print('🔥 Phone Auth Test Mode Enabled');
  }
  
  static void setTestPhoneNumber(String phoneNumber, String smsCode) {
    // Set test phone number for auto-retrieval testing
    FirebaseAuth.instance.firebaseAuthSettings
        .setAutoRetrievedSmsCodeForPhoneNumber(phoneNumber, smsCode);
    
    print('🔥 Test phone number configured: $phoneNumber with code: $smsCode');
  }
  
  static void forceRecaptcha() {
    // Force reCAPTCHA flow for testing
    FirebaseAuth.instance.firebaseAuthSettings
        .forceRecaptchaFlowForTesting();
    
    print('🔥 Forced reCAPTCHA flow for testing');
  }
  
  static void disableTestMode() {
    // Disable test mode
    FirebaseAuth.instance.firebaseAuthSettings
        .setAppVerificationDisabledForTesting(false);
    
    print('🔥 Phone Auth Test Mode Disabled');
  }
}
