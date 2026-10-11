import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/budget.dart';
import '../theme.dart';
import '../util.dart';
import 'section_card.dart';

/// Splits the total budget into categories and shows what is left.
class BudgetBreakdownCard extends StatelessWidget {
  const BudgetBreakdownCard({
    super.key,
    required this.total,
    required this.amounts,
    required this.onChanged,
    required this.onSuggest,
    required this.onClear,
    required this.suggesting,
    this.travelHint,
    this.onUseTravelHint,
  });

  final int total;
  final Map<String, int> amounts;
  final void Function(String key, int value) onChanged;
  final VoidCallback onSuggest;
  final VoidCallback onClear;
  final bool suggesting;

  /// Estimated cost of the chosen travel mode, offered as the Travel amount.
  final int? travelHint;
  final VoidCallback? onUseTravelHint;

  @override
  Widget build(BuildContext context) {
    final sum = summarize(total, amounts);
    final status = _status(sum);

    return SectionCard(
      title: 'Budget breakdown',
      icon: Icons.pie_chart_outline_rounded,
      summary: total <= 0
          ? 'Set a total budget first'
          : '${inr(sum.allocated)} of ${inr(total)} allocated',
      child: total <= 0
          ? const Text(
              'Enter your total budget above, then split it between travel, stay, food and more.',
              style: TextStyle(color: kMuted, height: 1.4),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Stat('Budget', inr(total)),
                    const SizedBox(width: 8),
                    _Stat('Allocated', inr(sum.allocated)),
                    const SizedBox(width: 8),
                    _Stat(
                      sum.state == BudgetState.over ? 'Over by' : 'Remaining',
                      inr(sum.state == BudgetState.over ? sum.overBy : sum.remaining),
                      color: sum.state == BudgetState.over ? kBad : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status.color.fade(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(status.icon, size: 20, color: status.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status.text,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimarySoft,
                          foregroundColor: kPrimary,
                          shape: const StadiumBorder(),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: suggesting ? null : onSuggest,
                        icon: suggesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(suggesting ? 'Working...' : 'Suggested split'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onClear,
                      child: const Text('Clear', style: TextStyle(color: kMuted)),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Suggested amounts are only a starting point. Edit any of them.',
                    style: TextStyle(fontSize: 12, color: kMuted),
                  ),
                ),
                if (travelHint != null && onUseTravelHint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: onUseTravelHint,
                      child: Text(
                        'Your travel estimate is ${inr(travelHint!)}. Tap to use it for Travel.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                for (final cat in budgetCategories)
                  BudgetCategoryRow(
                    category: cat,
                    value: amounts[cat.key] ?? 0,
                    total: total,
                    over: sum.state == BudgetState.over,
                    onChanged: (v) => onChanged(cat.key, v),
                  ),
              ],
            ),
    );
  }

  ({Color color, IconData icon, String text}) _status(BudgetSummary s) {
    switch (s.state) {
      case BudgetState.over:
        return (
          color: kBad,
          icon: Icons.warning_amber_rounded,
          text: 'Over budget by ${inr(s.overBy)}. Lower a category to save.',
        );
      case BudgetState.full:
        return (
          color: kWarn,
          icon: Icons.check_circle_outline,
          text: 'Fully allocated. Nothing left over.',
        );
      default:
        return (
          color: kGood,
          icon: Icons.savings_outlined,
          text: 'Under budget. ${inr(s.remaining)} left to allocate.',
        );
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});
  final String label, value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPanel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: kMuted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color ?? kInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// One editable budget category with a share bar.
class BudgetCategoryRow extends StatefulWidget {
  const BudgetCategoryRow({
    super.key,
    required this.category,
    required this.value,
    required this.total,
    required this.over,
    required this.onChanged,
  });

  final BudgetCategory category;
  final int value;
  final int total;
  final bool over;
  final ValueChanged<int> onChanged;

  @override
  State<BudgetCategoryRow> createState() => _BudgetCategoryRowState();
}

class _BudgetCategoryRowState extends State<BudgetCategoryRow> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value == 0 ? '' : '${widget.value}',
  );

  @override
  void didUpdateWidget(BudgetCategoryRow old) {
    super.didUpdateWidget(old);
    // Keep the field in step when the value changes from outside
    // (suggested split, clear, capped input).
    final typed = int.tryParse(_c.text) ?? 0;
    if (typed != widget.value) {
      final text = widget.value == 0 ? '' : '${widget.value}';
      _c.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final share = widget.total > 0 ? clampD(widget.value / widget.total, 0, 1) : 0.0;
    final pct = widget.total > 0 ? (widget.value * 100 / widget.total).round() : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(widget.category.icon, size: 20, color: kPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: widget.category.label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: '  $pct%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _c,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: kPanel,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (t) => widget.onChanged(int.tryParse(t) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              color: widget.over ? kBad : kPrimary,
              backgroundColor: kLine,
            ),
          ),
        ],
      ),
    );
  }
}
