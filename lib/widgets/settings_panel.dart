import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../data/account_service.dart';
import '../data/game_state.dart';
import '../audio/audio_manager.dart';
import '../widgets/themed_action_button.dart';
import '../widgets/themed_blue_button.dart';

class SettingsPanel {
  static void open(BuildContext context) {
    final state = context.read<GameState>();
    bool localSound = state.soundEnabled;
    bool localMusic = state.musicEnabled;
    bool localVibration = state.vibrationEnabled;
    double localVolume = state.musicVolume;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(right: 16),
          alignment: Alignment.topRight,
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Container(
                width: 300,
                margin: const EdgeInsets.only(top: 80),
                decoration: BoxDecoration(
                  color: const Color(0xFF131F24),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF49C0F7).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок "Настройки"
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Color(0xFF131F24),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "НАСТРОЙКИ",
                            style: TextStyle(
                              fontFamily: 'ClashRoyale',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF131F24),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Прокручиваемое содержимое
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Раздел Аудио
                              _sectionHeader(text: "АУДИО"),
                              const SizedBox(height: 12),

                              // Звук
                              _customSwitchRow(
                                label: 'ЗВУКИ',
                                value: localSound,
                                onChanged: (v) async {
                                  HapticFeedback.lightImpact();
                                  setLocalState(() => localSound = v);
                                  state.setSoundEnabled = v;
                                },
                                icon: Icons.volume_up,
                              ),

                              const SizedBox(height: 16),

                              // Музыка
                              _customSwitchRow(
                                label: 'ФОНОВАЯ МУЗЫКА',
                                value: localMusic,
                                onChanged: (v) async {
                                  HapticFeedback.lightImpact();
                                  setLocalState(() => localMusic = v);
                                  state.setMusicEnabled = v;
                                },
                                icon: Icons.music_note,
                              ),

                              // Регулятор громкости музыки
                              if (localMusic) ...[
                                const SizedBox(height: 16),
                                _volumeSlider(
                                  value: localVolume,
                                  onChanged: (v) {
                                    setLocalState(() => localVolume = v);
                                    state.setMusicVolume = v;
                                  },
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Раздел Обратная связь
                              _sectionHeader(text: "ОБРАТНАЯ СВЯЗЬ"),
                              const SizedBox(height: 12),

                              // Вибрация
                              _customSwitchRow(
                                label: 'ВИБРАЦИЯ',
                                value: localVibration,
                                onChanged: (v) {
                                  HapticFeedback.lightImpact();
                                  setLocalState(() => localVibration = v);
                                  state.setVibrationEnabled = v;
                                },
                                icon: Icons.vibration,
                              ),

                              const SizedBox(height: 24),

                              // Раздел Управление
                              _sectionHeader(text: "УПРАВЛЕНИЕ"),
                              const SizedBox(height: 12),

                              // Кнопка сброса прогресса
                              _actionButton(
                                context: context,
                                label: 'СБРОСИТЬ ПРОГРЕСС',
                                icon: Icons.restart_alt,
                                color: Colors.redAccent,
                                onTap: () =>
                                    _confirmResetProgress(context, state),
                              ),

                              const SizedBox(height: 12),

                              // Кнопка поддержки
                              _actionButton(
                                context: context,
                                label: 'ПОДДЕРЖКА',
                                icon: Icons.support_agent,
                                variant: ThemedActionButtonVariant.blue,
                                onTap: () => _showSupportMessage(context),
                              ),

                              const SizedBox(height: 24),

                              // Раздел Аккаунт
                              _sectionHeader(text: "АККАУНТ"),
                              const SizedBox(height: 12),

                              StreamBuilder<User?>(
                                stream: FirebaseAuth.instance
                                    .authStateChanges(),
                                builder: (context, snapshot) {
                                  final user = snapshot.data;
                                  final signedIn =
                                      user != null &&
                                      !user.isAnonymous &&
                                      (user.email == null ||
                                          user.emailVerified);
                                  final email = user?.email;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _accountStatusCard(
                                        signedIn: signedIn,
                                        email: email,
                                      ),
                                      const SizedBox(height: 12),
                                      _actionButton(
                                        context: context,
                                        label: signedIn
                                            ? 'УПРАВЛЕНИЕ АККАУНТОМ'
                                            : 'ВОЙТИ / АККАУНТ',
                                        icon: Icons.person,
                                        variant: ThemedActionButtonVariant.blue,
                                        onTap: () =>
                                            _showAccountDialog(context, state),
                                      ),
                                      if (signedIn) ...[
                                        const SizedBox(height: 12),
                                        _actionButton(
                                          context: context,
                                          label: 'ВЫЙТИ ИЗ АККАУНТА',
                                          icon: Icons.logout,
                                          color: Colors.redAccent,
                                          onTap: () =>
                                              _signOutFromPanel(context),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              // УПРОЩЕННАЯ ИНФОРМАЦИЯ О ВЕРСИИ (без аудио системы)
                              _buildVersionInfo(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==================

  static Widget _sectionHeader({required String text}) {
    return Container(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF49C0F7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static Widget _customSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    void handleChanged(bool nextValue) {
      AudioManager().playTapSound();
      onChanged(nextValue);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A34),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => handleChanged(!value),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFF49C0F7), size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: handleChanged,
                  activeColor: const Color(0xFF49C0F7),
                  activeTrackColor: const Color(0xFF49C0F7).withOpacity(0.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _volumeSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A34),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(
                      value == 0 ? Icons.volume_off : Icons.volume_up,
                      color: const Color(0xFF49C0F7),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'ГРОМКОСТЬ МУЗЫКИ',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3A42),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF49C0F7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: onChanged,
            activeColor: const Color(0xFF49C0F7),
            inactiveColor: const Color(0xFF2A3A42),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Тихо',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Громко',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    ThemedActionButtonVariant variant = ThemedActionButtonVariant.custom,
  }) {
    final shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ];

    if (variant == ThemedActionButtonVariant.blue) {
      return ThemedBlueButton(
        label: label,
        icon: icon,
        onTap: onTap,
        playTapSound: true,
        boxShadow: shadows,
      );
    }

    return ThemedActionButton(
      label: label,
      icon: icon,
      onTap: onTap,
      color: color,
      variant: variant,
      playTapSound: true,
      boxShadow: shadows,
    );
  }

  static Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1519),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3A42)),
      ),
      child: Column(
        children: [
          Text(
            'EduQuiz v1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _accountStatusCard({
    required bool signedIn,
    required String? email,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A34),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            signedIn ? 'Вы вошли в аккаунт' : 'Вы не вошли в аккаунт',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (signedIn) ...[
            const SizedBox(height: 6),
            Text(
              email ?? 'Email не указан',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Вход сохраняется на устройстве',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> openAccountDialog(BuildContext context) {
    final state = context.read<GameState>();
    return _showAccountDialog(context, state);
  }

  static Future<void> _signOutFromPanel(BuildContext context) async {
    HapticFeedback.lightImpact();
    final account = AccountService();
    final state = context.read<GameState>();
    try {
      await account.syncUp(state);
    } catch (_) {}
    await account.signOut();
    await state.resetProgress();
    if (context.mounted) {
      _showSnackBar(context, 'Вы вышли из аккаунта', Icons.logout);
    }
  }

  static Future<void> _showAccountDialog(
    BuildContext context,
    GameState state,
  ) async {
    HapticFeedback.lightImpact();

    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final account = AccountService();

    bool isLoading = false;
    String? errorText;
    bool? signedIn;
    bool checkedStatus = false;
    bool obscurePassword = true;

    Future<void> handleLogin() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        errorText = 'Введите email и пароль';
        return;
      }
      try {
        errorText = null;
        final result = await account.login(
          state: state,
          email: email,
          password: password,
        );
        if (context.mounted) {
          Navigator.pop(context);
          _showSnackBar(
            context,
            result.configApplied
                ? 'Прогресс загружен и применен'
                : 'Вход выполнен',
            Icons.check_circle,
          );
        }
      } catch (e) {
        errorText = _friendlyError(e);
      }
    }

    Future<void> handleRegister() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        errorText = 'Введите email и пароль';
        return;
      }
      try {
        errorText = null;
        await account.register(state: state, email: email, password: password);
        if (context.mounted) {
          Navigator.pop(context);
          _showSnackBar(
            context,
            'Письмо для подтверждения отправлено на email',
            Icons.check_circle,
          );
        }
      } catch (e) {
        errorText = _friendlyError(e);
      }
    }

    Future<void> handleResetPassword() async {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        errorText = 'Введите email для восстановления';
        return;
      }
      try {
        errorText = null;
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (context.mounted) {
          _showSnackBar(
            context,
            'Ссылка для восстановления отправлена',
            Icons.mark_email_read,
          );
        }
      } catch (e) {
        errorText = _friendlyError(e);
      }
    }

    Future<void> handleSignOut() async {
      try {
        await account.syncUp(state);
      } catch (_) {}
      await state.resetProgress();
      await account.signOut();
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(context, 'Вы вышли из аккаунта', Icons.logout);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            if (!checkedStatus) {
              checkedStatus = true;
              account.isSignedIn().then((value) {
                if (context.mounted) {
                  setLocalState(() => signedIn = value);
                }
              });
            }

            Future<void> wrap(Future<void> Function() action) async {
              setLocalState(() {
                isLoading = true;
                errorText = null;
              });
              await action();
              if (context.mounted) {
                setLocalState(() => isLoading = false);
              }
            }

            final media = MediaQuery.of(context);
            final isCompact = media.size.width < 360;

            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 24,
                vertical: 24,
              ),
              backgroundColor: const Color(0xFF131F24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Аккаунт',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _inputField(
                          controller: emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !isLoading,
                          onSubmitted: (_) =>
                              FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          controller: passwordController,
                          label: 'Пароль',
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !isLoading,
                          onSubmitted: (_) => wrap(handleLogin),
                          suffixIcon: IconButton(
                            tooltip: obscurePassword
                                ? 'Показать пароль'
                                : 'Скрыть пароль',
                            onPressed: isLoading
                                ? null
                                : () => setLocalState(
                                    () => obscurePassword = !obscurePassword,
                                  ),
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (errorText != null)
                          Text(
                            errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          )
                        else
                          const Text(
                            'Данные синхронизируются автоматически при входе.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              actions: [
                if (signedIn == true)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : () => wrap(handleSignOut),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('ВЫЙТИ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => wrap(handleLogin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF49C0F7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'ВОЙТИ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => wrap(handleResetPassword),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'ЗАБЫЛИ ПАРОЛЬ?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isLoading ? null : () => wrap(handleRegister),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'СОЗДАТЬ АККАУНТ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _inputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    TextInputAction? textInputAction,
    List<String>? autofillHints,
    void Function(String)? onSubmitted,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A2A34),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF49C0F7)),
        ),
      ),
    );
  }

  static String _friendlyError(Object error) {
    if (error is AuthRequiredException) {
      return 'Сначала выполните вход';
    }
    if (error is EmailNotVerifiedException) {
      return 'Почта не подтверждена. Проверьте email и откройте ссылку из письма';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Некорректный email';
        case 'user-disabled':
          return 'Пользователь отключен';
        case 'user-not-found':
        case 'wrong-password':
          return 'Неверный email или пароль';
        case 'email-already-in-use':
          return 'Email уже используется';
        case 'weak-password':
          return 'Слишком простой пароль';
        case 'network-request-failed':
          return 'Нет подключения к интернету';
        case 'too-many-requests':
          return 'Слишком много попыток, попробуйте позже';
        default:
          return error.message ?? 'Ошибка авторизации';
      }
    }
    if (error is FirebaseException) {
      return error.message ?? 'Ошибка синхронизации';
    }
    return 'Не удалось связаться с сервером';
  }

  static Future<void> _confirmResetProgress(
    BuildContext context,
    GameState state,
  ) async {
    HapticFeedback.lightImpact();

    try {
      await AudioManager().ensureInitialized();
      await AudioManager().playTapSound();
    } catch (e) {
      print('Audio error: $e');
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131F24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Сбросить прогресс?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Все ваши достижения будут удалены.\nЭто действие нельзя отменить.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'ОТМЕНА',
              style: TextStyle(
                color: Color(0xFF49C0F7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'СБРОСИТЬ',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AudioManager().ensureInitialized();
        await AudioManager().playTapSound();
      } catch (e) {
        print('Audio error: $e');
      }

      await state.resetProgress();
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(context, 'Прогресс сброшен 🧹', Icons.check_circle);
      }
    }
  }

  static void _showSupportMessage(BuildContext context) {
    HapticFeedback.lightImpact();

    try {
      AudioManager().ensureInitialized().then((_) {
        AudioManager().playTapSound();
      });
    } catch (e) {
      print('Audio error: $e');
    }

    Navigator.pop(context);
    _showSnackBar(context, 'support@eduquiz.app 💬', Icons.email);
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1899D5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
