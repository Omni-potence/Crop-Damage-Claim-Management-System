import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_event.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';
import 'package:crop_damage_app/services/firebase_service.dart';
import 'package:crop_damage_app/models/claim.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildHomeContent(context, state.appUser);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, user) {
    return Container(
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
        child: Column(
          children: [
            // Header Section
            _buildHeader(context, user),
            
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
                child: _buildMainContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // User Avatar with App Logo
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: AssetImage('assets/images/app_logo.jpeg'),
          ),
          const SizedBox(width: 16),
          
          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome_back'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.name.isNotEmpty ? user.name : 'user'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Language & Logout
          Row(
            children: [
              IconButton(
                onPressed: () => _changeLanguage(context),
                icon: const Icon(
                  Icons.language,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 30),
          
          // Main Actions
          Text(
            'quick_actions'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Action Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.add_circle,
                  title: 'submit_new_claim'.tr(),
                  subtitle: 'report_crop_damage'.tr(),
                  color: Colors.blue,
                  onTap: () => Navigator.of(context).pushNamed('/claim_form'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.track_changes,
                  title: 'track_claims'.tr(),
                  subtitle: 'view_claim_status'.tr(),
                  color: Colors.orange,
                  onTap: () => Navigator.of(context).pushNamed('/claim_status'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  title: 'claim_history'.tr(),
                  subtitle: 'past_submissions'.tr(),
                  color: Colors.purple,
                  onTap: () => Navigator.of(context).pushNamed('/claim_status'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.help,
                  title: 'help_support'.tr(),
                  subtitle: 'get_assistance'.tr(),
                  color: Colors.teal,
                  onTap: () => _showHelpDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return StreamBuilder<List<Claim>>(
            stream: FirebaseService().getUserClaims(state.appUser.id),
            builder: (context, snapshot) {
              int totalClaims = 0;
              int approvedClaims = 0;
              int pendingClaims = 0;

              if (snapshot.hasData && snapshot.data != null) {
                totalClaims = snapshot.data!.length;
                approvedClaims = snapshot.data!.where((claim) => claim.status == ClaimStatus.approved).length;
                pendingClaims = snapshot.data!.where((claim) => claim.status == ClaimStatus.pending).length;
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem('total_claims'.tr(), totalClaims.toString(), Icons.description),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.green.shade300,
                    ),
                    Expanded(
                      child: _buildStatItem('approved'.tr(), approvedClaims.toString(), Icons.check_circle),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.green.shade300,
                    ),
                    Expanded(
                      child: _buildStatItem('pending'.tr(), pendingClaims.toString(), Icons.pending),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return Container();
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade600, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.green.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeLanguage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('select_language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: const Text('English'),
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                },
                trailing: context.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.orange),
                title: const Text('हिंदी'),
                onTap: () {
                  context.setLocale(const Locale('hi'));
                  Navigator.of(context).pop();
                },
                trailing: context.locale.languageCode == 'hi'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.purple),
                title: const Text('मराठी'),
                onTap: () {
                  context.setLocale(const Locale('mr'));
                  Navigator.of(context).pop();
                },
                trailing: context.locale.languageCode == 'mr'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('logout'.tr()),
          content: Text('logout_confirmation'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(AuthSignedOut());
              },
              child: Text('logout'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('help_support'.tr()),
          content: Text('help_content'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'.tr()),
            ),
          ],
        );
      },
    );
  }
}
