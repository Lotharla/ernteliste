import 'package:intl/intl.dart';
import 'package:server/utils.dart';
import 'package:week_of_year/week_of_year.dart';
import 'package:date_checker/date_checker.dart';

/// A placeholder class that represents an entity or model.
class KwModel {
  const KwModel(this.woy);
  final int woy;

  @override
  String toString() {
    return '${year()}-$woy';
  }
  String description() {
    final DateTime dateFromWeek = dateTimeFromWeekNumber(year(), woy);
    var dateFormat = DateFormat("dd.MM.yy");
    var firstDay = dateFormat.format(weekStart(date: dateFromWeek));
    var lastDay = dateFormat.format(weekEnd(date: dateFromWeek));
    var kwNumber = NumberFormat("00").format(woy);
    return '${kwString(kwNumber)}  $firstDay - $lastDay';
  }

  static DateTime refTime = refDay();
  static year() => refTime.year;
  static week() => refTime.weekOfYear;
  static kwItems() => <KwModel>[for (int i=week(); i>0; i--) KwModel(i)];
}
