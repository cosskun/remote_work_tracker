import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_model.dart';
import '../theme.dart';

class AddWorkDialog extends StatefulWidget {
  final DateTime initialDate;
  final double hourlyRate;
  final Function(WorkLog) onAdd;

  const AddWorkDialog({
    Key? key,
    required this.initialDate,
    required this.hourlyRate,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddWorkDialog> createState() => _AddWorkDialogState();
}

class _AddWorkDialogState extends State<AddWorkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  late DateTime _selectedDate;
  String _selectedCategory = 'Yazılım';
  int _hours = 1;
  int _minutes = 0;

  final List<String> _categories = ['Yazılım', 'Toplantı', 'Tasarım', 'Ofis', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final totalMinutes = (_hours * 60) + _minutes;
      if (totalMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen geçerli bir çalışma süresi girin.'),
            backgroundColor: AppColors.accent,
          ),
        );
        return;
      }

      final String inputDescription = _titleController.text.trim();
      final String formattedTitle = 'EVDEN ÇALIŞMA ("$inputDescription")';

      final newLog = WorkLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: formattedTitle,
        date: _selectedDate,
        durationMinutes: totalMinutes,
        category: 'Ev',
        hourlyRate: widget.hourlyRate,
      );

      widget.onAdd(newLog);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handling padding for keyboard on mobile devices
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Indicator
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Yeni Çalışma Kaydı',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'İş Açıklaması',
                  hintText: 'Bugün ne üzerinde çalıştınız?',
                  prefixIcon: Icon(Icons.edit_note, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen iş açıklamasını girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Date Picker Button
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: AppTheme.cardDecoration(hasShadow: false),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tarih',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(_selectedDate),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Duration selector
              const Text(
                'Çalışma Süresi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Hours Selector
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppTheme.cardDecoration(hasShadow: false),
                      child: Column(
                        children: [
                          const Text('Saat', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_hours > 0) setState(() => _hours--);
                                },
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                              ),
                              Text(
                                '$_hours',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (_hours < 24) setState(() => _hours++);
                                },
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Minutes Selector
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppTheme.cardDecoration(hasShadow: false),
                      child: Column(
                        children: [
                          const Text('Dakika', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_minutes >= 15) {
                                    setState(() => _minutes -= 15);
                                  } else if (_minutes > 0) {
                                    setState(() => _minutes = 0);
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                              ),
                              Text(
                                '$_minutes',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (_minutes <= 45) {
                                    setState(() => _minutes += 15);
                                  }
                                },
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Selector
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
