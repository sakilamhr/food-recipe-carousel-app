import 'dart:convert';
import 'package:courosel/detail_recipeWidget.dart';
import 'package:http/http.dart' as http;
import 'package:courosel/apiconfig.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List recipes = [];
  List filteredItems = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak tersedia.');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$BaseURL/api/recipe/show'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          setState(() {
            recipes = List.from(responseData['data']);
            filteredItems = recipes;
          });
        } else {
          throw Exception('Gagal memuat kategori: ${responseData['message']}');
        }
      } else {
        throw Exception(
            'Request gagal dengan kode status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = query.isEmpty
          ? recipes
          : recipes.where((recipe) {
              final title = (recipe['title'] ?? '').toLowerCase();
              final userName = (recipe['user']?['name'] ?? '').toLowerCase();
              return title.contains(query.toLowerCase()) ||
                  userName.contains(query.toLowerCase());
            }).toList();
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: _filterItems,
      decoration: InputDecoration(
        labelText: 'Search',
        hintText: 'Type to search...',
        labelStyle: TextStyle(color: Colors.pink),
        prefixIcon: const Icon(Icons.search, color: Colors.pink),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.pink[50],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: Colors.pink, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: Colors.pink.withOpacity(0.8)),
        ),
      ),
      style: const TextStyle(fontSize: 16),
      cursorColor: Colors.pink,
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Recipe(recipe_id: recipe['id']),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          recipe['user']?['name'] ?? 'Unknown User',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      recipe['cooking_time'] != null &&
                              recipe['servings'] != null
                          ? '${recipe['cooking_time']} Jam - ${recipe['servings']} Person'
                          : 'Unknown Cooking Time or Servings',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        const Text('4.5 (20 Reviews)',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  recipe['image_url'] ?? 'https://via.placeholder.com/150',
                  height: 80.0,
                  width: 80.0,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/placeholder.png',
                      height: 80.0,
                      width: 80.0,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Search Recipe', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 20),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) =>
                          _buildRecipeCard(filteredItems[index]),
                      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
