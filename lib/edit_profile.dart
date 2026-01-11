import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentUserId;
  const EditProfileScreen({super.key, required this.currentUserId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', widget.currentUserId)
        .single();
    
    setState(() {
      _nameController.text = data['name'];
      _majorController.text = data['major'];
      _bioController.text = data['bio'];
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'name': _nameController.text.trim(),
        'major': _majorController.text.trim(),
        'bio': _bioController.text.trim(),
      }).eq('id', widget.currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!"), backgroundColor: AppTheme.teaGreen),
        );
        Navigator.pop(context); // Go back to Settings
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
      appBar: AppBar(title: Text("Edit Profile", style: AppTheme.theme.textTheme.headlineMedium)),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
                   const SizedBox(height: 20),
                   TextField(controller: _majorController, decoration: const InputDecoration(labelText: "Major")),
                   const SizedBox(height: 20),
                   TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: "Bio")),
                   const SizedBox(height: 40),
                   ElevatedButton(
                     onPressed: _updateProfile,
                     child: const Text("Save Changes"),
                   )
                ],
              ),
            ),
    );
  }
}