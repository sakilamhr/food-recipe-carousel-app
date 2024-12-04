import 'dart:convert';

import 'package:courosel/apiconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class Recipe extends StatefulWidget {
  final int recipe_id;

  const Recipe({
    super.key,
    required this.recipe_id,
  });

  @override
  _RecipeState createState() => _RecipeState();
}

class _RecipeState extends State<Recipe> {
  YoutubePlayerController? _controller;

  Map<String, dynamic> recipe = {};
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  Map<String, dynamic> user = {};
  List ingredients = [];
  List steps = [];
  bool isOwnRecipe = false;
  bool isVideoError = false;
  String? videoURL;
  TextEditingController _commentController = TextEditingController();

// API COMMENT
  Future<void> fetchComments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('Token Tidaak tersedia');
        print('Token Tidak tersedia');
      }

      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$BaseURL/api/comment/show/${widget.recipe_id}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Data = jsonDecode(response.body);
        if (Data['success'] == true && Data['data'] is List) {
          comments = (Data['data'] as List).cast<Map<String, dynamic>>();
        } else {
          print('Gagal memuat Data Comment: ${Data['message']}');
        }
      } else {
        throw Exception(
            'Request gagal dengan kode status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

// API BAHAN BAHAN
  Future<void> fetchIngredients() async {
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

      final response = await http.get(
        Uri.parse('$BaseURL/api/recipeIngredients/show/${widget.recipe_id}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          ingredients = responseData['data'];
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
    }
  }

// API LANGKAH LANGKAH
  Future<void> fetchStep() async {
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
        Uri.parse('$BaseURL/api/recipestep/show/${widget.recipe_id}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          steps = responseData['data'];
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

// API RECIPES
  Future<void> fetchRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final username = prefs.getString('username');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak tersedia.');
      }

      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$BaseURL/api/recipe/showByID/${widget.recipe_id}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] is Map) {
          recipe = responseData['data']; // Menyimpan data resep
          user = responseData['data']['user']; // Menyimpan data user
          isOwnRecipe = (username != null && username == user['username']);

          videoURL = recipe['code_yt']; // Ambil URL video

          if (videoURL != null) {
            // Ekstrak ID video dari URL
            String? extractedVideoId = YoutubePlayer.convertUrlToId(videoURL!);
            if (extractedVideoId != null) {
              String fullVideoURL =
                  'https://www.youtube.com/watch?v=$extractedVideoId'; // Konversi ke URL asli
              setState(() {
                videoURL = fullVideoURL; // Simpan URL asli ke state
                isVideoError = false; // Set error ke false jika video berhasil
              });

              // Setelah mendapatkan video ID, inisialisasi YoutubePlayerController
              if (extractedVideoId != null) {
                setState(() {
                  isVideoError = false;
                  _controller = YoutubePlayerController(
                    initialVideoId: extractedVideoId,
                    flags: YoutubePlayerFlags(autoPlay: false, mute: false),
                  );
                });
              } else {
                setState(() {
                  isVideoError =
                      true; // Tandai error jika video ID gagal diekstrak
                });
              }

              print('Video URL loaded: $fullVideoURL');
            } else {
              print('Gagal mengekstrak ID dari URL video.');
              setState(() {
                isVideoError =
                    true; // Tandai error jika video ID tidak dapat diambil
              });
            }
          } else {
            print('URL video tidak tersedia.');
            setState(() {
              isVideoError = true; // Tandai error jika URL video tidak ada
            });
          }
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

  Future<void> CreateComment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final String comment = _commentController.text;
    final int recipe_id = widget.recipe_id;

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak tersedia.');
    }
    if (comment.isEmpty || comment.isEmpty) {
      _showError("All fields are required");
      return;
    }

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await http.post(Uri.parse('$BaseURL/api/comment'),
        headers: headers,
        body: jsonEncode({'recipe_id': recipe_id, 'comment': comment}));

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Registrasi berhasil
      final data = jsonDecode(
          response.body); // Dekodekan hanya jika respons dalam format JSON

      await fetchComments();
      setState(() {});
    } else {
      // Registrasi gagal
      final data = jsonDecode(
          response.body); // Dekodekan hanya jika respons dalam format JSON
      _showError(data['message'] ?? 'Registration failed');
    }
  }

  String limitWords(String text, int wordLimit) {
    List<String> words = text.split(' ');
    if (words.length > wordLimit) {
      return words.sublist(0, wordLimit).join(' ') + '...';
    }
    return text;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
    );
  }

  fetchData() async {
    await fetchRecipes();
    await fetchIngredients();
    await fetchStep();
    await fetchComments();

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _controller?.dispose(); // Tambahkan null check
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.all(
                                      8), // Atur padding langsung di ElevatedButton
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.0), // Radius yang sama seperti sebelumnya
                                    side: BorderSide(
                                        color: Colors.pink), // Border di sini
                                  ),
                                  minimumSize: Size(40, 40)),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.pink,
                              ),
                            ),
                            Text(
                              limitWords(recipe['title']!, 2),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink),
                            ),
                            Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.pink),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Icon(
                                isOwnRecipe
                                    ? Icons.more_vert
                                    : Icons.share_outlined,
                                color: Colors.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Youtube Player or Fallback Image
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: videoURL != null &&
                              _controller != null &&
                              !isVideoError
                          ? YoutubePlayer(
                              controller:
                                  _controller!, // Gunakan `!` karena kita sudah memeriksa null
                              showVideoProgressIndicator: true,
                              onReady: () {
                                print('Youtube Player is ready.');
                              },
                            )
                          : Container(
                              height: 200.0,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                    image: NetworkImage(
                                      recipe['image'] ??
                                          'https://via.placeholder.com/1200',
                                    ),
                                    fit: BoxFit.cover),
                              ),
                            ),
                    ),

                    // Judul Resep
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              limitWords(
                                  recipe['title'] ?? 'Judul Tidak Tersedia', 3),
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            SizedBox(
                              height: 8.0,
                            ),
                            Text(
                              user['name'] ?? 'Pengguna Tidak Diketahui',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.black.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Color.fromARGB(255, 254, 174, 0),
                              ),
                              SizedBox(
                                width: 4.0,
                              ),
                              Text(
                                '4.5',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

// bawah title
                    SizedBox(
                      height: 16.0,
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_2,
                              color: Colors.blue,
                            ),
                            SizedBox(
                              width: 4.0,
                            ),
                            Text('2 Posri'),
                          ],
                        ),
                        SizedBox(
                          width: 12.0,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: Colors.yellow,
                            ),
                            SizedBox(
                              width: 4.0,
                            ),
                            Text('${recipe['cooking_time'] ?? 0} Jam'),
                          ],
                        ),
                        SizedBox(
                          width: 12.0,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              color: Colors.green,
                            ),
                            SizedBox(
                              width: 4.0,
                            ),
                            Text('Rp. ${recipe['money'] ?? '0'} ')
                          ],
                        )
                      ],
                    ),

                    SizedBox(
                      height: 20.0,
                    ),

