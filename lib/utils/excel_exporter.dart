import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/work_model.dart';
import 'file_saver.dart';
import 'holiday_helper.dart';

class ConsolidatedRow {
  final DateTime date;
  final String title;
  final double durationHours;
  final double earnings;

  ConsolidatedRow({
    required this.date,
    required this.title,
    required this.durationHours,
    required this.earnings,
  });
}

class ExcelExporter {
  static Future<String> exportToExcel({
    required List<WorkLog> logs,
    required DateTime startDate,
    required DateTime endDate,
    required double hourlyRate,
    bool autoIncludeOfficeWork = true,
  }) async {
    // Check if the start date is a Friday
    final bool isStartFriday = startDate.weekday == DateTime.friday;
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    // 1. Filter existing logs in date range (inclusive)
    final List<WorkLog> filteredLogs = logs.where((log) {
      final logDateOnly = DateTime(log.date.year, log.date.month, log.date.day);
      
      final bool inRange = (logDateOnly.isAtSameMomentAs(startOnly) || logDateOnly.isAfter(startOnly)) &&
          (logDateOnly.isAtSameMomentAs(endOnly) || logDateOnly.isBefore(endOnly));
          
      if (!inRange) return false;

      // Rule: If start date is a Friday, exclude any "OFİSTEN ÇALIŞMA" log on the start date itself
      if (isStartFriday &&
          log.title == 'OFİSTEN ÇALIŞMA' &&
          logDateOnly.year == startOnly.year &&
          logDateOnly.month == startOnly.month &&
          logDateOnly.day == startOnly.day) {
        return false;
      }

      return true;
    }).toList();

    // 2. Automatically include 8.5 hours office work for official workdays in date range
    if (autoIncludeOfficeWork) {
      DateTime curDay = startOnly;
      while (!curDay.isAfter(endOnly)) {
        // If it's a Friday start date, don't auto-add office work on that start Friday
        final bool isStartDayFriday = isStartFriday &&
            curDay.year == startOnly.year &&
            curDay.month == startOnly.month &&
            curDay.day == startOnly.day;

        if (!isStartDayFriday && HolidayHelper.isOfficialWorkday(curDay)) {
          final bool alreadyHasOfficeLog = filteredLogs.any((log) =>
              log.title == 'OFİSTEN ÇALIŞMA' &&
              log.date.year == curDay.year &&
              log.date.month == curDay.month &&
              log.date.day == curDay.day);

          if (!alreadyHasOfficeLog) {
            final double rate = curDay.isBefore(DateTime(2026, 1, 16)) ? 600.0 : hourlyRate;
            filteredLogs.add(WorkLog(
              id: 'auto_office_${curDay.year}_${curDay.month}_${curDay.day}',
              title: 'OFİSTEN ÇALIŞMA',
              date: curDay,
              durationMinutes: 510, // 8.5 hours
              category: 'Ofis',
              hourlyRate: rate,
            ));
          }
        }
        curDay = curDay.add(const Duration(days: 1));
      }
    }

    // Group logs by date
    final Map<String, List<WorkLog>> logsByDate = {};
    for (final log in filteredLogs) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(log.date);
      logsByDate.putIfAbsent(dateKey, () => []).add(log);
    }

    final List<ConsolidatedRow> rows = [];

    for (final dateKey in logsByDate.keys) {
      final dateLogs = logsByDate[dateKey]!;
      final DateTime logDate = dateLogs.first.date;

      // Filter EVDEN ÇALIŞMA logs and other logs
      final homeLogs = dateLogs.where((log) => log.title.startsWith('EVDEN ÇALIŞMA')).toList();
      final otherLogs = dateLogs.where((log) => !log.title.startsWith('EVDEN ÇALIŞMA')).toList();

      // Process EVDEN ÇALIŞMA logs
      if (homeLogs.isNotEmpty) {
        final List<String> descriptions = [];
        double sumHours = 0.0;
        double sumEarnings = 0.0;

        for (final log in homeLogs) {
          sumHours += log.durationHours;
          sumEarnings += log.durationHours * log.hourlyRate;

          // Extract what is inside the double quotes or parentheses
          String desc = log.title;
          final int startQuote = desc.indexOf('"');
          final int endQuote = desc.lastIndexOf('"');
          if (startQuote != -1 && endQuote != -1 && endQuote > startQuote) {
            descriptions.add(desc.substring(startQuote + 1, endQuote).trim());
          } else {
            final int startParen = desc.indexOf('(');
            final int endParen = desc.lastIndexOf(')');
            if (startParen != -1 && endParen != -1 && endParen > startParen) {
              descriptions.add(desc.substring(startParen + 1, endParen).trim().replaceAll('"', ''));
            } else {
              descriptions.add(desc.replaceAll('EVDEN ÇALIŞMA', '').trim().replaceAll('"', ''));
            }
          }
        }

        // Format exactly as: EVDEN ÇALIŞMA ( aciklama1, aciklama2 )
        final String consolidatedTitle = 'EVDEN ÇALIŞMA ( ${descriptions.join(', ')} )';
        
        rows.add(ConsolidatedRow(
          date: logDate,
          title: consolidatedTitle,
          durationHours: sumHours,
          earnings: sumEarnings,
        ));
      }

      // Process other logs (like OFİSTEN ÇALIŞMA) - keep them separate
      for (final log in otherLogs) {
        rows.add(ConsolidatedRow(
          date: log.date,
          title: log.title,
          durationHours: log.durationHours,
          earnings: log.durationHours * log.hourlyRate,
        ));
      }
    }

