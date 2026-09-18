import 'package:flutter/material.dart';

import '../design.dart';
import '../models.dart';
import '../push_model.dart';
import 'delivery_view.dart';
import 'home_view.dart';
import 'log_view.dart';

/// The signed-in experience: a tab bar hosting the three demo screens
/// (Home, Delivery, Log), ported from MainTabView. Each screen gets an
/// iOS-style large navigation title.
class MainTabView extends StatefulWidget {
  const MainTabView({super.key, required this.model});

  final PushModel model;

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  AppTab? _lastLoggedTab;

  PushModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    final isDiagnostics = model.selectedTab == AppTab.diagnostics;

    if (_lastLoggedTab != model.selectedTab) {
      _lastLoggedTab = model.selectedTab;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        model.logScreenView(model.selectedTab);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _largeTitleHeader(isDiagnostics),
          Expanded(
            child: IndexedStack(
              index: model.selectedTab.index,
              children: [
                HomeView(model: model),
                DeliveryView(model: model),
                LogView(model: model),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _tabBar(isDiagnostics),
    );
  }

  /// iOS-style large navigation title: 34pt bold, left-aligned, with the
  /// toolbar action inline on the right.
  Widget _largeTitleHeader(bool isDiagnostics) {
    final title = switch (model.selectedTab) {
      AppTab.home => 'Push registration',
      AppTab.delivery => 'Delivery',
      AppTab.diagnostics => 'Log',
    };

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.15,
                      color:
                          isDiagnostics ? MatrixColors.primary : AppColors.ink,
                    ),
                  ),
                ),
              ),
              if (model.selectedTab == AppTab.home)
                IconButton(
                  onPressed: model.isLoggingOut ? null : model.logout,
                  tooltip: 'Sign out',
                  icon: model.isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.person_off_outlined,
                          size: 24,
                          color: AppColors.ink,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar(bool isDiagnostics) {
    return BottomNavigationBar(
      currentIndex: model.selectedTab.index,
      onTap: (index) => model.selectTab(AppTab.values[index]),
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDiagnostics ? MatrixColors.surface : AppColors.surface,
      selectedItemColor: isDiagnostics ? MatrixColors.primary : AppColors.lilac,
      unselectedItemColor: isDiagnostics
          ? MatrixColors.dim
          : AppColors.ink.withValues(alpha: 0.42),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_outlined), label: 'Delivery'),
        BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'Log'),
      ],
    );
  }
}
