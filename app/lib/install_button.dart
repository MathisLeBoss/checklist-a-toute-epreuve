import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:js_interop';

@JS('installPWA')
external JSPromise<JSAny?> installPWA();

class InstallButton extends StatefulWidget {
  const InstallButton({super.key});

  @override
  State<InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<InstallButton> {
  bool installing = false;

  Future<void> install() async {
    if (!kIsWeb) return;

    setState(() {
      installing = true;
    });

    try {
      await installPWA().toDart;
    } catch (_) {}

    if (mounted) {
      setState(() {
        installing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return FilledButton.icon(
      onPressed: installing ? null : install,
      icon: installing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.download),
      label: Text(
        installing
            ? 'Installation...'
            : 'Installer l’application',
      ),
    );
  }
}
