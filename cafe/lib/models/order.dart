import 'menu_item.dart';

class OrderItemOption {
  final String name; // e.g. "Oat Milk", "Sugar-Free Syrup", "Extra Shot"
  final double extraPrice;

  const OrderItemOption({required this.name, this.extraPrice = 0.0});

  Map<String, dynamic> toJson() => {'name': name, 'extraPrice': extraPrice};

  factory OrderItemOption.fromJson(Map<String, dynamic> json) => OrderItemOption(
    name: json['name'] as String,
    extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0.0,
  );
}

class OrderItem {
  final MenuItem item;
  final int quantity;
  final List<OrderItemOption> options;
  final String? customInstructions;

  const OrderItem({
    required this.item,
    this.quantity = 1,
    this.options = const [],
    this.customInstructions,
  });

  double get totalPrice {
    final optionsCost = options.fold<double>(0.0, (sum, opt) => sum + opt.extraPrice);
    return (item.price + optionsCost) * quantity;
  }

  Map<String, dynamic> toJson() => {
    'item': item.toJson(),
    'quantity': quantity,
    'options': options.map((o) => o.toJson()).toList(),
    'customInstructions': customInstructions,
    'totalPrice': totalPrice,
  };

  factory OrderItem.fromParsedJson(Map<String, dynamic> json) {
    final itemName = json['name'] as String? ?? 'Custom Item';
    final matchedMenu = cafeMenuCatalog.firstWhere(
      (m) => m.name.toLowerCase().contains(itemName.toLowerCase()) || itemName.toLowerCase().contains(m.name.toLowerCase()),
      orElse: () => MenuItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: itemName,
        description: 'Customer requested beverage/snack',
        price: (json['unit_price'] as num?)?.toDouble() ?? 4.00,
        category: 'Custom',
        dietaryTags: List<String>.from(json['dietary_tags'] ?? []),
      ),
    );

    final rawOptions = json['options'] as List<dynamic>? ?? [];
    final parsedOptions = rawOptions.map((opt) {
      if (opt is String) {
        final lower = opt.toLowerCase();
        double extra = 0.0;
        if (lower.contains('oat') || lower.contains('almond')) extra = 0.75;
        if (lower.contains('extra shot')) extra = 1.00;
        return OrderItemOption(name: opt, extraPrice: extra);
      } else if (opt is Map<String, dynamic>) {
        return OrderItemOption.fromJson(opt);
      }
      return OrderItemOption(name: opt.toString());
    }).toList();

    return OrderItem(
      item: matchedMenu,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      options: parsedOptions,
      customInstructions: json['notes'] as String?,
    );
  }
}

class OrderReceipt {
  final String orderId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String customerLanguage;
  final String customerReply;
  final String staffNotesEnglish;
  final List<String> consolidatedDietaryTags;
  final DateTime timestamp;

  OrderReceipt({
    required this.orderId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.customerLanguage,
    required this.customerReply,
    required this.staffNotesEnglish,
    required this.consolidatedDietaryTags,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'customerLanguage': customerLanguage,
    'customerReply': customerReply,
    'staffNotesEnglish': staffNotesEnglish,
    'consolidatedDietaryTags': consolidatedDietaryTags,
    'timestamp': timestamp.toIso8601String(),
  };
}
