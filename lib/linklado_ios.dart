import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Mesmas cores do onboarding Android
const _purple = Color(0xFFb30ce3);
const _green  = Color(0xFFa4e036);

// Roxo escuro usado nos chips de caracteres (mesma cor da fileira roxa do teclado)
const _keyPurple = Color(0xFF7c3aed);

class LinkladoIOS extends StatefulWidget {
  const LinkladoIOS({super.key});

  @override
  State<LinkladoIOS> createState() => _LinkladoIOSState();
}

class _LinkladoIOSState extends State<LinkladoIOS> {
  int _step = 0;

  void _goTo(int s) => setState(() => _step = s);

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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          _StepBar(currentStep: _step),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _EnableScreen(onNext: () => _goTo(1)),
                _SwitchTipScreen(onNext: () => _goTo(2), onBack: () => _goTo(0)),
                _ReadyScreen(onBack: () => _goTo(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de progresso ────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int currentStep;
  const _StepBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
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

// ── Tela 0: Adicionar teclado nos Ajustes ─────────────────────────────────────

class _EnableScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _EnableScreen({required this.onNext});

  Future<void> _openKeyboardSettings() async {
    // Tenta abrir diretamente as configurações de teclado
    final deep = Uri.parse('App-Prefs:root=General&path=Keyboard');
    if (await canLaunchUrl(deep)) {
      await launchUrl(deep);
      return;
    }
    // Fallback: abre os Ajustes gerais do app
    final fallback = Uri.parse('app-settings:');
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback);
    }
  }

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
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Text(
            'O teclado para línguas indígenas amazônicas — com caracteres como ʉ, ɨ, ɛ, ŋ e muito mais.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 32),
          const _InstructionCard(step: '1', text: 'Toque em "Abrir Ajustes" para ir às configurações de teclado.'),
          const SizedBox(height: 12),
          const _InstructionCard(step: '2', text: 'Vá em Geral → Teclado → Teclados → Adicionar teclado…'),
          const SizedBox(height: 12),
          const _InstructionCard(step: '3', text: 'Em "Teclados de terceiros", encontre Linklado e toque para adicionar.'),
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
                    'O iOS exibe um aviso ao ativar teclados de terceiros. '
                    'O Linklado não coleta, armazena nem transmite nenhum texto digitado.',
                    style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _primaryBtn('Abrir Ajustes', _openKeyboardSettings),
          const SizedBox(height: 16),
          _ghostBtn('Já fiz isso', onNext),
        ],
      ),
    );
  }
}

// ── Tela 1: Como ativar o Linklado em um campo de texto ───────────────────────

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
            'Como usar o Linklado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'O Linklado está adicionado. Veja como ativá-lo sempre que precisar digitar caracteres especiais:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _InstructionCard(step: '1', text: 'Toque em qualquer campo de texto para abrir o teclado.'),
          const SizedBox(height: 10),
          const _InstructionCard(step: '2', text: 'Pressione e segure a tecla 🌐 (globo) no canto inferior do teclado.'),
          const SizedBox(height: 10),
          const _InstructionCard(step: '3', text: 'Selecione Linklado na lista que aparecer.'),
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
                    'Para voltar ao teclado padrão, segure 🌐 novamente e selecione o teclado desejado.',
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

// ── Tela 2: Tutorial + campo de teste ─────────────────────────────────────────

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
            style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'O Linklado está instalado e pronto para usar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          // Campo de teste
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Toque aqui e ative o Linklado para experimentar...',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                const _Tip(icon: Icons.view_week_rounded,  text: 'Na fileira inferior do teclado: ɛ ɔ ŋ ç ʔ ʼ ~ ´'),
                const SizedBox(height: 6),
                const _Tip(icon: Icons.compare_arrows_rounded, text: 'Ao lado das letras u e i: ʉ (depois do u) e ɨ (depois do i)'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['ɛ','ɔ','ŋ','ç','ʔ','ʼ','~','´','ʉ','ɨ','ñ'].map((c) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _keyPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ).toList(),
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
                _InstructionCard(step: '1', text: 'Pressione e segure qualquer tecla por um momento.'),
                SizedBox(height: 8),
                _InstructionCard(step: '2', text: 'Um menu aparece acima com todas as variantes disponíveis.'),
                SizedBox(height: 8),
                _InstructionCard(step: '3', text: 'Arraste o dedo até o caractere desejado e solte. Pronto!'),
                SizedBox(height: 10),
                _Tip(
                  icon: Icons.text_fields,
                  text: 'As teclas de acento (~ ´ ` ^ ¨ ¯ ˙ ˇ) são combinadas: toque primeiro o caractere e depois o acento (ex: a + ~ = ã, e + ´ = é).',
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
                _InstructionCard(step: '1', text: 'Enquanto o teclado estiver aberto, pressione e segure a tecla 🌐.'),
                SizedBox(height: 8),
                _InstructionCard(step: '2', text: 'Escolha o teclado desejado na lista.'),
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

// ── Widgets compartilhados ────────────────────────────────────────────────────

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
        image: DecorationImage(image: AssetImage('assets/logo_linklado.png'), fit: BoxFit.fill),
      ),
    );
  }
}

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
            decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Text(step, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _TutorialCard({required this.icon, required this.title, required this.child});

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
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
          child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }
}

Widget _primaryBtn(String label, VoidCallback onTap) => ElevatedButton(
  onPressed: onTap,
  style: ElevatedButton.styleFrom(
    backgroundColor: _green,
    foregroundColor: Colors.black87,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  label: const Text('Voltar', style: TextStyle(color: Colors.white54, fontSize: 15)),
);
