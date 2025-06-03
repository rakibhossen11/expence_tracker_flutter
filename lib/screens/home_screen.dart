import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:intl/intl.dart';
import 'package:expence_tracker/models/transaction.dart';
import 'package:expence_tracker/widgets/chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _balancePulseController;
  late final Animation<double> _balancePulseAnimation;
  late final AnimationController _cardSlideController;
  late final Animation<Offset> _cardSlideAnimation;

  final List<Transaction> _userTransactions = [
    Transaction(
      id: 't1',
      title: 'Salary',
      amount: 5000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      isIncome: true,
    ),
    Transaction(
      id: 't2',
      title: 'Groceries',
      amount: 200,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isIncome: false,
    ),
    Transaction(
      id: 't3',
      title: 'Freelance Work',
      amount: 800,
      date: DateTime.now(),
      isIncome: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _balancePulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _balancePulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _balancePulseController,
        curve: Curves.easeInOut,
      ),
    );

    _cardSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardSlideController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _balancePulseController.dispose();
    _cardSlideController.dispose();
    super.dispose();
  }

  List<Transaction> get _recentTransactions {
    return _userTransactions.where((tx) {
      return tx.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).toList();
  }

  double get _totalIncome => _userTransactions
      .where((tx) => tx.isIncome)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get _totalExpenses => _userTransactions
      .where((tx) => !tx.isIncome)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get _balance => _totalIncome - _totalExpenses;

  void _addNewTransaction(String title, double amount, bool isIncome) {
    final newTx = Transaction(
      id: DateTime.now().toString(),
      title: title,
      amount: amount,
      date: DateTime.now(),
      isIncome: isIncome,
    );

    setState(() {
      _userTransactions.add(newTx);
      _balancePulseController.forward(from: 0);
    });
  }

  void _deleteTransaction(String id) {
    setState(() {
      _userTransactions.removeWhere((tx) => tx.id == id);
      _balancePulseController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: ScaleTransition(
                scale: _balancePulseAnimation,
                child: Text(
                  currencyFormat.format(_balance),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _balance >= 0 ? Colors.green[400] : Colors.red[400],
                  ),
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColorDark,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _cardSlideAnimation,
              child: _buildFinancialOverview(context, currencyFormat),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardSlideController,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Chart(_recentTransactions),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('${_userTransactions.length} items'),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx = _userTransactions[index];
                return Dismissible(
                  key: Key(tx.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteTransaction(tx.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.isIncome
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        child: Icon(
                          tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: tx.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(tx.title),
                      subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                      trailing: Text(
                        '${tx.isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                        style: TextStyle(
                          color: tx.isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _userTransactions.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
        heroTag: 'addTransaction',
      ),
    );
  }

  Widget _buildFinancialOverview(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Financial Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinancialTile('Income', _totalIncome, Icons.arrow_downward, Colors.green, currencyFormat),
              _buildFinancialTile('Expenses', _totalExpenses, Icons.arrow_upward, Colors.red, currencyFormat),
              _buildFinancialTile('Balance', _balance, Icons.account_balance_wallet, 
                  _balance >= 0 ? Colors.blue : Colors.orange, currencyFormat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTile(
    String title, 
    double amount, 
    IconData icon, 
    Color color,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    // Implement your transaction form here
  }
}