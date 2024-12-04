import 'package:courosel/homeWidget.dart';
import 'package:courosel/myrecipeWidget.dart';
import 'package:courosel/profileWidget.dart';
import 'package:flutter/material.dart';

class CustomNavbar extends StatefulWidget {
  final int initialIndex; // Menambahkan parameter untuk index awal

  const CustomNavbar({Key? key, required this.initialIndex}) : super(key: key);

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar> {
  int index = 0;

  final List<Widget> page = [
    Home(),
    MyRecipe(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex; // Menggunakan nilai index yang diterima
  }

  void changePage(int selectedIndex) {
    setState(() {
      index = selectedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: page[index], // Menampilkan halaman berdasarkan index yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.pink,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        currentIndex: index,
        onTap: (value) =>
            changePage(value), // Ketika item dipilih, ganti halaman
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'My Recipe',
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
