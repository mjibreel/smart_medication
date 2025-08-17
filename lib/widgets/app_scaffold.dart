import 'package:flutter/material.dart';

class AppScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index, BuildContext context) {
    print('Tapped index: $index');
    print('Current route before: ${ModalRoute.of(context)?.settings.name}');
    
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/scheduling');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/medicine');
        break;
      case 3:
        print('Navigating to ProfileDisplayPage');
        Navigator.pushReplacementNamed(context, '/ProfileDisplayPage');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';
    print('Current route in build: $currentRoute');
    
    _selectedIndex = switch (currentRoute) {
      '/home' => 0,
      '/scheduling' => 1,
      '/medicine' => 2,
      '/ProfileDisplayPage' => 3,
      '/ProfileSetupPage' => 3,
      _ => 0,
    };
    print('Selected index: $_selectedIndex');

    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: widget.actions,
            )
          : null,
      body: widget.body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 