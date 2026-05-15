import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';
import 'styles.dart';

// Combining diacritics — (label, Unicode combining character)
const _diacriticos = [
  ('~', '̃'), ('´', '́'), ('`', '̀'), ('^', '̂'),
  ('¨', '̈'), ('¯', '̄'), ('˙', '̇'), ('ˇ', '̌'),
];

final _groups = <String, List<(String, String)>>{
  'Esp': [
    ('ñ','Ñ'), ('ç','Ç'), ('ŋ','Ŋ'), ('ɲ','Ɲ'),
    ('ɛ','Ɛ'), ('ɔ','Ɔ'), ('ɨ','Ɨ'), ('ʉ','Ʉ'),
    ('ə','Ə'), ('ß','ß'), ('æ','Æ'), ('ʔ','ʔ'), ('ʼ','ʼ'),
  ],
  'a': [('á','Á'),('à','À'),('â','Â'),('ã','Ã'),('ä','Ä'),('ā','Ā'),('ă','Ă'),('æ','Æ')],
  'e': [('é','É'),('è','È'),('ê','Ê'),('ẽ','Ẽ'),('ë','Ë'),('ē','Ē'),('ə','Ə')],
  'i': [('í','Í'),('ì','Ì'),('î','Î'),('ĩ','Ĩ'),('ï','Ï'),('ī','Ī')],
  'o': [('ó','Ó'),('ò','Ò'),('ô','Ô'),('õ','Õ'),('ö','Ö'),('ō','Ō')],
  'u': [('ú','Ú'),('ù','Ù'),('û','Û'),('ũ','Ũ'),('ü','Ü'),('ǘ','Ǘ'),('ǜ','Ǜ'),('ū','Ū')],
  'ɛ': [('ɛ̃','Ɛ̃'),('ɛ́','Ɛ́'),('ɛ̀','Ɛ̀')],
  'ɔ': [('ɔ̃','Ɔ̃'),('ɔ́','Ɔ́'),('ɔ̀','Ɔ̀')],
  'ɨ': [('ɨ̃','Ɨ̃'),('ɨ́','Ɨ́'),('ɨ̀','Ɨ̀')],
  'ʉ': [('ʉ̃','Ʉ̃'),('ʉ́','Ʉ́'),('ʉ̀','Ʉ̀'),('ʉ̈','Ʉ̈')],
};

class LinkladoWindows extends StatefulWidget {
  const LinkladoWindows({super.key});

  @override
  State<LinkladoWindows> createState() => _LinkladoWindowsState();
}

class _LinkladoWindowsState extends State<LinkladoWindows> with WindowListener {
  bool _shifted = false;
  String _selectedGroup = 'Esp';
  int _targetHwnd = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _poll() async {
    final isFocused = await windowManager.isFocused();
    if (!isFocused) {
      final fgHwnd = GetForegroundWindow();
      if (fgHwnd != 0) _targetHwnd = fgHwnd;
    }

    final shiftDown = GetAsyncKeyState(VK_SHIFT) & 0x8000 != 0;
    final capsOn = GetKeyState(VK_CAPITAL) & 0x0001 != 0;
    final newShifted = shiftDown ^ capsOn;
    if (newShifted != _shifted && mounted) {
      setState(() => _shifted = newShifted);
    }
  }

  void _type(String text) {
    if (_targetHwnd != 0) {
      SetForegroundWindow(_targetHwnd);
    }
    Future.delayed(const Duration(milliseconds: 50), () => _sendUnicode(text));
  }

  void _sendUnicode(String text) {
    final utf16 = text.codeUnits;
    final inputs = calloc<INPUT>(utf16.length * 2);
    for (var i = 0; i < utf16.length; i++) {
      inputs[i * 2].type = INPUT_KEYBOARD;
      inputs[i * 2].ki.wVk = 0;
      inputs[i * 2].ki.wScan = utf16[i];
      inputs[i * 2].ki.dwFlags = KEYEVENTF_UNICODE;

      inputs[i * 2 + 1].type = INPUT_KEYBOARD;
      inputs[i * 2 + 1].ki.wVk = 0;
      inputs[i * 2 + 1].ki.wScan = utf16[i];
      inputs[i * 2 + 1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    }
    SendInput(utf16.length * 2, inputs, sizeOf<INPUT>());
    free(inputs);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: roxoLinklado,
      child: Column(
        children: [
          _DiacriticsRow(
            shifted: _shifted,
            onToggleShift: () => setState(() => _shifted = !_shifted),
            onType: _type,
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white12),
          _CombinationsArea(
            pairs: _groups[_selectedGroup]!,
            shifted: _shifted,
            onType: _type,
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white12),
          _GroupPicker(
            groups: _groups.keys.toList(),
            selected: _selectedGroup,
            onSelect: (g) => setState(() => _selectedGroup = g),
          ),
        ],
      ),
    );
  }
}

// ── Diacritics row ─────────────────────────────────────────────────────────

class _DiacriticsRow extends StatelessWidget {
  final bool shifted;
  final VoidCallback onToggleShift;
  final void Function(String) onType;
  const _DiacriticsRow({required this.shifted, required this.onToggleShift, required this.onType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleShift,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: shifted ? verdeLinklado : Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text('⇧',
                  style: TextStyle(
                    fontSize: 15,
                    color: shifted ? Colors.black87 : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _diacriticos.map((d) {
                final (display, value) = d;
                return _KeyButton(display: display, size: 30, onTap: () => onType(value));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Combinations area ───────────────────────────────────────────────────────

class _CombinationsArea extends StatelessWidget {
  final List<(String, String)> pairs;
  final bool shifted;
  final void Function(String) onType;
  const _CombinationsArea({required this.pairs, required this.shifted, required this.onType});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: pairs.map((pair) {
            final char = shifted ? pair.$2 : pair.$1;
            return _KeyButton(display: char, size: 36, onTap: () => onType(char));
          }).toList(),
        ),
      ),
    );
  }
}

// ── Group / letter picker ───────────────────────────────────────────────────

class _GroupPicker extends StatelessWidget {
  final List<String> groups;
  final String selected;
  final void Function(String) onSelect;
  const _GroupPicker({required this.groups, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Row(
        children: groups.map((g) {
          final isSelected = g == selected;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? verdeLinklado : roxoEscuroLinklado,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                g,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Shared key button ───────────────────────────────────────────────────────

class _KeyButton extends StatefulWidget {
  final String display;
  final double size;
  final VoidCallback onTap;
  const _KeyButton({required this.display, required this.size, required this.onTap});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _pressed ? verdeLinklado.withValues(alpha: 0.65) : verdeLinklado,
          borderRadius: BorderRadius.circular(6),
          boxShadow: _pressed ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.28), offset: const Offset(0, 2), blurRadius: 3),
          ],
        ),
        child: Center(
          child: Text(widget.display,
            style: TextStyle(
              fontSize: widget.size * 0.44,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
