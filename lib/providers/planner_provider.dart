import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weekly_plan_model.dart';
import '../services/planner_service.dart';

enum PlannerStatus { initial, loading, loaded, error }

class PlannerProvider extends ChangeNotifier {
  final PlannerService _service = PlannerService();
  StreamSubscription? _sub;

  PlannerStatus _status = PlannerStatus.initial;
  WeeklyPlanModel? _currentWeek;
  DateTime _focusDate = DateTime.now();
  String? _errorMessage;

  PlannerStatus get status => _status;
  WeeklyPlanModel? get currentWeek => _currentWeek;
  DateTime get focusDate => _focusDate;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PlannerStatus.loading;

  int get filledDaysCount =>
      _currentWeek?.days.values.where((v) => v != null && v.isNotEmpty).length ?? 0;

  void watchWeek(String userId, DateTime date) {
    _focusDate = date;
    _status = PlannerStatus.loading;
    notifyListeners();

    _sub?.cancel();
    _sub = _service.watchWeek(userId, date).listen(
      (plan) {
        _currentWeek = plan;
        _status = PlannerStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _status = PlannerStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> assignOutfit({
    required String userId,
    required String dayKey,
    required String? outfitId,
  }) async {
    try {
      await _service.assignOutfit(
        userId: userId,
        date: _focusDate,
        dayKey: dayKey,
        outfitId: outfitId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Pazartesi vb. günlere atanmış kombinleri sürükle-bırak ile takas veya taşı.
  Future<void> swapDaysOutfits({
    required String userId,
    required String fromDayKey,
    required String toDayKey,
  }) async {
    try {
      await _service.swapOrMoveBetweenDays(
        userId: userId,
        date: _focusDate,
        fromDayKey: fromDayKey,
        toDayKey: toDayKey,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void changeWeek(String userId, int offsetWeeks) {
    final newDate = _focusDate.add(Duration(days: offsetWeeks * 7));
    watchWeek(userId, newDate);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
