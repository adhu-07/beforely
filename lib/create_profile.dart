import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'home_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  final String inviteCode; 
  const CreateProfileScreen({super.key, required this.inviteCode});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  
  // Default values for Dropdowns
  String _gender = 'Male';
  String _preference = 'Female';
  
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _majorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('profiles').insert({
        'id': widget.inviteCode,
        'name': _nameController.text.trim(),
        'major': _majorController.text.trim(),
        'bio': _bioController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 18,
        'gender': _gender,
        'preference': _preference,
      });

      if (mounted) {
        // Pass BOTH the ID and the Preference to the Home Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              currentUserId: widget.inviteCode,
              myPreference: _preference, // <--- NEW: We pass what they want to see
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("The Real You", style: AppTheme.theme.textTheme.headlineMedium)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Basic Info
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            const SizedBox(height: 20),
            TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Age")),
            const SizedBox(height: 20),
            TextField(controller: _majorController, decoration: const InputDecoration(labelText: "Major / Year")),
            const SizedBox(height: 20),

            // 2. The "Gender" Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: "I am..."),
                    items: ['Male', 'Female', 'Non-Binary'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _preference,
                    decoration: const InputDecoration(labelText: "Looking for..."),
                    items: ['Male', 'Female', 'Everyone'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setState(() => _preference = val!),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // 3. The Hook
            TextField(
              controller: _bioController, 
              maxLines: 4, 
              decoration: const InputDecoration(
                labelText: "A weird fact about you...",
                alignLabelWithHint: true,
              )
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Join Campus"),
            ),
          ],
        ),
      ),
    );
  }
}