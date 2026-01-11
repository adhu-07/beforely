import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

class CreatePollScreen extends StatefulWidget {
  final String currentUserId;
  const CreatePollScreen({super.key, required this.currentUserId});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _questionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _postPoll() async {
    if (_questionController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.from('polls').insert({
        'creator_id': widget.currentUserId,
        'question': _questionController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context, true); // Return "true" to refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Poll Posted!"), backgroundColor: AppTheme.teaGreen),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ask the Campus", style: AppTheme.theme.textTheme.headlineMedium)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("What's on your mind?", style: AppTheme.theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "e.g., Best study spot on campus?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _postPoll,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Post Poll"),
            ),
          ],
        ),
      ),
    );
  }
}