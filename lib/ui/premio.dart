import 'dart:async';

import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// After a rewarded video: a short, clear "you got it" card at the top of
/// the screen, so watching the ad feels worth it. Over everything (dialogs
/// included), never blocks touches, gone after a couple of seconds.
void mostrarPremio(
  BuildContext context,
  String texto, {
  IconData icon = Icons.card_giftcard_rounded,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Premio(
      texto: texto,
      icon: icon,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _Premio extends StatefulWidget {
  const _Premio({
    required this.texto,
    required this.icon,
    required this.onDone,
  });
  final String texto;
  final IconData icon;
  final VoidCallback onDone;

  @override
  State<_Premio> createState() => _PremioState();
}

class _PremioState extends State<_Premio> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2400), () async {
      if (!mounted) return;
      await _anim.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entra = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 70,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _anim,
            child: ScaleTransition(
              scale: entra,
              child: Semantics(
                container: true,
                liveRegion: true,
                label: widget.texto,
                excludeSemantics: true,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE082), Palette.accent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 12),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: const Color(0xFF6B3A00)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.texto,
                            textAlign: TextAlign.center,
                            style: displayText(
                              18,
                              color: const Color(0xFF3A1E00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
