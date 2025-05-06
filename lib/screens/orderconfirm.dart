import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the main screen instead of just the home screen
import 'package:soloz/main.dart'; // This should contain your MainScreen class

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final double? totalAmount;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    this.totalAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your order #$orderId has been placed and is being processed.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (totalAmount != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Total Amount: \$${totalAmount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Error loading order details: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      'Order details not found',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final orderData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final estimatedDelivery =
                      DateTime.now().add(const Duration(days: 5));

                  return Column(
                    children: [
                      Text(
                        'Estimated Delivery: ${_formatDate(estimatedDelivery)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shipping to: ${orderData['shippingAddress'] ?? 'Address not provided'}',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to MainScreen instead of just HomeScreen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (route) => false, // Clear all routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
