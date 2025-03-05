import 'package:flutter/material.dart';

class CustomButtonBar extends StatelessWidget {
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final Function(String) onShowInfo;

  const CustomButtonBar({
    super.key,
    required this.onIncrement,
    required this.onReset,
    required this.onShowInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("增加"),
            onPressed: onIncrement,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: const Text("重置"),
            onPressed: onReset,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.info),
            label: const Text("信息"),
            onPressed: () => onShowInfo("查看应用信息"),
          ),
        ],
      ),
    );
  }
}
