import 'package:flutter/material.dart';
import 'package:admin_panel/theme/theme.dart';

// Phones get a stacked, tighter layout; tablets and computers the roomy one.
bool isPhone(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

// Space between the screen edge and the page content.
double pagePadding(BuildContext context) => isPhone(context) ? 16 : 28;

// Page title + optional buttons (on the right, or below the title on phones).
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    bool phone = isPhone(context);
    double pad = pagePadding(context);
    Widget titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: phone ? 22 : 26, fontWeight: FontWeight.bold)),
        if (subtitle != null) Text(subtitle!, style: TextStyle(color: AppColors.textMuted(context))),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, phone ? 16 : 28, pad, phone ? 12 : 16),
      child: phone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titles,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: actions),
                ],
              ],
            )
          : Row(children: [Expanded(child: titles), ...actions]),
    );
  }
}

// Filter chips: one line you can swipe sideways on phones, wrapped lines on bigger screens.
class ChipBar extends StatelessWidget {
  final List<Widget> chips;

  const ChipBar({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    double pad = pagePadding(context);
    if (isPhone(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: pad),
        child: Row(children: [for (Widget c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c)]),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow(context), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textFaint(context)),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.textMuted(context))),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const StatusChip({super.key, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

// Asks "are you sure?"; returns true when confirmed.
Future<bool> confirmAction(BuildContext context, String title, String message, String action) async {
  bool? ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(action, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return ok == true;
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    width: isPhone(context) ? null : 420,
    backgroundColor: error ? Colors.red.shade600 : Colors.green.shade700,
    content: Text(text),
  ));
}
