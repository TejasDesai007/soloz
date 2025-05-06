import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soloz/screens/authscreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchUserOrders(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    final orders = snapshot.docs.map((doc) {
      final data = doc.data();
      data['orderId'] = doc.id;
      return data;
    }).toList();

    orders.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    return orders;
  }

  Future<Map<String, dynamic>?> _fetchProductById(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint("Error fetching product $productId: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text("${user.email}",
                          style: const TextStyle(fontSize: 18)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Logout',
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Your Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserOrders(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final orders = snapshot.data!;
                  if (orders.isEmpty) {
                    return const Center(child: Text('No orders placed yet.'));
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final createdAt =
                          (order['createdAt'] as Timestamp?)?.toDate();
                      final shippingAddress =
                          order['shippingAddress'] as Map<String, dynamic>?;
                      final items = order['items'] as List<dynamic>?;

                      double totalAmount = 0.0;
                      try {
                        totalAmount =
                            double.parse(order['totalAmount'].toString());
                      } catch (_) {}

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ExpansionTile(
                          leading: const Icon(Icons.shopping_cart),
                          title: Text('Order #${order['orderId']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total: ₹${totalAmount.toStringAsFixed(2)}'),
                              if (createdAt != null)
                                Text(
                                    'Date: ${createdAt.toLocal().toString().split(' ')[0]}'),
                              Text(
                                  'Status: ${order['orderStatus'] ?? 'Pending'}'),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Shipping Address',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  if (shippingAddress != null) ...[
                                    Text(
                                        'Address: ${shippingAddress['address']}'),
                                    Text('City: ${shippingAddress['city']}'),
                                    Text(
                                        'ZIP Code: ${shippingAddress['zipCode']}'),
                                  ],
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  const Text('Payment Method',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(order['paymentMethod'] ?? 'Credit Card'),
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  const Text('Items Ordered',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  if (items != null && items.isNotEmpty)
                                    ...items.map((item) {
                                      final itemMap =
                                          item as Map<String, dynamic>;
                                      final productId =
                                          itemMap['productId']?.toString();

                                      final quantity = int.tryParse(
                                              itemMap['quantity'].toString()) ??
                                          0;
                                      final price = double.tryParse(
                                              itemMap['price'].toString()) ??
                                          0.0;

                                      return FutureBuilder<
                                          Map<String, dynamic>?>(
                                        future:
                                            _fetchProductById(productId ?? ''),
                                        builder: (context, snapshot) {
                                          final product = snapshot.data;
                                          final productTitle =
                                              product?['title'] ??
                                                  'Unknown Product';
                                          final imageUrl =
                                              product?['image'] as String?;

                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: imageUrl != null
                                                ? (Uri.tryParse(imageUrl)
                                                            ?.hasAbsolutePath ==
                                                        true
                                                    ? Image.network(
                                                        imageUrl,
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.asset(
                                                        imageUrl,
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                      ))
                                                : const Icon(
                                                    Icons.shopping_bag),
                                            title: Text(productTitle),
                                            subtitle: Text(
                                                'Qty: $quantity × ₹${price.toStringAsFixed(2)}'),
                                            trailing: Text(
                                                '₹${(price * quantity).toStringAsFixed(2)}'),
                                          );
                                        },
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
