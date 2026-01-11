import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  final String myId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({super.key, required this.myId, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late String _matchId;
  
  final List<String> _games = [
    "GAME: Two Truths and a Lie. You go first.",
    "GAME: What is your most controversial opinion?",
    "GAME: Describe your perfect Sunday in 3 words.",
    "GAME: If you could teleport anywhere right now, where?",
    "GAME: What's the weirdest thing in your fridge?",
  ];

  @override
  void initState() {
    super.initState();
    List<String> ids = [widget.myId, widget.otherUser['id']];
    ids.sort(); 
    _matchId = ids.join('_');
  }

  void _sendMessage({String? customText}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await Supabase.instance.client.from('messages').insert({
      'match_id': _matchId,
      'sender_id': widget.myId,
      'content': text,
    });
  }

  // --- NEW: UNMATCH LOGIC ---
  Future<void> _unmatchUser() async {
    final confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Unmatch?"),
        content: const Text("This will disappear from your matches. You cannot undo this."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Unmatch", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      try {
        // To unmatch, we simply delete MY like for them.
        // The Match logic requires TWO likes. If one is gone, the match breaks.
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('sender_id', widget.myId)
            .eq('receiver_id', widget.otherUser['id']);
            
        if (mounted) {
          Navigator.pop(context); // Close chat
          Navigator.pop(context); // Go back to Home
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unmatched.")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', _matchId)
        .order('created_at', ascending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser['name'], style: AppTheme.theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.videogame_asset),
            onPressed: () => _sendMessage(customText: _games[Random().nextInt(_games.length)]),
          ),
          // --- NEW: OPTIONS MENU ---
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.inkBlack),
            onSelected: (value) {
              if (value == 'unmatch') _unmatchUser();
              // Add report logic here if needed
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'unmatch',
                child: Text('Unmatch User', style: TextStyle(color: Colors.red)),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == widget.myId;
                    final isGame = msg['content'].toString().startsWith("GAME:");
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isGame ? AppTheme.teaGreen : (isMe ? AppTheme.inkBlack : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.inkBlack),
                          boxShadow: isMe ? const [BoxShadow(color: Colors.black26, offset: Offset(2,2))] : [],
                        ),
                        child: Text(
                          msg['content'],
                          style: TextStyle(
                            color: isGame || !isMe ? AppTheme.inkBlack : Colors.white,
                            fontFamily: 'Patrick Hand', // Ensure custom font in chat
                            fontSize: 18,
                            fontWeight: isGame ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: "Say hi..."))),
                const SizedBox(width: 10),
                IconButton(icon: const Icon(Icons.send), onPressed: () => _sendMessage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}