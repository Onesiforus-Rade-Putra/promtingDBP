import 'package:flutter/material.dart';

class AddTargetPage extends StatelessWidget {
  const AddTargetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Target')),
      body: const Center(
        child: Text('Halaman Tambah Target'),
      ),
    );
  }
}
