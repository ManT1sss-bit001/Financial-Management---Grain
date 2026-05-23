import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:convert';

void main() => runApp(const GrainApp());

class GrainApp extends StatelessWidget {
  const GrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const HomePage(),
    );
  }
}

// --- 数据结构 ---
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
    this.notes = ""
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; 
  int? _touchedIndex; 
  int _selectedYear = 2026; 
  int _selectedMonth = DateTime.now().month;
  String _timeRange = "This Year";
  String _statsTimeRange = "This Month"; // 专门给统计页用的时间范围 

  // --- [修改] 补全缺少的索引和图标控制变量以消除红线 ---
  int _selectedCardIndex = 0; 
  int _selectedMoodIndex = 0;
  IconData _selectedIcon = Icons.shopping_bag_rounded; 

  // --- 颜色系统 ---
  Color _accentColor = const Color(0xFF5AC8FA); 
  List<Color> _bgColors = [const Color(0xFF1C1C1E), const Color(0xFF000000)];
  List<Color> _cardGradients = [const Color(0xFF4F46E5), const Color(0xFF9333EA), const Color(0xFFEC4899)];

  late List<Transaction> transactions;

  @override
  void initState() {
    super.initState();
    transactions = []; 
    _loadData();       
  }

  // --- 综合持久化：保存所有数据与视觉配置 ---
  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. 序列化账单列表
    List<Map<String, dynamic>> jsonList = transactions.map((t) => {
      'id': t.id,
      'title': t.title,
      'amount': t.amount,
      'date': t.date,
      'icon': t.icon.codePoint,
      'notes': t.notes,
      'timestamp': t.timestamp.toIso8601String(),
    }).toList();

    // 2. 写入硬盘
    await prefs.setString('grain_data_v1', jsonEncode(jsonList)); // 保存账单
    await prefs.setInt('user_color_pref', _accentColor.value);      // 保存主色调
    await prefs.setInt('user_card_index', _selectedCardIndex);   // 保存卡片渐变索引
    await prefs.setInt('user_mood_index', _selectedMoodIndex);   // 保存背景氛围索引
    
    // [添加] 确保颜色列表也被保存，防止直接覆盖带来的不匹配
    await prefs.setStringList('user_card_colors', _cardGradients.map((c) => c.value.toString()).toList());
    await prefs.setStringList('user_bg_colors', _bgColors.map((c) => c.value.toString()).toList());

    debugPrint("【系统】账单及所有视觉配置已同步至本地存储");
  }

  // --- 综合持久化：加载所有数据与视觉配置 ---
  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. 加载并还原账单
    String? savedData = prefs.getString('grain_data_v1');
    if (savedData != null) {
      List<dynamic> l = jsonDecode(savedData);
      setState(() {
        transactions = l.map((item) => Transaction(
          id: item['id'],
          title: item['title'],
          amount: (item['amount'] as num).toDouble(),
          date: item['date'],
          icon: IconData(item['icon'], fontFamily: 'MaterialIcons'),
          notes: item['notes'] ?? "",
          timestamp: DateTime.parse(item['timestamp']),
        )).toList();
      });
    }

    // 2. 加载并还原视觉设置
    setState(() {
      // 还原主色调
      int? colorValue = prefs.getInt('user_color_pref');
      if (colorValue != null) _accentColor = Color(colorValue);

      // 还原卡片渐变
      int? cardIdx = prefs.getInt('user_card_index');
      if (cardIdx != null) _selectedCardIndex = cardIdx;
      List<String>? cardClrs = prefs.getStringList('user_card_colors');
      if (cardClrs != null) _cardGradients = cardClrs.map((s) => Color(int.parse(s))).toList();

      // 还原背景氛围
      int? moodIdx = prefs.getInt('user_mood_index');
      if (moodIdx != null) _selectedMoodIndex = moodIdx;
      List<String>? bgClrs = prefs.getStringList('user_bg_colors');
      if (bgClrs != null) _bgColors = bgClrs.map((s) => Color(int.parse(s))).toList();
    });
    
    debugPrint("【系统】所有历史数据与个性化主题已恢复");
  }

  void _exportCSV() {
    if (transactions.isEmpty) return;
    List<Transaction> sortedTxs = List.from(transactions);
    sortedTxs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    String csv = "GRAIN FINANCIAL EXPENDITURE REPORT\n";
    csv += "User: Jerry Chen | Currency: AUD\n";
    csv += "Generated: ${DateTime.now().toString().split('.')[0]}\n\n";
    csv += "Date,Category,Price in AUS,Notes\n";
    double grandTotal = 0;
    int? currentMonth;
    int? currentYear;
    double monthSubtotal = 0;
    List<String> monthNames = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    for (int i = 0; i < sortedTxs.length; i++) {
      var t = sortedTxs[i];
      if (currentMonth != t.timestamp.month || currentYear != t.timestamp.year) {
        if (currentMonth != null) {
          csv += ">> Subtotal for ${monthNames[currentMonth]} $currentYear, ,${monthSubtotal.toStringAsFixed(2)}, [Monthly End]\n\n";
        }
        currentMonth = t.timestamp.month;
        currentYear = t.timestamp.year;
        monthSubtotal = 0;
        csv += "--- ${monthNames[currentMonth!].toUpperCase()} $currentYear ---\n";
      }
      String dateStr = "${t.timestamp.year}-${t.timestamp.month.toString().padLeft(2, '0')}-${t.timestamp.day.toString().padLeft(2, '0')}";
      csv += "$dateStr,${t.title},${t.amount.toStringAsFixed(2)},${t.notes.replaceAll(',', ';')}\n";
      monthSubtotal += t.amount;
      grandTotal += t.amount;
      if (i == sortedTxs.length - 1) {
        String status = (currentMonth == DateTime.now().month && currentYear == DateTime.now().year) 
            ? "Current Month To Date" 
            : "Monthly Total";
        csv += ">> $status (${monthNames[currentMonth!]} $currentYear), ,${monthSubtotal.toStringAsFixed(2)}, [Complete]\n";
      }
    }
    csv += "\n==========================\n";
    csv += "ALL-TIME TOTAL EXPENDITURE, ,AUD ${grandTotal.toStringAsFixed(2)}, \n";
    csv += "==========================\n";
    csv += "Grain app made by Jerry Chen";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Export Professional Report"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("The data is grouped by month with automatic subtotals.", style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 15),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    child: SelectableText(csv, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF5AC8FA))),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            onPressed: () { Navigator.pop(context); },
            child: const Text("Copy CSV", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  double get filteredSpending {
    DateTime now = DateTime.now();
    return transactions.where((t) {
      if (_timeRange == "Today") return t.timestamp.year == now.year && t.timestamp.month == now.month && t.timestamp.day == now.day;
      if (_timeRange == "This Month") return t.timestamp.year == now.year && t.timestamp.month == now.month;
      return t.timestamp.year == now.year; 
    }).fold(0, (sum, item) => sum + item.amount);
  }

  Transaction? get _mostExpensiveTransaction {
    if (transactions.isEmpty) return null;
    return transactions.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  void _addTransaction(String title, double amount, IconData icon, String note) {
    setState(() {
      transactions.insert(0, Transaction(id: DateTime.now().toString(), title: title.isEmpty ? "Unlabeled" : title, amount: amount, date: "Today, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}", icon: icon, notes: note, timestamp: DateTime.now()));
      _saveData();
    });
  }

  void _deleteTransaction(String id) {
    setState(() {
      transactions.removeWhere((t) => t.id == id);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColors.last,
      body: Stack(
        children: [
          Container(
            width: double.infinity, height: double.infinity,
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _bgColors)),
            child: SafeArea(child: Padding(padding: const EdgeInsets.only(bottom: 100), child: _buildBodyContent())),
          ),
          _buildFloatingBottomBar(), 
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_currentIndex == 0) return _buildHomeContent();
    if (_currentIndex == 1) return _buildStatisticsContent();
    if (_currentIndex == 2) return _buildCalendarContent();
    return _buildProfileContent(); 
  }

  Widget _buildHomeContent() {
    List<Transaction> displayList = transactions.length > 5 ? transactions.sublist(0, 5) : transactions;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 32),
          _buildMainCard(), 
          const SizedBox(height: 48),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Transactions", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            if (transactions.length > 5) GestureDetector(onTap: _showAllTransactions, child: Text("View all", style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold)))
          ]),
          const SizedBox(height: 20),
          Expanded(child: ListView.builder(physics: const BouncingScrollPhysics(), itemCount: displayList.length, itemBuilder: (context, index) => _buildDismissibleItem(displayList[index]))),
        ],
      ),
    );
  }

  void _showAllTransactions() {
    int count = 20;
    Navigator.push(context, MaterialPageRoute(builder: (context) => StatefulBuilder(builder: (context, setModalState) {
      List<Transaction> paged = transactions.take(count).toList();
      return Scaffold(
        backgroundColor: _bgColors.last,
        appBar: AppBar(title: const Text("History"), backgroundColor: Colors.transparent),
        body: NotificationListener<ScrollNotification>(
          onNotification: (s) {
            if (s.metrics.pixels == s.metrics.maxScrollExtent && count < transactions.length) {
              setModalState(() => count += 20);
            }
            return true;
          },
          child: ListView.builder(padding: const EdgeInsets.all(24), itemCount: paged.length, itemBuilder: (context, i) => _buildTransactionItem(paged[i])),
        ),
      );
    })));
  }

