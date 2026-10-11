class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> dietaryTags;
  final List<String> allergens;
  final String imageUrl;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.dietaryTags,
    this.allergens = const [],
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'dietaryTags': dietaryTags,
    'allergens': allergens,
  };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: (json['price'] as num).toDouble(),
    category: json['category'] as String? ?? 'General',
    dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
    allergens: List<String>.from(json['allergens'] ?? []),
    imageUrl: json['imageUrl'] as String? ?? '',
  );
}

const List<MenuItem> cafeMenuCatalog = [
  MenuItem(
    id: 'coffee_espresso',
    name: 'Espresso',
    description: 'Rich, bold single or double shot espresso',
    price: 3.25,
    category: 'Coffee',
    dietaryTags: ['Vegan', 'Gluten-Free', 'Sugar-Free'],
  ),
  MenuItem(
    id: 'coffee_latte',
    name: 'Caffe Latte',
    description: 'Espresso with steamed milk and light layer of foam',
    price: 4.75,
    category: 'Coffee',
    dietaryTags: ['Vegetarian', 'Gluten-Free'],
  ),
  MenuItem(
    id: 'coffee_cappuccino',
    name: 'Cappuccino',
    description: 'Equal parts espresso, steamed milk, and airy foam',
    price: 4.50,
    category: 'Coffee',
    dietaryTags: ['Vegetarian', 'Gluten-Free'],
  ),
  MenuItem(
    id: 'coffee_americano',
    name: 'Americano',
    description: 'Rich espresso shots topped with hot or iced filtered water',
    price: 3.75,
    category: 'Coffee',
    dietaryTags: ['Vegan', 'Gluten-Free', 'Sugar-Free'],
  ),
  MenuItem(
    id: 'coffee_flat_white',
    name: 'Flat White',
    description: 'Bold ristretto espresso shots blended with velvety microfoam',
    price: 4.95,
    category: 'Coffee',
    dietaryTags: ['Vegetarian', 'Gluten-Free'],
  ),
  MenuItem(
    id: 'coffee_cold_brew',
    name: 'Cold Brew',
    description: 'Slow-steeped craft iced coffee, exceptionally smooth and bold',
    price: 4.50,
    category: 'Coffee',
    dietaryTags: ['Vegan', 'Gluten-Free', 'Sugar-Free'],
  ),
  MenuItem(
    id: 'tea_matcha',
    name: 'Matcha Green Tea Latte',
    description: 'Stone-ground ceremonial Uji matcha with steamed milk',
    price: 5.25,
    category: 'Tea',
    dietaryTags: ['Vegetarian', 'Antioxidant-Rich'],
  ),
  MenuItem(
    id: 'tea_earl_grey',
    name: 'Earl Grey Tea',
    description: 'Black tea infused with bergamot citrus oils',
    price: 3.75,
    category: 'Tea',
    dietaryTags: ['Vegan', 'Gluten-Free', 'Sugar-Free'],
  ),
  MenuItem(
    id: 'tea_chai',
    name: 'Spiced Chai Latte',
    description: 'Black tea steeped with cinnamon, cardamom, and clove',
    price: 4.85,
    category: 'Tea',
    dietaryTags: ['Vegetarian', 'Gluten-Free'],
  ),
  MenuItem(
    id: 'croissant_butter',
    name: 'Butter Croissant',
    description: 'Flaky, buttery French golden pastry',
    price: 3.95,
    category: 'Bakery',
    dietaryTags: ['Vegetarian'],
    allergens: ['Dairy', 'Gluten'],
  ),
  MenuItem(
    id: 'pastry_vegan_muffin',
    name: 'Blueberry Oat Muffin',
    description: 'Wholesome gluten-free and vegan blueberry muffin',
    price: 4.25,
    category: 'Bakery',
    dietaryTags: ['Vegan', 'Gluten-Free', 'Dairy-Free'],
  ),
];
