class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String category;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final bool isNew;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.sizes,
    required this.colors,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.isNew = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      images: List<String>.from(json['images'] as List),
      category: json['category'] as String,
      sizes: List<String>.from(json['sizes'] as List),
      colors: List<String>.from(json['colors'] as List),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'sizes': sizes,
      'colors': colors,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      'isNew': isNew,
    };
  }
} 