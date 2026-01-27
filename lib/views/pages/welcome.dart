import 'package:flutter/material.dart';
import 'package:my_app/views/widget_tree.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(20),
              child: Image.asset("assets/image/hg5.jpg"),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pushReplacement(           //? legt eine neue Seite über die vorhandene
                context, 
                MaterialPageRoute(
                  builder: (context) {
                    return WidgetTree();
                  },
                ),
              );
          }, child: Text("Los gehts"))
          ],
        ),
      ),
    );
  }
}