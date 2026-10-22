import 'package:flutter/material.dart';

import '../core/hats.dart';
import '../main.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// Modal dialog showing Capi's Wardrobe to select, view, and equip hats.
class WardrobeDialog extends StatefulWidget {
  const WardrobeDialog({super.key, required this.services});
  final AppServices services;

  static Future<void> show(BuildContext context, AppServices services) {
    return showDialog(
      context: context,
      builder: (_) => WardrobeDialog(services: services),
    );
  }

  @override
  State<WardrobeDialog> createState() => _WardrobeDialogState();
}

class _WardrobeDialogState extends State<WardrobeDialog> {
  late CapiHat _selectedHat;
  CapiMood _previewMood = CapiMood.happy;

  @override
  void initState() {
    super.initState();
    _selectedHat = CapiHat.fromId(widget.services.store.equippedHat);
  }

  void _cycleMood() {
    widget.services.feedback.click();
    setState(() {
      _previewMood = switch (_previewMood) {
        CapiMood.happy => CapiMood.cheer,
        CapiMood.cheer => CapiMood.point,
        CapiMood.point => CapiMood.worried,
        CapiMood.worried => CapiMood.happy,
        _ => CapiMood.happy,
      };
    });
  }

  Future<void> _equip(CapiHat hat) async {
    widget.services.feedback.praise(2);
    await widget.services.store.equipHat(hat.id);
    setState(() {
      _selectedHat = hat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final equippedId = store.equippedHat;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: CardPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.checkroom_rounded,
                    color: Color(0xFFF59E0B),
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Guarda-Roupa do Capi',
                    style: displayText(20, color: Palette.text),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Fechar',
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Palette.textDim,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive Capi Preview
              GestureDetector(
                onTap: _cycleMood,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x334F46E5), Color(0x111E1B4B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33818CF8)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Capi(size: 110, mood: _previewMood, hat: _selectedHat),
                      Positioned(
                        bottom: 8,
                        child: Text(
                          'Toque no Capi para trocar o humor!',
                          style: bodyText(12, color: Palette.textDim),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Selected Hat details
              Text(
                _selectedHat.label,
                style: displayText(18, color: Palette.accent),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedHat.description,
                textAlign: TextAlign.center,
                style: bodyText(14, color: Palette.textDim),
              ),
              const SizedBox(height: 16),

              // Hat Selection Grid
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CapiHat.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final hat = CapiHat.values[index];
                    final isUnlocked = hat.isUnlocked(store);
                    final isEquipped = hat.id == equippedId;
                    final isSelected = hat == _selectedHat;

                    return Semantics(
                      button: true,
                      label:
                          '${hat.label}${isEquipped ? ', equipado' : (isUnlocked ? ', desbloqueado' : ', bloqueado')}',
                      child: GestureDetector(
                        onTap: () {
                          widget.services.feedback.click();
                          setState(() => _selectedHat = hat);
                        },
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0x44F59E0B)
                                : const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF59E0B)
                                  : (isEquipped
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0x22FFFFFF)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: isUnlocked ? 1.0 : 0.35,
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: CustomPaint(
                                        painter: CapiPainter(
                                          mood: CapiMood.happy,
                                          t: 0,
                                          hat: hat,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    const Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hat.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: displayText(12, color: Palette.text),
                              ),
                              const SizedBox(height: 4),
                              if (isEquipped)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'EM USO',
                                    style: displayText(9, color: Colors.white),
                                  ),
                                )
                              else if (isUnlocked)
                                Text(
                                  'Disponível',
                                  style: bodyText(
                                    10,
                                    color: const Color(0xFF34D399),
                                  ),
                                )
                              else
                                Text(
                                  'No Baú',
                                  style: bodyText(10, color: Palette.textDim),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (_selectedHat.id != equippedId &&
                  _selectedHat.isUnlocked(store))
                ChunkyButton(
                  label: 'Equipar ${_selectedHat.label}',
                  icon: Icons.check_circle_rounded,
                  onTap: () => _equip(_selectedHat),
                )
              else if (_selectedHat.id == equippedId)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x220284C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x550284C7)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF38BDF8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chapéu Atualmente Equipado',
                        style: displayText(14, color: Colors.white),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x22EF4444),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x44EF4444)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFF87171),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Complete missões para abrir o Baú!',
                        style: displayText(13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
