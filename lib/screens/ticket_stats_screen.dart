import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/themed_action_button.dart';

class TicketStatsScreen extends StatelessWidget {
  final int ticketId;
  final int correctAnswers;
  final int totalQuestions;
  final List<String> weakQuestions;

  const TicketStatsScreen({
    super.key,
    required this.ticketId,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.weakQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final int wrongAnswers = (totalQuestions - correctAnswers).clamp(
      0,
      totalQuestions,
    );
    final double accuracy = totalQuestions == 0
        ? 0
        : correctAnswers / totalQuestions;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ticket Stats',
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
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
                      'Статистика по билету №$ticketId',
                      style: TextStyle(
                        fontFamily: 'ClashRoyale',
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors.track,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: accuracy.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF58A700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _statRow(
                      label: 'Точность',
                      value: '${(accuracy * 100).round()}%',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _statRow(
                      label: 'Верных ответов',
                      value: '$correctAnswers / $totalQuestions',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _statRow(
                      label: 'Ошибок',
                      value: '$wrongAnswers',
                      colors: colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
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
                        'Слабые места',
                        style: TextStyle(
                          fontFamily: 'ClashRoyale',
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: weakQuestions.isEmpty
                            ? Center(
                                child: Text(
                                  'Отличная работа!\nЯвных слабых мест не найдено.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'ClashRoyale',
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: weakQuestions.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: Text(
                                      '${index + 1}. ${weakQuestions[index]}',
                                      style: TextStyle(
                                        fontFamily: 'ClashRoyale',
                                        fontSize: 12,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ThemedActionButton.green(
                label: 'CONTINUE',
                onTap: () => Navigator.of(context).pop(true),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                width: double.infinity,
                height: 50,
                textStyle: const TextStyle(
                  fontFamily: 'ClashRoyale',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow({
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
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
