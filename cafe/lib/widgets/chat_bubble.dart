import 'package:flutter/material.dart';
import '../models/order.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? translatedReceiptPreview;
  final List<String> suggestionChips;
  final Function(String chipText)? onChipSelected;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.translatedReceiptPreview,
    this.suggestionChips = const [],
    this.onChipSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isUser ? Colors.brown.shade700 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.brown.shade900,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (translatedReceiptPreview != null && translatedReceiptPreview!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🧾 English Barista Note: $translatedReceiptPreview',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.brown.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            // Interactive quick-selection chips for coffee types and options
            if (!isUser && suggestionChips.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Tap to select a coffee type:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestionChips.map((chip) {
                  return ActionChip(
                    avatar: const Icon(Icons.coffee_rounded, size: 14, color: Colors.brown),
                    label: Text(chip, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    backgroundColor: Colors.brown.shade50,
                    side: BorderSide(color: Colors.brown.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    visualDensity: VisualDensity.compact,
                    onPressed: onChipSelected != null ? () => onChipSelected!(chip) : null,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
