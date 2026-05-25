import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttaxi/theme.dart';
import 'package:smarttaxi/widgets/theme_mode_selector.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      icon: Icons.local_taxi_rounded,
      title: 'Welcome to\nSmartTaxi',
      subtitle: 'Your trusted companion for taxi travel across South Africa',
      emoji: '🚖',
    ),
    OnboardingContent(
      icon: Icons.calculate_rounded,
      title: 'Calculate\nFares Instantly',
      subtitle: 'Know your fare before you ride. No surprises, no hidden costs',
      emoji: '💰',
    ),
    OnboardingContent(
      icon: Icons.route_rounded,
      title: 'Plan Your\nJourney',
      subtitle: 'Multi-stop trips, route optimization, and time estimates',
      emoji: '🗺️',
    ),
    OnboardingContent(
      icon: Icons.offline_bolt_rounded,
      title: 'Works\nOffline',
      subtitle: 'Access saved routes and fare estimates even without internet',
      emoji: '⚡',
    ),
    OnboardingContent(
      icon: Icons.palette_rounded,
      title: 'Choose Your\nLook',
      subtitle: 'Pick the theme that feels right for you. You can change this anytime in settings.',
      emoji: '🎨',
      isThemeStep: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/auth');
    }
  }

  void _skip() {
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageContent(
                    content: _contents[index],
                    isActive: _currentPage == index,
                  );
                },
              ),
            ),
            
            // Bottom section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryColor
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _contents.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _contents.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
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

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingContent content;
  final bool isActive;

  const _OnboardingPageContent({
    required this.content,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: isActive ? scale : 0.8,
                  child: child,
                );
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.2),
                      primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      content.icon,
                      size: 64,
                      color: primaryColor,
                    ),
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Text(
                        content.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Title
            Text(
              content.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Subtitle
            Text(
              content.subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
            if (content.isThemeStep) ...[
              const SizedBox(height: AppSpacing.xl),
              const ThemeModeSelector(),
            ],
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final IconData icon;
  final String title;
  final String subtitle;
  final String emoji;
  final bool isThemeStep;

  OnboardingContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.isThemeStep = false,
  });
}
