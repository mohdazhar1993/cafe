import 'package:flutter/material.dart';

class QuickSignLegend extends StatelessWidget {
  final Function(String command)? onSelectSign;

  const QuickSignLegend({super.key, this.onSelectSign});

  static const List<Map<String, String>> signs = [
    {
      'sign': '👍',
      'label': 'Thumbs Up',
      'action': 'Confirm & Place Order',
      'command': 'Confirm order',
    },
    {
      'sign': '✋',
      'label': 'Open Palm',
      'action': 'Clear Order',
      'command': 'Clear order',
    },
    {
      'sign': '☝️',
      'label': 'Index Finger ("1")',
      'action': 'Order Coffee',
      'command': 'Order 1 Caffe Latte',
    },
    {
      'sign': '✌️',
      'label': 'Peace Sign ("2")',
      'action': 'Order Tea',
      'command': 'Order 1 Matcha Green Tea Latte',
    },
    {
      'sign': '👌',
      'label': 'OK Sign ("O")',
      'action': 'Oat Milk Modifier',
      'command': 'Add Oat Milk',
    },
    {
      'sign': '✊',
      'label': 'Closed Fist',
      'action': 'Sugar-Free Modifier',
      'command': 'Make it Sugar-Free',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sign_language_rounded, size: 18, color: Colors.brown),
              const SizedBox(width: 6),
              Text(
                'Supported Hand Signs & Gestures',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.brown.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: signs.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: onSelectSign != null ? () => onSelectSign!(s['command']!) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(s['sign']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['label']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              Text(
                                s['action']!,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
