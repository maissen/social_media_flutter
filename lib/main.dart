import 'package:flutter/material.dart';
import 'dart:io';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    // Set window title
    setWindowTitle('BrainHub - Where you inspire');

    // Fixed window size (unresizable)
    const fixedSize = Size(430, 932);
    setWindowMinSize(fixedSize);
    setWindowMaxSize(fixedSize);

    // Set initial position and size
    setWindowFrame(Rect.fromLTWH(100, 100, fixedSize.width, fixedSize.height));
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iPhone 17 Pro Max Demo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('iPhone 17 Pro Max Window')),
        body: Center(
          child: Text(
            'This window matches the iPhone 17 Pro Max size\n(430 x 932 px)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
