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
            children: const [
              Text(
                "Günther Hiden",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.star, color: Colors.amber, size: 20),
              Icon(Icons.star, color: Colors.amber, size: 20),
              Icon(Icons.star, color: Colors.amber, size: 20),
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
