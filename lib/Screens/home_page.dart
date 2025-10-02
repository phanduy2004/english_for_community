import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:recognize_face/Screens/recognize_facenet/face_enrollment_page.dart';
import 'package:recognize_face/screens/active_liveness/active_liveness_page2.dart';
import 'package:recognize_face/screens/app_settings_page.dart';
import 'package:recognize_face/screens/passive_liveness/liveness_screen.dart';
import 'package:recognize_face/screens/recognize_facenet/face_user_page.dart';
import 'package:recognize_face/screens/recognize_facenet/recognize_face_camera_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))
    ..forward();

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final features = <_Feature>[
    /*  _Feature(
        title: 'From Photo',
        subtitle: 'Recognize\nfrom Picture',
        icon: Icons.image_rounded,
        gradient: const [Color(0xFF34d399), Color(0xFF0ea5e9)],
        builder: () => const RecognizeFacePicturePage(),
      ),*/
      _Feature(
        title: 'Enrollment',
        subtitle: 'Enroll via Camera',
        icon: Icons.app_registration_rounded,
        gradient: const [Color(0xFFfb7185), Color(0xFFf59e0b)],
        builder: () => const FaceEnrollmentPage(),
      ),
      _Feature(
        title: 'Live Camera',
        subtitle: 'Real-time Recognition',
        icon: Icons.videocam_rounded,
        gradient: const [Color(0xFFa78bfa), Color(0xFF7c3aed)],
        builder: () => const RecognizeFaceCameraPage(),
      ),
      _Feature(
        title: 'User Management',
        subtitle: 'Edit, Delete...',
        icon: Icons.person,
        gradient: const [Color(0xFF34d399), Color(0xFF0ea5e9)],
        builder: () => const FaceUsersPage(),
      ),
      _Feature(
        title: 'Liveness',
        subtitle: 'Anti-spoofing',
        icon: Icons.security_rounded,
        gradient: const [Color(0xFFf43f5e), Color(0xFFec4899)],
        builder: () => const LivenessScreen(),
      ),
      _Feature(
        title: 'Active Liveness',
        subtitle: 'Active Liveness Detection',
        icon: Icons.accessibility_new_rounded,
        gradient: const [Color(0xFFa78bfa), Color(0xFF7c3aed)],
        builder: () => ActiveLivenessDetection2(),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const _LuxuryBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    pinned: true,
                    title: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFfb7185), Color(0xFF7c3aed)],
                      ).createShader(r),
                      child: Text(
                        'Face Recognition Research',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_rounded),
                        onPressed: (){
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AppSettingsPage()));
                        }
                      ),
                    ],
                    bottom: const PreferredSize(
                      preferredSize: Size.fromHeight(12),
                      child: SizedBox(height: 12),
                    ),
                  ),

                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _Frosted(
                        child: Row(
                          children: [
                            const _CircleBadge(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Choose a mode to start your face recognition workflow.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Feature grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: features.length,
                      itemBuilder: (_, i) => _FeatureTile(data: features[i]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Tip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _Frosted(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tip: even lighting and a stable frame produce more accurate embeddings.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),

          // Bottom glow
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      (isDark ? Colors.black : Colors.white).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Common widgets =====

class _LuxuryBackground extends StatelessWidget {
  const _LuxuryBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0f172a), Color(0xFF111827)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        _Blob(
          left: -80,
          top: -60,
          size: 220,
          colors: [Color(0xFFfb7185), Color(0xFFf59e0b)],
        ),
        _Blob(
          right: -70,
          bottom: -50,
          size: 260,
          colors: [Color(0xFF7c3aed), Color(0xFF0ea5e9)],
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final List<Color> colors;
  final double? left, top, right, bottom;

  const _Blob({
    required this.size,
    required this.colors,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors.map((c) => c.withOpacity(0.45)).toList(),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.2),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Frosted extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Frosted({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CircleBadge extends StatelessWidget {
  const _CircleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            LinearGradient(colors: [Color(0xFFfb7185), Color(0xFF7c3aed)]),
      ),
      child: const Icon(Icons.face_retouching_natural_rounded,
          color: Colors.white),
    );
  }
}

// ===== Feature grid =====

class _Feature {
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Widget Function() builder;

  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.builder,
  });
}

class _FeatureTile extends StatelessWidget {
  final _Feature data;
  const _FeatureTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(_go(data.builder())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradient.last.withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Icon(data.icon, color: Colors.white),
              ),
              const Spacer(),
              Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Route helper =====

PageRoute _go(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, a, __) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
        child: page,
      ),
    );
