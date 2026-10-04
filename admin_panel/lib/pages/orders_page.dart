import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/config.dart';
import 'package:admin_panel/services/db.dart';
import 'package:admin_panel/widgets/common.dart';
import 'package:admin_panel/widgets/product_image.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream = Db.orders();
  String? statusFilter;
  String search = "";

  bool matches(Map<String, dynamic> o) {
    if (statusFilter != null && (o["Status"] ?? "Pending") != statusFilter) return false;
    if (search.isEmpty) return true;
    String text = "${o["Product"]} ${o["Name"]} ${o["Email"]}".toLowerCase();
    return text.contains(search.toLowerCase());
  }

  Future<void> changeStatus(String id, String status) async {
    try {
      await Db.setOrderStatus(id, status);
      if (mounted) showMessage(context, "Order marked as $status");
    } catch (e) {
      if (mounted) showMessage(context, "Could not update order: $e", error: true);
    }
  }

  Future<void> delete(String id) async {
    if (!await confirmAction(context, "Delete order", "Delete this order? This cannot be undone.", "Delete")) return;
    try {
      await Db.deleteOrder(id);
      if (mounted) showMessage(context, "Order deleted");
    } catch (e) {
      if (mounted) showMessage(context, "Could not delete order: $e", error: true);
    }
  }

  Widget orderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> o = doc.data();
    String status = o["Status"] ?? "Pending";
    String image = o["ProductImage"] ?? "";
    Widget picture = Container(
      height: 64,
      width: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppColors.imageBox(context), borderRadius: BorderRadius.circular(12)),
      child: image.isEmpty ? const Icon(Icons.shopping_bag_outlined) : ProductImage(image),
    );
    Widget productInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${o["Product"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text("Qty ${o["Quantity"] ?? 1}  ·  \$${o["Price"] ?? 0} each"
            "${(o["Discount"] ?? 0) > 0 ? "  ·  ${o["Discount"]}% off" : ""}",
            style: TextStyle(color: AppColors.textMuted(context))),
        Text(formatDate((o["CreatedAt"] as Timestamp?)?.toDate()), style: TextStyle(color: AppColors.textFaint(context), fontSize: 12)),
      ],
    );
    Widget customer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${o["Name"] ?? "-"}", style: const TextStyle(fontWeight: FontWeight.w600)),
        SelectableText("${o["Email"] ?? "-"}", style: TextStyle(color: AppColors.textMuted(context))),
      ],
    );
    Widget total = Text("\$${o["Total"] ?? 0}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: accent));
    Widget statusPicker({bool fill = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<String>(
        isExpanded: fill, // on phones it takes only the space that is left
        value: orderStatuses.contains(status) ? status : null,
        hint: Text(status),
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(12),
        items: orderStatuses
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: TextStyle(color: statusColor(s), fontWeight: FontWeight.w600)),
                ))
            .toList(),
        onChanged: (s) {
          if (s != null && s != status) changeStatus(doc.id, s);
        },
      ),
    );
    Widget deleteButton = IconButton(
      tooltip: "Delete order",
      onPressed: () => delete(doc.id),
      icon: const Icon(Icons.delete_outline, color: Colors.red),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBox(
        padding: EdgeInsets.all(isPhone(context) ? 14 : 18),
        child: isPhone(context)
            // phone: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [picture, const SizedBox(width: 12), Expanded(child: productInfo)]),
                  const Divider(height: 22),
                  customer,
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: total),
                    ),
                    Flexible(flex: 2, child: statusPicker(fill: true)),
                    deleteButton,
                  ]),
                ],
              )
            // computer: one line
            : Row(
                children: [
                  picture,
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: productInfo),
                  Expanded(flex: 3, child: customer),
                  SizedBox(width: 90, child: total),
                  statusPicker(),
                  const SizedBox(width: 8),
                  deleteButton,
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        List<QueryDocumentSnapshot<Map<String, dynamic>>> all = snapshot.data?.docs ?? [];
        List<QueryDocumentSnapshot<Map<String, dynamic>>> shown = all.where((d) => matches(d.data())).toList();
        Map<String?, int> counts = {null: all.length};
        for (String s in orderStatuses) {
          counts[s] = all.where((d) => (d.data()["Status"] ?? "Pending") == s).length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: "Orders",
              subtitle: "Orders arrive here live. Change the status and the customer sees it in the app.",
              actions: [
                SizedBox(
                  width: isPhone(context) ? double.infinity : 260,
                  child: TextField(
                    onChanged: (v) => setState(() => search = v.trim()),
                    decoration: InputDecoration(
                      hintText: "Search product or customer",
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.card(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            ChipBar(
              chips: [null, ...orderStatuses].map((s) {
                return ChoiceChip(
                  label: Text("${s ?? "All"} (${counts[s] ?? 0})"),
                  selected: statusFilter == s,
                  onSelected: (_) => setState(() => statusFilter = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: snapshot.hasError
                  ? EmptyState(icon: Icons.lock_outline, text: "Could not load orders:\n${snapshot.error}")
                  : !snapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : shown.isEmpty
                          ? const EmptyState(icon: Icons.receipt_long_outlined, text: "No orders here")
                          : ListView(
                              padding: EdgeInsets.fromLTRB(pagePadding(context), 0, pagePadding(context), 28),
                              children: shown.map(orderCard).toList(),
                            ),
            ),
          ],
        );
      },
    );
  }
}
