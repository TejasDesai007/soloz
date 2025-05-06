import 'package:flutter/material.dart';
import 'products.dart'; // Import the products page

class HomeScreen extends StatelessWidget {
  final VoidCallback? onExplore;
  const HomeScreen({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Promotional Banner
            Container(
              margin: const EdgeInsets.all(10),
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage("assets/images/banner.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Welcome Message
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Welcome to SoloZ!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We offer a wide range of stylish and comfortable clothing for everyone.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "🧥 Men's Collection: Trendy casuals, formal wear, and ethnic styles.\n"
                    "👗 Women's Collection: Elegant dresses, tops, sarees, and more.\n"
                    "🔥 Seasonal Sale: Exclusive discounts on top brands.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Shop now and upgrade your wardrobe with the latest fashion trends!",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                    ),
                    onPressed: onExplore ??
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProductScreen()),
                          );
                        },
                    child: const Text(
                      "Explore Now",
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Shop by Category",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _CategoryCard(icon: Icons.male, label: "Men"),
                  _CategoryCard(icon: Icons.female, label: "Women"),
                  _CategoryCard(icon: Icons.child_friendly, label: "Kids"),
                  _CategoryCard(icon: Icons.accessibility, label: "Ethnic"),
                  _CategoryCard(icon: Icons.access_alarm, label: "Accessories"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const SizedBox(height: 30),

            // Testimonials
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("What Our Customers Say",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  _TestimonialCard(
                    name: "Aarav Mehta",
                    feedback:
                        "Great quality clothing! Delivery was super quick and support team is very helpful.",
                  ),
                  _TestimonialCard(
                    name: "Simran Kaur",
                    feedback:
                        "Loved the ethnic collection! It made my festival shopping so easy and elegant.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Newsletter Signup CTA
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber.shade100,
              child: Column(
                children: const [
                  Text(
                    "Get the latest updates and offers!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("Subscribe to our newsletter for style tips & deals."),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Reusable Category Card
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CategoryCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// Reusable Testimonial Card
class _TestimonialCard extends StatelessWidget {
  final String name;
  final String feedback;
  const _TestimonialCard({required this.name, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$feedback"',
                style:
                    const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text('- $name',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
