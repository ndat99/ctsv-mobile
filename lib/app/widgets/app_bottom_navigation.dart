import 'package:flutter/material.dart';

enum AppTab { home, schedules, scholarships, trainingScore, tuitionReduction }

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedTab,
    required this.onSelect,
  });

  final AppTab selectedTab;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final labelHeight = MediaQuery.textScalerOf(context).scale(11.5) * 1.2 * 2;
    return SizedBox(
      height: 74 + labelHeight.ceilToDouble() + bottomInset,
      child: PhysicalShape(
        color: colors.surface,
        elevation: 8,
        shadowColor: colors.shadow.withValues(alpha: 0.16),
        clipper: const _RaisedHomeClipper(),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: colors.surface,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _item(
                  key: const Key('nav-schedules'),
                  tab: AppTab.schedules,
                  label: 'SHCN',
                  icon: Icons.calendar_month_outlined,
                  selectedIcon: Icons.calendar_month,
                ),
                _item(
                  key: const Key('nav-training-score'),
                  tab: AppTab.trainingScore,
                  label: 'Điểm rèn luyện',
                  icon: Icons.fact_check_outlined,
                  selectedIcon: Icons.fact_check,
                ),
                _item(
                  key: const Key('nav-home'),
                  tab: AppTab.home,
                  label: 'Trang chủ',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  raised: true,
                ),
                _item(
                  key: const Key('nav-tuition-reduction'),
                  tab: AppTab.tuitionReduction,
                  label: 'MGHP',
                  icon: Icons.school_outlined,
                  selectedIcon: Icons.school,
                ),
                _item(
                  key: const Key('nav-scholarships'),
                  tab: AppTab.scholarships,
                  label: 'Học bổng',
                  icon: Icons.workspace_premium_outlined,
                  selectedIcon: Icons.workspace_premium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item({
    required Key key,
    required AppTab tab,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    bool raised = false,
  }) {
    return Expanded(
      child: _MenuItem(
        key: key,
        label: label,
        icon: selectedTab == tab ? selectedIcon : icon,
        selected: selectedTab == tab,
        raised: raised,
        onTap: () => onSelect(tab),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.raised,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool raised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, raised ? 6 : 30, 4, 6),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: raised ? 54 : 48,
                    height: raised ? 54 : 32,
                    decoration: BoxDecoration(
                      color: raised
                          ? (selected
                                ? colors.primary
                                : colors.primaryContainer)
                          : (selected
                                ? colors.primaryContainer
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(raised ? 27 : 16),
                    ),
                    child: Icon(
                      icon,
                      size: raised ? 28 : 24,
                      color: raised
                          ? (selected
                                ? colors.onPrimary
                                : colors.onPrimaryContainer)
                          : foreground,
                    ),
                  ),
                  SizedBox(height: raised ? 6 : 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.2,
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaisedHomeClipper extends CustomClipper<Path> {
  const _RaisedHomeClipper();

  @override
  Path getClip(Size size) {
    final center = size.width / 2;
    return Path()
      ..moveTo(0, 24)
      ..lineTo(center - 40, 24)
      ..arcToPoint(Offset(center + 40, 24), radius: const Radius.circular(46))
      ..lineTo(size.width, 24)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_RaisedHomeClipper oldClipper) => false;
}
