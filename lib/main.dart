import 'dart:async';
import 'dart:ffi';

import 'package:Linklado/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

var prefs;

void main() async {

  if(Platform.isWindows) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: ui.Size(400, 250),
      center: true,
      backgroundColor: roxoLinklado,
    );

    windowManager.setAlwaysOnTop(true);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

  } else {
    WidgetsFlutterBinding.ensureInitialized();
    prefs = await SharedPreferences.getInstance();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linklado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Platform.isAndroid ? const LinkladoAndroid() : const LinkladoWindows(),
    );
  }
}

class LinkladoWindows extends StatefulWidget {
  const LinkladoWindows({Key? key}) : super(key: key);

  @override
  State<LinkladoWindows> createState() => _LinkladoWindowsState();
}
class _LinkladoWindowsState extends State<LinkladoWindows> with WindowListener{

  int hwnd = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void onWindowBlur() {
    Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      bool isFocused = await windowManager.isFocused();
      if(isFocused) {
        timer.cancel();
      } else {
        hwnd = GetForegroundWindow();
      }
    });
  }

  Widget? linkladoKey({String? key, int? unicode}) {
    return GestureDetector(
      onTap: () {

        final inputs = calloc<INPUT>();

        inputs.ref.type = INPUT_KEYBOARD;
        inputs.ref.ki.wVk = 0;
        inputs.ref.ki.wScan = unicode!;
        inputs.ref.ki.dwFlags = KEYEVENTF_UNICODE;

        SetForegroundWindow(hwnd);
        SendInput(1, inputs, sizeOf<INPUT>());

      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
            color: verdeLinklado,
          borderRadius: BorderRadius.circular(10)
        ),
        child: Center(
          child: Text(
            key!,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              color: Colors.black
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoLinklado,
      appBar: AppBar(
        backgroundColor: roxoLinklado,
        title: const Text('Linklado'),
      ),
      body: Center(
          child: GridView.count(
            shrinkWrap: true,
            primary: false,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: const EdgeInsets.all(10),
            crossAxisCount: 7,
            children: [
              linkladoKey(key: 'ʉ', unicode: 0x0289)!,
              linkladoKey(key: 'ɨ', unicode: 0x0268)!,
              linkladoKey(key: 'ñ', unicode: 0x00F1)!,
              linkladoKey(key: 'ç', unicode: 0x00E7)!,
              linkladoKey(key: '\'', unicode: 0x0027)!,
              linkladoKey(key: '~', unicode: 0x0303)!,
              linkladoKey(key: '^', unicode: 0x0302)!,
              linkladoKey(key: 'Ʉ', unicode: 0x0244)!,
              linkladoKey(key: 'Ɨ', unicode: 0x0197)!,
              linkladoKey(key: 'Ñ', unicode: 0x00D1)!,
              linkladoKey(key: 'Ç', unicode: 0x00C7)!,
              linkladoKey(key: '´', unicode: 0x0301)!,
              linkladoKey(key: '`', unicode: 0x0300)!,
              linkladoKey(key: '¨', unicode: 0x0308)!,
            ],
          )
      ),
    );
  }
}

class LinkladoAndroid extends StatefulWidget {
  const LinkladoAndroid({Key? key}) : super(key: key);

  @override
  State<LinkladoAndroid> createState() => _LinkladoAndroidState();
}
class _LinkladoAndroidState extends State<LinkladoAndroid> {

  int index = 0;

  static const platform = MethodChannel('com.linklado.tuklado.tuklado_flutter/channelTuklado');

  void ativarLinklado() async {
    await platform.invokeMethod('startSettingsPageLinklado');
  }

  void metodoEntradaLinklado() async {
    await platform.invokeMethod('startInputMethodPageLinklado');
  }

  void checkNewUser() async {
    index = prefs.getInt("index") == null ? 0 : prefs.getInt('index');
  }

  @override
  void initState() {
    super.initState();

    checkNewUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoLinklado,
      appBar: AppBar(
        backgroundColor: roxoLinklado,
        title: const Text('Linklado'),
      ),
      body: IndexedStack(
        index: index,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 150,
                width: 150,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 0,
                    )
                  ],
                  image: DecorationImage(
                      image: AssetImage(
                        'assets/logo_linklado.png',
                      ),
                      fit: BoxFit.fill
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                  "Seja bem-vindo ao Linklado!\n Para começar a utilizar o teclado, ative nas configurações.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                  backgroundColor: MaterialStateProperty.all(verdeLinklado),
                  textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    )
                  )
                ),
                onPressed: ativarLinklado,
                child: const Text('Ativar o Linklado', style: TextStyle(color: roxoEscuroLinklado)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                    backgroundColor: MaterialStateProperty.all(verdeLinklado),
                    textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                    shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        )
                    )
                ),
                onPressed: () {
                  setState(() {
                    index += 1;
                    prefs.setInt('index', index);
                  });
                },
                child: const Text('>', style: TextStyle(color: roxoEscuroLinklado, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 150,
                width: 150,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 0,
                    )
                  ],
                  image: DecorationImage(
                      image: AssetImage(
                        'assets/logo_linklado.png',
                      ),
                      fit: BoxFit.fill
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                  "Agora, para utilizá-lo, ative-o como método de entrada.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                    backgroundColor: MaterialStateProperty.all(verdeLinklado),
                    textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                    shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        )
                    )
                ),
                onPressed: metodoEntradaLinklado,
                child: const Text('Usar o Linklado como método de entrada', textAlign: TextAlign.center, style: TextStyle(color: roxoEscuroLinklado, fontSize: 18)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children:
              [
                ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                      backgroundColor: MaterialStateProperty.all(verdeLinklado),
                      textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                      shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          )
                      )
                  ),
                  onPressed: () {
                    setState(() {
                      index -= 1;
                      prefs.setInt('index', index);
                    });
                  },
                  child: const Text('<', style: TextStyle(color: roxoEscuroLinklado, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 100),
                ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                      backgroundColor: MaterialStateProperty.all(verdeLinklado),
                      textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                      shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          )
                      )
                  ),
                  onPressed: () {
                    setState(() {
                      index += 1;
                      prefs.setInt('index', index);
                    });
                  },
                  child: const Text('>', style: TextStyle(color: roxoEscuroLinklado, fontWeight: FontWeight.bold)),
                ),
              ],)
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 150,
                width: 150,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 0,
                    )
                  ],
                  image: DecorationImage(
                      image: AssetImage(
                        'assets/logo_linklado.png',
                      ),
                      fit: BoxFit.fill
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                  "Se você precisar parar de usar o Linklado, \n quando você clicar em algum lugar que "
                      "precisa digitar um texto, o seguinte ícone irá aparecer no canto inferior direito da sua tela:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Center(
                child: Icon(
                  Icons.keyboard_alt_outlined, size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                  "Tudo o que você precisa fazer é apertar nele e selecionar o método de entrada que você desejar!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                      backgroundColor: MaterialStateProperty.all(verdeLinklado),
                      textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                      shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          )
                      )
                  ),
                  onPressed: () {
                    setState(() {
                      index -= 1;
                      prefs.setInt('index', index);
                    });
                  },
                  child: const Text('<', style: TextStyle(color: roxoEscuroLinklado, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 100),
                ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                      backgroundColor: MaterialStateProperty.all(verdeLinklado),
                      textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                      shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          )
                      )
                  ),
                  onPressed: () {
                    setState(() {
                      index += 1;
                      prefs.setInt('index', index);
                    });
                  },
                  child: const Text('>', style: TextStyle(color: roxoEscuroLinklado, fontWeight: FontWeight.bold)),
                ),
              ],)
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 150,
                width: 150,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 0,
                    )
                  ],
                  image: DecorationImage(
                      image: AssetImage(
                        'assets/logo_linklado.png',
                      ),
                      fit: BoxFit.fill
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                  "Parabéns, você instalou o Linklado!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                      backgroundColor: MaterialStateProperty.all(verdeLinklado),
                      textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                      shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          )
                      )
                  ),
                  onPressed: ativarLinklado,
                  child: const Text('Ativar o Linklado', style: TextStyle(color: roxoEscuroLinklado)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(16.0)),
                    backgroundColor: MaterialStateProperty.all(verdeLinklado),
                    textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                    shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        )
                    )
                ),
                onPressed: metodoEntradaLinklado,
                child: const Text('Usar o Linklado como método de entrada', textAlign: TextAlign.center, style: TextStyle(color: roxoEscuroLinklado, fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
