import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_model.dart';
import '../theme.dart';
import '../storage.dart';
import '../widgets/add_work_dialog.dart';

class HomeScreen extends StatefulWidget {
  final List<WorkLog> allLogs;
  final double hourlyRate;
  final Function(List<WorkLog>) onLogsChanged;
  final Function(double) onHourlyRateChanged;

  const HomeScreen({
    Key? key,
    required this.allLogs,
    required this.hourlyRate,
    required this.onLogsChanged,
    required this.onHourlyRateChanged,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  // Week boundary helpers
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Get Monday-Sunday dates of the week containing _selectedDate
  List<DateTime> _getCurrentWeekDays() {
    final start = _getStartOfWeek(_selectedDate);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  // Calculated stats for the currently selected week
  double get _weeklyHours {
    final start = _getStartOfWeek(_selectedDate);
    final end = DateTime(start.year, start.month, start.day, 23, 59, 59).add(const Duration(days: 6));
    
    return widget.allLogs.where((log) {
      return log.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
             log.date.isBefore(end.add(const Duration(seconds: 1)));
    }).fold(0.0, (sum, log) => sum + log.durationHours);
  }

  double get _weeklyEarnings {
    final start = _getStartOfWeek(_selectedDate);
    final end = DateTime(start.year, start.month, start.day, 23, 59, 59).add(const Duration(days: 6));
    
    return widget.allLogs.where((log) {
      return log.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
             log.date.isBefore(end.add(const Duration(seconds: 1)));
    }).fold(0.0, (sum, log) => sum + (log.durationHours * log.hourlyRate));
  }

  // Filter logs for the selected day
  List<WorkLog> get _selectedDayLogs {
    return widget.allLogs.where((log) {
      return log.date.year == _selectedDate.year &&
             log.date.month == _selectedDate.month &&
             log.date.day == _selectedDate.day;
    }).toList();
  }

  // Check if a day has any work logged
  bool _dayHasLogs(DateTime day) {
    return widget.allLogs.any((log) =>
        log.date.year == day.year &&
        log.date.month == day.month &&
        log.date.day == day.day);
  }

  // Add work log
  Future<void> _addLog(WorkLog newLog) async {
    // Check if the log is an office work log and there is already one on that date
    if (newLog.title == 'OFİSTEN ÇALIŞMA') {
      final bool hasOfficeLog = widget.allLogs.any((log) =>
          log.title == 'OFİSTEN ÇALIŞMA' &&
          log.date.year == newLog.date.year &&
          log.date.month == newLog.date.month &&
          log.date.day == newLog.date.day);
      
      if (hasOfficeLog) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seçilen tarihte zaten bir "OFİSTEN ÇALIŞMA" kaydı bulunmaktadır!'),
              backgroundColor: AppColors.accent,
            ),
          );
        }
        return; // Block insertion
      }
    }

