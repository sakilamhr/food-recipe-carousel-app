import 'dart:convert';
import 'package:courosel/apiconfig.dart'; // Pastikan BaseURL didefinisikan di sini
import 'package:courosel/formInsertRecipe.dart';
import 'package:courosel/detail_recipeWidget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MyRecipe extends StatefulWidget {
  const MyRecipe({super.key});

  @override
  State<MyRecipe> createState() => _MyRecipeState();
}

class _MyRecipeState extends State<MyRecipe> {
  List myRecipes = [];
  bool isLoading = true;

  // Fungsi untuk mengambil data resep
  Future<void> fetchMyRecipe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak tersedia');
      }

      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http
          .get(
            Uri.parse('$BaseURL/api/recipe/showByUser'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] is List) {
          if (mounted) {
            // Periksa apakah widget masih aktif sebelum memanggil setState
            setState(() {
              myRecipes = responseData['data'];
              isLoading = false;
            });
          }
        } else {
          throw Exception(
              'Gagal memuat data resep: ${responseData['message']}');
        }
      } else {
        throw Exception(
            'Request gagal dengan kode status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMyRecipe();
  }

  @override
  void dispose() {
    // Pastikan semua proses selesai sebelum widget dihapus
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Recipe',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        automaticallyImplyLeading: false, // Hilangkan tombol back
      ),
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: CircularProgressIndicator()),
            ) // Menampilkan indikator loading saat isLoading = true
          : myRecipes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_circle_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'No Recipes Available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ) // Menampilkan pesan jika tidak ada resep
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.separated(
                    itemCount: myRecipes.length,
                    separatorBuilder: (context, index) => const Divider(
                      thickness: 1,
                      color: Colors.grey,
                    ),
                    itemBuilder: (context, index) {
                      final myRecipe = myRecipes[index];
                      print('image: ${myRecipe['image']}');
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Recipe(recipe_id: myRecipe['id']),
                              ));
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gambar
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12.0)),
                                  image: DecorationImage(
                                    image: myRecipe['image'] != null &&
                                            myRecipe['image'].isNotEmpty
                                        ? NetworkImage(myRecipe['image'])
                                        : NetworkImage(
                                            'https://via.placeholder.com/1200'), // Gambar placeholder jika image tidak ada
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                height: 150,
                                width: double.infinity,
                              ),

                              // Konten
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Judul
                                    Text(
                                      myRecipe["title"] ?? 'No Title',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    // Rating dan Ulasan
                                    SizedBox(height: 8),
                                    // Waktu dan Ikon
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.timer,
                                                size: 16, color: Colors.yellow),
                                            SizedBox(width: 4),
                                            Text(
                                              '${myRecipe['cooking_time'] ?? 'No Time'} Jam',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 8.0),
                                        Row(
                                          children: [
                                            Icon(Icons.money,
                                                size: 16, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text(
                                              'Rp. ${myRecipe['money'] ?? 'Data Empty'} ',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: 8.0,
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.person,
                                                size: 16, color: Colors.blue),
                                            SizedBox(width: 4),
                                            Text(
                                              '${myRecipe['servings'] ?? 'Data Empty'} Person',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Warna bayangan
              spreadRadius: 1, // Mengatur seberapa jauh bayangan menyebar
              blurRadius: 8, // Mengatur seberapa kabur bayangan
              offset: Offset(0, 4), // Arah bayangan (horizontal, vertical)
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Aksi untuk tombol tambah data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FormRecipe(),
              ),
            );
          },
          backgroundColor: Colors.pink,
          child: Icon(
            shadows: [],
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
