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
var platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
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
    prefs = await SharedPreferences.getInstance();
  }

  if (Platform.isAndroid) {
    platform = const LinkladoAndroid();
  } else if (Platform.isWindows) {
    platform = const LinkladoWindows();
  } else if (Platform.isIOS) {
    platform = const LinkladoIOS();
  } else {
    platform = const LinkladoAndroid();
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
      home: platform,
    );
  }
}

class LinkladoWindows extends StatefulWidget {
  const LinkladoWindows({Key? key}) : super(key: key);

  @override
  State<LinkladoWindows> createState() => _LinkladoWindowsState();
}

class _LinkladoWindowsState extends State<LinkladoWindows> with WindowListener {
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
      if (isFocused) {
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            key!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
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
        title: const Text('Linklado', style: TextStyle(color: Colors.white),),
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
            linkladoKey(key: '¯', unicode: 0x0304)!,
            linkladoKey(key: '˙', unicode: 0x0307)!,
          ],
        ),
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
    // Assuming prefs is defined elsewhere in your code
    index = prefs.getInt("index") ?? 0;
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
        title: const Text('Linklado', style: TextStyle(color: Colors.white),),
      ),
      body: IndexedStack(
        index: index,
        children: [
          buildWelcomeScreen(),
          buildActivationScreen(),
          buildInputMethodScreen(),
          buildFinalScreen(),
        ],
      ),
    );
  }

  Widget buildWelcomeScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildLogo(),
        const SizedBox(height: 30),
        const Text(
          "Seja bem-vindo ao Linklado!\nPara começar a utilizar o teclado, ative nas configurações.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        buildButton('Ativar o Linklado', ativarLinklado),
        const SizedBox(height: 20),
        buildNextButton(),
      ],
    );
  }

  Widget buildActivationScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildLogo(),
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
        buildButton('Usar o Linklado como método de entrada', metodoEntradaLinklado),
        const SizedBox(height: 20),
        buildNavigationButtons(),
      ],
    );
  }

  Widget buildInputMethodScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildLogo(),
        const SizedBox(height: 30),
        const Text(
          "Se você precisar parar de usar o Linklado, \nquando você clicar em algum lugar que "
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
          "Tudo o que você precisa fazer é apertar nele e selecionar seu teclado normal!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        buildNavigationButtons(),
      ],
    );
  }

  Widget buildFinalScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildLogo(),
        const SizedBox(height: 30),
        const Text(
          "Parabéns! O teclado Linklado está pronto para uso!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          "Para acessar caracteres especiais como ~, ', \\, -, entre outros pressione e segure a tecla correspondente.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        buildNavigationButtons(),
      ],
    );
  }

  Widget buildLogo() {
    return Container(
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
          image: AssetImage('assets/logo_linklado.png'),
          fit: BoxFit.fill,
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget buildButton(String text, Function onTap) {
    return ElevatedButton(
      onPressed: () => onTap(),
      style: ElevatedButton.styleFrom(
        backgroundColor: verdeLinklado,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text(text),
    );
  }

  Widget buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          index = 1;
          prefs.setInt("index", 1);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: verdeLinklado,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: const Text('Próximo'),
    );
  }

  Widget buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (index > 0) {
                index--;
                prefs.setInt("index", index);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeLinklado,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('<'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (index < 3) {
                index++;
                prefs.setInt("index", index);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeLinklado,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('>'),
        ),
      ],
    );
  }
}

class LinkladoIOS extends StatefulWidget {
  const LinkladoIOS({Key? key}) : super(key: key);

  @override
  State<LinkladoIOS> createState() => _LinkladoIOSState();
}

class _LinkladoIOSState extends State<LinkladoIOS> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoLinklado,
      appBar: AppBar(
        backgroundColor: roxoLinklado,
        title: const Text(
          'Linklado',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: index,
        children: [
          buildWelcomeScreen(),
          buildInstructionsScreen(),
          buildFinalScreen(),
        ],
      ),
    );
  }

  Widget buildWelcomeScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildLogo(),
        const SizedBox(height: 30),
        const Text(
          "Seja bem-vindo ao Linklado!\nPara começar a utilizar o teclado, siga as instruções.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        buildNextButton(),
      ],
    );
  }

  Widget buildInstructionsScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Instruções para iOS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInstructionStep('1. Abra as "Configurações" do seu dispositivo iOS.'),
          _buildInstructionStep('2. Vá para "Geral" > "Teclado" > "Teclados" > "Adicionar novo teclado".'),
          _buildInstructionStep('3. Encontre "Linklado" na lista de teclados de terceiros e adicione-o.'),
          _buildInstructionStep('4. Clique em "Linklado" na lista de teclados adicionados.'),
          _buildInstructionStep('5. Ative a opção "Permitir Acesso Total".'),
          _buildInstructionStep('6. Abra qualquer aplicativo que exija entrada de texto.'),
          _buildInstructionStep('7. Pressione e segure o ícone de globo no teclado e selecione "Linklado".'),
          const SizedBox(height: 30),
          buildNextButton(),
        ],
      ),
    );
  }

  Widget buildFinalScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildLogo(),
        const SizedBox(height: 30),
        const Text(
          "Parabéns! O teclado Linklado está pronto para uso!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Para acessar caracteres especiais como ~, ', \\, -, pressione e segure a tecla correspondente.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildLogo() {
    return Container(
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
          image: AssetImage('assets/logo_linklado.png'),
          fit: BoxFit.fill,
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget buildNextButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            index++;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeLinklado,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: const Text('Próximo'),
      ),
    );
  }

  Widget _buildInstructionStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}