import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Local Storage
import 'app_theme.dart';
import 'create_profile.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase (FIXED: Removed .instance)
  await Supabase.initialize(
    url: 'https://sekzsndykwzjnbrkcutj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNla3pzbmR5a3d6am5icmtjdXRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxMTcwNTYsImV4cCI6MjA4MzY5MzA1Nn0.psPQCBDGz6Te2VLft7oZqEIVUmobbEwPP6lb0PYV6-0',
  );

  // 2. Check for Device Lock (Auto-Login)
  final prefs = await SharedPreferences.getInstance();
  final savedId = prefs.getString('my_id');
  final savedPreference = prefs.getString('my_preference');

  runApp(BeforelyApp(initialId: savedId, initialPreference: savedPreference));
}

class BeforelyApp extends StatelessWidget {
  final String? initialId;
  final String? initialPreference;

  const BeforelyApp({super.key, this.initialId, this.initialPreference});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beforely',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Logic: If we have a saved ID, go straight to Home. Otherwise, Login.
      home: initialId != null 
          ? HomeScreen(currentUserId: initialId!, myPreference: initialPreference ?? 'Everyone') 
          : const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _message = "";
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    final inputCode = _codeController.text.trim();

    try {
      final data = await Supabase.instance.client
          .from('invite_codes')
          .select()
          .eq('code', inputCode)
          .maybeSingle();

      if (data == null) {
        setState(() => _message = "Invalid Code.");
      } else {
        // SUCCESS: Check if profile exists
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', inputCode)
            .maybeSingle();
        
        if (profile != null) {
           // USER ALREADY EXISTS -> SAVE TO DEVICE & GO HOME
           final prefs = await SharedPreferences.getInstance();
           await prefs.setString('my_id', inputCode);
           await prefs.setString('my_preference', profile['preference'] ?? 'Everyone');

           if (mounted) {
             Navigator.pushReplacement(
               context, 
               MaterialPageRoute(builder: (_) => HomeScreen(
                 currentUserId: inputCode, 
                 myPreference: profile['preference'] ?? 'Everyone')
               )
             );
           }
        } else {
           // NEW USER -> GO TO CREATE PROFILE
           if (mounted) {
             Navigator.pushReplacement(
               context,
               MaterialPageRoute(builder: (_) => CreateProfileScreen(inviteCode: inputCode)),
             );
           }
        }
      }
    } catch (e) {
      setState(() => _message = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Beforely.", style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: "Enter Code"),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Verify"),
            ),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}