import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/place.dart';
import '../models/tourist_place.dart';
import '../models/travel.dart';
import '../models/trip_draft.dart';
import '../services/api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/budget_breakdown_card.dart';
import '../widgets/common.dart';
import '../widgets/map_section_card.dart';
import '../widgets/nearby_places_card.dart';
import '../widgets/photo_box.dart';
import '../widgets/required_items_card.dart';
import '../widgets/section_card.dart';
import '../widgets/travel_comparison_card.dart';

void openPlace(BuildContext context, Place p, String heroTag) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => DetailScreen(p: p, heroTag: heroTag),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ),
  );
}

/// Destination page, top to bottom: header, total budget, budget breakdown,
/// travel comparison, required items, nearby places, save.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.p, required this.heroTag});
  final Place p;
  final String heroTag;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final TripDraft _d;
  late final TextEditingController _budgetCtrl;
  int _variant = 0;
  bool _busy = false;
  bool _suggesting = false;

  TravelPlan? _plan;
  bool _planLoading = false;
  String? _planError;
  int _travelReq = 0;

  List<TouristPlace>? _nearby;
  bool _nearbyLoading = false;
  String? _nearbyError;
  String _sort = 'nearest';
  String? _category;

  Place get p => widget.p;

  @override
  void initState() {
    super.initState();
    final saved = AppScope.read(context).trips[p.id];
    _d = TripDraft.fromTrip(saved);
    _budgetCtrl = TextEditingController(text: _d.budget?.toString() ?? '');
    // Sections that already hold saved data load straight away.
    if (_d.travelMode != null) _loadTravel();
    if (_d.places.isNotEmpty) _loadNearby();
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───────── loading ─────────

  Future<void> _loadTravel() async {
    final req = ++_travelReq;
    setState(() {
      _planLoading = true;
      _planError = null;
    });
    try {
      final plan = await AppScope.read(context).travelPlan(p.id, _d.travelers);
      if (!mounted || req != _travelReq) return;
      setState(() {
        _plan = plan;
        _planLoading = false;
        final m = _d.travelMode;
        if (m != null && plan.byMode(m) == null) _d.travelMode = null;
      });
    } on ApiException {
      if (!mounted || req != _travelReq) return;
      setState(() {
        _planLoading = false;
        _planError = 'Unable to load travel options. Please try again.';
      });
    }
  }

  Future<void> _loadNearby() async {
    setState(() {
      _nearbyLoading = true;
      _nearbyError = null;
    });
    try {
      final list = await AppScope.read(context).nearbyPlaces(p.id);
      if (!mounted) return;
      setState(() {
        _nearby = list;
        _nearbyLoading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _nearbyLoading = false;
        _nearbyError = 'Unable to load nearby places. Please try again.';
      });
    }
  }

  Future<void> _suggest() async {
    final total = _d.budgetValue;
    if (total <= 0) {
      _snack('Enter a total budget first.');
      return;
    }
    setState(() => _suggesting = true);
    try {
      final split = await AppScope.read(context).suggestBudget(p.id, total);
      if (!mounted) return;
      setState(() {
        _suggesting = false;
        _d.breakdown
          ..clear()
          ..addAll(split);
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _suggesting = false);
      _snack('Unable to suggest a split. Please try again.');
    }
  }

  // ───────── editing ─────────

  void _setBudget(String text) {
    final v = int.tryParse(text);
    setState(() => _d.budget = (v == null || v <= 0) ? null : v);
  }

  void _useEstimate() {
    final v = p.estimate(_d.days);
    _budgetCtrl.text = '$v';
    setState(() => _d.budget = v);
  }

  void _setCategory(String key, int value) {
    final cap = _d.budgetValue;
    // One category can never be larger than the whole budget.
    final v = cap > 0 ? math.min(value, cap) : value;
    setState(() {
      if (v <= 0) {
        _d.breakdown.remove(key);
      } else {
        _d.breakdown[key] = v;
      }
    });
  }

  void _useTravelHint() {
    final m = _d.travelMode;
    final o = m == null ? null : _plan?.byMode(m);
    if (o != null) _setCategory('travel', o.costTotal);
  }

  Future<void> _onSave() async {
    final s = AppScope.read(context);
    final saved = s.trips[p.id];
    final problem = _d.problem;
    if (problem != null) {
      _snack(problem);
      return;
    }
    final dirty = !_d.sameAs(saved);
    setState(() => _busy = true);
    String? err;
    String done;
    if (saved == null) {
      err = await s.saveTrip(p, _d);
      done = 'Saved';
    } else if (dirty) {
      err = await s.saveTrip(p, _d);
      done = 'Updated';
    } else {
      err = await s.removeTrip(p.id);
      done = 'Removed';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(err ?? done);
  }

  // ───────── build ─────────

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final saved = s.trips[p.id];
    final problem = _d.problem;
    final dirty = !_d.sameAs(saved);
    final label = problem != null
        ? 'Fix budget to save'
        : saved == null
            ? 'Save trip'
            : (dirty ? 'Update trip' : 'Saved');

    final bar = _BottomBar(
      p: p,
      label: label,
      busy: _busy,
      warn: problem != null,
      onTap: _onSave,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 900
            ? _wide(bar, saved != null)
            : _narrow(bar, saved != null),
      ),
    );
  }

  Widget _narrow(Widget bar, bool saved) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 320, child: _header(saved, radius: 32)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _content(),
                ),
              ),
            ],
          ),
        ),
        bar,
      ],
    );
  }

  Widget _wide(Widget bar, bool saved) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _header(saved, radius: 32, allSides: true),
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      children: _content(),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: bar),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(bool saved, {required double radius, bool allSides = false}) {
    final r = allSides
        ? BorderRadius.circular(radius)
        : BorderRadius.vertical(bottom: Radius.circular(radius));
    return Stack(
      children: [
        Positioned.fill(
          child: Hero(
            tag: widget.heroTag,
            child: ClipRRect(
              borderRadius: r,
              child: PhotoBox(p: p, variant: _variant, radius: 0),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            translucent: true,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: RoundIconButton(
            icon: saved ? Icons.bookmark : Icons.bookmark_border_rounded,
            tooltip: saved ? 'Saved' : 'Not saved yet',
            translucent: true,
            color: saved ? kPrimary : kInk,
            onTap: () => _snack(saved ? 'This trip is saved.' : 'Tap Save trip below to save it.'),
          ),
        ),
      ],
    );
  }

  List<Widget> _content() {
    final mode = _d.travelMode;
    final modeOpt = mode == null ? null : _plan?.byMode(mode);
    final estimate = p.estimate(_d.days);

    return [
      Row(
        children: [
          Expanded(
            child: Text(
              p.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ),
          Rating(p.rating),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: LocationLine(p.country, size: 15)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: kPrimarySoft, borderRadius: BorderRadius.circular(14)),
            child: Text(
              p.season,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Text(p.tagline, style: const TextStyle(color: kMuted, height: 1.5)),
      const SizedBox(height: 16),
      Row(
        children: [
          _Fact(Icons.thermostat_rounded, '${p.temp}°C', 'Average'),
          const SizedBox(width: 8),
          _Fact(Icons.flight_takeoff_rounded, fmtHours(p.flightHours), 'Flight'),
          const SizedBox(width: 8),
          _Fact(Icons.payments_outlined, inr(p.perDay), 'Per day'),
        ],
      ),
      const SizedBox(height: 20),
      const Text('More images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => Semantics(
            button: true,
            selected: _variant == i,
            label: 'Photo ${i + 1}',
            child: GestureDetector(
              onTap: () => setState(() => _variant = i),
              child: Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _variant == i ? kPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: PhotoBox(p: p, variant: i, radius: 14),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),

      // 1. Total budget
      SectionCard(
        title: 'Total budget',
        icon: Icons.account_balance_wallet_outlined,
        collapsible: false,
        summary: _d.budget == null ? 'How much do you want to spend?' : inr(_d.budget!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              onChanged: _setBudget,
              decoration: InputDecoration(
                hintText: 'e.g. 30000',
                prefixText: '₹ ',
                filled: true,
                fillColor: kPanel,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Trip length', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text('${_d.days} days', style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary)),
              ],
            ),
            Slider(
              value: _d.days.toDouble(),
              min: 2,
              max: 21,
              divisions: 19,
              label: '${_d.days} days',
              onChanged: (v) => setState(() => _d.days = v.round()),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rough estimate', style: TextStyle(fontSize: 12, color: kMuted)),
                        const SizedBox(height: 2),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: estimate.toDouble()),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, v, _) => Text(
                            inr(v),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Text(
                          'Stay for the chosen days plus a return flight',
                          style: TextStyle(fontSize: 11.5, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _useEstimate,
                    child: const Text('Use as budget'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 2. Budget breakdown
      BudgetBreakdownCard(
        total: _d.budgetValue,
        amounts: _d.breakdown,
        suggesting: _suggesting,
        onChanged: _setCategory,
        onSuggest: _suggest,
        onClear: () => setState(_d.breakdown.clear),
        travelHint: modeOpt?.costTotal,
        onUseTravelHint: modeOpt == null ? null : _useTravelHint,
      ),

      // 3. Travel comparison
      TravelComparisonCard(
        plan: _plan,
        loading: _planLoading,
        error: _planError,
        onRetry: _loadTravel,
        selected: _d.travelMode,
        onSelect: (m) => setState(() => _d.travelMode = m),
        travelers: _d.travelers,
        onTravelers: (n) {
          setState(() => _d.travelers = n);
          _loadTravel();
        },
        onFirstExpand: _loadTravel,
        initiallyExpanded: _d.travelMode != null,
      ),

      // 4. Required items (checklist only, never part of the budget)
      RequiredItemsCard(
        items: p.pack,
        packed: _d.packed,
        initiallyExpanded: _d.packed.isNotEmpty,
        onToggle: (item, on) => setState(() {
          if (on) {
            _d.packed.add(item);
          } else {
            _d.packed.remove(item);
          }
        }),
      ),

      // 5. Nearby places
      NearbyPlacesCard(
        places: _nearby,
        loading: _nearbyLoading,
        error: _nearbyError,
        onRetry: _loadNearby,
        sort: _sort,
        onSort: (v) => setState(() => _sort = v),
        category: _category,
        onCategory: (c) => setState(() => _category = c),
        selectedIds: _d.places.keys.toSet(),
        onToggle: (tp) => setState(() {
          if (_d.places.containsKey(tp.id)) {
            _d.places.remove(tp.id);
          } else {
            _d.places[tp.id] = tp.name;
          }
        }),
        onFirstExpand: _loadNearby,
        initiallyExpanded: _d.places.isNotEmpty,
      ),

      // 6. Interactive Map & Navigation
      MapSectionCard(
        destination: p,
        places: _nearby,
      ),
    ];
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, size: 20, color: kPrimary),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Text(label, style: const TextStyle(fontSize: 11.5, color: kMuted)),
            ],
          ),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.p,
    required this.label,
    required this.busy,
    required this.warn,
    required this.onTap,
  });

  final Place p;
  final String label;
  final bool busy;
  final bool warn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: kLine)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(inr(p.perDay), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const Text('/day, estimate', style: TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: PillButton(
                label: label,
                busy: busy,
                color: warn ? kWarn : kPrimary,
                icon: warn ? Icons.warning_amber_rounded : null,
                onPressed: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
