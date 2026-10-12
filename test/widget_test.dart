import 'package:flutter_test/flutter_test.dart';
import 'package:remote_work_tracker/models/work_model.dart';
import 'package:remote_work_tracker/utils/holiday_helper.dart';

void main() {
  group('WorkLog Model Tests', () {
    test('Çalışma saati hesaplaması doğru olmalı', () {
      // 8.5 hours = 510 minutes
      final log1 = WorkLog(
        id: '1',
        title: 'OFİSTEN ÇALIŞMA',
        date: DateTime(2026, 7, 17),
        durationMinutes: 510,
        category: 'Ofis',
        hourlyRate: 150.0,
      );

      expect(log1.durationHours, 8.5);
      expect(log1.formattedDuration, '8 sa 30 dk');

      // 2 hours = 120 minutes
      final log2 = WorkLog(
        id: '2',
        title: 'Toplantı',
        date: DateTime(2026, 7, 17),
        durationMinutes: 120,
        category: 'Toplantı',
        hourlyRate: 150.0,
      );

      expect(log2.durationHours, 2.0);
      expect(log2.formattedDuration, '2 sa');

      // 45 minutes
      final log3 = WorkLog(
        id: '3',
        title: 'Hata düzeltme',
        date: DateTime(2026, 7, 17),
        durationMinutes: 45,
        category: 'Yazılım',
        hourlyRate: 200.0,
      );

      expect(log3.durationHours, 0.75);
      expect(log3.formattedDuration, '45 dk');
    });

    test('JSON serileştirme ve geri yükleme düzgün çalışmalı', () {
      final originalLog = WorkLog(
        id: 'test-123',
        title: 'Kodlama Yapıldı',
        date: DateTime(2026, 7, 17, 10, 30),
        durationMinutes: 180,
        category: 'Yazılım',
        hourlyRate: 200.0,
      );

      final json = originalLog.toJson();
      final restoredLog = WorkLog.fromJson(json);

      expect(restoredLog.id, originalLog.id);
      expect(restoredLog.title, originalLog.title);
      expect(restoredLog.date, originalLog.date);
      expect(restoredLog.durationMinutes, originalLog.durationMinutes);
      expect(restoredLog.category, originalLog.category);
      expect(restoredLog.hourlyRate, originalLog.hourlyRate);
      expect(restoredLog.durationHours, 3.0);
    });

    test('Kazanç hesaplaması doğru olmalı', () {
      final log = WorkLog(
        id: 'test-456',
        title: 'Hızlı Giriş Ofis',
        date: DateTime(2026, 7, 17),
        durationMinutes: 510, // 8.5 saat
        category: 'Ofis',
        hourlyRate: 150.0,
      );

      final earnings = log.durationHours * log.hourlyRate;

      expect(earnings, 1275.0); // 8.5 * 150 = 1275
    });
  });

  group('HolidayHelper Tests', () {
    test('Sabit ve dini bayramlar tatil olarak tespit edilmeli', () {
      // 1 Ocak Yılbaşı
      expect(HolidayHelper.isOfficialHoliday(DateTime(2026, 1, 1)), isTrue);
      expect(HolidayHelper.isOfficialWorkday(DateTime(2026, 1, 1)), isFalse);

      // 19 Mayıs Gençlik ve Spor Bayramı
      expect(HolidayHelper.isOfficialHoliday(DateTime(2026, 5, 19)), isTrue);
      expect(HolidayHelper.isOfficialWorkday(DateTime(2026, 5, 19)), isFalse);

      // 23 Nisan Çocuk Bayramı
      expect(HolidayHelper.isOfficialHoliday(DateTime(2026, 4, 23)), isTrue);
      expect(HolidayHelper.isOfficialWorkday(DateTime(2026, 4, 23)), isFalse);
    });

    test('Normal hafta içi günler resmi iş günü olarak tespit edilmeli', () {
      // 17 Temmuz 2026 Cuma (Tatil olmayan normal hafta içi iş günü)
      final friday = DateTime(2026, 7, 17);
      expect(HolidayHelper.isOfficialHoliday(friday), isFalse);
      expect(HolidayHelper.isOfficialWorkday(friday), isTrue);
    });

    test('Hafta sonları iş günü olmamalı', () {
      // 18 Temmuz 2026 Cumartesi
      final saturday = DateTime(2026, 7, 18);
      expect(HolidayHelper.isOfficialWorkday(saturday), isFalse);

      // 19 Temmuz 2026 Pazar
      final sunday = DateTime(2026, 7, 19);
      expect(HolidayHelper.isOfficialWorkday(sunday), isFalse);
    });
  });
}
