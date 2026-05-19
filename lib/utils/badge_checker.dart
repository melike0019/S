import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/clothing_provider.dart';
import '../providers/history_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

/// Rozet kontrolü yap ve yeni kazanılanları snackbar ile göster.
/// Kıyafet ekleme, kombin kaydetme, profil güncelleme sonrasında çağrılır.
Future<void> checkBadgesAndNotify(BuildContext context) async {
  if (!context.mounted) return;

  final auth    = context.read<AuthProvider>();
  final userId  = auth.user?.id;
  if (userId == null) return;

  final userProv   = context.read<UserProvider>();
  final clothing   = context.read<ClothingProvider>();
  final outfits    = context.read<OutfitProvider>();
  final history    = context.read<HistoryProvider>();
  final planner    = context.read<PlannerProvider>();

  // UserProvider henüz yüklenmediyse önce yükle
  if (userProv.user == null) {
    await userProv.loadUser(userId);
    if (userProv.user == null) return;
  }

  final aiCount   = outfits.outfits.where((o) => o.source == 'ai').length;
  final newBadges = await userProv.checkAndAwardBadges(
    userId:        userId,
    clothingCount: clothing.items.length,
    outfitCount:   outfits.outfits.length,
    aiOutfitCount: aiCount,
    historyCount:  history.entries.length,
    plannedDays:   planner.filledDaysCount,
  );

  if (newBadges.isNotEmpty && context.mounted) {
    final messenger = ScaffoldMessenger.of(context);
    for (final badge in newBadges) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yeni rozet kazandın: $badge',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryRose,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      // Birden fazla rozet varsa aralarında kısa bekleme
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }
}
