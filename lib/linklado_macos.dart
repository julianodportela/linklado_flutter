import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles.dart';

const _channel = MethodChannel('com.linklado/keyboard');

// Combining diacritics — (label, Unicode combining character)
const _diacriticos = [
  ('~', '̃'), ('´', '́'), ('`', '̀'), ('^', '̂'),
  ('¨', '̈'), ('¯', '̄'), ('˙', '̇'), ('ˇ', '̌'),
];

// Each group: list of (lowercase, uppercase) pairs.
// When no distinct uppercase exists the two values are identical.
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

class LinkladoMacOS extends StatefulWidget {
  const LinkladoMacOS({super.key});

  @override
  State<LinkladoMacOS> createState() => _LinkladoMacOSState();
}

class _LinkladoMacOSState extends State<LinkladoMacOS> {
  bool _hasAccessibility = false;
  bool _shifted = false;
  String _selectedGroup = 'Esp';
  Timer? _permissionPoller;

  @override
  void initState() {
    super.initState();
    _checkAccessibility();
    _channel.setMethodCallHandler(_handleNativeCall);
    _permissionPoller = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_hasAccessibility) _checkAccessibility();
    });
  }

  @override
  void dispose() {
    _permissionPoller?.cancel();
    super.dispose();
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'shiftChanged' && mounted) {
      setState(() => _shifted = call.arguments as bool? ?? false);
    }
  }

  Future<void> _checkAccessibility() async {
    final ok = await _channel.invokeMethod<bool>('checkAccessibility') ?? false;
    if (mounted) {
      setState(() => _hasAccessibility = ok);
      _resizeWindow(ok);
      if (ok) {
        _permissionPoller?.cancel();
        _permissionPoller = null;
      }
    }
  }

  void _resizeWindow(bool showKeyboard) {
    _channel.invokeMethod('setWindowSize', {
      'width': 310.0,
      'height': showKeyboard ? 200.0 : 280.0,
    });
  }

  Future<void> _type(String value) async {
    await _channel.invokeMethod('typeCharacter', value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccessibility) {
      return _PermissionBanner(
        onOpenSettings: () => _channel.invokeMethod('requestAccessibility'),
      );
    }

    return Material(
      color: roxoLinklado,
      child: Column(
        children: [
          // Diacríticos — always visible at the top (most important)
          _DiacriticsRow(
            shifted: _shifted,
            onToggleShift: () => setState(() => _shifted = !_shifted),
            onType: _type,
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white12),
          // Precomposed combinations for the selected group
          _CombinationsArea(
            pairs: _groups[_selectedGroup]!,
            shifted: _shifted,
            onType: _type,
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white12),
          // Letter / group picker
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
          // Shift toggle
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
          // Diacritic buttons — fill remaining width equally
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

// ── Permission banner ───────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionBanner({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: roxoLinklado,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(Icons.lock_open, color: Colors.white, size: 36),
            const Spacer(flex: 2),
            const Text(
              'Permissão necessária',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'O Linklado precisa de permissão de Acessibilidade para digitar em outros aplicativos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const Spacer(flex: 2),
            ElevatedButton(
              onPressed: onOpenSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: verdeLinklado,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Permitir acesso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
