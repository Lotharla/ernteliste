import 'package:calendar_date_picker2/calendar_date_picker2.dart' hide YearPicker;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:server/utils.dart';
import 'package:week_of_year/week_of_year.dart';
import 'package:date_checker/date_checker.dart';

/// A placeholder class that represents an entity or model.
class KwModel {
  final int woy;
  final int year;
  const KwModel(this.woy, this.year);
  @override
  String toString() {
    return '$year-${woyString(woy)}';
  }
  String description() {
    final DateTime dateFromWeek = dateTimeFromWeekNumber(year, woy);
    var dateFormat = DateFormat("dd.MM.yy");
    var firstDay = dateFormat.format(weekStart(date: dateFromWeek));
    var lastDay = dateFormat.format(weekEnd(date: dateFromWeek));
    return '${kwString(woyString(woy))}  $firstDay - $lastDay';
  }

  static ValueNotifier<DateTime> refTime = ValueNotifier<DateTime>(refDay());
  static refYear() => refTime.value.year;
  static refWeek([int? year]) => refDay(year).weekOfYear;
  static kwItems() => <KwModel>[for (int w=refWeek(refYear()); w>0; w--) KwModel(w, refYear())];
}
yearPicker(BuildContext context) {
  final now = DateTime.now();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Bestimme Jahr"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(now.year - 10, 1),
            lastDate: DateTime(now.year + 10, 1),
            selectedDate: KwModel.refTime.value,
            onChanged: (DateTime dateTime) async {
              KwModel.refTime.value = dateTime;
              Navigator.pop(context);
            },
          ),
        ),
      );
    },
  );
}
Future<List<DateTime?>?> kwPicker(BuildContext context) {
  return showCalendarDatePicker2Dialog(
    context: context,
    config: CalendarDatePicker2WithActionButtonsConfig(
      weekNumbers: true,
      weekNumberLabel: 'Kw',
      weekNumberTextStyle: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogSize: const Size(400, 400),
    borderRadius: BorderRadius.circular(15),
    dialogBackgroundColor: Colors.white,
    // value: [KwModel.refTime],
  );
}
