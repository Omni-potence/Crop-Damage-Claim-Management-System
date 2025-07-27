import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';
import 'package:crop_damage_app/models/claim.dart';
import 'package:crop_damage_app/services/firebase_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimStatusScreen extends StatelessWidget {
  const ClaimStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return Center(child: Text('not_authenticated_message'.tr()));
    }

    final String userId = authState.appUser.id;

    return Scaffold(
      appBar: AppBar(title: Text('claim_status_title'.tr())),
      body: StreamBuilder<List<Claim>>(
        stream: firebaseService.getUserClaims(userId),
        builder: (context, snapshot) {
          print('🔥 UI: StreamBuilder state - ConnectionState: ${snapshot.connectionState}');
          print('🔥 UI: Has data: ${snapshot.hasData}');
          print('🔥 UI: Has error: ${snapshot.hasError}');
          if (snapshot.hasData) {
            print('🔥 UI: Data length: ${snapshot.data!.length}');
          }
          if (snapshot.hasError) {
            print('🔥 UI: Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your claims...'),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error fetching claims:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force rebuild to retry
                      (context as Element).markNeedsBuild();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No claims found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('You haven\'t submitted any claims yet.', textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/claim_form'),
                    child: Text('Submit Your First Claim'),
                  ),
                ],
              ),
            );
          }

          final claims = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: claims.length,
            itemBuilder: (context, index) {
              final claim = claims[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${'claim_id'.tr()}: ${claim.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Builder(builder: (context) {
                        Color statusColor;
                        switch (claim.status) {
                          case ClaimStatus.approved:
                            statusColor = Colors.green;
                            break;
                          case ClaimStatus.rejected:
                            statusColor = Colors.red;
                            break;
                          case ClaimStatus.pending:
                          default:
                            statusColor = Colors.orange;
                            break;
                        }
                        return Text(
                          '${'status'.tr()}: ${claim.status.name.tr()}',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text('${'reason'.tr()}: ${claim.reason.tr()}'),
                      const SizedBox(height: 4),
                      Text('${'land_address'.tr()}: ${claim.landAddress}'),
                      const SizedBox(height: 4),
                      Text('${'area_in_acres'.tr()}: ${claim.areaInAcres}'),
                      const SizedBox(height: 4),
                      Text('${'submitted_at'.tr()}: ${DateFormat('dd-MM-yyyy HH:mm').format(claim.submittedAt.toDate())}'),
                      const SizedBox(height: 8),
                      Text('${'officer_remarks'.tr()}: ${claim.officerRemarks.isEmpty ? 'no_remarks'.tr() : claim.officerRemarks}'),
                      const SizedBox(height: 8),
                      if (claim.imageUrl.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('uploaded_photo'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Image.network(claim.imageUrl, height: 150, fit: BoxFit.cover),
                            const SizedBox(height: 8),
                          ],
                        ),
                      if (claim.documentUrls.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('supporting_documents'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ...claim.documentUrls.map((url) => GestureDetector(
                              onTap: () async {
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${'could_not_open_url'.tr()}: $url')),
                                  );
                                }
                              },
                              child: Text(
                                url.split('/').last.split('?').first, // Display filename
                                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                              ),
                            )).toList(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      Text('${'gps_location'.tr()}: Lat: ${claim.gps.latitude.toStringAsFixed(4)}, Lon: ${claim.gps.longitude.toStringAsFixed(4)}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
