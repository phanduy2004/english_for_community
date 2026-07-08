import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../core/theme/app_color.dart';

/// Drives the "Login Machine" Rive remix (Teddy-style inputs).
class LoginRiveInputs {
  LoginRiveInputs(this._stateMachine);

  final StateMachine _stateMachine;

  void _bool(String name, bool value) {
    _stateMachine.boolean(name)?.value = value;
  }

  void _num(String name, double value) {
    _stateMachine.number(name)?.value = value;
  }

  void fireTrigger(String name) {
    _stateMachine.trigger(name)?.fire();
  }

  void idle() {
    _bool('isChecking', false);
    _bool('isHandsUp', false);
    _num('numLook', 0);
  }

  /// Focus ô email / đang gõ username.
  void emailActive({required bool focused, int textLength = 0}) {
    if (!focused) {
      idle();
      return;
    }
    _bool('isChecking', true);
    _bool('isHandsUp', false);
    _num('numLook', textLength.clamp(0, 12).toDouble());
  }

  /// Focus ô password — che mắt khi obscure.
  void passwordActive({required bool focused, required bool obscure}) {
    if (!focused) {
      idle();
      return;
    }
    if (obscure) {
      _bool('isHandsUp', true);
      _bool('isChecking', false);
    } else {
      _bool('isHandsUp', false);
      _bool('isChecking', true);
    }
  }

  void loginSuccess() => fireTrigger('trigSuccess');

  void loginFailed() => fireTrigger('trigFail');
}

/// Interactive login mascot (`login_machine.riv`).
class AuthLoginRiveMascot extends StatefulWidget {
  const AuthLoginRiveMascot({
    super.key,
    this.onReady,
  });

  final ValueChanged<LoginRiveInputs>? onReady;

  @override
  State<AuthLoginRiveMascot> createState() => _AuthLoginRiveMascotState();
}

class _AuthLoginRiveMascotState extends State<AuthLoginRiveMascot> {
  static const _assetPath = 'assets/animations/rive/login_machine.riv';

  late final FileLoader _fileLoader = FileLoader.fromAsset(
    _assetPath,
    riveFactory: Factory.rive,
  );

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  double _height(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 600) return 168;
    if (w >= 400) return 148;
    return 128;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height(context),
      width: double.infinity,
      child: RiveWidgetBuilder(
        fileLoader: _fileLoader,
        stateMachineSelector: const StateMachineNamed('Login Machine'),
        onLoaded: (state) {
          final inputs = LoginRiveInputs(state.controller.stateMachine);
          inputs.idle();
          widget.onReady?.call(inputs);
        },
        builder: (context, state) => switch (state) {
          RiveLoading() => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          RiveFailed() => Icon(
              Icons.sentiment_satisfied_alt_outlined,
              size: 72,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          RiveLoaded(:final controller) => RiveWidget(
              controller: controller,
              fit: Fit.contain,
            ),
        },
      ),
    );
  }
}
