import 'package:flutter/material.dart';

import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, AppState s) async {
    final ctrl = TextEditingController(text: s.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'What should we call you?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) await s.setUserName(name);
  }

  Future<void> _editServer(BuildContext context, AppState s) async {
    final ctrl = TextEditingController(text: apiBase);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect mobile app to your laptop backend (e.g. http://10.161.197.7:8001) or cloud server:',
              style: TextStyle(fontSize: 13, color: kMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'http://10.161.197.7:8001',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (url != null) await s.setCustomApiUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final name = s.userName.isEmpty ? 'Traveller' : s.userName;
    final packed = s.trips.values.fold<int>(0, (a, t) => a + t.packed.length);
    final places = s.trips.values.fold<int>(0, (a, t) => a + t.places.length);

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: kPrimarySoft,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _Stat('${s.trips.length}', 'Saved trips'),
                  const SizedBox(width: 10),
                  _Stat('$places', 'Places added'),
                  const SizedBox(width: 10),
                  _Stat('$packed', 'Items packed'),
                ],
              ),
              const SizedBox(height: 22),
              _Tile(Icons.edit_outlined, 'Change your name', () => _editName(context, s)),
              _Tile(Icons.dns_outlined, 'Server connection (IP / URL)', () => _editServer(context, s)),
              _Tile(Icons.refresh_rounded, 'Refresh destinations', () => s.load()),
              _Tile(Icons.slideshow_rounded, 'Replay the intro', () => s.setOnboardingSeen(false)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _editServer(context, s),
                child: Center(
                  child: Text(
                    'Server: $apiBase (tap to change)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: cardDecoration(radius: 20),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kPrimary)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11.5, color: kMuted)),
            ],
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: kPanel,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: kPrimary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: kMuted),
                ],
              ),
            ),
          ),
        ),
      );
}
