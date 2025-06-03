import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FinanceTrackerScreen extends StatefulWidget {
  const FinanceTrackerScreen({super.key});

  @override
  _FinanceTrackerScreenState createState() => _FinanceTrackerScreenState();
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isIncome;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'isIncome': isIncome,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      isIncome: map['isIncome'],
    );
  }
}

class _FinanceTrackerScreenState extends State<FinanceTrackerScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Transaction> _transactions = [];
  String _selectedCategory = 'Salary';
  bool _isIncome = true;
  int _filterIndex = 0; // 0 = All, 1 = Income, 2 = Expense

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other'
  ];

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Housing',
    'Entertainment',
    'Utilities',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionData = prefs.getString('transactions');
    if (transactionData != null) {
      final List<dynamic> jsonList = json.decode(transactionData);
      setState(() {
        _transactions = jsonList
            .map((item) => Transaction.fromMap(item as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionData =
        json.encode(_transactions.map((tx) => tx.toMap()).toList());
    await prefs.setString('transactions', transactionData);
  }

  double get _totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _totalExpense {
    return _transactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _balance {
    return _totalIncome - _totalExpense;
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final enteredTitle = _titleController.text;
      final enteredAmount = double.tryParse(_amountController.text) ?? 0;

      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: enteredTitle,
        amount: enteredAmount,
        date: DateTime.now(),
        category: _selectedCategory,
        isIncome: _isIncome,
      );

      setState(() {
        _transactions.add(newTransaction);
      });

      await _saveTransactions();

      // Clear the form
      _titleController.clear();
      _amountController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _deleteTransaction(String id) async {
    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });
    await _saveTransactions();
  }

  void _clearAllTransactions() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all your transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _transactions.clear();
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('transactions');
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Transaction> get _filteredTransactions {
    switch (_filterIndex) {
      case 1:
        return _transactions.where((t) => t.isIncome).toList();
      case 2:
        return _transactions.where((t) => !t.isIncome).toList();
      default:
        return _transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAllTransactions,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Income', _totalIncome, Colors.green),
                        _buildSummaryItem('Expense', _totalExpense, Colors.red),
                        _buildSummaryItem(
                            'Balance', _balance, _balance >= 0 ? Colors.blue : Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_transactions.length} transaction${_transactions.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleButtons(
              isSelected: [
                _filterIndex == 0,
                _filterIndex == 1,
                _filterIndex == 2
              ],
              onPressed: (index) {
                setState(() {
                  _filterIndex = index;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('All'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Income'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Expense'),
                ),
              ],
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Colors.blue,
              color: Colors.grey,
              constraints: const BoxConstraints(
                minHeight: 40,
                minWidth: 80,
              ),
            ),
          ),

          // Form Section
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Income/Expense Toggle
                    ToggleButtons(
                      isSelected: [_isIncome, !_isIncome],
                      onPressed: (index) {
                        setState(() {
                          _isIncome = index == 0;
                          _selectedCategory = _isIncome
                              ? _incomeCategories[0]
                              : _expenseCategories[0];
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Income'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Expense'),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: _isIncome ? Colors.green : Colors.red,
                      color: Colors.grey,
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        minWidth: 100,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: (_isIncome ? _incomeCategories : _expenseCategories)
                          .map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor:
                              _isIncome ? Colors.green : Colors.blueAccent,
                        ),
                        child: Text(
                          'Add ${_isIncome ? 'Income' : 'Expense'}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: _buildTransactionList(_filteredTransactions),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    return transactions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _filterIndex == 1
                      ? Icons.money_off
                      : _filterIndex == 2
                          ? Icons.shopping_bag
                          : Icons.list,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _filterIndex == 1
                      ? 'No income records yet'
                      : _filterIndex == 2
                          ? 'No expense records yet'
                          : 'No transactions yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: transactions.length,
            itemBuilder: (ctx, index) {
              final transaction = transactions[index];
              return Dismissible(
                key: Key(transaction.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteTransaction(transaction.id),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: transaction.isIncome
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(transaction.category),
                        color: transaction.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      transaction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.category,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(transaction.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '\$${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: transaction.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Salary':
        return Icons.work;
      case 'Freelance':
        return Icons.computer;
      case 'Investment':
        return Icons.trending_up;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Housing':
        return Icons.home;
      case 'Entertainment':
        return Icons.movie;
      case 'Utilities':
        return Icons.bolt;
      default:
        return Icons.money;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}