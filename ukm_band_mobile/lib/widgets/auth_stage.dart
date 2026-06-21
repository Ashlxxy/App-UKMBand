import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'song_artwork.dart';

class AuthStage extends StatelessWidget {
  final String appBarTitle;
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final String? infoText;
  final Widget child;

  const AuthStage({
    super.key,
    required this.appBarTitle,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    this.infoText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF30080E), AppColors.ink, Color(0xFF06131A)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppGlassCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.16),
                          AppColors.card.withValues(alpha: 0.72),
                          AppColors.ink.withValues(alpha: 0.76),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (badge != null && badge!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Text(
                                    badge!,
                                    style: const TextStyle(
                                      color: AppColors.accentHot,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppColors.cream,
                                      fontWeight: FontWeight.w900,
                                      height: 1.04,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        _AuthRecord(icon: icon),
                      ],
                    ),
                  ),
                ),
                if (infoText != null && infoText!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppGlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.offline_pin_rounded,
                            color: AppColors.accentHot,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            infoText!,
                            style: const TextStyle(
                              color: AppColors.cream,
                              fontWeight: FontWeight.w700,
                              height: 1.32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppGlassCard(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthRecord extends StatelessWidget {
  final IconData icon;

  const _AuthRecord({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardSoft,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          Positioned(
            right: 0,
            top: 14,
            child: Container(
              width: 34,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