// Bahan-Bahan
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 5.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).hintColor.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        collapsedIconColor: Colors.pink,
                        iconColor: Colors.pink,
                        title: Text(
                          'Bahan-Bahan',
                          style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink),
                        ),
                        childrenPadding: EdgeInsets.symmetric(horizontal: 20),
                        children: ingredients.isNotEmpty
                            ? ingredients
                                .map((ingredient) => ListTile(
                                      title: Text(
                                          ingredient['ingredient_name'] ??
                                              'Nama Tidak Ditemukan'),
                                      subtitle: Text(
                                          'Jumlah: ${ingredient['quantity'] ?? 'Tidak Tersedia'}'),
                                    ))
                                .toList()
                            : [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada bahan yang tersedia.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    ),

// Langkah-Langkah
                    Container(
                      margin: EdgeInsets.only(
                          right: 5, left: 5, top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).hintColor.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        collapsedIconColor: Colors.pink,
                        iconColor: Colors.pink,
                        title: Text(
                          'Langkah - Langkah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        childrenPadding: EdgeInsets.symmetric(horizontal: 20),
                        children: steps.isNotEmpty
                            ? steps.map((value) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 20),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${value['step_number']}. ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Expanded(
                                        child: Text(
                                          value['step'] ??
                                              'Langkah tidak tersedia',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList()
                            : [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada langkah yang tersedia.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      recipe['description'],
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.pink,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      height: 200.0, // Atur tinggi daftar komentar

                      child: comments.isNotEmpty
                          ? ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                print('Image: ${comment['user']['image']}');
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Gambar Profil
                                          Container(
                                            height: 50.0,
                                            width: 50.0,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  '${comment['user']['image']}' ??
                                                      'https://via.placeholder.com/blue', // Placeholder jika null
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16.0),
                                          // Detail Komentar
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      comment['user']['name'] ??
                                                          'Pengguna Tidak Diketahui',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14.0,
                                                      ),
                                                    ),
                                                    Text(
                                                      comment['updated_at'] ??
                                                          'Tidak Tersedia',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  comment['comment'] ??
                                                      'Komentar tidak tersedia.',
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.black
                                                        .withOpacity(0.8),
                                                  ),
                                                  textAlign: TextAlign.justify,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index <
                                        comments.length -
                                            1) // Divider antar komentar
                                      Divider(
                                        color: Colors.grey.shade300,
                                        thickness: 1.0,
                                      ),
                                  ],
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                'Tidak ada komentar.',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),

                    SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Masukkan isi komentar anda',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 20),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(60),
                                  borderSide: BorderSide(
                                    color: Colors.pink,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(60),
                                  borderSide: BorderSide(
                                    color: Colors.pink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 8.0,
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                            ),
                            onPressed: () {
                              CreateComment();
                            },
                            child: Text(
                              'Send',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
