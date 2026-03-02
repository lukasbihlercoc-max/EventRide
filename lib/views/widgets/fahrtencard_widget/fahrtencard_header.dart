import 'package:flutter/material.dart';

class FahrtenCardHeader extends StatelessWidget {
  final String ownerName;
  final bool isEditable;
  final VoidCallback? onChat;

  const FahrtenCardHeader({
    super.key,
    required this.ownerName,
    required this.isEditable,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                ownerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const Icon(Icons.star, color: Colors.amber, size: 20),
            ],
          ),
        ),
        if (isEditable)
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: onChat,
          ),
      ],
    );
  }
}
