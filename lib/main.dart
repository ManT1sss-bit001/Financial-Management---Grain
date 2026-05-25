import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _grainFullLogoAsset = "assets/03_grain_full_logo_primary_37D1B8_transparent.png";
const String _grainOnboardingSeenKey = "grain_has_seen_onboarding_v1";
const Color _grainNavyDeep = Color(0xFF060E20);
const Color _grainNavy = Color(0xFF0B1326);
const Color _grainAccent = Color(0xFF37D1B8);
const Color _grainCyan = Color(0xFF00F5D4);

void main() => runApp(const GrainApp());

class GrainApp extends StatelessWidget {
  const GrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: _grainNavyDeep,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _grainCyan,
          brightness: Brightness.dark,
        ),
      ),
      home: const GrainOpeningScreen(),
    );
  }
}

class GrainOpeningScreen extends StatefulWidget {
  const GrainOpeningScreen({super.key});

  @override
  State<GrainOpeningScreen> createState() => _GrainOpeningScreenState();
}

class _GrainOpeningScreenState extends State<GrainOpeningScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _sloganFade;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.05, 0.75, curve: Curves.easeOutCubic)),
    );
    _sloganFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 1, curve: Curves.easeOut),
    );

    _completeOpening();
  }

  Future<void> _completeOpening() async {
    final prefsFuture = SharedPreferences.getInstance();
    await Future<void>.delayed(const Duration(milliseconds: 1650));
    final prefs = await prefsFuture;
    if (!mounted) return;

    final hasSeenOnboarding = prefs.getBool(_grainOnboardingSeenKey) ?? false;
    setState(() {
      _nextScreen = hasSeenOnboarding ? const HomePage() : const GrainOnboardingScreen();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _nextScreen ?? _buildOpeningFrame(),
    );
  }

  Widget _buildOpeningFrame() {
    return Scaffold(
      backgroundColor: _grainNavyDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _GrainOpeningParticlePainter(progress: _controller.value),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        _grainFullLogoAsset,
                        height: 76,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          "Grain",
                          style: TextStyle(
                            color: _grainAccent,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _sloganFade,
                    child: const Text(
                      "Small spending. Clear habits.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB9CAC4),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GrainOnboardingScreen extends StatefulWidget {
  const GrainOnboardingScreen({super.key});

  @override
  State<GrainOnboardingScreen> createState() => _GrainOnboardingScreenState();
}

class _GrainOnboardingScreenState extends State<GrainOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.savings_outlined,
      title: "Track small spending",
      body:
          "Money is accumulated little by little, like grains. Grain helps you record daily expenses before they become invisible.",
    ),
    _OnboardingPageData(
      icon: Icons.insights_rounded,
      title: "Understand your habits",
      body: "Use the calendar, insights, and category summaries to see where your money goes.",
    ),
    _OnboardingPageData(
      icon: Icons.notifications_active_outlined,
      title: "Smart local reminders",
      body: "Grain gives budget and spending reminders using local data, without cloud AI or system notifications.",
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_grainOnboardingSeenKey, true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
        transitionDuration: const Duration(milliseconds: 360),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
    );
  }

  void _handlePrimaryAction() {
    if (_isLastPage) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _grainNavyDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_grainNavyDeep, _grainNavy, Color(0xFF071C24)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            child: Column(
              children: [
                Image.asset(
                  _grainFullLogoAsset,
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    "Grain",
                    style: TextStyle(color: _grainAccent, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(_pages[index]);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _buildPageIndicators(),
                const SizedBox(height: 22),
                _buildPrimaryButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(_OnboardingPageData page) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: _grainCyan.withOpacity(0.08),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_grainCyan, _grainAccent]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _grainCyan.withOpacity(0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(page.icon, color: const Color(0xFF00201A), size: 28),
              ),
              const SizedBox(height: 28),
              Text(
                page.title,
                style: const TextStyle(
                  color: Color(0xFFDAE2FD),
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.body,
                style: const TextStyle(
                  color: Color(0xFFB9CAC4),
                  fontSize: 15,
                  height: 1.48,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: isActive ? 26 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? _grainAccent : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_grainCyan, _grainAccent]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _grainCyan.withOpacity(0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _handlePrimaryAction,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _isLastPage ? "Start using Grain" : "Next",
                  key: ValueKey<bool>(_isLastPage),
                  style: const TextStyle(
                    color: Color(0xFF00201A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String date;
  final IconData icon;
  final String notes;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.icon,
    required this.timestamp,
    this.notes = "",
  });
}

class _CategoryOption {
  final String label;
  final IconData icon;

  const _CategoryOption(this.label, this.icon);
}

class _ExpenseAmountValidation {
  final double? amount;
  final String? error;

  const _ExpenseAmountValidation.valid(this.amount) : error = null;

  const _ExpenseAmountValidation.invalid(this.error) : amount = null;

  bool get isValid => amount != null && error == null;
}

class _GrainOpeningParticlePainter extends CustomPainter {
  final double progress;

  const _GrainOpeningParticlePainter({required this.progress});

  static const List<_OpeningParticle> _particles = [
    _OpeningParticle(0.18, 0.68, 2.8, 0.00, 0.95),
    _OpeningParticle(0.30, 0.58, 4.2, 0.12, 0.82),
    _OpeningParticle(0.42, 0.70, 2.4, 0.04, 0.88),
    _OpeningParticle(0.57, 0.62, 3.5, 0.10, 0.92),
    _OpeningParticle(0.70, 0.55, 2.6, 0.18, 0.78),
    _OpeningParticle(0.82, 0.66, 4.0, 0.08, 0.86),
    _OpeningParticle(0.36, 0.43, 2.2, 0.22, 0.74),
    _OpeningParticle(0.66, 0.40, 2.8, 0.16, 0.80),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x3320E6CB), Color(0x00060E20)],
      ).createShader(Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide * 0.58));
    canvas.drawRect(Offset.zero & size, glowPaint);

    for (final particle in _particles) {
      final localProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0).toDouble();
      final eased = Curves.easeOutCubic.transform(localProgress);
      final opacity = math.sin(localProgress * math.pi).clamp(0.0, 1.0).toDouble() * particle.opacity;
      if (opacity <= 0) continue;

      final drift = math.sin((particle.x * 9.0) + eased * math.pi) * 10;
      final center = Offset(
        size.width * particle.x + drift,
        size.height * particle.y - eased * 72,
      );
      final paint = Paint()..color = const Color(0xFF37D1B8).withOpacity(opacity * 0.55);
      canvas.drawCircle(center, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainOpeningParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _OpeningParticle {
  final double x;
  final double y;
  final double radius;
  final double delay;
  final double opacity;

  const _OpeningParticle(this.x, this.y, this.radius, this.delay, this.opacity);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _navy = Color(0xFF0B1326);
  static const Color _navyDeep = Color(0xFF060E20);
  static const Color _navySoft = Color(0xFF171F33);
  static const Color _textOnDark = Color(0xFFDAE2FD);
  static const Color _textMutedDark = Color(0xFFB9CAC4);
  static const Color _defaultAccent = Color(0xFF00F5D4);
  static const Color _cyan = Color(0xFF00DFC1);
  static const Color _blue = Color(0xFF1493FF);
  static const Color _amber = Color(0xFFFFB955);
  static const Color _pink = Color(0xFFFF8B98);
  static const Color _refinedGreen = Color(0xFF5FD6B8);
  static const Color _refinedRed = Color(0xFFE56B73);
  static const String _fullLogoAsset = _grainFullLogoAsset;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  final List<_CategoryOption> _categories = const [
    _CategoryOption("Shopping", Icons.shopping_bag_outlined),
    _CategoryOption("Dining", Icons.restaurant_rounded),
    _CategoryOption("Transport", Icons.directions_car_rounded),
    _CategoryOption("Groceries", Icons.local_grocery_store_outlined),
    _CategoryOption("Bills", Icons.bolt_rounded),
    _CategoryOption("Study", Icons.school_rounded),
    _CategoryOption("Health", Icons.medical_services_outlined),
    _CategoryOption("Home", Icons.home_rounded),
  ];

  int _currentIndex = 0;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedDay = DateTime.now().day;
  bool _isDarkMode = true;
  double _monthlyBudget = 650;
  Color _accentColor = _defaultAccent;
  String _selectedCategory = "Shopping";
  IconData _selectedIcon = Icons.shopping_bag_outlined;
  DateTime _expenseDate = DateTime.now();
  String? _formError;
  Set<String> _seenReminderIds = {};

  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Color get _pageBackground => _isDarkMode ? _navyDeep : const Color(0xFFEAF7F5);
  Color get _pageBackgroundAlt => _isDarkMode ? _navy : const Color(0xFFF8FEFC);
  Color get _textPrimary => _isDarkMode ? _textOnDark : const Color(0xFF102328);
  Color get _textMuted => _isDarkMode ? _textMutedDark : const Color(0xFF54686A);
  Color get _glassFill =>
      _isDarkMode ? Colors.white.withOpacity(0.045) : Colors.white.withOpacity(0.72);
  Color get _glassStroke =>
      _isDarkMode ? Colors.white.withOpacity(0.09) : Colors.black.withOpacity(0.08);

  LinearGradient get _accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_accentColor, _blendAccent(_accentColor)],
      );

  Color _blendAccent(Color color) {
    return Color.lerp(color, _blue, 0.28) ?? _cyan;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions
        .map(
          (t) => {
            'id': t.id,
            'title': t.title,
            'amount': t.amount,
            'date': t.date,
            'icon': t.icon.codePoint,
            'notes': t.notes,
            'timestamp': t.timestamp.toIso8601String(),
          },
        )
        .toList();

    await prefs.setString('grain_data_v1', jsonEncode(jsonList));
    await prefs.setInt('user_color_pref', _accentColor.value);
    await prefs.setBool('grain_dark_mode_v2', _isDarkMode);
    await prefs.setDouble('grain_monthly_budget_v2', _monthlyBudget);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('grain_data_v1');
    final loadedTransactions = <Transaction>[];

    if (savedData != null) {
      final list = jsonDecode(savedData) as List<dynamic>;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final timestamp = _loadTransactionTimestamp(map);
        loadedTransactions.add(
          Transaction(
            id: map['id'] as String,
            title: map['title'] as String,
            amount: (map['amount'] as num).toDouble(),
            date: _formatStoredTransactionDate(timestamp),
            icon: _iconFromCodePoint(map['icon'] as int),
            notes: (map['notes'] as String?) ?? "",
            timestamp: timestamp,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      transactions = loadedTransactions;
      final colorValue = prefs.getInt('user_color_pref');
      if (colorValue != null) _accentColor = Color(colorValue);
      _isDarkMode = prefs.getBool('grain_dark_mode_v2') ?? true;
      _monthlyBudget = prefs.getDouble('grain_monthly_budget_v2') ?? 650;
      _seenReminderIds = (prefs.getStringList('grain_seen_reminders_v1') ?? const <String>[]).toSet();
    });
  }

  double get monthlyTotal {
    final now = DateTime.now();
    return _sumTransactions(
      transactions.where((t) => t.timestamp.year == now.year && t.timestamp.month == now.month),
    );
  }

  double get todayTotal {
    final now = DateTime.now();
    return _sumTransactions(
      transactions.where(
        (t) =>
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month &&
            t.timestamp.day == now.day,
      ),
    );
  }

  double get selectedMonthTotal {
    return _sumTransactions(
      transactions.where((t) => t.timestamp.year == _selectedYear && t.timestamp.month == _selectedMonth),
    );
  }

  double get previousMonthTotal {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    return _sumTransactions(
      transactions.where((t) => t.timestamp.year == previous.year && t.timestamp.month == previous.month),
    );
  }

  List<Transaction> get _monthTransactions {
    final now = DateTime.now();
    return transactions
        .where((t) => t.timestamp.year == now.year && t.timestamp.month == now.month)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  double _sumTransactions(Iterable<Transaction> items) {
    return items.fold(0, (sum, item) => sum + item.amount);
  }

  void _addTransaction({
    required String title,
    required double amount,
    required IconData icon,
    required String note,
    required DateTime timestamp,
  }) {
    setState(() {
      transactions.insert(
        0,
        Transaction(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.isEmpty ? "Unlabeled" : title,
          amount: amount,
          date: _formatStoredTransactionDate(timestamp),
          icon: icon,
          notes: note,
          timestamp: timestamp,
        ),
      );
    });
    _saveData();
  }

  void _deleteTransaction(String id) {
    setState(() {
      transactions.removeWhere((t) => t.id == id);
    });
    _saveData();
  }

  Future<void> _exportCSV() async {
    if (transactions.isEmpty) {
      _showSnack("No transactions to export yet.");
      return;
    }

    final sortedTxs = List<Transaction>.from(transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final monthNames = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    final buffer = StringBuffer()
      ..writeln("GRAIN FINANCIAL EXPENDITURE REPORT")
      ..writeln("Currency: AUD")
      ..writeln("Generated: ${DateTime.now().toString().split('.').first}")
      ..writeln()
      ..writeln("Date,Category,Price in AUD,Notes");

    double grandTotal = 0;
    int? currentMonth;
    int? currentYear;
    double monthSubtotal = 0;

    for (var i = 0; i < sortedTxs.length; i++) {
      final t = sortedTxs[i];
      final transactionMonth = t.timestamp.month;
      final transactionYear = t.timestamp.year;
      if (currentMonth != transactionMonth || currentYear != transactionYear) {
        if (currentMonth != null && currentYear != null) {
          final previousMonth = currentMonth;
          final previousYear = currentYear;
          buffer.writeln(
            ">> Subtotal for ${monthNames[previousMonth]} $previousYear, ,${monthSubtotal.toStringAsFixed(2)}, [Monthly End]",
          );
          buffer.writeln();
        }
        currentMonth = transactionMonth;
        currentYear = transactionYear;
        monthSubtotal = 0;
        buffer.writeln("--- ${monthNames[transactionMonth].toUpperCase()} $transactionYear ---");
      }

      final dateStr =
          "${t.timestamp.year}-${t.timestamp.month.toString().padLeft(2, '0')}-${t.timestamp.day.toString().padLeft(2, '0')}";
      buffer.writeln(
        "$dateStr,${_csvClean(t.title)},${t.amount.toStringAsFixed(2)},${_csvClean(t.notes)}",
      );
      monthSubtotal += t.amount;
      grandTotal += t.amount;

      if (i == sortedTxs.length - 1) {
        final closingMonth = currentMonth!;
        final closingYear = currentYear!;
        final status = closingMonth == DateTime.now().month && closingYear == DateTime.now().year
            ? "Current Month To Date"
            : "Monthly Total";
        buffer.writeln(
          ">> $status (${monthNames[closingMonth]} $closingYear), ,${monthSubtotal.toStringAsFixed(2)}, [Complete]",
        );
      }
    }

    buffer
      ..writeln()
      ..writeln("==========================")
      ..writeln("ALL-TIME TOTAL EXPENDITURE, ,AUD ${grandTotal.toStringAsFixed(2)}, ")
      ..writeln("==========================")
      ..writeln("Grain app made by Jerry Chen");

    final csv = buffer.toString();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? _navySoft : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Export CSV", style: TextStyle(color: _textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Data is grouped by month with automatic subtotals.",
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 14),
              Container(
                height: 320,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(_isDarkMode ? 0.28 : 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _glassStroke),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: _isDarkMode ? _accentColor : const Color(0xFF12383F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: const Color(0xFF00201A),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(context);
              _showSnack("CSV copied to clipboard.");
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text("Copy CSV"),
          ),
        ],
      ),
    );
  }

  String _csvClean(String value) => value.replaceAll(',', ';').replaceAll('\n', ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _pageBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_pageBackgroundAlt, _pageBackground],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 92),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(_currentIndex),
                  child: _buildBodyContent(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomNavigation(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildCalendarScreen();
      case 2:
        return _buildAddExpenseScreen();
      case 3:
        return _buildInsightsScreen();
      case 4:
      default:
        return _buildSettingsScreen();
    }
  }

  Widget _buildHomeScreen() {
    final recent = transactions.take(5).toList();
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildTopBar(),
        const SizedBox(height: 26),
        _buildSummaryCard(),
        const SizedBox(height: 22),
        _buildQuickActions(),
        const SizedBox(height: 22),
        _buildAiInsightCard(),
        const SizedBox(height: 28),
        _sectionHeader("Recent Activity", trailing: transactions.length > 5 ? "View all" : null, onTap: _showAllTransactions),
        const SizedBox(height: 14),
        if (recent.isEmpty) _buildEmptyState("No expenses yet", "Add your first expense to start tracking daily spending."),
        ...recent.map(_buildDismissibleItem),
      ],
    );
  }

  Widget _buildTopBar({String? eyebrow, bool compact = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              Image.asset(
                _fullLogoAsset,
                height: compact ? 32 : 42,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (context, error, stackTrace) => Text(
                  "Grain",
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: compact ? 24 : 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildReminderBell(),
      ],
    );
  }

  Widget _buildReminderBell() {
    final urgentCount = _activeUrgentReminderCount();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _iconButton(Icons.notifications_none_rounded, _showSmartReminderCenter),
        if (urgentCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _refinedRed,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _pageBackgroundAlt, width: 1.4),
              ),
              child: Center(
                child: Text(
                  urgentCount > 9 ? "9+" : "$urgentCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final progress = _budgetProgress;
    final budgetColor = _budgetStatusColor();
    final monthDeltaColor = _monthDeltaStatusColor();
    return _glassCard(
      radius: 36,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _metricBlock(
                  "Monthly Total",
                  monthlyTotal,
                  amountSize: 42,
                  subtext: _monthDeltaText(),
                  icon: _monthDeltaTrendIcon(),
                  subtextColor: monthDeltaColor,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.topRight,
                  child: _metricBlock(
                    "Today",
                    todayTotal,
                    amountSize: 28,
                    alignRight: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _labelText("Budget Goal"),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%",
                      style: TextStyle(color: budgetColor, fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text: " of ${_money(_monthlyBudget, decimals: 0)}",
                      style: TextStyle(color: _textMuted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _animatedProgress(progress, color: budgetColor),
        ],
      ),
    );
  }

  Widget _metricBlock(
    String label,
    double value, {
    required double amountSize,
    String? subtext,
    IconData? icon,
    Color? subtextColor,
    bool alignRight = false,
  }) {
    final resolvedSubtextColor = subtextColor ?? _accentColor;
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _labelText(label),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: _animatedMoney(value, fontSize: amountSize),
          ),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 14, color: resolvedSubtextColor),
              if (icon != null) const SizedBox(width: 5),
              Flexible(
                child: Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: resolvedSubtextColor, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction("Add Expense", Icons.add_circle_outline_rounded, () => _goToTab(2), primary: true),
      _QuickAction("Calendar", Icons.calendar_month_rounded, () => _goToTab(1)),
      _QuickAction("Insights", Icons.insights_rounded, () => _goToTab(3)),
      _QuickAction("Export", Icons.ios_share_rounded, _exportCSV),
    ];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final action = actions[index];
          return action.primary
              ? _gradientButton(action.label, action.icon, action.onTap)
              : _glassActionButton(action.label, action.icon, action.onTap);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: actions.length,
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return _glassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      accentEdge: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accentColor.withOpacity(0.25)),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: _accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labelText("Smart Insight", color: _accentColor),
                const SizedBox(height: 8),
                Text(
                  _smartInsight(),
                  style: TextStyle(color: _textPrimary, fontSize: 15, height: 1.45, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarScreen() {
    final selectedTxs = _transactionsForDay(_selectedYear, _selectedMonth, _selectedDay);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildTopBar(eyebrow: "Calendar Spending", compact: true),
        const SizedBox(height: 26),
        _screenTitle("Financial Calendar", "Analyze daily spending across your month."),
        const SizedBox(height: 18),
        _glassCard(
          padding: const EdgeInsets.all(20),
          radius: 22,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelText(_formatMonthYear(DateTime(_selectedYear, _selectedMonth))),
                    const SizedBox(height: 6),
                    _animatedMoney(selectedMonthTotal, fontSize: 32),
                  ],
                ),
              ),
              _monthButton(Icons.chevron_left_rounded, () => _changeMonth(-1)),
              const SizedBox(width: 8),
              _monthButton(Icons.chevron_right_rounded, () => _changeMonth(1)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCalendarGrid(),
        const SizedBox(height: 24),
        _buildSelectedDayTransactions(selectedTxs),
        const SizedBox(height: 18),
        _buildMonthlyLimitCard(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedYear, _selectedMonth);
    final leadingSlots = firstDay.weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    var totalSlots = leadingSlots + daysInMonth;
    if (totalSlots % 7 != 0) totalSlots += 7 - totalSlots % 7;

    final dailyTotals = {
      for (var day = 1; day <= daysInMonth; day++) day: _dayTotal(_selectedYear, _selectedMonth, day),
    };
    final highSpend = dailyTotals.values.fold<double>(0, (a, b) => math.max(a, b).toDouble());

    return _glassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthNames[_selectedMonth],
                style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              PopupMenuButton<int>(
                color: _navySoft,
                initialValue: _selectedYear,
                onSelected: (year) => setState(() => _selectedYear = year),
                itemBuilder: (context) => [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1]
                    .map((year) => PopupMenuItem(value: year, child: Text("$year")))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accentColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("$_selectedYear", style: TextStyle(color: _accentColor, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more_rounded, color: _accentColor, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: _weekdays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(color: _textMuted.withOpacity(0.65), fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalSlots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingSlots + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
              final total = dailyTotals[day] ?? 0;
              final isSelected = day == _selectedDay;
              final isHigh = total > 0 && total == highSpend;
              return _calendarCell(day, total, isSelected, isHigh);
            },
          ),
        ],
      ),
    );
  }

  Widget _calendarCell(int day, double total, bool selected, bool high) {
    final hasSpend = total > 0;
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? _accentColor.withOpacity(0.18)
              : high
                  ? _accentColor.withOpacity(0.11)
                  : Colors.white.withOpacity(_isDarkMode ? 0.035 : 0.55),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? _accentColor
                : high
                    ? _accentColor.withOpacity(0.45)
                    : _glassStroke,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected || high
              ? [BoxShadow(color: _accentColor.withOpacity(0.16), blurRadius: 18, offset: const Offset(0, 8))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$day",
              style: TextStyle(
                color: selected || high ? _accentColor : _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (hasSpend)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(total, decimals: 0),
                  style: TextStyle(color: selected || high ? _accentColor : _textPrimary, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              )
            else
              Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: _textMuted.withOpacity(0.25), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayTransactions(List<Transaction> selectedTxs) {
    final selectedDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    return _glassCard(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelText("Transactions For"),
          const SizedBox(height: 6),
          Text(
            _formatFullDate(selectedDate),
            style: TextStyle(color: _textPrimary, fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          if (selectedTxs.isEmpty)
            _inlineEmpty("No spending recorded on this day.")
          else
            ...selectedTxs.map(_buildCompactTransactionItem),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _gradientButton(
              "Add Transaction",
              Icons.add_rounded,
              () {
                setState(() {
                  _expenseDate = selectedDate;
                  _currentIndex = 2;
                });
              },
              compact: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLimitCard() {
    final budgetColor = _budgetStatusColor();
    return _glassCard(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _labelText("Monthly Limit", color: budgetColor),
              Text(
                "${(_budgetProgress * 100).clamp(0, 999).toStringAsFixed(0)}% Used",
                style: TextStyle(color: budgetColor, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _animatedProgress(_budgetProgress, color: budgetColor),
        ],
      ),
    );
  }

  Widget _buildAddExpenseScreen() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            _iconButton(Icons.close_rounded, () => _goToTab(0)),
            Expanded(
              child: Center(
                child: Text(
                  "Grain",
                  style: TextStyle(color: _accentColor, fontSize: 34, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 46),
          ],
        ),
        const SizedBox(height: 28),
        Center(child: _labelText("Amount")),
        const SizedBox(height: 8),
        _buildAmountInput(),
        const SizedBox(height: 26),
        _glassCard(
          radius: 32,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _labelText("Category"),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 24),
              _labelText("Date"),
              const SizedBox(height: 10),
              _dateSelector(),
              const SizedBox(height: 24),
              _labelText("Notes"),
              const SizedBox(height: 10),
              _noteInput(),
              if (_formError != null) ...[
                const SizedBox(height: 14),
                _validationMessage(_formError!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _gradientButton("Save Expense", Icons.arrow_forward_ios_rounded, _saveExpenseFromForm, fullWidth: true),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Row(
      children: [
        Text(
          "\$",
          style: TextStyle(color: _accentColor.withOpacity(0.72), fontSize: 48, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _amountController,
            autofocus: false,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_formError != null) setState(() => _formError = null);
            },
            style: TextStyle(
              color: _accentColor,
              fontSize: 58,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              hintText: "0.00",
              hintStyle: TextStyle(color: _textMuted.withOpacity(0.28)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category.label == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category.label;
                _selectedIcon = category.icon;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _accentColor.withOpacity(0.18) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? _accentColor : _glassStroke),
                boxShadow: selected ? [BoxShadow(color: _accentColor.withOpacity(0.18), blurRadius: 16)] : null,
              ),
              child: Row(
                children: [
                  Icon(category.icon, color: selected ? _accentColor : _textMuted, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      color: selected ? _accentColor : _textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dateSelector() {
    return GestureDetector(
      onTap: _pickExpenseDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(_isDarkMode ? 0.14 : 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _glassStroke),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _accentColor, size: 20),
            const SizedBox(width: 12),
            Text(
              _formatFullDate(_expenseDate),
              style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Icon(Icons.expand_more_rounded, color: _textMuted),
          ],
        ),
      ),
    );
  }

  Widget _noteInput() {
    return TextField(
      controller: _noteController,
      maxLines: 4,
      style: TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        hintText: "What was this for?",
        hintStyle: TextStyle(color: _textMuted.withOpacity(0.58)),
        filled: true,
        fillColor: Colors.black.withOpacity(_isDarkMode ? 0.14 : 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: _glassStroke)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: _glassStroke)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: _accentColor)),
      ),
    );
  }

  Widget _validationMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _pink.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pink.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: _pink, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: _pink, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpenseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _accentColor,
              surface: _navySoft,
              onSurface: _textOnDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  void _saveExpenseFromForm() {
    final amountValidation = _validateExpenseAmount(_amountController.text);
    if (!amountValidation.isValid) {
      setState(() => _formError = amountValidation.error);
      return;
    }

    final amount = amountValidation.amount!;
    final now = DateTime.now();
    final timestamp = DateTime(
      _expenseDate.year,
      _expenseDate.month,
      _expenseDate.day,
      now.hour,
      now.minute,
      now.second,
    );
    final selectedCategory = _selectedCategoryOption();

    _addTransaction(
      title: selectedCategory.label,
      amount: amount,
      icon: selectedCategory.icon,
      note: _noteController.text.trim(),
      timestamp: timestamp,
    );

    final defaultCategory = _categories.first;
    setState(() {
      _amountController.clear();
      _noteController.clear();
      _formError = null;
      _expenseDate = DateTime.now();
      _selectedCategory = defaultCategory.label;
      _selectedIcon = defaultCategory.icon;
      _selectedYear = timestamp.year;
      _selectedMonth = timestamp.month;
      _selectedDay = timestamp.day;
      _currentIndex = 0;
    });
    _showSnack("Expense saved.");
  }

  _ExpenseAmountValidation _validateExpenseAmount(String input) {
    final rawAmount = input.trim();
    if (rawAmount.isEmpty) {
      return const _ExpenseAmountValidation.invalid("Enter an amount to save this expense.");
    }

    if (rawAmount.contains(',') && !RegExp(r'^\d{1,3}(,\d{3})*(\.\d+)?$').hasMatch(rawAmount)) {
      return const _ExpenseAmountValidation.invalid("Use valid number formatting, for example 12.50.");
    }

    final normalizedAmount = rawAmount.replaceAll(',', '');
    final parsedAmount = double.tryParse(normalizedAmount);
    if (parsedAmount != null && !parsedAmount.isFinite) {
      return const _ExpenseAmountValidation.invalid("Enter a finite amount.");
    }

    if (!RegExp(r'^(?:\d+|\d*\.\d+)$').hasMatch(normalizedAmount)) {
      return const _ExpenseAmountValidation.invalid("Enter a valid number amount.");
    }

    final decimalIndex = normalizedAmount.indexOf('.');
    if (decimalIndex >= 0 && normalizedAmount.length - decimalIndex - 1 > 2) {
      return const _ExpenseAmountValidation.invalid("Use no more than two decimal places.");
    }

    if (parsedAmount == null) {
      return const _ExpenseAmountValidation.invalid("Enter a valid number amount.");
    }

    if (parsedAmount <= 0) {
      return const _ExpenseAmountValidation.invalid("Amount must be greater than zero.");
    }

    return _ExpenseAmountValidation.valid(parsedAmount);
  }

  _CategoryOption _selectedCategoryOption() {
    if (_selectedCategory.trim().isEmpty) return _categories.first;

    for (final category in _categories) {
      if (category.label == _selectedCategory) return category;
    }

    return _categories.first;
  }

  Widget _buildInsightsScreen() {
    final currentMonthTxs = _monthTransactions;
    final categoryTotals = _categoryTotals(currentMonthTxs);
    final topCategory = _topCategory(categoryTotals);
    final topExpense = currentMonthTxs.isEmpty
        ? null
        : currentMonthTxs.reduce((a, b) => a.amount >= b.amount ? a : b);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildTopBar(eyebrow: "Insights", compact: true),
        const SizedBox(height: 24),
        _screenTitle("Financial Intelligence", "Local spending signals from your Grain data."),
        const SizedBox(height: 18),
        _glassCard(
          radius: 26,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _labelText("Total Spending - ${_monthNames[DateTime.now().month]}"),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _animatedMoney(monthlyTotal, fontSize: 42)),
                  _deltaPill(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildInsightHighlights(topCategory, topExpense),
        const SizedBox(height: 18),
        _buildCategoryAllocation(categoryTotals),
        const SizedBox(height: 18),
        _buildMonthComparison(),
        const SizedBox(height: 28),
        Text(
          "Smart Insights",
          style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        _buildSmartInsightCarousel(),
        const SizedBox(height: 28),
        _sectionHeader("Significant Expenses", trailing: transactions.length > 4 ? "View all" : null, onTap: _showAllTransactions),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          _buildEmptyState("No large expenses yet", "Your most important expenses will appear here.")
        else
          ...transactions
              .toList()
              .sortedByAmount()
              .take(4)
              .map(_buildTransactionItem),
      ],
    );
  }

  Widget _buildInsightHighlights(MapEntry<String, double>? topCategory, Transaction? topExpense) {
    final budgetStatus = _budgetProgress < 0.75
        ? "Healthy"
        : _budgetProgress < 1
            ? "Watch"
            : "Over";
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 520;
        final children = [
          _smallInsightCard(
            icon: Icons.account_balance_wallet_outlined,
            label: "Top Category",
            title: topCategory?.key ?? "None yet",
            detail: topCategory == null ? "Add expenses to calculate" : "${_money(topCategory.value)} this month",
            color: _amber,
          ),
          _smallInsightCard(
            icon: topExpense?.icon ?? Icons.shopping_bag_outlined,
            label: "Largest Expense",
            title: topExpense?.title ?? "None yet",
            detail: topExpense == null ? "Waiting for data" : "${_money(topExpense.amount)} - ${_formatShortDate(topExpense.timestamp)}",
            color: _blue,
          ),
          _smallInsightCard(
            icon: Icons.favorite_border_rounded,
            label: "Budget Health",
            title: budgetStatus,
            detail: "${(_budgetProgress * 100).clamp(0, 999).toStringAsFixed(0)}% of budget used",
            color: _budgetStatusColor(),
            detailColor: _budgetStatusColor(),
          ),
        ];

        if (wide) {
          return Row(children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: child))).toList());
        }

        return Column(
          children: [
            Row(children: [Expanded(child: children[0]), const SizedBox(width: 12), Expanded(child: children[1])]),
            const SizedBox(height: 12),
            children[2],
          ],
        );
      },
    );
  }

  Widget _smallInsightCard({
    required IconData icon,
    required String label,
    required String title,
    required String detail,
    required Color color,
    Color? detailColor,
  }) {
    return _glassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Flexible(child: _labelText(label, color: color, textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w900, height: 1.1),
          ),
          const SizedBox(height: 8),
          Text(detail, style: TextStyle(color: detailColor ?? _textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCategoryAllocation(Map<String, double> categoryTotals) {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(4).toList();
    final colors = [_accentColor, _blue, _amber, _pink];
    return _glassCard(
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelText("Category Allocation"),
          const SizedBox(height: 18),
          if (topEntries.isEmpty)
            _inlineEmpty("No monthly categories yet.")
          else ...[
            Center(
              child: SizedBox(
                width: 190,
                height: 190,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: topEntries.map((e) => e.value).toList(),
                    colors: colors,
                    trackColor: _isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _compactMoney(monthlyTotal),
                          style: TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        _labelText("Total"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              runSpacing: 10,
              spacing: 16,
              children: topEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final share = monthlyTotal == 0 ? 0 : data.value / monthlyTotal * 100;
                return SizedBox(
                  width: 142,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: colors[index], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${data.key} (${share.toStringAsFixed(0)}%)",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthComparison() {
    final maxValue = math.max(math.max(monthlyTotal, previousMonthTotal), 1).toDouble();
    return _glassCard(
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _labelText("Month-Over-Month")),
              Text(_monthDeltaText(), style: TextStyle(color: _monthDeltaStatusColor(), fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 22),
          _comparisonBar("Previous", previousMonthTotal, maxValue, Colors.white.withOpacity(0.18)),
          const SizedBox(height: 14),
          _comparisonBar("Current", monthlyTotal, maxValue, _accentColor),
        ],
      ),
    );
  }

  Widget _comparisonBar(String label, double value, double max, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(label, style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value / max),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, ratio, _) => LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: color,
                backgroundColor: Colors.white.withOpacity(_isDarkMode ? 0.06 : 0.14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 76,
          child: Text(
            _money(value, decimals: 0),
            textAlign: TextAlign.right,
            style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartInsightCarousel() {
    final insights = _insightCards();
    final textScaler = MediaQuery.textScalerOf(context);
    final bodyHeight = textScaler.scale(16) * 1.35 * 3;
    final actionHeight = textScaler.scale(11) * 1.35;
    final carouselHeight = math.max(
      198.0,
      20 + 42 + 18 + bodyHeight + 12 + actionHeight + 20,
    ).toDouble();
    return SizedBox(
      height: carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final insight = insights[index];
          return SizedBox(
            width: 280,
            child: _glassCard(
              radius: 22,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: insight.color.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(insight.icon, color: insight.color, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    insight.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _textPrimary, fontSize: 16, height: 1.35, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    insight.action.toUpperCase(),
                    style: TextStyle(color: insight.color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildTopBar(eyebrow: "Settings", compact: true),
        const SizedBox(height: 28),
        _settingsSection("Visual Appearance", [
          _settingsRow(
            icon: Icons.dark_mode_rounded,
            title: "Dark Mode",
            trailing: Switch(
              value: _isDarkMode,
              activeColor: _accentColor,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                _saveData();
              },
            ),
          ),
          _accentPickerRow(),
        ]),
        const SizedBox(height: 24),
        _settingsSection("Planning", [
          _settingsRow(
            icon: Icons.savings_outlined,
            title: "Monthly Budget",
            subtitle: "${_money(_monthlyBudget)} set",
            onTap: _showBudgetDialog,
            trailing: Icon(Icons.chevron_right_rounded, color: _textMuted),
          ),
        ]),
        const SizedBox(height: 24),
        _settingsSection("Data Management", [
          _settingsRow(
            icon: Icons.download_rounded,
            title: "Export as CSV",
            onTap: _exportCSV,
            trailing: Icon(Icons.chevron_right_rounded, color: _textMuted),
          ),
          _settingsDivider(),
          _settingsRow(
            icon: Icons.info_outline_rounded,
            title: "About Grain",
            onTap: _showAboutGrain,
            trailing: Icon(Icons.chevron_right_rounded, color: _textMuted),
          ),
        ]),
        const SizedBox(height: 34),
        Center(
          child: Column(
            children: [
              Image.asset(
                _fullLogoAsset,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(
                  "Grain",
                  style: TextStyle(color: _accentColor, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Money is accumulated little by little, like grains.",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textMuted.withOpacity(0.72), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0),
              ),
              const SizedBox(height: 6),
              Text(
                "Made by Jerry Chen",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textMuted.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: _labelText(title),
        ),
        _glassCard(
          radius: 20,
          padding: const EdgeInsets.all(6),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _accentColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _accentPickerRow() {
    final colors = [_defaultAccent, _blue, _amber, _pink, const Color(0xFFB388FF)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: _accentColor, size: 22),
              const SizedBox(width: 14),
              Text("Accent Colour", style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: colors.map((color) {
              final selected = color == _accentColor;
              return GestureDetector(
                onTap: () {
                  setState(() => _accentColor = color);
                  _saveData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? _textPrimary : Colors.transparent, width: 2),
                    boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 16)] : null,
                  ),
                  child: selected ? const Icon(Icons.check_rounded, color: Color(0xFF00201A), size: 20) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _settingsDivider() => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 14), color: _glassStroke);

  void _showBudgetDialog() {
    _budgetController.text = _monthlyBudget.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? _navySoft : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Monthly Budget", style: TextStyle(color: _textPrimary)),
        content: TextField(
          controller: _budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            prefixText: "\$ ",
            prefixStyle: TextStyle(color: _accentColor, fontWeight: FontWeight.w900),
            hintText: "650",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: _textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: const Color(0xFF00201A)),
            onPressed: () {
              final value = double.tryParse(_budgetController.text.trim());
              if (value == null || value <= 0) {
                _showSnack("Enter a valid monthly budget.");
                return;
              }
              setState(() => _monthlyBudget = value);
              _saveData();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAboutGrain() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? _navySoft : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("About Grain", style: TextStyle(color: _textPrimary)),
        content: Text(
          "Grain is a lightweight local-first personal expense tracker for daily spending in AUD. Every small expense matters.",
          style: TextStyle(color: _textMuted, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: _accentColor))),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      _NavItem(Icons.home_rounded, "Home"),
      _NavItem(Icons.calendar_month_rounded, "Calendar"),
      _NavItem(Icons.add_rounded, "Add"),
      _NavItem(Icons.insights_rounded, "Insights"),
      _NavItem(Icons.settings_outlined, "Settings"),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: (_isDarkMode ? _navySoft : Colors.white).withOpacity(_isDarkMode ? 0.72 : 0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _glassStroke),
              boxShadow: [
                BoxShadow(color: _accentColor.withOpacity(0.12), blurRadius: 28, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final selected = _currentIndex == index;
                final isAdd = index == 2;
                return GestureDetector(
                  onTap: () => _goToTab(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isAdd ? 58 : 52,
                    height: isAdd ? 58 : 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isAdd && selected ? _accentGradient : null,
                      color: selected && !isAdd ? _accentColor.withOpacity(0.16) : Colors.transparent,
                      boxShadow: selected
                          ? [BoxShadow(color: _accentColor.withOpacity(0.26), blurRadius: 20, offset: const Offset(0, 8))]
                          : null,
                    ),
                    child: Icon(
                      item.icon,
                      color: selected
                          ? isAdd
                              ? const Color(0xFF00201A)
                              : _accentColor
                          : _textMuted.withOpacity(0.78),
                      size: isAdd ? 30 : 24,
                      semanticLabel: item.label,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleItem(Transaction t) {
    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) => _confirmDelete(t),
      onDismissed: (_) => _deleteTransaction(t.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: _pink.withOpacity(0.72), borderRadius: BorderRadius.circular(22)),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      child: _buildTransactionItem(t),
    );
  }

  Future<bool> _confirmDelete(Transaction t) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? _navySoft : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("Delete Expense?", style: TextStyle(color: _textPrimary)),
        content: Text("Remove ${t.title} for ${_money(t.amount)}?", style: TextStyle(color: _textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: TextStyle(color: _textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildTransactionItem(Transaction t) {
    return GestureDetector(
      onTap: () => _showDetailDialog(t),
      child: _glassCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _transactionIcon(t.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${t.notes.isEmpty ? "Expense" : t.notes} - ${_formatShortDate(t.timestamp)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "-${_money(t.amount)}",
              style: TextStyle(color: _pink, fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTransactionItem(Transaction t) {
    return GestureDetector(
      onTap: () => _showDetailDialog(t),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            _transactionIcon(t.icon, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w900)),
                  Text(
                    t.notes.isEmpty ? "Expense" : t.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _textMuted.withOpacity(0.72), fontSize: 12),
                  ),
                ],
              ),
            ),
            Text("-${_money(t.amount)}", style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _transactionIcon(IconData icon, {double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2D3449) : const Color(0xFFE1F0EE),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: _glassStroke),
      ),
      child: Icon(icon, color: _accentColor, size: size * 0.46),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    EdgeInsetsGeometry? margin,
    double radius = 24,
    bool accentEdge = false,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _glassFill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: _glassStroke),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDarkMode ? 0.24 : 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: accentEdge
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 3, decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(99))),
                        const SizedBox(width: 16),
                        Expanded(child: child),
                      ],
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }

  Widget _gradientButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool compact = false,
    bool fullWidth = false,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 48 : 62,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
        decoration: BoxDecoration(
          gradient: _accentGradient,
          borderRadius: BorderRadius.circular(compact ? 18 : 24),
          boxShadow: [
            BoxShadow(color: _accentColor.withOpacity(0.26), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00201A), size: compact ? 20 : 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF00201A), fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: button);
    return button;
  }

  Widget _glassActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: _glassCard(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accentColor),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.68),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _glassStroke),
        ),
        child: Icon(icon, color: _textPrimary, size: 22),
      ),
    );
  }

  Widget _animatedMoney(double value, {double fontSize = 32}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => Text(
        _money(animatedValue),
        maxLines: 1,
        style: TextStyle(
          color: _accentColor,
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _animatedProgress(double progress, {Color? color}) {
    final progressColor = color ?? _accentColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 9,
          backgroundColor: Colors.white.withOpacity(_isDarkMode ? 0.08 : 0.18),
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      ),
    );
  }

  Widget _labelText(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style: TextStyle(
        color: color ?? _textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _sectionHeader(String title, {String? trailing, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              trailing.toUpperCase(),
              style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0),
            ),
          ),
      ],
    );
  }

  Widget _screenTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: _textPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: _textMuted, fontSize: 15, height: 1.35)),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return _glassCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: _accentColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: _textMuted, fontSize: 13, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }

  Widget _deltaPill() {
    final percent = _monthOverMonthPercent();
    final isIncrease = percent != null && percent > 0;
    final statusColor = _monthDeltaStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(_monthDeltaText(short: true), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _monthButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accentColor.withOpacity(0.18)),
        ),
        child: Icon(icon, color: _accentColor),
      ),
    );
  }

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        _formError = null;
      }
    });
  }

  void _changeMonth(int delta) {
    final next = DateTime(_selectedYear, _selectedMonth + delta);
    setState(() {
      _selectedYear = next.year;
      _selectedMonth = next.month;
      final days = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
      _selectedDay = math.min(_selectedDay, days).toInt();
    });
  }

  void _showAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: _pageBackground,
          appBar: AppBar(
            backgroundColor: _pageBackgroundAlt,
            title: const Text("History"),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: transactions.isEmpty
                ? [_buildEmptyState("No history", "Saved expenses will appear here.")]
                : transactions.map(_buildDismissibleItem).toList(),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(Transaction item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? _navySoft : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(item.title, style: TextStyle(color: _textPrimary)),
        content: Text(
          "Amount: ${_money(item.amount)}\nDate: ${_formatShortDate(item.timestamp)}\nNote: ${item.notes.isEmpty ? "No note" : item.notes}",
          style: TextStyle(color: _textMuted, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: TextStyle(color: _accentColor))),
        ],
      ),
    );
  }

  void _showSmartReminderCenter() {
    final reminders = _smartReminders();
    _markRemindersSeen(reminders);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            decoration: BoxDecoration(
              color: (_isDarkMode ? _navySoft : Colors.white).withOpacity(_isDarkMode ? 0.94 : 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: _glassStroke),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: _textMuted.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _accentColor.withOpacity(0.25)),
                        ),
                        child: Icon(Icons.notifications_active_outlined, color: _accentColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Smart Reminders",
                              style: TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Local signals from your spending data",
                              style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (reminders.isEmpty)
                    _buildEmptyReminderState()
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: reminders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildReminderTile(reminders[index]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyReminderState() {
    final title = transactions.isEmpty ? "No spending reminders yet" : "No new reminders";
    final message = transactions.isEmpty
        ? "Add your first expense to let Grain generate insights."
        : "You are all caught up. Grain will surface budget and spending signals here when they matter.";

    return _glassCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: _refinedGreen, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(color: _textMuted, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(_SmartReminder reminder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_isDarkMode ? 0.045 : 0.64),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _glassStroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reminder.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(reminder.icon, color: reminder.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  reminder.message,
                  style: TextStyle(color: _textMuted, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _navySoft,
      ),
    );
  }

  double get _budgetProgress => _monthlyBudget <= 0 ? 0 : monthlyTotal / _monthlyBudget;

  Color _budgetStatusColor() {
    return _budgetProgress > 1 ? _refinedRed : _refinedGreen;
  }

  Color _monthDeltaStatusColor() {
    final percent = _monthOverMonthPercent();
    if (percent != null && percent > 100) return _refinedRed;
    return _refinedGreen;
  }

  IconData _monthDeltaTrendIcon() {
    final percent = _monthOverMonthPercent();
    return percent != null && percent < 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded;
  }

  int _activeUrgentReminderCount() {
    return _smartReminders().where((reminder) => reminder.isUrgent).length;
  }

  void _markRemindersSeen(List<_SmartReminder> reminders) {
    if (reminders.isEmpty) return;
    final nextSeenIds = {..._seenReminderIds, ...reminders.map((reminder) => reminder.id)};
    setState(() => _seenReminderIds = nextSeenIds);
    _saveSeenReminderIds();
  }

  Future<void> _saveSeenReminderIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('grain_seen_reminders_v1', _seenReminderIds.toList()..sort());
  }

  List<_SmartReminder> _smartReminders() {
    final monthItems = _monthTransactions;
    if (transactions.isEmpty) return const [];

    final now = DateTime.now();
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final reminders = <_SmartReminder>[];
    final topCategory = _topCategory(_categoryTotals(monthItems));
    final highestDay = _highestSpendingDay(monthItems);
    final monthDifference = monthlyTotal - previousMonthTotal;
    final isOverBudget = _monthlyBudget > 0 && monthlyTotal > _monthlyBudget;

    if (isOverBudget) {
      reminders.add(
        _SmartReminder(
          id: "$monthKey-budget-over",
          title: "Monthly budget exceeded",
          message: "You are ${_money(monthlyTotal - _monthlyBudget)} over your monthly budget.",
          icon: Icons.warning_amber_rounded,
          color: _refinedRed,
          priority: 0,
          isUrgent: true,
        ),
      );
    }

    if (monthDifference > 0) {
      reminders.add(
        _SmartReminder(
          id: "$monthKey-month-higher",
          title: "Spending is higher than last month",
          message: "Your spending this month is now higher than last month. You have spent ${_money(monthDifference)} more than last month.",
          icon: Icons.trending_up_rounded,
          color: _refinedRed,
          priority: 1,
          isUrgent: true,
        ),
      );
    }

    if (topCategory != null) {
      reminders.add(
        _SmartReminder(
          id: "$monthKey-top-category-${topCategory.key}",
          title: isOverBudget ? "Budget pressure source" : "Top category this month",
          message: isOverBudget
              ? "Your highest spending category this month is ${topCategory.key}, which may be the main reason for the budget pressure."
              : "${topCategory.key} is currently your top spending category this month.",
          icon: Icons.category_outlined,
          color: _accentColor,
          priority: 2,
        ),
      );
    }

    if (highestDay != null) {
      final dayKey =
          "${highestDay.date.year}-${highestDay.date.month.toString().padLeft(2, '0')}-${highestDay.date.day.toString().padLeft(2, '0')}";
      reminders.add(
        _SmartReminder(
          id: "$monthKey-highest-day-$dayKey",
          title: "Highest spending day",
          message:
              "Your highest spending day this month was ${_formatShortDate(highestDay.date)}, with ${_money(highestDay.total, decimals: 0)} spent.",
          icon: Icons.calendar_today_rounded,
          color: _blue,
          priority: 3,
        ),
      );
    }

    if (monthDifference < 0) {
      reminders.add(
        _SmartReminder(
          id: "$monthKey-month-lower",
          title: "Spending is lower than last month",
          message: "Good progress. You are currently spending ${_money(monthDifference.abs())} less than last month.",
          icon: Icons.trending_down_rounded,
          color: _refinedGreen,
          priority: 4,
        ),
      );
    }

    reminders.sort((a, b) => a.priority.compareTo(b.priority));
    return reminders;
  }

  double _dayTotal(int year, int month, int day) {
    return _sumTransactions(
      transactions.where((t) => t.timestamp.year == year && t.timestamp.month == month && t.timestamp.day == day),
    );
  }

  List<Transaction> _transactionsForDay(int year, int month, int day) {
    return transactions
        .where((t) => t.timestamp.year == year && t.timestamp.month == month && t.timestamp.day == day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Map<String, double> _categoryTotals(List<Transaction> items) {
    final totals = <String, double>{};
    for (final item in items) {
      totals[item.title] = (totals[item.title] ?? 0) + item.amount;
    }
    return totals;
  }

  MapEntry<String, double>? _topCategory(Map<String, double> totals) {
    if (totals.isEmpty) return null;
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  Transaction? _largestTransactionIn(List<Transaction> items) {
    if (items.isEmpty) return null;
    return items.reduce((a, b) => a.amount >= b.amount ? a : b);
  }

  _DailySpending? _highestSpendingDay(List<Transaction> items) {
    if (items.isEmpty) return null;

    final dailyTotals = <DateTime, double>{};
    for (final item in items) {
      final day = _dateOnly(item.timestamp);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + item.amount;
    }

    if (dailyTotals.isEmpty) return null;
    final highestDay = dailyTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return _DailySpending(highestDay.key, highestDay.value);
  }

  _RepeatedPurchaseInsight? _repeatedSmallPurchases(List<Transaction> items) {
    final grouped = <String, List<Transaction>>{};
    for (final item in items) {
      if (item.amount <= 0 || item.amount > 25) continue;
      final label = item.title.trim().isEmpty ? "Unlabeled" : item.title.trim();
      grouped.putIfAbsent(label, () => []).add(item);
    }

    _RepeatedPurchaseInsight? best;
    for (final entry in grouped.entries) {
      if (entry.value.length < 3) continue;
      final total = _sumTransactions(entry.value);
      final candidate = _RepeatedPurchaseInsight(
        label: entry.key,
        count: entry.value.length,
        total: total,
        average: total / entry.value.length,
      );
      if (best == null || candidate.total > best.total) best = candidate;
    }

    return best;
  }

  _BudgetProjection? _budgetProjectionForCurrentMonth() {
    if (_monthlyBudget <= 0 || monthlyTotal <= 0) return null;

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final elapsedDays = math.max(now.day, 1);
    final dailyAverage = monthlyTotal / elapsedDays;
    final projectedTotal = dailyAverage * daysInMonth;

    return _BudgetProjection(
      projectedTotal: projectedTotal,
      dailyAverage: dailyAverage,
      remainingDays: math.max(daysInMonth - now.day, 0).toInt(),
    );
  }

  double? _monthOverMonthPercent() {
    if (previousMonthTotal <= 0) return null;
    return (monthlyTotal - previousMonthTotal) / previousMonthTotal * 100;
  }

  String _smartInsight() {
    final monthItems = _monthTransactions;
    if (transactions.isEmpty) {
      return "Start by adding a few expenses. Grain will surface local spending patterns once it has data.";
    }
    if (monthItems.isEmpty) {
      return "No spending recorded this month yet. Add an expense to activate monthly insights.";
    }

    final projection = _budgetProjectionForCurrentMonth();
    if (_budgetProgress > 1) {
      final overAmount = monthlyTotal - _monthlyBudget;
      return "You are ${_money(overAmount)} over this month's budget. Pause flexible purchases first.";
    }
    if (projection != null && projection.projectedTotal > _monthlyBudget * 1.05) {
      return "At this pace, you may finish near ${_money(projection.projectedTotal)} this month. That is above your ${_money(_monthlyBudget)} budget.";
    }

    final monthDelta = _monthOverMonthPercent();
    if (monthDelta != null && monthDelta <= -5) {
      return "Nice work. Spending is down ${monthDelta.abs().toStringAsFixed(0)}% compared with last month.";
    }

    final repeated = _repeatedSmallPurchases(monthItems);
    if (repeated != null) {
      return "${repeated.label} has ${repeated.count} small purchases this month, totaling ${_money(repeated.total)} at ${_money(repeated.average)} on average.";
    }

    final highestDay = _highestSpendingDay(monthItems);
    if (highestDay != null && monthItems.length > 1) {
      return "Your highest spending day this month was ${_formatShortDate(highestDay.date)} at ${_money(highestDay.total)}.";
    }

    final top = _topCategory(_categoryTotals(monthItems));
    if (top == null) {
      return "No spending recorded this month yet. Add an expense to activate monthly insights.";
    }
    final remaining = (_monthlyBudget - monthlyTotal).clamp(0, double.infinity).toDouble();
    return "${top.key} is your highest category this month. You still have ${_money(remaining)} before reaching your monthly budget.";
  }

  List<_SmartInsight> _insightCards() {
    final monthItems = _monthTransactions;
    final top = _topCategory(_categoryTotals(monthItems));
    final largest = _largestTransactionIn(monthItems);
    final highestDay = _highestSpendingDay(monthItems);
    final repeated = _repeatedSmallPurchases(monthItems);
    final projection = _budgetProjectionForCurrentMonth();
    final monthDelta = _monthOverMonthPercent();
    final remaining = _monthlyBudget - monthlyTotal;

    if (transactions.isEmpty) {
      return [
        _SmartInsight(
          Icons.lightbulb_outline_rounded,
          "Add a few expenses and Grain will build local spending signals for you.",
          "Start tracking",
          _accentColor,
        ),
        _SmartInsight(
          Icons.lock_outline_rounded,
          "Insights run on this device using your saved transactions only.",
          "Local only",
          _blue,
        ),
        _SmartInsight(
          Icons.savings_outlined,
          "Set a monthly budget to unlock budget health and projection insights.",
          "Budget setup",
          _amber,
        ),
      ];
    }

    if (monthItems.isEmpty) {
      return [
        _SmartInsight(
          Icons.calendar_month_rounded,
          "No spending has been recorded for this month yet.",
          "New month",
          _accentColor,
        ),
        _SmartInsight(
          Icons.trending_down_rounded,
          previousMonthTotal > 0
              ? "Last month ended at ${_money(previousMonthTotal)}. This month is still clean."
              : "Add this month's first expense to compare trends.",
          "Monthly reset",
          _blue,
        ),
        _SmartInsight(
          Icons.add_circle_outline_rounded,
          "Your next saved expense will update Home, Calendar, and Insights instantly.",
          "Ready",
          _amber,
        ),
      ];
    }

    final cards = <_SmartInsight>[
      _SmartInsight(
        Icons.lightbulb_outline_rounded,
        top == null
            ? "Add expenses for a clearer category forecast."
            : "${top.key} leads this month at ${_money(top.value)}.",
        "Top category",
        _accentColor,
      ),
      _SmartInsight(
        Icons.savings_outlined,
        _budgetHealthInsight(remaining, projection),
        "Budget health",
        remaining >= 0 ? _blue : _pink,
      ),
    ];

    if (monthDelta != null) {
      cards.add(
        _SmartInsight(
          monthDelta <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
          monthDelta <= 0
              ? "Spending is down ${monthDelta.abs().toStringAsFixed(0)}% from last month. Good control."
              : "Spending is up ${monthDelta.toStringAsFixed(0)}% from last month. Watch flexible categories.",
          "Month over month",
          monthDelta <= 0 ? _accentColor : _amber,
        ),
      );
    }

    if (highestDay != null) {
      cards.add(
        _SmartInsight(
          Icons.calendar_today_rounded,
          "${_formatShortDate(highestDay.date)} is your highest spending day this month at ${_money(highestDay.total)}.",
          "Peak day",
          _blue,
        ),
      );
    }

    if (repeated != null) {
      cards.add(
        _SmartInsight(
          Icons.repeat_rounded,
          "${repeated.count} small ${repeated.label} purchases total ${_money(repeated.total)} this month, averaging ${_money(repeated.average)}.",
          "Small spends",
          _amber,
        ),
      );
    }

    cards.add(
      _SmartInsight(
        Icons.receipt_long_outlined,
        largest == null
            ? "Largest single expense will appear after this month has spending."
            : "Largest single expense this month: ${largest.title} at ${_money(largest.amount)}.",
        "Largest expense",
        _pink,
      ),
    );

    return cards;
  }

  String _budgetHealthInsight(double remaining, _BudgetProjection? projection) {
    if (remaining < 0) {
      return "You are ${_money(remaining.abs())} over your monthly budget.";
    }
    if (projection != null && projection.projectedTotal > _monthlyBudget * 1.05) {
      return "At ${_money(projection.dailyAverage)}/day, projected spend is ${_money(projection.projectedTotal)} with ${projection.remainingDays} days left.";
    }
    if (projection != null && projection.projectedTotal < _monthlyBudget * 0.85) {
      return "Current pace projects ${_money(projection.projectedTotal)}, comfortably under budget.";
    }
    return "You have ${_money(remaining)} left before your budget cap.";
  }

  IconData _iconFromCodePoint(int codePoint) {
    final knownIcons = [
      ..._categories.map((category) => category.icon),
      Icons.fastfood,
      Icons.shopping_cart,
      Icons.directions_car,
      Icons.school_rounded,
      Icons.home_rounded,
      Icons.medical_services,
      Icons.shopping_bag_rounded,
      Icons.shopping_bag_outlined,
    ];

    for (final icon in knownIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.shopping_bag_outlined;
  }

  DateTime _loadTransactionTimestamp(Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    if (rawTimestamp is String) {
      final parsedTimestamp = DateTime.tryParse(rawTimestamp);
      if (parsedTimestamp != null) return parsedTimestamp;
    }

    final recoveredDate = _tryParseAbsoluteSavedDate(map['date']);
    if (recoveredDate != null) return recoveredDate;

    return _unknownLegacyDate;
  }

  DateTime? _tryParseAbsoluteSavedDate(Object? rawDate) {
    if (rawDate is! String) return null;
    final value = rawDate.trim();
    if (value.isEmpty) return null;

    final lowerValue = value.toLowerCase();
    if (lowerValue.startsWith("today") || lowerValue.startsWith("yesterday")) {
      return null;
    }

    final directDate = DateTime.tryParse(value);
    if (directDate != null && RegExp(r'\d{4}').hasMatch(value)) {
      return directDate;
    }

    final pieces = value.replaceAll(',', ' ').split(RegExp(r'\s+')).where((piece) => piece.isNotEmpty).toList();
    if (pieces.length < 3) return null;

    final month = _monthIndexFromName(pieces[0]);
    final day = int.tryParse(pieces[1]);
    final year = int.tryParse(pieces[2]);
    if (month == null || day == null || year == null) return null;

    return DateTime(year, month, day);
  }

  int? _monthIndexFromName(String value) {
    final normalized = value.toLowerCase();
    for (var i = 1; i < _monthNames.length; i++) {
      final month = _monthNames[i].toLowerCase();
      if (month == normalized || month.substring(0, 3) == normalized) return i;
    }
    return null;
  }

  String _monthDeltaText({bool short = false}) {
    final delta = monthlyTotal - previousMonthTotal;
    if (previousMonthTotal == 0) {
      if (monthlyTotal == 0) return short ? "0%" : "0% vs last month";
      return short ? "New" : "New month data";
    }
    final percent = delta / previousMonthTotal * 100;
    final sign = percent >= 0 ? "+" : "";
    return short ? "$sign${percent.toStringAsFixed(0)}%" : "$sign${percent.toStringAsFixed(0)}% vs last month";
  }

  String _money(double value, {int decimals = 2}) => "\$${value.toStringAsFixed(decimals)}";

  String _compactMoney(double value) {
    if (value.abs() >= 1000) return "\$${(value / 1000).toStringAsFixed(1)}k";
    return _money(value, decimals: 0);
  }

  String _formatStoredTransactionDate(DateTime date) {
    if (_isUnknownLegacyDate(date)) return "unknown";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatShortDate(DateTime date) {
    if (_isUnknownLegacyDate(date)) return "Date unknown";

    final today = _dateOnly(DateTime.now());
    final transactionDate = _dateOnly(date);
    if (transactionDate == today) return "Today";
    if (transactionDate == today.subtract(const Duration(days: 1))) return "Yesterday";

    final shortDate = "${_monthNames[date.month].substring(0, 3)} ${date.day}";
    return date.year == today.year ? shortDate : "$shortDate, ${date.year}";
  }

  String _formatFullDate(DateTime date) {
    if (_isUnknownLegacyDate(date)) return "Date unknown";
    return "${_monthNames[date.month]} ${date.day}, ${date.year}";
  }

  String _formatMonthYear(DateTime date) => "${_monthNames[date.month]} ${date.year}";

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isUnknownLegacyDate(DateTime date) => _dateOnly(date) == _unknownLegacyDate;

  static const List<String> _monthNames = [
    "",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  static const List<String> _weekdays = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

  static final DateTime _unknownLegacyDate = DateTime(1970, 1, 1);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _QuickAction(this.label, this.icon, this.onTap, {this.primary = false});
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

class _SmartInsight {
  final IconData icon;
  final String text;
  final String action;
  final Color color;

  const _SmartInsight(this.icon, this.text, this.action, this.color);
}

class _SmartReminder {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final int priority;
  final bool isUrgent;

  const _SmartReminder({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.priority,
    this.isUrgent = false,
  });
}

class _DailySpending {
  final DateTime date;
  final double total;

  const _DailySpending(this.date, this.total);
}

class _RepeatedPurchaseInsight {
  final String label;
  final int count;
  final double total;
  final double average;

  const _RepeatedPurchaseInsight({
    required this.label,
    required this.count,
    required this.total,
    required this.average,
  });
}

class _BudgetProjection {
  final double projectedTotal;
  final double dailyAverage;
  final int remainingDays;

  const _BudgetProjection({
    required this.projectedTotal,
    required this.dailyAverage,
    required this.remainingDays,
  });
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height).toDouble() / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, math.max(0.05, sweep - 0.035).toDouble(), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors || oldDelegate.trackColor != trackColor;
  }
}

extension _TransactionSorting on List<Transaction> {
  List<Transaction> sortedByAmount() {
    return List<Transaction>.from(this)..sort((a, b) => b.amount.compareTo(a.amount));
  }
}
