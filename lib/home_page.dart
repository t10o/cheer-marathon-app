import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: 位置情報の送信を開始
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(
                    side: BorderSide(
                      color: Colors.black,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  padding: const EdgeInsets.all(50),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
