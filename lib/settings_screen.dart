import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'main.dart'; 
import 'edit_profile.dart'; // <--- Import the new screen

class SettingsScreen extends StatelessWidget {
  final String currentUserId;
  const SettingsScreen({super.key, required this.currentUserId});

  // LOGOUT
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // DELETE ACCOUNT
  Future<void> _deleteAccount(BuildContext context) async {
    // Show Confirmation Dialog
    bool confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This cannot be undone. You will disappear from the campus forever."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    try {
      // Delete the row from Supabase
      await Supabase.instance.client.from('profiles').delete().eq('id', currentUserId);
      
      // Then Logout
      if (context.mounted) _logout(context);

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings", style: AppTheme.theme.textTheme.headlineMedium)),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
            const Icon(Icons.person, size: 80, color: AppTheme.inkBlack),
            const SizedBox(height: 20),
            Center(child: Text("ID: $currentUserId", style: AppTheme.theme.textTheme.headlineSmall)),
            const SizedBox(height: 40),

            // EDIT PROFILE
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.inkBlack),
              title: const Text("Edit Profile"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => EditProfileScreen(currentUserId: currentUserId))
                );
              },
            ),
            const Divider(),

            // LOGOUT
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.inkBlack),
              title: const Text("Log Out"),
              onTap: () => _logout(context),
            ),
            const Divider(),

            // DELETE ACCOUNT (Red Zone)
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppTheme.errorRed),
              title: const Text("Delete Account", style: TextStyle(color: AppTheme.errorRed)),
              onTap: () => _deleteAccount(context),
            ),
        ],
      ),
    );
  }
}