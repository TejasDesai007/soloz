import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'productDetails.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  ProductScreenState createState() => ProductScreenState();
}

class ProductScreenState extends State<ProductScreen> {
  final List<Map<String, String>> categories = [
    {"name": "All", "icon": "🌐"},
    {"name": "Men", "icon": "👕"},
    {"name": "Women", "icon": "👗"},
  ];

  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 10),
            child: Text(
              "Explore Products",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Category Chips
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories.map((category) {
                bool isSelected = category["name"] == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category["name"]!;
                      });
                    },
                    child: Chip(
                      label: Text(
                        "${category["icon"]} ${category["name"]}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      backgroundColor: isSelected ? Colors.amber : Colors.black,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Product Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No products found."));
                }

                final products = snapshot.data!.docs.where((doc) {
                  final category = doc['category'] ?? '';
                  if (selectedCategory == "All") return true;
                  return category == selectedCategory;
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      // Get the document ID of the product
                      final productId = product.id;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                product: {
                                  "id":
                                      productId, // Pass the document ID properly
                                  "image": product['image'],
                                  "title": product['title'],
                                  "price": product['price'],
                                  "category": product['category'],
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10)),
                                  child: Image.asset(
                                    product['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 150,
                                  )),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  product['title'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  product['price'],
                                  style: const TextStyle(color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
