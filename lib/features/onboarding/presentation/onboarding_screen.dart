import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:bharatstock/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _pageOffset = _controller.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  List<Color> _getInterpolatedGradient(List<List<Color>> gradients) {
    int currentPage = _pageOffset.floor();
    int nextPage = (_pageOffset.ceil()) % gradients.length;
    double progress = _pageOffset - currentPage;

    if (currentPage == nextPage || nextPage >= gradients.length) {
      return gradients[currentPage];
    }

    return [
      Color.lerp(gradients[currentPage][0], gradients[nextPage][0], progress)!,
      Color.lerp(gradients[currentPage][1], gradients[nextPage][1], progress)!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const baseColor = Color(0xFFF2F4F8);

    final pages = [
      {
        'title': l.onboardingTitle1,
        'desc': l.onboardingDesc1,
        'image': 'assets/images/smart_stock.png',
        'gradient': [const Color(0xFFE8EEE1), const Color(0xFFF5F5DC)],
        'icon': Icons.inventory_2_rounded,
        'iconColor': const Color(0xFF4CAF50),
      },
      {
        'title': l.onboardingTitle2,
        'desc': l.onboardingDesc2,
        'image': 'assets/images/work_easy.png',
        'gradient': [const Color(0xFFFFE8D6), const Color(0xFFFFF4E6)],
        'icon': Icons.trending_up_rounded,
        'iconColor': const Color(0xFFFF9800),
      },
      {
        'title': l.onboardingTitle3,
        'desc': l.onboardingDesc3,
        'image': null,
        'gradient': [const Color(0xFFE0F0FF), const Color(0xFFF0F8FF)],
        'icon': Icons.business_center_rounded,
        'iconColor': const Color(0xFF2196F3),
      },
    ];

    final gradients = pages.map((p) => p['gradient'] as List<Color>).toList();
    final gradientColors = _getInterpolatedGradient(gradients);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              gradientColors[0],
              gradientColors[1],
              const Color(0xFFFAFAFA),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // PAGE VIEW - images
            Positioned.fill(
              top: 100,
              bottom: 310,
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  if (page['image'] == null) {
                    return _buildToolkitScene(baseColor);
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 20.0,
                    ),
                    child: Center(
                      child: Image.asset(
                        page['image'] as String,
                        fit: BoxFit.contain,
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    ),
                  );
                },
              ),
            ),

            // BACK BUTTON (Top Left)
            Positioned(
              top: 54,
              left: 20,
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/language'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ),
            ),

            // SKIP BUTTON (Top Right) — only for first 2 pages
            if (_currentIndex < 2)
              Positioned(
                top: 54,
                right: 20,
                child: GestureDetector(
                  onTap: _goToLogin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      l.skip,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // BOTTOM CARD
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        pages[_currentIndex]['title'] as String,
                        key: ValueKey(_currentIndex),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        pages[_currentIndex]['desc'] as String,
                        key: ValueKey('desc_$_currentIndex'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pages.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentIndex == index ? 28 : 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? const Color(0xFFFFA726)
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),

                    // Next / Get Started button
                    GestureDetector(
                      onTap: () {
                        if (_currentIndex < pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        } else {
                          _goToLogin();
                        }
                      },
                      child: ClayContainer(
                        surfaceColor: const Color(0xFFFFA726),
                        parentColor: Colors.white,
                        borderRadius: 16,
                        depth: 10,
                        spread: 2,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == pages.length - 1
                                    ? l.getStarted
                                    : l.next,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentIndex == pages.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolkitScene(Color baseColor) {
    return Stack(
      children: [
        _floatingCard(
          top: 40,
          left: 30,
          icon: Icons.verified_user_rounded,
          label: 'GST',
          iconColor: const Color(0xFF4CAF50),
          bg: const Color(0xFFE8F5E9),
        ),
        _floatingCard(
          top: 100,
          right: 50,
          icon: Icons.receipt_long_rounded,
          label: 'Invoice',
          iconColor: const Color(0xFF2196F3),
          bg: const Color(0xFFE3F2FD),
        ),
        _floatingCard(
          top: 190,
          left: 40,
          icon: Icons.bar_chart_rounded,
          label: 'Reports',
          iconColor: const Color(0xFF9C27B0),
          bg: const Color(0xFFF3E5F5),
        ),
        _floatingCard(
          top: 170,
          right: 30,
          icon: Icons.inventory_2_rounded,
          label: 'Stock',
          iconColor: const Color(0xFFFF5722),
          bg: const Color(0xFFFBE9E7),
        ),
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.currency_rupee_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cash Flow',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _floatingCard({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bg,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
