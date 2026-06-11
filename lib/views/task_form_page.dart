import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/create_task_request_model.dart';
import '../models/task_model.dart';
import '../viewmodels/progress_tracking_view_model.dart';

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  static const Color _primaryRed = Color(0xFFE21C36);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskCategory? _selectedCategory = TaskCategory.akademik;
  TaskPriority? _selectedPriority = TaskPriority.sedang;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (selectedTime == null) return;

    setState(() {
      _deadline = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_deadline == null) {
      _showMessage('Deadline wajib dipilih.');
      return;
    }

    final viewModel = context.read<ProgressTrackingViewModel>();
    final result = await viewModel.addTask(
      CreateTaskRequestModel(
        title: _titleController.text,
        category: _selectedCategory!.apiValue,
        priority: _selectedPriority!.apiValue,
        deadline: _deadline!,
        description: _descriptionController.text,
      ),
    );

    if (!mounted) return;
    if (viewModel.takeSessionExpired()) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }
    if (result) {
      Navigator.of(context).pop(true);
      return;
    }
    _showMessage(
      viewModel.takeErrorMessage() ?? 'Tugas gagal ditambahkan.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        context.watch<ProgressTrackingViewModel>().isCreatingTask;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        title: const Text(
          'Tambah Tugas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFF0F1F4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Buat Target Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171A23),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Isi detail tugas belajar yang ingin kamu selesaikan.',
                      style: TextStyle(color: Color(0xFF737786)),
                    ),
                    const SizedBox(height: 22),
                    _label('Judul Tugas'),
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('Contoh: Belajar Bab 4'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tugas wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Kategori'),
                    DropdownButtonFormField<TaskCategory>(
                      value: _selectedCategory,
                      decoration: _inputDecoration('Pilih kategori'),
                      items: TaskCategory.values
                          .map(
                            (category) => DropdownMenuItem<TaskCategory>(
                              value: category,
                              child: Text(category.label),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setState(() => _selectedCategory = value),
                      validator: (value) =>
                          value == null ? 'Kategori wajib dipilih.' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Prioritas'),
                    DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                      decoration: _inputDecoration('Pilih prioritas'),
                      items: TaskPriority.values
                          .map(
                            (priority) => DropdownMenuItem<TaskPriority>(
                              value: priority,
                              child: Text(priority.label),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setState(() => _selectedPriority = value),
                      validator: (value) =>
                          value == null ? 'Prioritas wajib dipilih.' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Deadline'),
                    InkWell(
                      onTap: isSaving ? null : _selectDeadline,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: _inputDecoration('Pilih deadline'),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF727688),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _deadline == null
                                  ? 'Pilih tanggal dan waktu'
                                  : DateFormat('dd/MM/yyyy HH:mm')
                                      .format(_deadline!),
                              style: TextStyle(
                                color: _deadline == null
                                    ? const Color(0xFF9CA1AE)
                                    : const Color(0xFF171A23),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Deskripsi (Opsional)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Tambahkan catatan singkat tugas...',
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSaving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Tambah',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF252936),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA1AE)),
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE7E9EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE7E9EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryRed, width: 1.4),
      ),
    );
  }
}