    final updated = await WorkStorage.addWorkLog(newLog);
    widget.onLogsChanged(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çalışma kaydı başarıyla eklendi!'),
          backgroundColor: AppColors.successText,
        ),
      );
    }
  }

  // Delete work log
  Future<void> _deleteLog(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu çalışma kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = await WorkStorage.deleteWorkLog(id);
      widget.onLogsChanged(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt silindi.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    }
  }

  // Quick-Log Office shortcut
  Future<void> _quickOfficeLog() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'OFİSTEN ÇALIŞMA TARİHİ SEÇİN',
      confirmText: 'EKLE',
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

    if (pickedDate != null) {
      // 8.5 hours = 510 minutes
      final quickLog = WorkLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'OFİSTEN ÇALIŞMA',
        date: pickedDate,
        durationMinutes: 510,
        category: 'Ofis',
        hourlyRate: widget.hourlyRate,
      );
      
      await _addLog(quickLog);
      setState(() {
        _selectedDate = pickedDate; // Focus on the day we added the log
      });
    }
  }



  // Open add log bottom sheet
  void _openAddWorkDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddWorkDialog(
          initialDate: _selectedDate,
          hourlyRate: widget.hourlyRate,
          onAdd: _addLog,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getCurrentWeekDays();
    final dayLogs = _selectedDayLogs;
    final DateFormat dayNameFormat = DateFormat('E', 'tr_TR');
    final DateFormat fullDateFormat = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR');

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 1. Weekly Earnings and Summary Card (Pastel Green)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(
                color: AppColors.successLight,
                hasBorder: false,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HAFTALIK KAZANÇ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₺${NumberFormat('#,##0.00', 'tr_TR').format(_weeklyEarnings)}',
                            style: const TextStyle(
                              color: AppColors.successText,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_weeklyHours.toStringAsFixed(1)} saat',
                          style: const TextStyle(
                            color: AppColors.successText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white, height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bu hafta uzaktan çalışılan toplam süre.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Hafta: ${DateFormat('dd.MM').format(weekDays.first)} - ${DateFormat('dd.MM').format(weekDays.last)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Action Cards Row
            Row(
              children: [
                // Card 1: Hızlı Ofis Kaydı (Soft Rose)
                Expanded(
                  child: InkWell(
                    onTap: _quickOfficeLog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      height: 104,
                      decoration: AppTheme.cardDecoration(
                        color: AppColors.accentLight,
                        hasBorder: false,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.accent,
                            radius: 18,
                            child: Icon(Icons.business, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Hızlı Ofis',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '8.5 Saat Ekle',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Card 2: Yeni İş Ekle (Soft Blue)
                Expanded(
                  child: InkWell(
                    onTap: _openAddWorkDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      height: 104,
                      decoration: AppTheme.cardDecoration(
                        color: AppColors.primaryLight,
                        hasBorder: false,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 18,
                            child: Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Yeni İş Ekle',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Detaylı Kayıt Gir',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Weekly Strip Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Haftalık Takvim',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 24),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Önceki Hafta',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDate),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppColors.primary, size: 24),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Sonraki Hafta',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Calendar strip container
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((day) {
                final isSelected = day.year == _selectedDate.year &&
                    day.month == _selectedDate.month &&
                    day.day == _selectedDate.day;
                final isToday = day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;
                final hasLogs = _dayHasLogs(day);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDate = day;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primaryLight
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : isToday
                                    ? AppColors.primary.withOpacity(0.5)
                                    : AppColors.border,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayNameFormat.format(day).substring(0, 3),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Log indicator dot
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasLogs
                                    ? (isSelected ? Colors.white : AppColors.successText)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 4. Tasks list for selected day
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Günlük Çalışma Kayıtları',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullDateFormat.format(_selectedDate),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sönük buton kaldırıldı, yerine yukarıdaki büyük kart buton eklendi!
              ],
            ),
            const SizedBox(height: 10),

            // List view of daily tasks
            if (dayLogs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_calendar,
                      size: 48,
                      color: AppColors.textLight.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bu güne ait iş kaydı bulunamadı.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yukarıdaki "Yeni İş Ekle" butonundan veya "Hızlı Ofis Kaydı" ile iş ekleyebilirsiniz.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayLogs.length,
                itemBuilder: (context, index) {
                  final log = dayLogs[index];
                  final double earnings = log.durationHours * log.hourlyRate;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      children: [
                        // Category Icon/Avatar
                        CircleAvatar(
                          backgroundColor: log.title == 'OFİSTEN ÇALIŞMA'
                              ? AppColors.accentLight
                              : AppColors.primaryLight,
                          radius: 20,
                          child: Icon(
                            log.title == 'OFİSTEN ÇALIŞMA'
                                ? Icons.business
                                : Icons.home_rounded,
                            color: log.title == 'OFİSTEN ÇALIŞMA'
                                ? AppColors.accent
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title & Duration details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    log.formattedDuration,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Earnings and Delete action
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${earnings.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: AppColors.successText,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _deleteLog(log.id),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
   );
  }
}
