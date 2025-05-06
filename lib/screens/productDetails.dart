import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soloz/screens/authscreen.dart';
import 'package:soloz/screens/checkout.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Check if user is logged in
  bool _isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Safely show snackbar checking if context is still valid
  void _safeShowSnackBar(String message, Color backgroundColor) {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  // Safely navigate if context is still valid
  void _safeNavigate(Widget screen) {
    if (!_isDisposed && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  // Get product ID safely
  String _getProductId() {
    return widget.product['id']?.toString() ??
        widget.product['title']
            ?.toString()
            .replaceAll(' ', '_')
            .toLowerCase() ??
        DateTime.now().toIso8601String();
  }

  // Add product to cart
  Future<void> _addToCart() async {
    if (!_isUserLoggedIn()) {
      _safeNavigate(const AuthScreen());
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final productId = _getProductId();

      final cartItem = {
        'productId': productId,
        'title': widget.product['title']?.toString() ?? 'Unknown Product',
        'price': widget.product['price']?.toString() ?? '0.00',
        'image': widget.product['image']?.toString() ?? '',
        'category': widget.product['category']?.toString() ?? 'Uncategorized',
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .add(cartItem);

      if (!_isDisposed && mounted) {
        _safeShowSnackBar('Added to cart!', Colors.green);
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _safeShowSnackBar('Error adding to cart: $e', Colors.red);
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Buy now function
  // Buy now function without server timestamp
  Future<void> _buyNow() async {
    if (!_isUserLoggedIn()) {
      _safeNavigate(const AuthScreen());
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productId = _getProductId();
      final price =
          double.tryParse(widget.product['price']?.toString() ?? '0.0') ?? 0.0;

      final cartItem = {
        'productId': productId,
        'title': widget.product['title']?.toString() ?? 'Unknown Product',
        'price': widget.product['price']?.toString() ?? '0.00',
        'image': widget.product['image']?.toString() ?? '',
        'category': widget.product['category']?.toString() ?? 'Uncategorized',
        'quantity': 1,
        'addedAt': DateTime.now()
            .toIso8601String(), // Use ISO string instead of server timestamp
      };

      _safeNavigate(CheckoutScreen(cartItems: [cartItem], totalAmount: price));
    } catch (e) {
      _safeShowSnackBar('Error: $e', Colors.red);
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Submit a review
  void _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _safeNavigate(const AuthScreen());
      return;
    }

    final productId = _getProductId();
    if (productId.isEmpty) {
      _safeShowSnackBar('Cannot identify product', Colors.red);
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reviewRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(user.uid);

      final existingReview = await reviewRef.get();

      if (existingReview.exists) {
        _safeShowSnackBar(
          'You have already reviewed this product.',
          Colors.orange,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (!_isDisposed && mounted) {
        String comment = '';
        double rating = 3;

        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Write a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) => comment = value,
                    decoration: const InputDecoration(labelText: 'Comment'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(builder: (context, setDialogState) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Rating: '),
                        DropdownButton<double>(
                          value: rating,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                rating = value;
                              });
                            }
                          },
                          items: [1, 2, 3, 4, 5]
                              .map((e) => DropdownMenuItem(
                                  value: e.toDouble(), child: Text('$e')))
                              .toList(),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await reviewRef.set({
                        'userId': user.uid,
                        'username':
                            user.email ?? user.displayName ?? 'Anonymous',
                        'rating': rating,
                        'comment': comment,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      _safeShowSnackBar('Review submitted!', Colors.green);
                    } catch (e) {
                      _safeShowSnackBar(
                          'Error submitting review: $e', Colors.red);
                    } finally {
                      if (!_isDisposed && mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        ).then((_) {
          // Ensure we reset loading state if dialog is dismissed
          if (_isLoading && !_isDisposed && mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      _safeShowSnackBar('Error checking review status: $e', Colors.red);
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Determine image source and load properly
  Widget _buildProductImage() {
    final imagePath = widget.product['image']?.toString() ?? '';

    if (imagePath.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
      );
    }

    // Check if it's a network image (starts with http)
    if (imagePath.toLowerCase().startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
          );
        },
      );
    } else {
      // Try to load as asset
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productId = _getProductId();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && !(_isDisposed && mounted)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: _buildProductImage(),
                  ),

                  // Product Details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.product["title"]?.toString() ??
                              'Unknown Product',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Price
                        Text(
                          widget.product["price"]?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category
                        Text(
                          'Category: ${widget.product["category"]?.toString() ?? 'Uncategorized'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product['description']?.toString() ??
                              'This is a high-quality ${widget.product["title"]?.toString()?.toLowerCase() ?? "product"} that offers both style and comfort. Perfect for any occasion, this item combines modern design with premium materials to ensure durability and a great fit.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            // Add to Cart Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _addToCart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text(
                                        'Add to Cart',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Buy Now Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _buyNow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Buy Now',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        const Text(
                          'Reviews',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Review List
                        StreamBuilder<QuerySnapshot>(
                          stream: productId.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(productId)
                                  .collection('reviews')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Text(
                                  'Error loading reviews: ${snapshot.error}');
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text(
                                  'No reviews yet. Be the first to review!');
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final reviewData = snapshot.data!.docs[index]
                                        .data() as Map<String, dynamic>? ??
                                    {};

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      reviewData['username']?.toString() ??
                                          'Anonymous',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                        reviewData['comment']?.toString() ??
                                            ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        (reviewData['rating'] as num?)
                                                ?.toInt() ??
                                            0,
                                        (index) => const Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // Write Review Button
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black54,
                                    ),
                                  )
                                : const Text(
                                    'Write a Review',
                                    style: TextStyle(color: Colors.black),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
