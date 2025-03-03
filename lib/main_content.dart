import 'package:flutter/material.dart';

class MainContent extends StatelessWidget {
  final int counter;

  const MainContent({super.key, required this.counter});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "当前计数器值：",
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              Text(
                '$counter',
                style: TextStyle(
                  fontSize: 48,
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}