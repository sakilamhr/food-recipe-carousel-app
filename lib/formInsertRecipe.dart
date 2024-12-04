import 'dart:convert';
import 'dart:io';
import 'package:courosel/apiconfig.dart';
import 'package:courosel/myrecipeWidget.dart';
import 'package:courosel/navbar.dart';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormRecipe extends StatefulWidget {
  const FormRecipe({super.key});

  @override
  State<FormRecipe> createState() => _FormRecipeState();
}

class _FormRecipeState extends State<FormRecipe> {
  String? _selectedCategory;

  List categories = [];
  List<Map<String, dynamic>> _controllers = [];
  List<TextEditingController> _controllerSteps = [];
  String? yourRecipeId = ""; // Ganti dengan ID resep yang sesuai
  TextEditingController _servingController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _cookingTimeController = TextEditingController();
  TextEditingController _totalController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _linkYtController = TextEditingController();
  File? selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

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

  Future<void> _createRecipe() async {
    final String title = _titleController.text;
    final String description = _descriptionController.text;
    final String cookingTime = _cookingTimeController.text;
    final String servings = _servingController.text;
    final String money = _totalController.text;
    final String categoryId = _selectedCategory ?? '';
    final String codeYt = _linkYtController.text;

    // Pastikan gambar dipilih
    if (selectedImage == null) {
      print("Image is required");
      return;
    }

    // Validasi field yang diperlukan
    if (money.isEmpty) {
      print("Money field is required");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak tersedia.');
      }

      // Persiapkan ingredients dan steps
      List<Map<String, dynamic>> ingredients = [];
      List<Map<String, dynamic>> steps = [];

      // Tambahkan ingredients
      for (var controller in _controllers) {
        if (controller['nameController'] != null &&
            controller['quantityController'] != null) {
          ingredients.add({
            'ingredient_name': controller['nameController'].text,
            'quantity': controller['quantityController'].text,
          });
        } else {
          print("Ingredient name or quantity is missing");
          return;
        }
      }

      // Validasi ingredients
      if (ingredients.isEmpty) {
        print("Ingredients are required");
        return;
      }

      // Tambahkan steps
      for (int i = 0; i < _controllerSteps.length; i++) {
        steps.add({
          'step_number': i + 1,
          'step': _controllerSteps[i].text,
        });
      }

      // Validasi steps
      if (steps.isEmpty) {
        print("Steps are required");
        return;
      }

      // Persiapkan request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BaseURL/api/recipe/post'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['category_id'] = categoryId;
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['cooking_time'] = cookingTime;
      request.fields['servings'] = servings;
      request.fields['money'] = money;
      request.fields['code_yt'] = codeYt;

      // Tambahkan file gambar
      request.files
          .add(await http.MultipartFile.fromPath('image', selectedImage!.path));
      print('Ingredients JSON: ${jsonEncode(ingredients)}');
      print('Steps JSON: ${jsonEncode(steps)}');

      // Konversi ingredients dan steps menjadi JSON string
      request.fields['ingredients'] = jsonEncode(ingredients);
      request.fields['steps'] = jsonEncode(steps);

      // Kirim request
      final response = await request.send();

      if (response.statusCode == 200) {
        print('Recipe created successfully');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => CustomNavbar(initialIndex: 1)),
          (route) => false, // Hapus semua stack sebelumnya
        );
      } else {
        print('Failed to create recipe');
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);

        if (responseData.containsKey('message')) {
          print('Error message: ${responseData['message']}');
          print('Data Error message: ${responseData['data']}');
        } else {
          print('Unknown error: $responseBody');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    // Bersihkan semua controller
    for (var controller in _controllers) {
      controller['nameController'].dispose();
      controller['quantityController'].dispose();
    }
    for (var controller in _controllerSteps) {
      controller.dispose();
    }
    _servingController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _totalController.dispose();
    _categoryController.dispose();
    _linkYtController.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    fetchCategories();

    // Menambahkan elemen pertama ke dalam _controllers
    _controllers.add({
      'nameController': TextEditingController(),
      'quantityController': TextEditingController(),
      'ingredient_name': '',
      'quantity': 0,
    });

    // Menambahkan controller untuk langkah-langkah resep (jika ada)
    _controllerSteps.add(TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        child: Icon(
                                          Icons.warning,
                                          size: 60,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Hapus resep ini',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                                content: Text(
                                    'Apakah Anda yakin ingin menghapus resep ini?'),
                                actions: [
                                  // Tombol Cancel
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Menutup dialog
                                    },
                                    child: Text(
                                      'Batal',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                  // Tombol Reset
                                  TextButton(
                                    onPressed: () {
                                      // Fungsi untuk mereset atau menghapus sesuatu
                                      print("Resep dihapus");

                                      // Tutup dialog dan pop halaman sebelumnya
                                      Navigator.of(context)
                                          .pop(); // Menutup dialog
                                      Navigator.of(context)
                                          .pop(); // Mem-pop halaman sebelumnya
                                    },
                                    child: Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            });
                      },
                      icon: Icon(Icons.close),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.pink,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                    'Terbitkan resep ',
                                    style: TextStyle(color: Colors.pink),
                                  ),
                                  content: Text(
                                      'Apakah Anda yakin ingin menerbitkan resep ini?'),
                                  actions: [
                                    // Tombol Cancel
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Menutup dialog
                                      },
                                      child: Text(
                                        'Batal',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ),
                                    // Tombol Reset
                                    TextButton(
                                      onPressed: () {
                                        // Fungsi untuk mereset atau menghapus sesuatu

                                        _createRecipe();
                                      },
                                      child: Text(
                                        'Terbitkan',
                                        style: TextStyle(color: Colors.pink),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            'Terbitkan',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upload Image
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  // color: Colors.pink,
                  image: DecorationImage(
                    image: selectedImage != null
                        ? FileImage(selectedImage!)
                        : NetworkImage('https://placehold.co/600x400'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload,
                            size: 24, color: Colors.black.withOpacity(0.6)),
                        SizedBox(width: 8),
                        Text(
                          '[Wajib] Upload Image',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Form Input
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _titleController,
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '[Wajib] Judul: Sup Ayam Favorit',
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Cerita Masakan
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14),
                          hintText:
                              '(Opsional) Cerita di balik masakan ini. Apa atau siapa yang menginspirasimu? Apa yang membuatnya istimewa? Bagaimana caramu menikmatinya?',
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Porsi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Porsi:',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black54.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _servingController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '[wajib]',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Text(
                              'Orang',
                              style: TextStyle(fontSize: 14),
                            )
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lama Memasak:',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black54.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _cookingTimeController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '[wajib]',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Text(
                              'Jam',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Biaya:',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black54.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _totalController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '20000 Contoh',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 16,
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: Text(
                        'Pilih kategori',
                        style: TextStyle(
                          fontSize: 16, // Ukuran font
                          color: Colors.grey[600], // Warna teks hint
                        ),
                      ),
                      items:
                          categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'].toString(),
                          child: Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 16, // Ukuran font
                              fontWeight: FontWeight.w400, // Tebal font
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });

                        print('Kategori terpilih: $value');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey, // Warna garis border
                            width: 1.5, // Ketebalan garis border
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.pink,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      dropdownColor: Colors.white,
                    ),
                    SizedBox(
                      height: 20,
                    ),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: _linkYtController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '(Opsional) Masukkan Link Youtube',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),

                    Text(
                      'Bahan-Bahan',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    // Bahan-bahan
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _controllers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[index]
                                          ['nameController'],
                                      decoration: InputDecoration(
                                        labelText: "Bahan ${index + 1}",
                                        hintText: "Input Bahan ${index + 1}",
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.pink),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[index]
                                          ['quantityController'],
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(
                                        labelText: "Quantity ${index + 1}",
                                        hintText: "Enter quantity",
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.pink),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _controllers.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              setState(() {
                                _controllers.add({
                                  'nameController': TextEditingController(),
                                  'quantityController': TextEditingController(),
                                });
                              });
                            },
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              "Add",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),
                    Text(
                      'Langkah-Langkah',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _controllerSteps.length,
                          itemBuilder: (context, index) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: TextField(
                                      controller: _controllerSteps[index],
                                      decoration: InputDecoration(
                                          labelText: "Langkah ${index + 1}",
                                          hintText:
                                              "Input Langkah ${index + 1}",
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.pink))),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _controllerSteps.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), // Border radius tombol
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              setState(() {
                                _controllerSteps.add(TextEditingController());
                              });
                            },
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Add",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
