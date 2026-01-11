import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; 
import 'app_theme.dart';
import 'matches_screen.dart'; 
import 'settings_screen.dart'; 
import 'polls_screen.dart';
import 'chat_screen.dart'; // Import Chat Screen for instant navigation

class HomeScreen extends StatefulWidget {
  final String currentUserId; 
  final String myPreference;

  const HomeScreen({
    super.key, 
    required this.currentUserId, 
    required this.myPreference
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _candidates = [];
  bool _isLoading = true;
  final CardSwiperController _controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    var query = Supabase.instance.client.from('profiles').select();
    if (widget.myPreference != 'Everyone') {
      query = query.eq('gender', widget.myPreference);
    }
    
    final allUsers = await query;
    final myLikes = await Supabase.instance.client.from('likes').select('receiver_id').eq('sender_id', widget.currentUserId);
    final myDislikes = await Supabase.instance.client.from('dislikes').select('receiver_id').eq('sender_id', widget.currentUserId);
    
    final seenIds = {
      ...myLikes.map((e) => e['receiver_id']),
      ...myDislikes.map((e) => e['receiver_id']),
      widget.currentUserId
    };

    if (mounted) {
      setState(() {
        _candidates = List<Map<String, dynamic>>.from(allUsers).where((u) => !seenIds.contains(u['id'])).toList();
        _isLoading = false;
      });
    }
  }

  // --- NEW: MATCH DIALOG ANIMATION ---
  void _showMatchDialog(Map<String, dynamic> matchedUser) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.paperWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.inkBlack, width: 3),
              boxShadow: const [BoxShadow(color: AppTheme.inkBlack, offset: Offset(10, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: AppTheme.errorRed, size: 80),
                const SizedBox(height: 20),
                Text("IT'S A MATCH!", style: AppTheme.theme.textTheme.displayLarge),
                const SizedBox(height: 10),
                Text("You and ${matchedUser['name']} vibe.", textAlign: TextAlign.center, style: AppTheme.theme.textTheme.headlineSmall),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => ChatScreen(myId: widget.currentUserId, otherUser: matchedUser))
                    );
                  }, 
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teaGreen, foregroundColor: AppTheme.inkBlack),
                  child: const Text("SAY HELLO NOW"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("KEEP SWIPING"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) async {
    final user = _candidates[previousIndex];
    
    if (direction == CardSwiperDirection.right) {
      // 1. Check Limit
      final today = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
      final likesToday = await Supabase.instance.client.from('likes').select().eq('sender_id', widget.currentUserId).gt('created_at', today);
      if (likesToday.length >= 10) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Daily limit reached!")));
        return false;
      }
      
      // 2. Save Like
      await Supabase.instance.client.from('likes').insert({
        'sender_id': widget.currentUserId,
        'receiver_id': user['id'],
      });

      // 3. --- INSTANT MATCH CHECK ---
      // Did they already like me?
      final checkBack = await Supabase.instance.client
          .from('likes')
          .select()
          .eq('sender_id', user['id']) // They are sender
          .eq('receiver_id', widget.currentUserId) // I am receiver
          .maybeSingle();

      if (checkBack != null) {
        // BOOM! Match found.
        if (mounted) _showMatchDialog(user);
      }

      return true;

    } else if (direction == CardSwiperDirection.left) {
      await Supabase.instance.client.from('dislikes').insert({'sender_id': widget.currentUserId, 'receiver_id': user['id']});
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("The Hallway", style: AppTheme.theme.textTheme.headlineMedium),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.poll, size: 28, color: AppTheme.inkBlack),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PollsScreen(currentUserId: widget.currentUserId))),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 28, color: AppTheme.inkBlack),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchesScreen(currentUserId: widget.currentUserId))),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 30, color: AppTheme.inkBlack),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(currentUserId: widget.currentUserId))),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.inkBlack))
        : _candidates.isEmpty 
          ? Center(child: Text("No more profiles!", style: AppTheme.theme.textTheme.headlineMedium))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: CardSwiper(
                controller: _controller,
                cardsCount: _candidates.length,
                onSwipe: _onSwipe,
                numberOfCardsDisplayed: 2,
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  final user = _candidates[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.paperWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.inkBlack, width: 2),
                      boxShadow: const [BoxShadow(color: AppTheme.inkBlack, offset: Offset(8, 8))],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('"${user['bio']}"', textAlign: TextAlign.center, style: AppTheme.theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
                              const SizedBox(height: 30),
                              Chip(
                                backgroundColor: AppTheme.teaGreen,
                                label: Text(user['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                              ),
                              const SizedBox(height: 10),
                              Text("${user['major']} • ${user['age']}", style: AppTheme.theme.textTheme.bodyLarge),
                              const Spacer(),
                              const Text("Swipe Right ->", style: TextStyle(color: AppTheme.pencilGrey)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10, right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.flag_outlined, color: AppTheme.pencilGrey),
                            onPressed: () { /* Report Logic Already Added */ },
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}