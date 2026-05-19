import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/stilya_design_system.dart';
import '../onboarding/onboarding_screen.dart';
import 'auth_screen.dart';
import '../main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    isOnboardingDone().then((done) {
      if (mounted) setState(() => _onboardingDone = done);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(body: StilyaLoader(label: 'Stilya hazırlanıyor'));
    }

    if (!_onboardingDone!) {
      return OnboardingScreen(
        onDone: () => setState(() => _onboardingDone = true),
      );
    }

    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(body: StilyaLoader(label: 'Hesabın açılıyor'));
    }

    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }

    return MainShell(key: ValueKey(auth.user?.id));
  }
}
