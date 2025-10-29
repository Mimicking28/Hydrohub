import 'package:flutter/material.dart';
import 'package:hydrohub/Owner/Account/manage_staff.dart';
import 'package:hydrohub/Owner/Account/station_profile.dart';
import 'package:hydrohub/Owner/Account/update_staff.dart';
import 'package:hydrohub/owner/Account/add_staff.dart';
import '../../widgets/custom_menu_button.dart';
import '../home_page.dart';
import '../profile.dart'; // ✅ Import profile page

class AccountPage extends StatelessWidget {
  final int stationId; // 🔹 Pass the owner’s assigned station ID
  final int ownerId;

  const AccountPage({super.key, required this.stationId, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021526), // Dark background
      body: Stack(
        children: [
          // 🔵 Top-right ovals
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -80,
            child: Container(
              width: 160,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF6EACDA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          // 🔵 Bottom-left oval
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Icon aligned top-right
                   Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OwnerProfilePage(
                              ownerId: ownerId,
                              stationId: stationId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.account_circle,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // HydroHub Title centered
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(stationId: stationId, ownerId: ownerId),
                          ),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'Hydro',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Hub',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Buttons
                  CustomMenuButton(
                    icon: Icons.store,
                    label: "Station Account",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StationProfile(stationId: stationId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomMenuButton(
                    icon: Icons.person_add_alt_outlined,
                    label: "Add New Staff",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddStaff(stationId: stationId),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  CustomMenuButton(
                    icon: Icons.manage_accounts,
                    label: "Manage Station Accounts",
                    onPressed: () {
                      // TODO: Replace AddStaff() with ManageStaffPage()
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageStaff(stationId: stationId),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  CustomMenuButton(
                    icon: Icons.list_alt,
                    label: "Update Staff Accounts",
                    onPressed: () {
                      // TODO: Replace AddStaff() with AccountListPage()
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateStaff(stationId: stationId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
