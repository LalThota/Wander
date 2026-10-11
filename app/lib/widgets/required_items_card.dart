import 'package:flutter/material.dart';

import '../theme.dart';
import 'section_card.dart';

/// Things to bring. A checklist only: nothing here changes the trip budget.
class RequiredItemsCard extends StatelessWidget {
  const RequiredItemsCard({
    super.key,
    required this.items,
    required this.packed,
    required this.onToggle,
    this.initiallyExpanded = false,
  });

  final List<String> items;
  final Set<String> packed;
  final void Function(String item, bool checked) onToggle;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final done = items.where(packed.contains).length;
    return SectionCard(
      title: 'Required for this trip',
      icon: Icons.checklist_rounded,
      initiallyExpanded: initiallyExpanded,
      summary: '$done of ${items.length} packed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: items.isEmpty ? 0 : done / items.length,
              minHeight: 6,
              color: kPrimary,
              backgroundColor: kLine,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in items)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: kPrimary,
              checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              value: packed.contains(item),
              title: Text(
                item,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: packed.contains(item) ? TextDecoration.lineThrough : null,
                  color: packed.contains(item) ? kMuted : kInk,
                ),
              ),
              onChanged: (v) => onToggle(item, v ?? false),
            ),
          const SizedBox(height: 4),
          const Text(
            'This is a checklist only. These items are not added to your trip budget.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }
}
