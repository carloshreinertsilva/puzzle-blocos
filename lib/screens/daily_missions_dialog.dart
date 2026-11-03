import 'package:flutter/material.dart';

import '../core/daily_missions.dart';
import '../core/passe.dart';
import '../core/presente_diario.dart';
import '../core/wardrobe.dart';
import '../main.dart';
import '../ads/ad_service.dart';
import '../services/progress_store.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import 'passe_sheet.dart';
import 'presente_dialog.dart';
import 'wardrobe_dialog.dart';

/// Modal dialog showing the daily 3 missions, progress tracking, and the daily chest.
/// Stars in the daily bonus chest.
const bauBonusEstrelas = 5;

class DailyMissionsDialog extends StatefulWidget {
  const DailyMissionsDialog({super.key, required this.services});
  final AppServices services;

  static Future<void> show(BuildContext context, AppServices services) {
    return showDialog(
      context: context,
      builder: (_) => DailyMissionsDialog(services: services),
    );
  }

  @override
  State<DailyMissionsDialog> createState() => _DailyMissionsDialogState();
}

class _DailyMissionsDialogState extends State<DailyMissionsDialog> {
  final DateTime _today = DateTime.now();

  Future<void> _claimMission(DailyMission m) async {
    widget.services.feedback.praise(2);
    final ok = await DailyMissionsManager.claimMission(
      widget.services.store,
      m,
      _today,
    );
    if (ok && mounted) {
      setState(() {});
    }
  }

