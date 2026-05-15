import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel =
    MethodChannel('com.linklado.tuklado.tuklado_flutter/channelLinklado');

const _purple = Color(0xFFb30ce3);
const _green = Color(0xFFa4e036);
const _keyPurple = Color(0xFF7c3aed);

class LinkladoAndroid extends StatefulWidget {
  const LinkladoAndroid({super.key});

  @override
  State<LinkladoAndroid> createState() => _LinkladoAndroidState();
}

class _LinkladoAndroidState extends State<LinkladoAndroid>
    with WidgetsBindingObserver {
  int _step = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Reconfirma o status sempre que o usuário volta de outro aplicativo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    try {
      final enabled =
          await _channel.invokeMethod<bool>('isLinkladoEnabled') ?? false;
      final active =
          await _channel.invokeMethod<bool>('isLinkladoActive') ?? false;

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('onboarding_step') ?? 0;

      int step;
      if (active) {
        // Só pula a dica de troca (passo 2) se o usuário já a concluiu (passo salvo >= 3).
        // "Já fiz isso" no passo 1 salva passo=2, o que não deve pular o passo 2.
        step = saved >= 3 ? 3 : 2;
      } else if (enabled) {
        step = 1;
      } else {
        step = saved;
        // Não permite avançar além do passo 0 se o teclado não está habilitado
        if (step > 0) step = 0;
      }

      if (mounted) setState(() { _step = step; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onboarding_step', step);
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _saveStep(step);
  }

  Future<void> _openSettings() =>
      _channel.invokeMethod('startSettingsPageLinklado');

  Future<void> _openInputPicker() =>
      _channel.invokeMethod('startInputMethodPageLinklado');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purple,
      appBar: AppBar(
        backgroundColor: _purple,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Linklado',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _StepBar(currentStep: _step),
                Expanded(
                  child: IndexedStack(
                    index: _step,
                    children: [
                      _EnableScreen(
                        onEnable: _openSettings,
                        onNext: () => _goTo(1),
                      ),
                      _ActivateScreen(
                        onActivate: _openInputPicker,
                        onNext: () => _goTo(2),
                        onBack: () => _goTo(0),
                      ),
                      _SwitchTipScreen(
                        onNext: () => _goTo(3),
                        onBack: () => _goTo(1),
                      ),
                      _ReadyScreen(onBack: () => _goTo(2)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Step progress bar ─────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int currentStep;
  const _StepBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(4, (i) {
          final done = i <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: done ? _green : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
        image: DecorationImage(
          image: AssetImage('assets/logo_linklado.png'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

Widget _primaryBtn(String label, VoidCallback onTap) => ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _green,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );

Widget _ghostBtn(String label, VoidCallback onTap) => TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white54,
        ),
      ),
    );

Widget _backBtn(VoidCallback onTap) => TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 18),
      label: const Text(
        'Voltar',
        style: TextStyle(color: Colors.white54, fontSize: 15),
      ),
    );

// ── Screen 0: Enable in Settings ─────────────────────────────────────────────

class _EnableScreen extends StatelessWidget {
  final VoidCallback onEnable;
  final VoidCallback onNext;
  const _EnableScreen({required this.onEnable, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const _Logo(),
          const SizedBox(height: 28),
          const Text(
            'Bem-vindo ao Linklado!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Text(
            'O teclado para línguas indígenas amazônicas — com caracteres como ʉ, ɨ, ɛ, ŋ e muito mais.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 32),
          const _InstructionCard(
            step: '1',
            text:
                'Toque em "Ativar o Linklado" para abrir as configurações de teclado do Android.',
          ),
          const SizedBox(height: 12),
          const _InstructionCard(
            step: '2',
            text: 'Encontre "Linklado" na lista e ative o interruptor.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: Colors.white70, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'O Android exibe um aviso de segurança ao ativar qualquer teclado de terceiros. '
                    'O Linklado não coleta, armazena nem transmite nenhum texto digitado.',
                    style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _primaryBtn('Ativar o Linklado', onEnable),
          const SizedBox(height: 16),
          _ghostBtn('Já fiz isso', onNext),
        ],
      ),
    );
  }
}

// ── Screen 1: Set as active IME ──────────────────────────────────────────────

class _ActivateScreen extends StatelessWidget {
  final VoidCallback onActivate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  const _ActivateScreen(
      {required this.onActivate, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const _Logo(),
          const SizedBox(height: 28),
          const Text(
            'Definir como teclado ativo',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Text(
            'O Linklado está ativado. Agora defina-o como seu teclado padrão.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 32),
          const _InstructionCard(
            step: '1',
            text: 'Toque em "Usar o Linklado" para abrir o seletor de teclado.',
          ),
          const SizedBox(height: 12),
          const _InstructionCard(
            step: '2',
            text:
                'Selecione "Linklado" na lista de teclados disponíveis.',
          ),
          const SizedBox(height: 28),
          _primaryBtn('Usar o Linklado', onActivate),
          const SizedBox(height: 16),
          _ghostBtn('Já fiz isso', onNext),
          const SizedBox(height: 4),
          _backBtn(onBack),
        ],
      ),
    );
  }
}

// ── Screen 2: Switch tip ──────────────────────────────────────────────────────

class _SwitchTipScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const _SwitchTipScreen({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.swap_horiz_rounded, size: 70, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'Como trocar de teclado',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'O Linklado agora é seu teclado padrão. Veja como alternar entre ele e o teclado normal quando precisar:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _InstructionCard(
            step: '1',
            text: 'Abra qualquer aplicativo onde você digita (ex: WhatsApp, Notas).',
          ),
          const SizedBox(height: 10),
          const _InstructionCard(
            step: '2',
            text: 'Enquanto o teclado estiver aberto, procure o ícone de teclado na barra de navegação inferior.',
          ),
          const SizedBox(height: 10),
          const _InstructionCard(
            step: '3',
            text: 'Toque nesse ícone e escolha o teclado que deseja usar.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white54, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Em alguns celulares o ícone é um globo ou fica dentro da barra de atalhos do próprio teclado.',
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _primaryBtn('Continuar', onNext),
          const SizedBox(height: 4),
          _backBtn(onBack),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }
}

// ── Screen 3: Ready ───────────────────────────────────────────────────────────

class _ReadyScreen extends StatelessWidget {
  final VoidCallback onBack;
  const _ReadyScreen({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 24 + keyboardH),
      child: Column(
        children: [
          const _Logo(),
          const SizedBox(height: 20),
          const Text(
            'Tudo pronto!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'O Linklado está instalado e pronto para usar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Toque aqui e experimente o teclado Linklado...',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 24),
          _TutorialCard(
            icon: Icons.auto_fix_high,
            title: 'Onde estão os caracteres especiais?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'As teclas em roxo têm os sons das línguas indígenas. Elas ficam em dois lugares:',
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 10),
                const _Tip(
                  icon: Icons.view_week_rounded,
                  text: 'Na fileira inferior do teclado: ɛ ɔ ŋ ç ʔ ʼ ~ ´',
                ),
                const SizedBox(height: 6),
                const _Tip(
                  icon: Icons.compare_arrows_rounded,
                  text: 'Ao lado das letras u e i: ʉ (depois do u) e ɨ (depois do i)',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'ɛ', 'ɔ', 'ŋ', 'ç', 'ʔ', 'ʼ', '~', '´', 'ʉ', 'ɨ', 'ñ',
                  ].map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _keyPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _TutorialCard(
            icon: Icons.touch_app,
            title: 'Como acessar ainda mais variantes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InstructionCard(
                  step: '1',
                  text: 'Pressione e segure qualquer tecla (roxa ou normal) por um momento.',
                ),
                SizedBox(height: 8),
                _InstructionCard(
                  step: '2',
                  text: 'Um menu aparece acima com todas as variantes disponíveis.',
                ),
                SizedBox(height: 8),
                _InstructionCard(
                  step: '3',
                  text: 'Arraste o dedo até o caractere que deseja e solte. Pronto!',
                ),
                SizedBox(height: 10),
                _Tip(
                  icon: Icons.text_fields,
                  text:
                      'As teclas de acento (~ ´ ` ^ ¨ ¯ ˙ ˇ) são combinadas: toque primeiro o caractere e depois o acento desejado (ex: a + ~ = ã, e + ´ = é).',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _TutorialCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Como trocar de teclado',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para voltar ao teclado padrão ou escolher outro:',
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 10),
                _InstructionCard(
                  step: '1',
                  text: 'Enquanto o teclado estiver aberto, toque no ícone de teclado na barra de navegação.',
                ),
                SizedBox(height: 8),
                _InstructionCard(
                  step: '2',
                  text: 'Escolha o teclado desejado na lista.',
                ),
                SizedBox(height: 10),
                _Tip(
                  icon: Icons.info_outline,
                  text: 'Em alguns celulares o ícone aparece como um globo ou fica na barra de atalhos do teclado.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _backBtn(onBack),
        ],
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _TutorialCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Instruction card ──────────────────────────────────────────────────────────

class _InstructionCard extends StatelessWidget {
  final String step;
  final String text;
  const _InstructionCard({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
