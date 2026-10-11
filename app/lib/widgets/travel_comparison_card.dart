import 'package:flutter/material.dart';

import '../models/travel.dart';
import '../theme.dart';
import '../util.dart';
import 'common.dart';
import 'section_card.dart';

/// "How do you want to travel?" with cost, time and quick picks.
/// All values are estimates and are labelled that way.
class TravelComparisonCard extends StatelessWidget {
  const TravelComparisonCard({
    super.key,
    required this.plan,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.selected,
    required this.onSelect,
    required this.travelers,
    required this.onTravelers,
    required this.onFirstExpand,
    required this.initiallyExpanded,
  });

  final TravelPlan? plan;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final int travelers;
  final ValueChanged<int> onTravelers;
  final VoidCallback onFirstExpand;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final sel = selected == null ? null : plan?.byMode(selected!);
    return SectionCard(
      title: 'How do you want to travel?',
      icon: Icons.commute_rounded,
      initiallyExpanded: initiallyExpanded,
      onFirstExpand: onFirstExpand,
      summary: sel != null
          ? '${modeLabel(sel.mode)}, about ${inr(sel.costTotal)} (estimate)'
          : 'Compare cost and time (estimates)',
      child: _body(),
    );
  }

  Widget _body() {
    if (plan == null) {
      if (error != null) return ErrorBox(message: error!, onRetry: onRetry);
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LoadingBox(message: 'Comparing travel options...'),
      );
    }
    final p = plan!;
    if (p.options.isEmpty) {
      return const Text('No travel estimates yet for this place.', style: TextStyle(color: kMuted));
    }
    final multi = p.options.length > 1;
    final r = p.recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kWarn.fade(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: kWarn),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.note, style: const TextStyle(fontSize: 12.5, height: 1.35)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text('Travellers', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                ),
              ),
            _StepButton(
              icon: Icons.remove,
              onTap: travelers > 1 ? () => onTravelers(travelers - 1) : null,
              label: 'Fewer travellers',
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$travelers',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: travelers < 10 ? () => onTravelers(travelers + 1) : null,
              label: 'More travellers',
            ),
          ],
        ),
        if (multi) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (r['cheapest'] != null)
                _Pick(Icons.savings_outlined, 'Cheapest', r['cheapest']!),
              if (r['fastest'] != null) _Pick(Icons.bolt, 'Fastest', r['fastest']!),
              if (r['best_value'] != null)
                _Pick(Icons.star_outline_rounded, 'Best value', r['best_value']!),
              if (r['best_group'] != null)
                _Pick(Icons.groups_outlined, 'Best for ${p.groupSize}+', r['best_group']!),
            ],
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Flying is the only practical option for this trip.',
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
          ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(flex: 5, child: Text('Mode', style: _head)),
            Expanded(flex: 3, child: Text('Cost', style: _head)),
            Expanded(flex: 3, child: Text('Time', style: _head)),
          ],
        ),
        const SizedBox(height: 6),
        for (final o in p.options) _row(o, p),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Tap a mode to add it to your trip. Tap again to remove it.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
        ),
      ],
    );
  }

  static const _head = TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600);

  Widget _row(TravelOption o, TravelPlan p) {
    final r = p.recommendations;
    final on = selected == o.mode;
    final badges = <String>[
      if (p.options.length > 1 && r['cheapest'] == o.mode) 'Cheapest',
      if (p.options.length > 1 && r['fastest'] == o.mode) 'Fastest',
      if (p.options.length > 1 && r['best_value'] == o.mode) 'Best value',
      if (p.options.length > 1 && r['best_group'] == o.mode) 'Group pick',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: on,
        label: '${modeLabel(o.mode)}, ${inr(o.costTotal)}, ${fmtHours(o.hours)}',
        child: GestureDetector(
          onTap: () => onSelect(on ? null : o.mode),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: on ? kPrimarySoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: on ? kPrimary : kLine, width: on ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(modeIcon(o.mode), size: 20, color: kPrimary),
                              const SizedBox(width: 8),
                              Text(
                                modeLabel(o.mode),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              if (on) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle, size: 16, color: kPrimary),
                              ],
                            ],
                          ),
                          if (badges.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [for (final b in badges) _Badge(b)],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inr(o.costTotal),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (travelers > 1)
                            Text(
                              '${inr(o.costPerPerson)} each',
                              style: const TextStyle(fontSize: 11.5, color: kMuted),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        fmtHours(o.hours),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  o.description,
                  style: const TextStyle(fontSize: 12.5, color: kMuted, height: 1.35),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good for: ${o.suitableFor}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pick extends StatelessWidget {
  const _Pick(this.icon, this.label, this.mode);
  final IconData icon;
  final String label, mode;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: kPrimary),
            const SizedBox(width: 6),
            Text(
              '$label: ${modeLabel(mode)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: kPrimary.fade(0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kPrimary),
        ),
      );
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap, required this.label});
  final IconData icon;
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null ? kPanel : kPrimarySoft,
            ),
            child: Icon(icon, size: 18, color: onTap == null ? kMuted : kPrimary),
          ),
        ),
      );
}
