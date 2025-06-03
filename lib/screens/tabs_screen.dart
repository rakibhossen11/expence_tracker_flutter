import 'package:expence_tracker/screens/expense_screen.dart';
import 'package:expence_tracker/screens/home_screen.dart';
import 'package:expence_tracker/screens/income_screen.dart';
import 'package:expence_tracker/screens/income_screen.dart';
import 'package:flutter/material.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  _TabsScreenState createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  final List<Map<String, Object>> _pages = [
    {'page': const HomeScreen(), 'title': 'Overview'},
    {'page': const FinanceTrackerScreen(), 'title': 'Income'},
    {'page': const ExpenseScreen(), 'title': 'Expenses'},
  ];
  
  int _selectedPageIndex = 0;
  final PageController _pageController = PageController();

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pages[_selectedPageIndex]['title'] as String,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : theme.primaryColorDark,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? theme.primaryColor : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : theme.primaryColorDark,
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages.map((page) => page['page'] as Widget).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            onTap: _selectPage,
            backgroundColor: isDarkMode ? theme.primaryColor : Colors.white,
            unselectedItemColor: isDarkMode ? Colors.white70 : Colors.grey,
            selectedItemColor: isDarkMode 
                ? theme.colorScheme.secondary 
                : theme.primaryColor,
            currentIndex: _selectedPageIndex,
            elevation: 10,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedPageIndex == 0
                        ? (isDarkMode 
                            ? theme.colorScheme.secondary.withOpacity(0.2) 
                            : theme.primaryColor.withOpacity(0.1))
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _selectedPageIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
                    size: 24,
                  ),
                ),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedPageIndex == 1
                        ? (isDarkMode 
                            ? theme.colorScheme.secondary.withOpacity(0.2) 
                            : theme.primaryColor.withOpacity(0.1))
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _selectedPageIndex == 1 ? Icons.attach_money : Icons.attach_money_outlined,
                    size: 24,
                  ),
                ),
                label: 'Income',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedPageIndex == 2
                        ? (isDarkMode 
                            ? theme.colorScheme.secondary.withOpacity(0.2) 
                            : theme.primaryColor.withOpacity(0.1))
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _selectedPageIndex == 2 ? Icons.money_off : Icons.money_off_outlined,
                    size: 24,
                  ),
                ),
                label: 'Expenses',
              ),
            ],
          ),
        ),
      ),
    );
  }
}