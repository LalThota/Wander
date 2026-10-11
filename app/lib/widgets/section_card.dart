import 'package:flutter/material.dart';

import '../theme.dart';

/// White rounded card with an icon header that can fold away.
class SectionCard extends StatefulWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.summary,
    this.initiallyExpanded = true,
    this.collapsible = true,
    this.onFirstExpand,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? summary;
  final bool initiallyExpanded;
  final bool collapsible;

  /// Called once, the first time the user opens the card. Used to load data lazily.
  final VoidCallback? onFirstExpand;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late bool _open = widget.initiallyExpanded || !widget.collapsible;
  late bool _fired = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _open = !_open);
    if (_open && !_fired) {
      _fired = true;
      widget.onFirstExpand?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.collapsible ? _toggle : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: kPrimarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, size: 20, color: kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (widget.summary != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.summary!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: kMuted),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.collapsible)
                      Icon(
                        _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: kMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