  Future<void> _claimChest() async {
    widget.services.feedback.praise(4);
    final unlockedHat = await DailyMissionsManager.claimChest(
      widget.services.store,
      _today,
    );
    if (!mounted) return;
    setState(() {});

    // Show celebratory announcement
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFACC15), width: 2),
        ),
        title: Center(child: OutlinedTitle('Baú Aberto!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'art/missions/icone-bau-128.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 12),
            Text(
              '+5 Estrelas adicionadas à carteira!',
              textAlign: TextAlign.center,
              style: displayText(16, color: const Color(0xFFFDE047)),
            ),
            const SizedBox(height: 12),
            if (unlockedHat != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x33F59E0B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x66F59E0B)),
                ),
                child: Column(
                  children: [
                    Text(
                      'NOVO ITEM DO CAPI!',
                      style: displayText(13, color: const Color(0xFFF59E0B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unlockedHat.label,
                      style: displayText(18, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlockedHat.descricao,
                      textAlign: TextAlign.center,
                      style: bodyText(13, color: Palette.textDim),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Você já tem todos os itens que o baú pode dar!',
                textAlign: TextAlign.center,
                style: bodyText(14, color: Palette.textDim),
              ),
            ],
          ],
        ),
        actions: [
          ChunkyButton(
            label: 'Maravilha!',
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _abrirPresente() {
    final services = widget.services;
    final nav = Navigator.of(context);
    nav.pop();
    showPresente(nav.context, services);
  }

  /// One short line, with the full list a tap away.
  Widget _chestPoolLine(ProgressStore store) {
    final pool = Wardrobe.chestPool(store);
    if (pool.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Você já tem todos os itens do baú: ele dá 5 estrelas.',
          textAlign: TextAlign.center,
          style: bodyText(11, color: Palette.textDim),
        ),
      );
    }
    return TextButton(
      onPressed: () => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          title: Text(
            'O que pode sair no baú',
            style: displayText(17, color: Palette.text),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Um destes itens que você ainda não tem, escolhido pelo dia. '
              'O baú é grátis e não se compra.\n\n'
              '${pool.map((c) => '• ${c.label} (${c.raridade.label})').join('\n')}',
              style: bodyText(13, color: Palette.textDim),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Ok', style: displayText(14, color: Palette.accent)),
            ),
          ],
        ),
      ),
      child: Text(
        'Pode sair 1 de ${pool.length} itens · Ver lista',
        style: bodyText(12, color: Palette.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final missions = DailyMissionsManager.missionsFor(store, _today);
    final streak = store.missionsStreak(_today);
    final chestAvailable = DailyMissionsManager.isChestAvailable(store, _today);
    final chestClaimed = DailyMissionsManager.isChestClaimed(store, _today);

    var completedCount = 0;
    for (final m in missions) {
      if (DailyMissionsManager.isCompleted(store, m, _today)) {
        completedCount++;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: CardPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Image.asset(
                    'art/missions/icone-missoes-128.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Color(0xFF818CF8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    header: true,
                    label: 'Missões Diárias',
                    child: Text(
                      'Missões Diárias',
                      style: displayText(20, color: Palette.text),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Fechar',
                    // No tooltip: it would read "Fechar" a second time.
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
              const SizedBox(height: 4),

              // Streak indicator & Wardrobe shortcut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33EF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFEF4444),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streak ${streak == 1 ? 'dia' : 'dias'}',
                          semanticsLabel:
                              '$streak ${streak == 1 ? 'dia' : 'dias'} de sequência',
                          style: displayText(12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _PasseChip(
                    prontas: PasseDoCapi.prontas(store, DateTime.now()),
                    onTap: () {
                      Navigator.of(context).pop();
                      showPasse(context, widget.services);
                    },
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      WardrobeDialog.show(context, widget.services);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33F59E0B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x55F59E0B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.checkroom_rounded,
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Guarda-Roupa',
                            style: displayText(
                              12,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // The daily gift, if not taken yet today.
              if (PresenteDiario.disponivel(store, DateTime.now())) ...[
                const SizedBox(height: 10),
                Semantics(
                  button: true,
                  label: 'Abrir o presente do dia',
                  excludeSemantics: true,
                  onTap: _abrirPresente,
                  child: GestureDetector(
                    onTap: _abrirPresente,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFC94D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Palette.accent),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard_rounded,
                            color: Palette.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Presente do dia ${PresenteDiario.dia(store, DateTime.now()) + 1} esperando!',
                              style: displayText(13, color: Palette.text),
                            ),
                          ),
                          Text(
                            'Abrir',
                            style: displayText(13, color: Palette.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Mission Cards
              for (final m in missions) ...[
                _buildMissionCard(m, store),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 10),

              // Daily Chest Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x331E3A8A), Color(0x330F172A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: chestAvailable
                        ? const Color(0xFFFACC15)
                        : const Color(0x3338BDF8),
                    width: chestAvailable ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'art/missions/icone-bau-128.png',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: 'Baú do Capi',
                            child: Text(
                              'Baú do Capi',
                              style: displayText(16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (chestClaimed)
                            Text(
                              'Aberto! Volte amanhã',
                              style: bodyText(
                                12,
                                color: const Color(0xFF34D399),
                              ),
                            )
                          else if (chestAvailable)
                            Text(
                              'Pronto para abrir! (+5★ e um item)',
                              style: bodyText(
                                12,
                                color: const Color(0xFFFDE047),
                              ),
                            )
                          else
                            Text(
                              'Complete as 3 missões ($completedCount/3)',
                              style: bodyText(12, color: Palette.textDim),
                            ),
                        ],
                      ),
                    ),
                    if (chestAvailable)
                      Semantics(
                        button: true,
                        label: 'Abrir Baú do Capi',
                        child: ElevatedButton(
                          onPressed: _claimChest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF3A1D0D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Abrir!',
                            style: displayText(
                              14,
                              color: const Color(0xFF3A1D0D),
                            ),
                          ),
                        ),
                      )
                    else if (chestClaimed)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF34D399),
                        size: 28,
                      ),
                  ],
                ),
              ),
              // No surprises: the chest shows every item it can give.
              if (!chestClaimed) _chestPoolLine(store),
              if (widget.services.ads.hasVideoAds) ...[
                const SizedBox(height: 10),
                _bauBonus(store),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Once a day, a short video gives a few stars. What it gives is shown
  /// up front: nothing random.
  Widget _bauBonus(ProgressStore store) {
    final aberto = store.isBonusChestClaimed(_today);
    return Semantics(
      button: !aberto,
      label: aberto
          ? 'Baú bônus aberto. Volte amanhã'
          : 'Abrir baú bônus: +$bauBonusEstrelas estrelas com vídeo',
      excludeSemantics: true,
      onTap: aberto ? null : _abrirBauBonus,
      child: Material(
        color: const Color(0x2234D399),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: aberto ? null : _abrirBauBonus,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_display_rounded,
                  color: Color(0xFF34D399),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aberto
                        ? 'Baú bônus aberto! Volte amanhã'
                        : 'Baú bônus: +$bauBonusEstrelas★ com um vídeo',
                    style: displayText(14, color: Colors.white),
                  ),
                ),
                if (aberto)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34D399),
                  )
                else
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFF34D399),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _abrindoBonus = false;

  Future<void> _abrirBauBonus() async {
    final store = widget.services.store;
    if (_abrindoBonus || store.isBonusChestClaimed(_today)) return;
    _abrindoBonus = true;
    try {
      final ok = await widget.services.ads.rewarded(
        context,
        RewardPlacement.bonusChest,
      );
      if (!ok || !mounted) return;
      await store.setBonusChestClaimed(_today);
      await store.addStars(bauBonusEstrelas);
      widget.services.feedback.praise(3);
      if (mounted) setState(() {});
    } finally {
      _abrindoBonus = false;
    }
  }

  Widget _buildMissionCard(DailyMission m, ProgressStore store) {
    final prog = store.dailyMissionProgress(_today, m.index);
    final isDone = DailyMissionsManager.isCompleted(store, m, _today);
    final isClaimed = DailyMissionsManager.isClaimed(store, m, _today);
    final ratio = (prog / m.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0x4434D399) : const Color(0x11FFFFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.description,
                  style: displayText(14, color: Palette.text),
                ),
              ),
              const SizedBox(width: 8),
              if (isClaimed)
                Semantics(
                  label: 'Concluída',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x2234D399),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF34D399),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Concluída',
                          style: displayText(
                            11,
                            color: const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isDone)
                Semantics(
                  button: true,
                  label: 'Resgatar ${m.rewardStars} estrelas',
                  child: ElevatedButton(
                    onPressed: () => _claimMission(m),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '+${m.rewardStars}★ Resgatar',
                      style: displayText(12, color: Colors.white),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x22FBBF24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${m.rewardStars}★',
                    style: displayText(12, color: const Color(0xFFFBBF24)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.type.shortTitle,
                style: bodyText(11, color: Palette.textDim),
              ),
              Text(
                '$prog / ${m.target}',
                style: displayText(
                  11,
                  color: isDone ? const Color(0xFF34D399) : Palette.textDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opens the Passe do Capi; a dot shows rewards waiting.
class _PasseChip extends StatelessWidget {
  const _PasseChip({required this.prontas, required this.onTap});
  final int prontas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: prontas > 0
        ? 'Passe do Capi, $prontas prêmios para pegar'
        : 'Passe do Capi',
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x33FFC94D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x88FFC94D)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.military_tech_rounded,
              color: Palette.accent,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text('Passe', style: displayText(12, color: Palette.accent)),
            if (prontas > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Palette.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$prontas',
                  style: displayText(10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
