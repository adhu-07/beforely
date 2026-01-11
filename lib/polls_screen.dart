import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'create_poll.dart';

class PollsScreen extends StatefulWidget {
  final String currentUserId;
  const PollsScreen({super.key, required this.currentUserId});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  List<Map<String, dynamic>> _polls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    setState(() => _isLoading = true);
    
    // 1. Get Polls
    final pollsData = await Supabase.instance.client
        .from('polls')
        .select()
        .order('created_at', ascending: false);
    
    // 2. Get Votes (to calculate percentages)
    final votesData = await Supabase.instance.client.from('poll_votes').select();
    
    List<Map<String, dynamic>> processedPolls = [];

    for (var poll in pollsData) {
      final pollId = poll['id'];
      final pollVotes = (votesData as List).where((v) => v['poll_id'] == pollId).toList();
      
      final yesVotes = pollVotes.where((v) => v['option_chosen'] == 'Yes').length;
      final noVotes = pollVotes.where((v) => v['option_chosen'] == 'No').length;
      final total = yesVotes + noVotes;
      
      // Check if I voted
      final myVote = pollVotes.firstWhere(
        (v) => v['voter_id'] == widget.currentUserId, 
        orElse: () => null
      );

      processedPolls.add({
        ...poll,
        'yes': yesVotes,
        'no': noVotes,
        'total': total,
        'my_vote': myVote != null ? myVote['option_chosen'] : null, // 'Yes', 'No', or null
      });
    }

    if (mounted) {
      setState(() {
        _polls = processedPolls;
        _isLoading = false;
      });
    }
  }

  Future<void> _vote(int pollId, String option) async {
    try {
      await Supabase.instance.client.from('poll_votes').insert({
        'poll_id': pollId,
        'voter_id': widget.currentUserId,
        'option_chosen': option
      });
      _loadPolls(); // Refresh to show new stats
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Campus Polls", style: AppTheme.theme.textTheme.headlineMedium)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.inkBlack,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final refresh = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => CreatePollScreen(currentUserId: widget.currentUserId))
          );
          if (refresh == true) _loadPolls();
        },
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _polls.length,
              itemBuilder: (context, index) {
                final poll = _polls[index];
                final hasVoted = poll['my_vote'] != null;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: AppTheme.paperWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.inkBlack, width: 1.5)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(poll['question'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        if (hasVoted) ...[
                          // RESULTS VIEW
                          _buildResultBar("Yes", poll['yes'], poll['total']),
                          const SizedBox(height: 8),
                          _buildResultBar("No", poll['no'], poll['total']),
                          const SizedBox(height: 8),
                          Text("You voted: ${poll['my_vote']}", style: const TextStyle(color: Colors.grey)),
                        ] else ...[
                          // VOTING BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _vote(poll['id'], 'Yes'),
                                  child: const Text("YES"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _vote(poll['id'], 'No'),
                                  child: const Text("NO"),
                                ),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildResultBar(String label, int count, int total) {
    double percent = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text("${(percent * 100).toStringAsFixed(0)}%"),
          ],
        ),
        LinearProgressIndicator(
          value: percent, 
          backgroundColor: Colors.grey[200],
          color: AppTheme.inkBlack,
          minHeight: 8,
        ),
      ],
    );
  }
}