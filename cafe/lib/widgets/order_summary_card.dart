import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderSummaryCard extends StatelessWidget {
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final Set<String> dietaryTags;
  final VoidCallback? onClear;
  final VoidCallback? onConfirm;

  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.dietaryTags,
    this.onClear,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.coffee_rounded, size: 48, color: Colors.brown.shade200),
              const SizedBox(height: 8),
              Text(
                'Your cart is empty',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Speak in any language, type, or use hand signs!',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Colors.brown),
                  const SizedBox(width: 8),
                  Text(
                    'Active Order (${items.length} items)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: onClear,
                tooltip: 'Clear cart',
              ),
            ],
          ),

          // Dietary tags chips
          if (dietaryTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: dietaryTags.map((tag) {
                Color chipColor = Colors.green.shade50;
                Color textColor = Colors.green.shade800;
                IconData icon = Icons.check_circle_outline;

                if (tag.contains('Dairy-Free')) {
                  chipColor = Colors.blue.shade50;
                  textColor = Colors.blue.shade800;
                  icon = Icons.local_drink_outlined;
                } else if (tag.contains('Sugar-Free')) {
                  chipColor = Colors.purple.shade50;
                  textColor = Colors.purple.shade800;
                  icon = Icons.health_and_safety_outlined;
                }

                return Chip(
                  avatar: Icon(icon, size: 14, color: textColor),
                  label: Text(tag, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600)),
                  backgroundColor: chipColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],

          const Divider(height: 20),

          // Item breakdown
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (item.options.isNotEmpty)
                        Text(
                          item.options.map((o) => o.name).join(', '),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          )),

          const Divider(height: 20),

          // Pricing live total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (8.25%)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text('\$${tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.brown.shade900,
                ),
              ),
            ],
          ),

          if (onConfirm != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
                label: const Text('Confirm Order (or Sign Thumbs-Up 👍)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
