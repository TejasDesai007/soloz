import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soloz/screens/orderconfirm.dart';
import 'package:soloz/services/firebase_service.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCVVController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPaymentMethod = 'Credit Card';
  String _selectedShippingMethod = 'Standard';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseService.getUserProfile(user.uid);

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _emailController.text = userData['email'] ?? '';
            _nameController.text = userData['name'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _cityController.text = userData['city'] ?? '';
            _zipCodeController.text = userData['zipCode'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCVVController.dispose();
    super.dispose();
  }

  // Shipping information validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }
    return null;
  }

  String? _validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'ZIP code is required';
    }
    return null;
  }

  // Payment information validation
  String? _validateCardNumber(String? value) {
    if (_selectedPaymentMethod != 'Credit Card') return null;

    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    if (value.replaceAll(' ', '').length != 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _validateCardExpiry(String? value) {
    if (_selectedPaymentMethod != 'Credit Card') return null;

    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use format MM/YY';
    }
    return null;
  }

  String? _validateCardCVV(String? value) {
    if (_selectedPaymentMethod != 'Credit Card') return null;

    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    if (value.length < 3 || value.length > 4) {
      return 'CVV must be 3-4 digits';
    }
    return null;
  }

// This function modifies the cart items to remove FieldValue.serverTimestamp()
// and replace it with a client-side timestamp before sending to Firestore
  List<Map<String, dynamic>> _prepareCartItemsForFirestore(
      List<Map<String, dynamic>> items) {
    return items.map((item) {
      // Create a new map to avoid modifying the original
      final processedItem = Map<String, dynamic>.from(item);

      // Replace serverTimestamp with a client-side timestamp if present
      if (processedItem.containsKey('addedAt') &&
          processedItem['addedAt'] is FieldValue) {
        processedItem['addedAt'] = DateTime.now().toIso8601String();
      }

      return processedItem;
    }).toList();
  }

// Process order function with the fix
  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      final userId =
          user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      // Prepare cart items by removing FieldValue.serverTimestamp()
      final processedCartItems =
          _prepareCartItemsForFirestore(widget.cartItems);

      // Create order in Firestore
      final orderData = {
        'userId': userId,
        'customerName': _nameController.text,
        'email': _emailController.text,
        'shippingAddress': {
          'address': _addressController.text,
          'city': _cityController.text,
          'zipCode': _zipCodeController.text,
        },
        'items': processedCartItems,
        'totalAmount': widget.totalAmount,
        'paymentMethod': _selectedPaymentMethod,
        'shippingMethod': _selectedShippingMethod,
        'orderStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('Creating order in Firestore');
      DocumentReference orderRef =
          await _firestore.collection('orders').add(orderData);
      final orderId = orderRef.id;
      debugPrint('Order created with ID: $orderId');

      // Save shipping info for logged in users
      if (user != null) {
        try {
          // Update user document directly with Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'name': _nameController.text,
            'address': _addressController.text,
            'city': _cityController.text,
            'zipCode': _zipCodeController.text,
          });
          debugPrint('User profile updated successfully');
        } catch (e) {
          debugPrint('Error updating user profile: $e');
          // Continue even if profile update fails
        }
      }

      if (!mounted) return;

      // Navigate to order confirmation screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            orderId: orderId,
            totalAmount: widget.totalAmount,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error processing order: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to process your order. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Checkout Icon
                  Icon(
                    Icons.shopping_cart_checkout,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Complete Your Order',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${widget.cartItems.length} items'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total'),
                            Text(
                              '\$${widget.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Shipping Information Section
                  const Text(
                    'Shipping Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: _validateName,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'your.email@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: _validateEmail,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Address Field
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: '123 Main St',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: _validateAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // City Field
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      hintText: 'New York',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: _validateCity,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // ZIP Code Field
                  TextFormField(
                    controller: _zipCodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ZIP Code',
                      hintText: '10001',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: _validateZipCode,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Shipping Method Selection
                  const Text(
                    'Shipping Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Standard Shipping (3-5 days)'),
                          subtitle: const Text('\$0.00'),
                          value: 'Standard',
                          groupValue: _selectedShippingMethod,
                          onChanged: (String? value) {
                            if (value != null && !_isLoading) {
                              setState(() {
                                _selectedShippingMethod = value;
                              });
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Express Shipping (1-2 days)'),
                          subtitle: const Text('\$9.99'),
                          value: 'Express',
                          groupValue: _selectedShippingMethod,
                          onChanged: (String? value) {
                            if (value != null && !_isLoading) {
                              setState(() {
                                _selectedShippingMethod = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Section
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Credit Card'),
                          value: 'Credit Card',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (String? value) {
                            if (value != null && !_isLoading) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('PayPal'),
                          value: 'PayPal',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (String? value) {
                            if (value != null && !_isLoading) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Credit Card Details (only show if Credit Card is selected)
                  if (_selectedPaymentMethod == 'Credit Card')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Number Field
                        TextFormField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            hintText: '1234 5678 9012 3456',
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: _validateCardNumber,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Row for Expiry and CVV
                        Row(
                          children: [
                            // Expiry Date Field
                            Expanded(
                              child: TextFormField(
                                controller: _cardExpiryController,
                                decoration: InputDecoration(
                                  labelText: 'Expiry Date',
                                  hintText: 'MM/YY',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                validator: _validateCardExpiry,
                                enabled: !_isLoading,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // CVV Field
                            Expanded(
                              child: TextFormField(
                                controller: _cardCVVController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'CVV',
                                  hintText: '123',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                validator: _validateCardCVV,
                                enabled: !_isLoading,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Place Order Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _processOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        : Text(
                            'Place Order - \$${widget.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
