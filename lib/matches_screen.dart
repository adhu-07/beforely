import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'chat_screen.dart'; 

class MatchesScreen extends StatefulWidget {
  final String currentUserId;
  const MatchesScreen({super.key, required this.currentUserId});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      // 1. Get everyone I liked
      final myLikes = await Supabase.instance.client
          .from('likes')
          .select('receiver_id')
          .eq('sender_id', widget.currentUserId);

      List<String> myLikedIds = (myLikes as List).map((e) => e['receiver_id'] as String).toList();

      if (myLikedIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Check which of them ALSO liked me back
      final mutualLikes = await Supabase.instance.client
          .from('likes')
          .select('sender_id')
          .filter('sender_id', 'in', myLikedIds) // <--- FIXED: Used .filter instead of .in_
          .eq('receiver_id', widget.currentUserId); // Filter: They sent the like to ME

      List<String> matchIds = (mutualLikes as List).map((e) => e['sender_id'] as String).toList();

      if (matchIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 3. Get their profile details
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select()
          .filter('id', 'in', matchIds); // <--- FIXED: Used .filter instead of .in_

      if (mounted) {
        setState(() {
          _matches = List<Map<String, dynamic>>.from(profiles);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading matches: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Matches", style: AppTheme.theme.textTheme.headlineMedium),
        backgroundColor: AppTheme.paperWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.inkBlack),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.inkBlack)) 
          : _matches.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("No matches yet.", style: AppTheme.theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text("Keep swiping to find your people!", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matches.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = _matches[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.teaGreen,
                        child: Text(
                          user['name'][0].toUpperCase(), 
                          style: const TextStyle(color: AppTheme.inkBlack, fontWeight: FontWeight.bold, fontSize: 24)
                        ),
                      ),
                      title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text(user['major'], style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.chat_bubble_outline, color: AppTheme.inkBlack),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              myId: widget.currentUserId, 
                              otherUser: user
                            )
                          )
                        );
                      },
                    );
                  },
                ),
    );
  }
}