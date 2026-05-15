import 'package:Linklado/linklado_android.dart';
import 'package:Linklado/linklado_ios.dart';
import 'package:Linklado/linklado_macos.dart';
import 'package:Linklado/linklado_windows.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: ui.Size(310, 200),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: false,
    );

    windowManager.setAlwaysOnTop(true);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }

  // macOS: window size and always-on-top are handled natively in MainFlutterWindow.swift.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (Platform.isAndroid) {
      home = const LinkladoAndroid();
    } else if (Platform.isWindows) {
      home = const LinkladoWindows();
    } else if (Platform.isIOS) {
      home = const LinkladoIOS();
    } else if (Platform.isMacOS) {
      home = const LinkladoMacOS();
    } else {
      home = const LinkladoAndroid();
    }

    return MaterialApp(
      title: 'Linklado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: home,
    );
  }
}


