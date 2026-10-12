import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_model.dart';
import '../theme.dart';
import '../storage.dart';

class ProfileScreen extends StatefulWidget {
  final double hourlyRate;
  final Function(double) onHourlyRateChanged;

  const ProfileScreen({
    Key? key,
    required this.hourlyRate,
    required this.onHourlyRateChanged,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rateController.text = widget.hourlyRate.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _rateController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _updateRate() async {
    final double? rate = double.tryParse(_rateController.text);
    if (rate != null && rate > 0) {
      await WorkStorage.setHourlyRate(rate);
      widget.onHourlyRateChanged(rate);
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saatlik ücret başarıyla ₺$rate olarak güncellendi.'),
            backgroundColor: AppColors.successText,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir saatlik ücret girin.'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  Future<void> _importData() async {
    final String rawText = _importController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen not defterinden kopyaladığınız verileri yapıştırın.'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    final List<String> lines = rawText.split('\n');
    final List<WorkLog> parsedLogs = [];
    
    DateTime? currentLogDate;
    double currentLogHours = 0.0;
    final List<String> currentDescriptions = [];

    // Helper regex to match a date
    final RegExp dateRegExp = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})');
    // Helper regex to match hours (e.g. 5 saat, 6 saat , 3.5 saat)
    final RegExp hourRegExp = RegExp(r'(\d+(?:\.\d+)?)\s*saat');

    void saveCurrentLog() {
      if (currentLogDate != null && currentLogHours > 0) {
        // Correct the year typo (31.12.2026 should be 31.12.2025)
        DateTime logDate = currentLogDate!;
        if (logDate.day == 31 && logDate.month == 12 && logDate.year == 2026) {
          logDate = DateTime(2025, 12, 31);
        }

        // Determine rate
        // Prior to 16.01.2026, the rate is 600.0, else 825.0
        final double rate = logDate.isBefore(DateTime(2026, 1, 16)) ? 600.0 : 825.0;
        
        // Format description
        String title = '';
        if (currentDescriptions.isNotEmpty) {
          title = 'EVDEN ÇALIŞMA ("${currentDescriptions.join(', ')}")';
        } else {
          title = 'EVDEN ÇALIŞMA ("Genel İşler")';
        }

        parsedLogs.add(WorkLog(
          id: 'imported_${logDate.millisecondsSinceEpoch}_${parsedLogs.length}',
          title: title,
          date: logDate,
          durationMinutes: (currentLogHours * 60).round(),
          category: 'Ev',
          hourlyRate: rate,
        ));
      }
      currentLogDate = null;
      currentLogHours = 0.0;
      currentDescriptions.clear();
    }

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if line contains a date and "saat"
      if (dateRegExp.hasMatch(line) && hourRegExp.hasMatch(line)) {
        // Save previous log if any
        saveCurrentLog();

        // Extract date
        final dateMatches = dateRegExp.allMatches(line).toList();
        if (dateMatches.isNotEmpty) {
          final firstMatch = dateMatches.first;
          final int day = int.parse(firstMatch.group(1)!);
          final int month = int.parse(firstMatch.group(2)!);
          final int year = int.parse(firstMatch.group(3)!);
          currentLogDate = DateTime(year, month, day);
        }

        // Extract hours
        final hourMatch = hourRegExp.firstMatch(line);
        if (hourMatch != null) {
          currentLogHours = double.parse(hourMatch.group(1)!);
        }
      } else if (currentLogDate != null) {
        // Bullet point lines or descriptions
        // Strip bullet symbols
        if (line.startsWith('⁃') || line.startsWith('-') || line.startsWith('*') || line.startsWith('•')) {
          String cleaned = line.substring(1).trim();
          if (cleaned.isNotEmpty) {
            currentDescriptions.add(cleaned);
          }
        } else if (!line.contains('————') && !line.contains('alındı') && !line.contains('ofis') && !line.contains('alınacak')) {
          // If it's a regular text line under a date, treat it as a description
          currentDescriptions.add(line);
        }
      }
    }
    // Save last log
    saveCurrentLog();

    if (parsedLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not defterinden geçerli bir iş kaydı tespit edilemedi. Lütfen yazım biçimini kontrol edin.'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    // Confirm dialog
    if (!mounted) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${parsedLogs.length} Kayıt Tespit Edildi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yapıştırılan metinden toplam ${parsedLogs.length} adet evden çalışma günü başarıyla çözümlendi.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• 16.01.2026 öncesi kayıtlar: ₺600 / saat\n• 16.01.2026 sonrası kayıtlar: ₺825 / saat\nüzerinden otomatik hesaplanacaktır.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bu kayıtlar mevcut verilerinizle birleştirilecektir. Aynı tarihli eski evden çalışma kayıtları varsa onların üzerine yazılacaktır.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('İçe Aktar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Save parsed logs into WorkStorage
      // Load current logs
      final currentLogs = await WorkStorage.getWorkLogs();
      
      // Filter out existing EVDEN ÇALIŞMA logs that share the exact date with our parsed logs
      final Set<String> parsedDates = parsedLogs.map((log) => DateFormat('yyyy-MM-dd').format(log.date)).toSet();
      
      final updatedLogs = currentLogs.where((log) {
        final String logDateStr = DateFormat('yyyy-MM-dd').format(log.date);
        // Remove if it's an EVDEN ÇALIŞMA log on one of our parsed dates to avoid duplicates
        if (log.title.startsWith('EVDEN ÇALIŞMA') && parsedDates.contains(logDateStr)) {
          return false;
        }
        return true;
      }).toList();

      // Append new parsed logs
      updatedLogs.addAll(parsedLogs);
      
      // Save back
      await WorkStorage.saveWorkLogs(updatedLogs);
      
      // Notify parent widget to refresh state
      widget.onHourlyRateChanged(widget.hourlyRate);
      
      if (mounted) {
        _importController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${parsedLogs.length} adet evden çalışma kaydı başarıyla sisteme aktarıldı!'),
            backgroundColor: AppColors.successText,
          ),
        );
      }
    }
  }

  Future<void> _autoPopulateWorkdays() async {
    final currentLogs = await WorkStorage.getWorkLogs();
    DateTime startDate = DateTime(2025, 12, 1);
    if (currentLogs.isNotEmpty) {
      final earliest = currentLogs.map((l) => l.date).reduce((a, b) => a.isBefore(b) ? a : b);
      if (earliest.isBefore(startDate)) {
        startDate = earliest;
      }
    }
    final endDate = DateTime.now();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resmi İş Günlerini Otomatik Doldur'),
          content: Text(
            '${DateFormat('dd.MM.yyyy').format(startDate)} ile ${DateFormat('dd.MM.yyyy').format(endDate)} arasındaki tüm resmi iş günlerine (hafta içi günler, resmi tatiller hariç) otomatik olarak 8.5 saatlik "OFİSTEN ÇALIŞMA" kaydı eklensin mi?\n\n• Zaten ofis kaydı olan günlere mükerrer kayıt eklenmez.\n• 16.01.2026 öncesi için ₺600, sonrası için ₺${widget.hourlyRate.toStringAsFixed(0)} uygulanır.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Evet, Ekle'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final addedCount = await WorkStorage.autoPopulateOfficialWorkdays(
        startDate: startDate,
        endDate: endDate,
        currentHourlyRate: widget.hourlyRate,
      );

      // Trigger update
      widget.onHourlyRateChanged(widget.hourlyRate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              addedCount > 0
                  ? '$addedCount adet resmi iş gününe 8.5 saat ofis çalışması başarıyla eklendi!'
                  : 'Tüm resmi iş günlerinde zaten ofis kaydı mevcut, yeni kayıt gerekmedi.',
            ),
            backgroundColor: AppColors.successText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecoration(
                color: AppColors.primaryLight,
                hasBorder: false,
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uzaktan Çalışan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Freelance & Remote Developer',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hourly Rate Settings Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.settings, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Çalışma Ayarları',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Saatlik Ücret Girişi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Örn: 200',
                            prefixText: '₺ ',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ButtonTheme(
                        minWidth: 100,
                        child: ElevatedButton(
                          onPressed: _updateRate,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Güncelle'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bulk Import Notepad Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.drive_file_rename_outline, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Not Defterinden Toplu İçe Aktar',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Not defterinizdeki tarihli çalışma kayıtlarını olduğu gibi yapıştırıp tek tıkla sisteme aktarabilirsiniz.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _importController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Örnek format:\n27.12.2025 5 saat\n\t⁃ İş açıklaması 1\n\t⁃ İş açıklaması 2\n...',
                      hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 13),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Verileri Çözümle ve İçe Aktar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Auto-populate Official Workdays Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Resmi İş Günlerine Ofis Kaydı Ekle',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pazartesi-Cuma arasındaki resmi iş günlerine (resmi tatiller hariç) otomatik 8.5 saatlik "OFİSTEN ÇALIŞMA" kayıtlarını topluca ekler.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _autoPopulateWorkdays,
                      icon: const Icon(Icons.auto_mode, size: 18),
                      label: const Text('Tüm Resmi İş Günlerine 8.5 Sa Ofis Kaydı Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Informational Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration(
                color: AppColors.successLight,
                hasBorder: false,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.successText),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Belirlediğiniz saatlik ücret, ana ekrandaki haftalık kazançlarınızda ve Excel raporlarınızdaki ücret hesaplamalarında otomatik olarak kullanılacaktır.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.9),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
