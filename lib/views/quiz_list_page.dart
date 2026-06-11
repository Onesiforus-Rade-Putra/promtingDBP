import 'package:flutter/material.dart';

class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz List')),
      body: const Center(
        child: Text('Halaman Quiz List'),
      ),
    );
  }
}
