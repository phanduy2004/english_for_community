import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/locale/l10n_context.dart';
import '../core/theme/app_color.dart';
import '../core/theme/app_skill_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/ui/student_mobile_ui.dart';
import '../l10n/generated/app_localizations.dart';
import 'auth/login_page.dart';
import 'auth/widgets/auth_form_widgets.dart';

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

  void _onPrimaryCta(List<_SlideContent> slides) {
    if (_current < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      context.pushNamed(LoginPage.routeName);
    }
  }

  List<_SlideContent> _slides(AppLocalizations t) => [
        _SlideContent(
          title: t.onboardingSlide1Title,
          subtitle: t.onboardingSlide1Subtitle,
          icon: Icons.timeline_rounded,
          skill: SkillType.reading,
        ),
        _SlideContent(
          title: t.onboardingSlide2Title,
          subtitle: t.onboardingSlide2Subtitle,
          icon: Icons.psychology_rounded,
          skill: SkillType.speaking,
        ),
        _SlideContent(
          title: t.onboardingSlide3Title,
          subtitle: t.onboardingSlide3Subtitle,
          icon: Icons.emoji_events_rounded,
          useAccent: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final slides = _slides(t);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.pushNamed(LoginPage.routeName),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(44, 44),
                ),
                child: Text(t.onboardingSkip, style: AppTypography.label()),
              ),
            ),
            _LogoTitle(brand: t.appNameBrand, tagline: t.appTagline),
            const SizedBox(height: AppSpacing.s7),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudentMobileUi.pageHPadding,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: slides.length,
                        onPageChanged: (i) => setState(() => _current = i),
                        itemBuilder: (_, i) => _Slide(data: slides[i]),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _Dots(active: _current, total: slides.length, slides: slides),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: StudentMobileUi.pagePadding.copyWith(top: 0),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => _onPrimaryCta(slides),
                    style: AuthFormUi.primaryButtonStyle().copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size(double.infinity, 48),
                      ),
                    ),
                    child: Text(
                      _current < slides.length - 1 ? t.next : t.continueAction,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.alreadyHaveAccount,
                        style: StudentMobileUi.body(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pushNamed(LoginPage.routeName),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                          ),
                          minimumSize: const Size(44, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(t.signInAction, style: AppTypography.label()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoTitle extends StatelessWidget {
  const _LogoTitle({required this.brand, required this.tagline});

  final String brand;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StudentMobileUi.roundIconBox(
          Icons.school_rounded,
          size: 96,
          color: AppColors.accent,
          bg: AppColors.accentTint,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          brand,
          textAlign: TextAlign.center,
          style: context.h1Style.copyWith(
            fontSize: AppTypography.mobileDisplay,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s7),
          child: Text(
            tagline,
            textAlign: TextAlign.center,
            style: StudentMobileUi.body(context),
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
  final SkillType? skill;
  final bool useAccent;

  const _SlideContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.skill,
    this.useAccent = false,
  });
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});
  final _SlideContent data;

  @override
  Widget build(BuildContext context) {
    final colors = data.useAccent
        ? null
        : (data.skill != null ? AppSkillColors.of(data.skill!) : null);
    final fg = data.useAccent ? AppColors.accent : colors?.color ?? AppColors.primary;
    final bg = data.useAccent ? AppColors.accentTint : colors?.tint ?? AppColors.primaryTint;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          width: 240,
          height: 240,
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: fg.withValues(alpha: 0.25)),
              ),
              child: Icon(data.icon, color: fg, size: 56),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: context.h2Style,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: StudentMobileUi.body(context),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.active,
    required this.total,
    required this.slides,
  });

  final int active;
  final int total;
  final List<_SlideContent> slides;

  Color _dotColor(int index, bool isActive) {
    if (!isActive) return AppColors.outlineStrong;
    final slide = slides[index];
    if (slide.useAccent) return AppColors.accent;
    if (slide.skill != null) return AppSkillColors.of(slide.skill!).color;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _dotColor(i, isActive),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
