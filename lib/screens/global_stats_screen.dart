import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_service.dart';
import '../data/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/themed_action_button.dart';

class GlobalStatsScreen extends StatefulWidget {
  const GlobalStatsScreen({super.key});

  @override
  State<GlobalStatsScreen> createState() => _GlobalStatsScreenState();
}

class _GlobalStatsScreenState extends State<GlobalStatsScreen> {
  late Future<GlobalTicketStats> _statsFuture;
  final AccountService _accountService = AccountService();

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<GlobalTicketStats> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AuthRequiredException();
    }
    return _accountService.fetchGlobalTicketStats(currentUserId: user.uid);
  }

  bool _isSignedIn(User? user) {
    return user != null &&
        !user.isAnonymous &&
        (user.email == null || user.emailVerified);
  }

  int _myCompletedTickets(GameState gameState) {
    return gameState.ticketsProgress.values
        .where((t) => t.subject == Subject.chemistry && t.isCompleted)
        .length;
  }

  int _myPerfectTickets(GameState gameState) {
    return gameState.ticketsProgress.values
        .where((t) => t.subject == Subject.chemistry && t.isCompleted)
        .where((t) => t.answeredQuestions.values.every((v) => v))
        .length;
  }

  String _percentileLabel(GlobalTicketStats stats, int myCompleted) {
    if (stats.completedTicketsPerUser.isEmpty) {
      return 'Недостаточно данных';
    }

    int notAhead = 0;
    for (final value in stats.completedTicketsPerUser) {
      if (value <= myCompleted) notAhead++;
    }

    final percentile = ((notAhead / stats.completedTicketsPerUser.length) * 100)
        .round();
    return '$percentile-й перцентиль';
  }

  void _reload() {
    setState(() {
      _statsFuture = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gameState = context.watch<GameState>();
    final myCompleted = _myCompletedTickets(gameState);
    final myPerfect = _myPerfectTickets(gameState);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final locked = !_isSignedIn(snapshot.data);

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Global Stats',
                        style: TextStyle(
                          fontFamily: 'ClashRoyale',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: locked
                            ? const SizedBox.shrink()
                            : FutureBuilder<GlobalTicketStats>(
                                future: _statsFuture,
                                builder: (context, asyncSnapshot) {
                                  if (asyncSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: colors.accent,
                                      ),
                                    );
                                  }

                                  if (asyncSnapshot.hasError) {
                                    return _buildErrorState(colors);
                                  }

                                  final stats = asyncSnapshot.data;
                                  if (stats == null) {
                                    return _buildErrorState(colors);
                                  }

                                  return RefreshIndicator(
                                    onRefresh: () async => _reload(),
                                    child: ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        _statsSummaryCard(colors, stats),
                                        const SizedBox(height: 12),
                                        _ticketPopularityCard(colors, stats),
                                        const SizedBox(height: 12),
                                        _myStatusCard(
                                          colors,
                                          stats,
                                          myCompleted,
                                          myPerfect,
                                        ),
                                        const SizedBox(height: 12),
                                        _socialCard(colors),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (locked) Container(color: Colors.black54),
                if (locked) _buildLockedOverlay(colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Не удалось загрузить глобальную статистику',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 14,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _reload, child: const Text('Повторить')),
        ],
      ),
    );
  }

  Widget _statsSummaryCard(AppColors colors, GlobalTicketStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.track, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity Bars',
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _rowMetric(
            colors,
            'Аккаунтов в выборке',
            stats.usersCount.toString(),
          ),
          const SizedBox(height: 6),
          _rowMetric(
            colors,
            'Завершено билетов',
            stats.totalCompletedTickets.toString(),
          ),
          const SizedBox(height: 6),
          _rowMetric(
            colors,
            'Идеально завершено',
            stats.totalPerfectTickets.toString(),
          ),
          const SizedBox(height: 6),
          _rowMetric(
            colors,
            'Среднее на аккаунт',
            stats.averageCompletedTickets.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

  Widget _ticketPopularityCard(AppColors colors, GlobalTicketStats stats) {
    final entries = stats.completedByTicket.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final maxValue = top.isEmpty ? 1 : top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.track, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Популярность билетов',
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (top.isEmpty)
            Text(
              'Пока недостаточно данных по другим аккаунтам.',
              style: TextStyle(
                fontFamily: 'ClashRoyale',
                fontSize: 12,
                color: colors.textSecondary,
              ),
            )
          else
            ...top.map((entry) {
              final ratio = (entry.value / maxValue).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Билет ${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontFamily: 'ClashRoyale',
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(6),
                      backgroundColor: colors.track,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _myStatusCard(
    AppColors colors,
    GlobalTicketStats stats,
    int myCompleted,
    int myPerfect,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.track, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Interactive Status',
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _rowMetric(colors, 'Мои завершенные билеты', '$myCompleted'),
          const SizedBox(height: 6),
          _rowMetric(colors, 'Мои идеальные билеты', '$myPerfect'),
          const SizedBox(height: 6),
          _rowMetric(
            colors,
            'Позиция относительно других',
            _percentileLabel(stats, myCompleted),
          ),
        ],
      ),
    );
  }

  Widget _socialCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.track, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedActionButton.green(
            label: 'Add friends button',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Социальные связи будут добавлены позже'),
                ),
              );
            },
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            width: double.infinity,
            height: 44,
            textStyle: const TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'friend list, if connection provided',
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedOverlay(AppColors colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF131F24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.track, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: colors.accent),
            const SizedBox(height: 12),
            Text(
              'Нужно авторизоваться',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ClashRoyale',
                fontSize: 20,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Войдите в аккаунт и подтвердите почту, чтобы открыть глобальную статистику.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ClashRoyale',
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowMetric(AppColors colors, String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: 12,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
