import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/config.dart';
import 'package:admin_panel/models/product.dart';
import 'package:admin_panel/services/db.dart';
import 'package:admin_panel/widgets/common.dart';

class DashboardPage extends StatelessWidget {
  final VoidCallback onOpenOrders;

  const DashboardPage({super.key, required this.onOpenOrders});

  Widget stat(BuildContext context, String title, String value, IconData icon, Color color) {
    // icon above the number, so the card fits even half a phone screen
    return CardBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted(context))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Db.orders(),
      builder: (context, orderSnap) {
        return StreamBuilder<List<Product>>(
          stream: Db.products(),
          builder: (context, productSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: Db.users(),
              builder: (context, userSnap) {
                if (orderSnap.hasError || productSnap.hasError || userSnap.hasError) {
                  return EmptyState(
                    icon: Icons.lock_outline,
                    text: "Could not load data:\n${orderSnap.error ?? productSnap.error ?? userSnap.error}\n\n"
                        "Make sure the Firestore rules from the shopping app folder are published.",
                  );
                }
                List<Map<String, dynamic>> orders = orderSnap.data?.docs.map((d) => d.data()).toList() ?? [];
                num revenue = 0;
                for (var o in orders) {
                  if (o["Status"] != "Cancelled") revenue += (o["Total"] as num?) ?? 0;
                }
                int pending = orders.where((o) => (o["Status"] ?? "Pending") == "Pending").length;

                return ListView(
                  children: [
                    const PageHeader(title: "Dashboard", subtitle: "Your shop at a glance"),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pagePadding(context)),
                      child: LayoutBuilder(builder: (context, c) {
                        int columns = c.maxWidth > 1000 ? 5 : (c.maxWidth > 650 ? 3 : 2);
                        double w = (c.maxWidth - (columns - 1) * 16) / columns;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(width: w, child: stat(context, "Revenue", "\$$revenue", Icons.payments_outlined, Colors.green)),
                            SizedBox(width: w, child: stat(context, "Orders", "${orders.length}", Icons.receipt_long_outlined, Colors.blue)),
                            SizedBox(width: w, child: stat(context, "Pending", "$pending", Icons.pending_actions_outlined, Colors.orange)),
                            SizedBox(width: w, child: stat(context, "Products", "${productSnap.data?.length ?? 0}", Icons.inventory_2_outlined, accent)),
                            SizedBox(width: w, child: stat(context, "Users", "${userSnap.data?.docs.length ?? 0}", Icons.people_outline, Colors.purple)),
                          ],
                        );
                      }),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pagePadding(context), 28, pagePadding(context), 12),
                      child: Row(
                        children: [
                          const Expanded(child: Text("Latest orders", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                          TextButton(onPressed: onOpenOrders, child: const Text("See all")),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pagePadding(context), 0, pagePadding(context), 28),
                      child: CardBox(
                        padding: EdgeInsets.zero,
                        child: orders.isEmpty
                            ? const EmptyState(icon: Icons.receipt_long_outlined, text: "No orders yet")
                            : Column(
                                children: [
                                  for (var o in orders.take(5))
                                    ListTile(
                                      leading: const Icon(Icons.shopping_bag_outlined),
                                      title: Text("${o["Product"]}  x${o["Quantity"] ?? 1}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${o["Name"] ?? "-"} · ${formatDate((o["CreatedAt"] as Timestamp?)?.toDate())}",
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                          // on phones the status goes under the name to save width
                                          if (isPhone(context))
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: StatusChip(status: o["Status"] ?? "Pending", color: statusColor(o["Status"])),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("\$${o["Total"] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          if (!isPhone(context)) ...[
                                            const SizedBox(width: 12),
                                            StatusChip(status: o["Status"] ?? "Pending", color: statusColor(o["Status"])),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
