import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_plan_model.dart';

class PlannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _plannerRef(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('planner');

  static DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String _weekId(DateTime weekStart) =>
      '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

  Future<WeeklyPlanModel> getOrCreateWeek(
      String userId, DateTime date) async {
    final start = _weekStart(date);
    final docId = _weekId(start);
    final ref = _plannerRef(userId).doc(docId);
    final snap = await ref.get();

    if (snap.exists) {
      return WeeklyPlanModel.fromFirestore(
          snap.data() as Map<String, dynamic>, snap.id);
    }

    final newPlan = WeeklyPlanModel(
      id: docId,
      userId: userId,
      weekStartDate: start,
      days: {
        'monday': null,
        'tuesday': null,
        'wednesday': null,
        'thursday': null,
        'friday': null,
        'saturday': null,
        'sunday': null,
      },
    );
    await ref.set(newPlan.toFirestore());
    return newPlan;
  }

  Stream<WeeklyPlanModel> watchWeek(String userId, DateTime date) {
    final start = _weekStart(date);
    final docId = _weekId(start);
    return _plannerRef(userId).doc(docId).snapshots().map((snap) {
      if (!snap.exists) {
        return WeeklyPlanModel(
          id: docId,
          userId: userId,
          weekStartDate: start,
          days: {
            'monday': null,
            'tuesday': null,
            'wednesday': null,
            'thursday': null,
            'friday': null,
            'saturday': null,
            'sunday': null,
          },
        );
      }
      return WeeklyPlanModel.fromFirestore(
          snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  /// İki güne atanmış kombinleri atomik olarak takas/taşı (biri boş ise taşıma).
  Future<void> swapOrMoveBetweenDays({
    required String userId,
    required DateTime date,
    required String fromDayKey,
    required String toDayKey,
  }) async {
    if (fromDayKey == toDayKey) return;

    final start = _weekStart(date);
    final docId = _weekId(start);
    final ref = _plannerRef(userId).doc(docId);

    await _firestore.runTransaction((txn) async {
      var snap = await txn.get(ref);
      if (!snap.exists) {
        txn.set(ref, WeeklyPlanModel(
              id: docId,
              userId: userId,
              weekStartDate: start,
              days: const {
                'monday': null,
                'tuesday': null,
                'wednesday': null,
                'thursday': null,
                'friday': null,
                'saturday': null,
                'sunday': null,
              },
            ).toFirestore());
        snap = await txn.get(ref);
      }
      if (!snap.exists) return;

      final data = snap.data()! as Map<String, dynamic>;
      final daysSrc = Map<String, dynamic>.from(
        (data['days'] as Map<String, dynamic>? ?? {}),
      );

      final aOut = daysSrc[fromDayKey];
      final bOut = daysSrc[toDayKey];
      daysSrc[fromDayKey] = bOut;
      daysSrc[toDayKey] = aOut;

      txn.update(ref, {'days': daysSrc});
    });
  }

  Future<void> assignOutfit({
    required String userId,
    required DateTime date,
    required String dayKey,
    required String? outfitId,
  }) async {
    final start = _weekStart(date);
    final docId = _weekId(start);
    final ref = _plannerRef(userId).doc(docId);
    final snap = await ref.get();

    if (!snap.exists) {
      await getOrCreateWeek(userId, date);
    }

    await ref.update({'days.$dayKey': outfitId});
  }
}
