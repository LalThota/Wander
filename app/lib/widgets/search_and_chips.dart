import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({
    super.key,
    required this.initial,
    required this.onChanged,
    this.autofocus = false,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Search places',
        hintStyle: const TextStyle(color: kMuted),
        prefixIcon: const Icon(Icons.search_rounded, color: kMuted),
        suffixIcon: _c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded, color: kMuted),
                onPressed: () {
                  _c.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: kPanel,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Beach, Mountain, Culture. Tap one to filter, tap it again to clear.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.includeAll = false,
  });

  final Mood selected;
  final ValueChanged<Mood> onSelected;
  final EdgeInsetsGeometry padding;
  final bool includeAll;

  static const _meta = <Mood, (IconData, Color)>{
    Mood.all: (Icons.apps_rounded, kPrimary),
    Mood.beach: (Icons.beach_access, Color(0xFFFF8A3D)),
    Mood.mountain: (Icons.terrain, Color(0xFF3FA66B)),
    Mood.culture: (Icons.account_balance, Color(0xFFB07AE0)),
  };

  @override
  Widget build(BuildContext context) {
    final moods = [
      if (includeAll) Mood.all,
      Mood.beach,
      Mood.mountain,
      Mood.culture,
    ];
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          for (final m in moods)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 4, bottom: 8),
              child: _chip(m),
            ),
        ],
      ),
    );
  }

  Widget _chip(Mood m) {
    final on = selected == m;
    final meta = _meta[m]!;
    return Semantics(
      button: true,
      selected: on,
      label: m.label,
      child: GestureDetector(
        onTap: () => onSelected(!includeAll && on ? Mood.all : m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: on ? kPrimarySoft : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: on ? kPrimary : Colors.transparent, width: 1.4),
            boxShadow: softShadow(0.07),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(meta.$1, size: 18, color: meta.$2),
              const SizedBox(width: 8),
              Text(
                m.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
