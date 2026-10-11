import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderReceiptModal extends StatelessWidget {
  final OrderReceipt receipt;

  const OrderReceiptModal({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Sent to Barista! 🎉',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Ticket #${receipt.orderId}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dual Language Display: Customer Native Response
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.translate_rounded, size: 14, color: Colors.brown.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Customer Language (${receipt.customerLanguage}):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receipt.customerReply,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Barista Ticket (English standard)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_cafe_rounded, size: 14, color: Colors.grey.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'Barista Ticket (Standard English):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...receipt.items.map((item) => Text(
                    '• ${item.quantity}x ${item.item.name} ${item.options.isNotEmpty ? "(${item.options.map((o) => o.name).join(', ')})" : ""}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  )),
                  const SizedBox(height: 6),
                  Text(
                    'Kitchen Note: ${receipt.staffNotesEnglish}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Charged', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '\$${receipt.total.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown.shade900),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done & Start New Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
