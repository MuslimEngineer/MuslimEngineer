import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onBoardingComplete;

  const WelcomeScreen({Key? key, required this.onBoardingComplete}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 4;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'أهلاً بك في تطبيق المهندس المسلم',
      'description': 'الدليل الشامل لتنظيم عباداتك ومهامك اليومية في مكان واحد',
      'icon': Icons.mosque_outlined,
      'color': AppColors.mosqueGreen,
    },
    {
      'title': 'أوقات الصلاة واتجاه القبلة',
      'description': 'احصل على أوقات الصلاة الدقيقة واتجاه القبلة بناء على موقعك',
      'icon': Icons.access_time_filled,
      'color': AppColors.prayerBlue,
    },
    {
      'title': 'تنظيم المهام والعبادات',
      'description': 'تتبع عباداتك ومهامك وأهدافك الدنيوية والأخروية بطريقة منظمة',
      'icon': Icons.check_circle_outline,
      'color': AppColors.accentColor,
    },
    {
      'title': 'القرآن الكريم والأذكار',
      'description': 'اقرأ القرآن الكريم والأذكار اليومية في أي وقت وفي أي مكان',
      'icon': Icons.menu_book,
      'color': AppColors.quranGold,
    },
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // خلفية متدرجة
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.9),
                  AppColors.secondaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // نمط زخرفي إسلامي في الخلفية
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/islamic_pattern.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                
                // عنوان التطبيق المتحرك
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'تطبيق المهندس المسلم',
                      textStyle: const TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                
                // الوصف
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'لتنظيم العبادات والمهام بطريقة متكاملة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
                
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                
                // صفحات العرض التقديمي
                Expanded(
                  child: PageView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildPage(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // مؤشرات الصفحات
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),
                ),
                
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                
                // زر التخطي أو البدء
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _currentPage == _numPages - 1
                      ? _buildStartButton()
                      : _buildNavigationButtons(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final data = _onboardingData[index];
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: data['color'].withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data['icon'],
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            data['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            data['description'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18.0,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _numPages; i++) {
      indicators.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return indicators;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 10.0,
      width: isActive ? 24.0 : 10.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: widget.onBoardingComplete,
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'البدء الآن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(
          onPressed: () {
            widget.onBoardingComplete();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text(
            'تخطي',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.ease,
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 3,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'التالي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
