import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabDef('/home',      Icons.home_outlined,       Icons.home_rounded,         'nav.home'),
    _TabDef('/care-log',  Icons.book_outlined,        Icons.book_rounded,          'nav.care_log'),
    _TabDef('/sos',       Icons.emergency_outlined,   Icons.emergency_rounded,     'nav.sos'),
    _TabDef('/map',       Icons.map_outlined,         Icons.map_rounded,           'nav.map'),
    _TabDef('/profile',   Icons.person_outline,       Icons.person_rounded,        'nav.profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => context.go(_tabs[i].path),
        type: BottomNavigationBarType.fixed,
        items: _tabs.map((t) {
          final isActive = _tabs.indexOf(t) == idx;
          final isSos = t.path == '/sos';
          return BottomNavigationBarItem(
            icon: isSos
                ? Container(
                    width: 48, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.emergency,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isActive ? t.activeIcon : t.icon,
                      color: Colors.white, size: 22,
                    ),
                  )
                : Icon(isActive ? t.activeIcon : t.icon),
            label: tr(t.labelKey),
          );
        }).toList(),
      ),
    );
  }
}

class _TabDef {
  final String path, labelKey;
  final IconData icon, activeIcon;
  const _TabDef(this.path, this.icon, this.activeIcon, this.labelKey);
}
