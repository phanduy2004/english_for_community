import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static String routeName = 'OnboardingPage';
  static String routePath = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    if (_current < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pushNamed('GoalSetupPage'); // đổi theo route của bạn
    }
  }

  void _onSignIn() => Navigator.of(context).pushNamed('AuthPage'); // đổi route

  static final _slides = <_SlideContent>[
    _SlideContent(
      title: 'Personalized Learning Path',
      subtitle: 'A plan tailored to your goals, CEFR level, and schedule.',
      icon: Icons.timeline_rounded,
    ),
    _SlideContent(
      title: 'AI Tutor for Speaking & Writing',
      subtitle: 'Realtime pronunciation feedback & rubric-based review.',
      icon: Icons.psychology_rounded,
    ),
    _SlideContent(
      title: 'Stay Motivated with Rewards',
      subtitle: 'Streaks, XP, and badges keep you engaged daily.',
      icon: Icons.emoji_events_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF19DB8A), Color(0x4C19DB8A)],
                  begin: Alignment(1, 1),
                  end: Alignment(-1, -1),
                ),
              ),
            ),
            // Content
            Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('GoalSetupPage'),
                    child: const Text('Skip', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),

                // Logo & title
                const _LogoTitle(),

                const SizedBox(height: 24),

                // Slides + dots
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _slides.length,
                            onPageChanged: (i) => setState(() => _current = i),
                            itemBuilder: (_, i) => _Slide(data: _slides[i]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Dots(active: _current, total: _slides.length),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_current < _slides.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            } else {
                              // slide cuối -> đi tới LoginPage
                              context.pushNamed('LoginPage'); // hoặc LoginPage.routeName
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF19DB8A),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(_current < _slides.length - 1 ? 'Get Started' : 'Continue'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: text.bodyMedium!.copyWith(color: Colors.white.withOpacity(.85)),
                          ),
                          InkWell(
                            onTap: () => context.pushNamed('LoginPage'), // giữ như cũ
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )

              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoTitle extends StatelessWidget {
  const _LogoTitle();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 112, height: 112,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(blurRadius: 20, color: Color(0x40000000), offset: Offset(0, 8))],
          ),
          child: const Icon(Icons.school_rounded, color: Color(0xFF19DB8A), size: 56),
        ),
        const SizedBox(height: 12),
        Text('LearnLingo',
            textAlign: TextAlign.center,
            style: text.displayMedium?.copyWith(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Master English with AI-powered learning',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: Colors.white.withOpacity(.92), fontSize: 16, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _SlideContent {
  final String title;
  final String subtitle;
  final IconData icon;
  const _SlideContent({required this.title, required this.subtitle, required this.icon});
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});
  final _SlideContent data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 84, height: 84,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(data.icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 18),
        Text(data.title,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(data.subtitle,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: Colors.white.withOpacity(.9), height: 1.4)),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.active, required this.total});
  final int active;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
