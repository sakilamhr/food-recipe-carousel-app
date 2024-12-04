import 'dart:ui';
import 'package:courosel/Category.dart';
import 'package:courosel/apiconfig.dart';
import 'package:courosel/search.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String name = "User";

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("name");
  }

  void getUserData() async {
    String? fetchedName = await getName();
    if (fetchedName != null) {
      setState(() {
        name = fetchedName;
      });
    }
  }

  @override
  void initState() {
    getUserData();
    fetchCategories();
    super.initState();
  }

  List categories = [];
  Future<void> fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak tersedia.');
      }

      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$BaseURL/api/category/show'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            categories = responseData['data'];
          });
        } else {
          throw Exception('Gagal memuat kategori: ${responseData['message']}');
        }
      } else {
        throw Exception('Gagal memuat kategori: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageList = [
      'assets/image1.png',
      'assets/image2.png',
      'assets/image3.png'
    ];

    final List<String> popularList = [
      'assets/popular1.png',
      'assets/popular2.png',
      'assets/popular3.png',
    ];

    final List<String> titleList = [
      'Ayam Kari',
      'Chicken Mentai Rice',
      'Odeng Rasa Ikan',
    ];
    final List<String> subTitle = [
      'Ala Rumah Mama bubu',
      'Ala Mak bibi',
      'Ala Ghifari',
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search bar dan greeting user
            Padding(
              padding:
                  const EdgeInsets.only(top: 16.0, right: 20.0, left: 20.0),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.pink[200],
                          border: Border.all(color: Colors.pink),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      "Hello, $name 👋",
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.pink[200],
                        border: Border.all(color: Colors.pink),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Carousel Slider
            SizedBox(height: 28.0),
            CarouselSlider(
              options: CarouselOptions(
                height: 280.0,
                autoPlay: true,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                autoPlayInterval: Duration(seconds: 3),
              ),
              items: imageList.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        image: DecorationImage(
                          image: AssetImage(item),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            // Section untuk category
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.pink,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  categories.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            height:
                                120.0, // Sesuaikan tinggi untuk daftar kategori
                            child: ListView.separated(
                              scrollDirection:
                                  Axis.horizontal, // Agar kategori horizontal
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Category(
                                              category_id: category['id'],
                                              category: category['name']),
                                        ));
                                  },
                                  child: CategoryButton(
                                    name: category['name'],
                                    icon: category[
                                        'icon'], // Memperbaiki penggunaan icon
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) {
                                return SizedBox(
                                    width: 20.0); // Jarak antar item
                              },
                            ),
                          ),
                        ),
                  SizedBox(height: 24.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Popular Recipes🔥',
                          style: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.0),

            // ListView untuk popular recipes
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: popularList.length,
              separatorBuilder: (context, index) {
                return SizedBox(height: 20);
              },
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                return RecipeCard(
                  image: popularList[index],
                  title: titleList[index],
                  subtitle: subTitle[index],
                );
              },
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

IconData getIconFromString(String iconName) {
  switch (iconName) {
    case 'local_bar':
      return Icons.local_bar;
    case 'rice_bowl':
      return Icons.rice_bowl;
    case 'shopping_cart':
      return Icons.shopping_cart;
    case 'ramen_dining':
      return Icons.ramen_dining;
    case 'cake':
      return Icons.cake;
    // Add more cases for other icons
    default:
      return Icons.help; // Default icon if no match is found
  }
}

class CategoryButton extends StatelessWidget {
  final String name;
  final String icon;

  const CategoryButton({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70.0,
          height: 70.0,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.pink,
                blurRadius: 4.0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              getIconFromString(icon), // Ganti dengan ikon yang sesuai
              size: 32.0,
              color: Colors.pink,
            ),
          ),
        ),
        SizedBox(height: 12.0),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class RecipeCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  const RecipeCard({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(16.0),
                      bottomLeft: Radius.circular(16.0),
                    ),
                    color: Colors.black45,
                  ),
                  height: 60,
                  width: 352,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow),
                    SizedBox(width: 8.0),
                    Text(
                      '4.5',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
