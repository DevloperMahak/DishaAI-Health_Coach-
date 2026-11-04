import 'package:get_storage/get_storage.dart';

class StepStorage {
  StepStorage._();
  static final StepStorage instance = StepStorage._();
  final GetStorage _storage = GetStorage();

  // Getters
  String get savedDate => _storage.read<String>('step_date') ?? '';
  int get baselineSteps => _storage.read<int>('baseline_steps') ?? 0;
  int get previousTotal => _storage.read<int>('previous_total') ?? 0;
  int get todaySteps => _storage.read<int>('today_steps') ?? 0;

  // Setters
  Future<void> saveDate(String date) async =>
      await _storage.write('step_date', date);
  Future<void> saveBaseline(int steps) async =>
      await _storage.write('baseline_steps', steps);
  Future<void> savePreviousTotal(int steps) async =>
      await _storage.write('previous_total', steps);
  Future<void> saveTodaySteps(int steps) async =>
      await _storage.write('today_steps', steps);
}
