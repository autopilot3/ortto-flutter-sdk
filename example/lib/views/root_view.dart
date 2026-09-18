import 'package:flutter/material.dart';

import '../design.dart';
import '../models.dart';
import '../push_model.dart';
import 'controls.dart';
import 'login_background.dart';
import 'login_view.dart';
import 'main_tab_view.dart';

/// App shell: shows LoginView until an email is signed in, then MainTabView.
/// Also hosts the cross-screen background fade, the action toast overlay,
/// and the notification deeplink confirmation modal.
class RootView extends StatefulWidget {
  const RootView({super.key, required this.model});

  final PushModel model;

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  DeepLinkPrompt? _visiblePrompt;

  PushModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.addListener(_onModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      model.prepareInitialState();

      // Ortto SDK: push registration starts here on first open — the
      // notification permission prompt, then the Firebase token is forwarded
      // to the SDK when it arrives.
      model.performFirstOpenPushIfNeeded();
    });
  }

  @override
  void dispose() {
    model.removeListener(_onModelChanged);
    super.dispose();
  }

  void _onModelChanged() {
    final prompt = model.deepLinkPrompt;
    if (prompt != null && prompt != _visiblePrompt) {
      _visiblePrompt = prompt;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDeepLinkPrompt(prompt);
      });
    }
    if (prompt == null) {
      _visiblePrompt = null;
    }
  }

  /// Default (body-tap) action confirmation modal.
  Future<void> _showDeepLinkPrompt(DeepLinkPrompt prompt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open from notification?'),
        content: Text('You tapped a push notification.\n${prompt.link}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Delivery'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed ?? false) {
      model.confirmDeepLinkPrompt();
    } else {
      model.dismissDeepLinkPrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final isSignedIn = model.isSignedIn;
        final isDiagnostics = model.selectedTab == AppTab.diagnostics;

        return Stack(
          children: [
            // Cross-screen background: animated gradient when signed out,
            // grouped grey (or the matrix backdrop) when signed in.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              child: !isSignedIn
                  ? const LoginBackground(key: ValueKey('login-bg'))
                  : Container(
                      key: ValueKey(isDiagnostics ? 'matrix-bg' : 'grouped-bg'),
                      color: isDiagnostics
                          ? MatrixColors.surface
                          : AppColors.groupedBackground,
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 340),
              switchInCurve: Curves.easeInOut,
              child: isSignedIn
                  ? MainTabView(key: const ValueKey('main'), model: model)
                  : Scaffold(
                      key: const ValueKey('login'),
                      backgroundColor: Colors.transparent,
                      resizeToAvoidBottomInset: false,
                      body: LoginView(model: model),
                    ),
            ),
            // Floating action toast, above the tab bar.
            if (isSignedIn)
              Positioned(
                left: 18,
                right: 18,
                bottom: 98,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      )),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: model.actionToast != null
                        ? Center(
                            key: ValueKey('toast-${model.toastGeneration}'),
                            child: SDKToastView(toast: model.actionToast!),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-toast')),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