Widget _buildStatisticsContent() {
    // 1. 根据 _statsTimeRange 过滤账单数据
    DateTime now = DateTime.now();
    List<Transaction> statsList = transactions.where((t) {
      if (_statsTimeRange == "Today") {
        return t.timestamp.year == now.year && t.timestamp.month == now.month && t.timestamp.day == now.day;
      }
      if (_statsTimeRange == "This Week") {
        // 计算本周一的零点
        DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
        weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return t.timestamp.isAfter(weekStart) || t.timestamp.isAtSameMomentAs(weekStart);
      }
      if (_statsTimeRange == "This Month") {
        return t.timestamp.year == now.year && t.timestamp.month == now.month;
      }
      return t.timestamp.year == now.year; // This Year
    }).toList();

    // 2. 统计分类数据
    Map<IconData, double> categoryData = {};
    for (var item in statsList) { categoryData[item.icon] = (categoryData[item.icon] ?? 0) + item.amount; }
    double maxVal = categoryData.values.isEmpty ? 1.0 : categoryData.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // --- 修改后的 Header：增加了时间选择器 ---
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildHeader(),
            PopupMenuButton<String>(
              onSelected: (val) => setState(() => _statsTimeRange = val),
              itemBuilder: (context) => ["Today", "This Week", "This Month", "This Year"]
                  .map((s) => PopupMenuItem(value: s, child: Text(s)))
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(_statsTimeRange, style: TextStyle(fontSize: 12, color: _accentColor, fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_drop_down, size: 16, color: _accentColor),
                  ],
                ),
              ),
            ),
          ]),
          // ------------------------------------
          const SizedBox(height: 32),
          const Text("Financial\nStatistics", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1)),
          const SizedBox(height: 40),
          SizedBox(
            height: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
              children: categoryData.entries.toList().asMap().entries.map((entry) {
                int index = entry.key; var data = entry.value; double ratio = data.value / maxVal; bool isTouched = _touchedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _touchedIndex = isTouched ? null : index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isTouched) Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(8)), child: Text("\$${data.value.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio * 160),
                        duration: Duration(milliseconds: 600 + (index * 200)),
                        curve: Curves.easeOutBack,
                        builder: (context, val, child) => Container(width: 45, height: val, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isTouched ? [Colors.white, _accentColor] : [_accentColor, _accentColor.withAlpha(150)]), borderRadius: BorderRadius.circular(15))),
                      ),
                      const SizedBox(height: 12),
                      Icon(data.key, color: isTouched ? _accentColor : Colors.white54),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(child: ListView(children: categoryData.entries.map((e) => _buildStatRow(e.key, e.value)).toList())),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final List<List<Color>> bgOptions = [
      [const Color(0xFF1C1C1E), const Color(0xFF000000)],
      [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
      [const Color(0xFF141E30), const Color(0xFF243B55)],
      [const Color(0xFF3E5151), const Color(0xFFDECBA4)],
      [const Color(0xFF1f4037), const Color(0xFF99f2c8)],
    ];
    final List<List<Color>> cardPalettes = [
      [const Color(0xFF4F46E5), const Color(0xFF9333EA), const Color(0xFFEC4899)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
      [const Color(0xFFf12711), const Color(0xFFf5af19)],
      [const Color(0xFF00c6ff), const Color(0xFF0072ff)],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 32),
          const Text("Theme\nSettings", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 40),
          const Text("Card Gradient", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: cardPalettes.length, itemBuilder: (context, i) => GestureDetector(onTap: () { setState(() { _cardGradients = cardPalettes[i]; _selectedCardIndex = i; }); _saveData(); }, child: Container(width: 100, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(gradient: LinearGradient(colors: cardPalettes[i]), borderRadius: BorderRadius.circular(15), border: _selectedCardIndex == i ? Border.all(color: Colors.white, width: 2) : null))))),
          const SizedBox(height: 30),
          const Text("Accent Color", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildAccentColorPicker(),
          const SizedBox(height: 30),
          const Text("Background Atmosphere", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ...bgOptions.asMap().entries.map((e) => GestureDetector(
            onTap: () { setState(() { _bgColors = e.value; _selectedMoodIndex = e.key; }); _saveData(); },
            child: Container(height: 70, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(gradient: LinearGradient(colors: e.value), borderRadius: BorderRadius.circular(20), border: _selectedMoodIndex == e.key ? Border.all(color: _accentColor, width: 2) : null), child: Center(child: Text("Mood Palette ${e.key + 1}", style: const TextStyle(fontWeight: FontWeight.bold))))
          )).toList(),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _exportCSV,
            child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _accentColor.withOpacity(0.2))), child: const Row(children: [Icon(Icons.ios_share), SizedBox(width: 15), Text("Export Excel CSV"), Spacer(), Icon(Icons.arrow_forward_ios, size: 14)])),
          ),
          const SizedBox(height: 120), 
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("New Spending", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 25),
                const Text("Amount", style: TextStyle(color: Colors.white54)),
                TextField(controller: amountController, keyboardType: TextInputType.number, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _accentColor), decoration: const InputDecoration(hintText: "0.00", prefixText: "\$ ", border: InputBorder.none)),
                const SizedBox(height: 15),
                const Text("Category Name", style: TextStyle(color: Colors.white54)),
                TextField(controller: titleController, decoration: InputDecoration(hintText: "Where did you spend?", filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                const SizedBox(height: 20),
                const Text("Select Icon", style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    Icons.fastfood, 
                    Icons.shopping_cart, 
                    Icons.directions_car, 
                    Icons.school_rounded, // 新增：学校图标
                    Icons.home_rounded,   // 新增：房子图标
                    Icons.medical_services,
                  ].map((icon) => GestureDetector(
                    onTap: () {
                      setModalState(() => _selectedIcon = icon);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon ? _accentColor.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _selectedIcon == icon ? Border.all(color: _accentColor) : null
                      ),
                      child: Icon(icon, color: _selectedIcon == icon ? _accentColor : Colors.white38, size: 30),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 25),
                const Text("Notes", style: TextStyle(color: Colors.white54)),
                TextField(controller: noteController, maxLines: 2, decoration: InputDecoration(hintText: "Add details...", filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () { _addTransaction(titleController.text, double.tryParse(amountController.text) ?? 0.0, _selectedIcon, noteController.text); Navigator.pop(context); }, child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Positioned(bottom: 30, left: 20, right: 20, child: ClipRRect(borderRadius: BorderRadius.circular(35), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Container(height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(35), border: Border.all(color: _accentColor.withOpacity(0.3), width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navBtn(Icons.grid_view_rounded, 0, 28), _navBtn(Icons.pie_chart_outline_rounded, 1, 28), GestureDetector(onTap: () => _showAddTransactionSheet(context), child: Container(width: 56, height: 56, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 38))), _navBtn(Icons.calendar_today_rounded, 2, 24), _navBtn(Icons.person_2_outlined, 3, 28)])))));
  }

Widget _buildMainCard() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(38),
          gradient: LinearGradient(colors: _cardGradients, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("🇦🇺 AUS", style: TextStyle(fontWeight: FontWeight.bold)),
          PopupMenuButton<String>(
              onSelected: (val) => setState(() => _timeRange = val),
              itemBuilder: (context) => ["Today", "This Month", "This Year"].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Text(_timeRange, style: const TextStyle(fontSize: 12)),
                    const Icon(Icons.arrow_drop_down, size: 16)
                  ])))
        ]),
        const SizedBox(height: 40),
        const Text("Total Spending", style: TextStyle(color: Colors.white70)),
        // --- 核心修改：包裹这一层以防止金额过长换行 ---
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0, end: filteredSpending),
                builder: (context, val, child) => Text("\$${val.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900))),
          ),
        ),
      ]));
  Widget _navBtn(IconData i, int idx, double s) => IconButton(icon: Icon(i, color: _currentIndex == idx ? _accentColor : Colors.white30, size: s), onPressed: () => setState(() => _currentIndex = idx));
  Widget _buildHeader() => Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('Grain', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))]);
  Widget _buildStatRow(IconData i, double a, {String label = "Total"}) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(24)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(i, color: _accentColor), const SizedBox(width: 15), Text(label)]), Text("\$${a.toStringAsFixed(2)}")]));
  Widget _buildTransactionItem(Transaction t) => GestureDetector(onTap: () => _showDetailDialog(t), child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(24)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(t.icon, color: _accentColor), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(t.date, style: const TextStyle(color: Colors.white30, fontSize: 12))])]), Text("- \$${t.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900))])));

  Widget _buildDismissibleItem(Transaction t) {
    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Confirm Delete"),
              content: Text("Are you sure you want to delete '${t.title}'?"),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel", style: TextStyle(color: Colors.white30))),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete", style: TextStyle(color: Colors.white))),
              ],
            );
          },
        );
      },
      onDismissed: (dir) => _deleteTransaction(t.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.centerLeft,
        child: const Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.white), SizedBox(width: 8), Text("Delete Transaction", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
      ),
      child: _buildTransactionItem(t),
    );
  }

  Widget _buildAccentColorPicker() {
    final List<Color> opts = [const Color(0xFF5AC8FA), Colors.orangeAccent, Colors.greenAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.amberAccent];
    return SizedBox(height: 50, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: opts.length, itemBuilder: (context, i) {
      final colorItem = opts[i];
      return GestureDetector(
        onTap: () { setState(() => _accentColor = colorItem); _saveData(); },
        child: Container(width: 50, margin: const EdgeInsets.only(right: 15), child: CircleAvatar(backgroundColor: colorItem, radius: 20, child: _accentColor == colorItem ? const Icon(Icons.check, size: 20, color: Colors.white) : null)),
      );
    }));
  }

  Widget _buildCalendarContent() {
    int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    var mostExp = _mostExpensiveTransaction;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildHeader(),
            DropdownButton<int>(value: _selectedYear, items: [2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text("$y"))).toList(), onChanged: (v) => setState(() => _selectedYear = v!))
          ]),
          const SizedBox(height: 25),
          SizedBox(height: 40, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 12, itemBuilder: (context, i) => GestureDetector(onTap: () => setState(() => _selectedMonth = i + 1), child: Container(margin: const EdgeInsets.only(right: 20), child: Text(months[i], style: TextStyle(fontSize: 18, fontWeight: _selectedMonth == i + 1 ? FontWeight.w900 : FontWeight.w400, color: _selectedMonth == i + 1 ? _accentColor : Colors.white30)))))),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int day = index + 1;
              var dailyTxs = transactions.where((t) => t.timestamp.year == _selectedYear && t.timestamp.month == _selectedMonth && t.timestamp.day == day).toList();
              bool hasData = dailyTxs.isNotEmpty;
              return GestureDetector(
                onTap: () { if(hasData) _showDailyTransactions(day, dailyTxs); },
                child: Container(decoration: BoxDecoration(color: hasData ? _accentColor.withOpacity(0.15) : const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12), border: hasData ? Border.all(color: _accentColor.withOpacity(0.5)) : null), child: Center(child: Text("$day", style: TextStyle(color: hasData ? _accentColor : Colors.white)))),
              );
            },
          ),
          const SizedBox(height: 30),
          if (mostExp != null) _buildStatRow(Icons.stars_rounded, mostExp.amount, label: "Max: ${mostExp.timestamp.day}/${mostExp.timestamp.month}"),
        ],
      ),
    );
  }

  void _showDailyTransactions(int day, List<Transaction> dailyTxs) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("Records of Day $day"), const SizedBox(height: 20), Flexible(child: ListView.builder(shrinkWrap: true, itemCount: dailyTxs.length, itemBuilder: (context, i) => _buildTransactionItem(dailyTxs[i])))]))));
  }

  void _showDetailDialog(Transaction item) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF2C2C2E), title: Text(item.title), content: Text("Amount: \$${item.amount}\nNote: ${item.notes}"), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  }
}