    // Sort rows by date ascending
    rows.sort((a, b) => a.date.compareTo(b.date));

    // 2. Initialize Excel Workbook
    final excel = Excel.createExcel();
    const String sheetName = 'Çalışma Raporu';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Styles Configuration
    final CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#7C92FF'), // Soft Lavender Blue
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle regularStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle numberStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle earningsStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: CustomNumericNumFormat(formatCode: r'#,##0.00 "₺"'),
    );

    // Green Background Total Row Styles
    final CellStyle totalStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#B5EAD7'), // Soft Mint Green
      fontColorHex: ExcelColor.fromHexString('#2E8B57'),       // Dark Mint Green Text
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      verticalAlign: VerticalAlign.Center,
    );
    
    final CellStyle totalNumberStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#B5EAD7'),
      fontColorHex: ExcelColor.fromHexString('#2E8B57'),
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle totalEarningsStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#B5EAD7'),
      fontColorHex: ExcelColor.fromHexString('#2E8B57'),
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: CustomNumericNumFormat(formatCode: r'#,##0.00 "₺"'),
    );

    // Headers
    final List<String> headers = ['Tarih', 'İş Açıklama', 'Saat (Süre)', 'Kazanç'];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    double totalHours = 0.0;
    double totalEarnings = 0.0;
    final DateFormat formatter = DateFormat('dd.MM.yyyy');

    int rowIdx = 1;
    for (final row in rows) {
      totalHours += row.durationHours;
      totalEarnings += row.earnings;

      // Col 0: Date
      final cellDate = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
      cellDate.value = TextCellValue(formatter.format(row.date));
      cellDate.cellStyle = regularStyle;

      // Col 1: Description
      final cellDesc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
      cellDesc.value = TextCellValue(row.title);
      cellDesc.cellStyle = regularStyle;

      // Col 2: Hours
      final cellHours = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx));
      cellHours.value = DoubleCellValue(row.durationHours);
      cellHours.cellStyle = numberStyle;

      // Col 3: Earnings
      final cellEarnings = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx));
      cellEarnings.value = DoubleCellValue(row.earnings);
      cellEarnings.cellStyle = earningsStyle;

      rowIdx++;
    }

    // Add Totals Row
    // Column 0: "Toplam"
    final cellTotalLabel1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
    cellTotalLabel1.value = TextCellValue('Toplam');
    cellTotalLabel1.cellStyle = totalStyle;

    // Column 1: spacer
    final cellTotalLabel2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
    cellTotalLabel2.value = TextCellValue('');
    cellTotalLabel2.cellStyle = totalStyle;

    // Column 2: Hours Sum
    final cellTotalHours = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx));
    cellTotalHours.value = DoubleCellValue(totalHours);
    cellTotalHours.cellStyle = totalNumberStyle;

    // Column 3: Earnings Sum
    final cellTotalEarnings = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx));
    cellTotalEarnings.value = DoubleCellValue(totalEarnings);
    cellTotalEarnings.cellStyle = totalEarningsStyle;

    // Set Column Widths
    sheet.setColumnWidth(0, 16.0);
    sheet.setColumnWidth(1, 55.0);
    sheet.setColumnWidth(2, 16.0);
    sheet.setColumnWidth(3, 18.0);

    // Save Workbook
    final List<int>? fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Excel dosyası kodlanamadı.');
    }

    final String startDateStr = formatter.format(startDate).replaceAll('.', '-');
    final String endDateStr = formatter.format(endDate).replaceAll('.', '-');
    final String fileName = 'rapor_${startDateStr}_to_${endDateStr}.xlsx';

    return await saveExcelFile(fileBytes, fileName);
  }
}
