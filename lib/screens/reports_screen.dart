import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_model.dart';
import '../theme.dart';
import '../utils/excel_exporter.dart';

class ReportsScreen extends StatefulWidget {
  final List<WorkLog> allLogs;
  final double hourlyRate;

  const ReportsScreen({
    Key? key,
    required this.allLogs,
    required this.hourlyRate,
  }) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Default range: From 7 days ago to today
    final today = DateTime.now();
    _startDate = today.subtract(const Duration(days: 7));
    _endDate = today;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<WorkLog> get _filteredLogs {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    
    return widget.allLogs.where((log) {
      return log.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
             log.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // Sort newer first in UI list
  }

  double get _totalHours {
    return _filteredLogs.fold(0.0, (sum, log) => sum + log.durationHours);
  }

  double get _totalEarnings {
    return _filteredLogs.fold(0.0, (sum, log) => sum + (log.durationHours * log.hourlyRate));
  }

  Future<void> _exportExcel() async {
    if (_filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seçilen tarih aralığında hiçbir iş bulunmamaktadır.'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final String resultMessage = await ExcelExporter.exportToExcel(
        logs: widget.allLogs,
        startDate: _startDate,
        endDate: _endDate,
        hourlyRate: widget.hourlyRate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(resultMessage)),
              ],
            ),
            backgroundColor: AppColors.successText,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel dışa aktarılırken hata oluştu: $e'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd MMM yyyy', 'tr_TR');
    final logs = _filteredLogs;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Range Selection Card
          InkWell(
            onTap: () => _selectDateRange(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.date_range, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tarih Aralığı Seçin',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatter.format(_startDate)} - ${formatter.format(_endDate)}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.swap_horiz, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overview Statistics for the Range
          Row(
            children: [
              // Total Hours Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time_filled, color: AppColors.primary, size: 30),
                      const SizedBox(height: 8),
                      const Text(
                        'Toplam Süre',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_totalHours.toStringAsFixed(1)} sa',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Estimated Earnings Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: AppTheme.cardDecoration(
                    color: AppColors.successLight,
                    hasBorder: false,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.successText, size: 30),
                      const SizedBox(height: 8),
                      const Text(
                        'Toplam Kazanç',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₺${NumberFormat('#,##0.00', 'tr_TR').format(_totalEarnings)}',
                        style: const TextStyle(
                          color: AppColors.successText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Button to Export Excel
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportExcel,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.description),
            label: Text(_isExporting ? 'Aktarılıyor...' : 'Excel Dosyası Olarak Dışa Aktar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successText,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bu Aralıktaki İşler (${logs.length})',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filtered list
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: AppColors.textLight.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'Seçilen tarihlerde iş kaydı yok.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final double earnings = log.durationHours * log.hourlyRate;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                DateFormat('dd.MM').format(log.date),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.formattedDuration,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₺${earnings.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
