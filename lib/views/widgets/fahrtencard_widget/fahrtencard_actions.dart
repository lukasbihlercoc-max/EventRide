import 'package:flutter/material.dart';

class FahrtenCardActions extends StatelessWidget {
  final bool isEditable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onJoin;

  const FahrtenCardActions({
    super.key,
    required this.isEditable,
    required this.onEdit,
    required this.onDelete,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: isEditable
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: onDelete,
                  child: const Text("Löschen"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onEdit,
                  child: const Text("Bearbeiten"),
                ),
              ],
            )
          : ElevatedButton(
              onPressed: onJoin,
              child: const Text("Mitfahren"),
            ),
    );
  }
}
