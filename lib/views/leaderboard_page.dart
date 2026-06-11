import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  final String title;

  const LeaderboardPage({
    super.key,
    this.title = 'Leaderboard',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('Halaman $title'),
      ),
    );
  }
}
