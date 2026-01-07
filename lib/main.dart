import 'dart:async';
import 'package:flutter/material.dart';
import 'network_channel.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  StreamSubscription<NetStatus>? _sub;
  NetStatus _status = NetStatus.disconnected;

  // ---------- UI helpers ----------
  bool get _isOnline => _status == NetStatus.connected;

  IconData get _statusIcon => _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;

  String get _titleText => _isOnline ? 'Connected' : 'Disconnected';

  String get _subtitleText => _isOnline
      ? 'Internet is available on this device.'
      : 'No internet connection detected.';

  void _showSnack(String text, {IconData? icon}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _refreshOnce() async {
    try {
      final s = await NetworkChannel.current();
      if (!mounted) return;
      setState(() => _status = s);

      _showSnack(
        'Checked: ${s == NetStatus.connected ? 'connected' : 'disconnected'}',
        icon: Icons.refresh_rounded,
      );
    } catch (e) {
      _showSnack('Error while checking: $e', icon: Icons.error_outline_rounded);
    }
  }

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();

    // initial check
    _refreshOnce();

    // realtime stream
    _sub = NetworkChannel.changes().listen((s) {
      if (!mounted) return;

      setState(() => _status = s);

      if (s == NetStatus.connected) {
        _showSnack('Network connected', icon: Icons.wifi_rounded);
      } else {
        _showSnack('Network disconnected', icon: Icons.wifi_off_rounded);
      }
    }, onError: (e) {
      _showSnack('Stream error: $e', icon: Icons.error_outline_rounded);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Monitor'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Card(
                key: ValueKey(_isOnline),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _StatusPill(isOnline: _isOnline),
                      ),
                      const SizedBox(height: 14),

                      _IconCircle(
                        isOnline: _isOnline,
                        icon: _statusIcon,
                      ),

                      const SizedBox(height: 16),
                      Text(
                        _titleText,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitleText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),

                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Try toggling Wi-Fi / Mobile Data to test.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _refreshOnce,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Re-check'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ------------------- Small UI Widgets -------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = isOnline ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = isOnline ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: fg),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.isOnline,
    required this.icon,
  });

  final bool isOnline;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = isOnline ? cs.primaryContainer : cs.errorContainer;
    final fg = isOnline ? cs.onPrimaryContainer : cs.onErrorContainer;

    return Container(
      height: 92,
      width: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      child: Icon(icon, size: 44, color: fg),
    );
  }
}
