import 'package:flutter/material.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/config.dart';
import 'package:admin_panel/models/product.dart';
import 'package:admin_panel/pages/product_form.dart';
import 'package:admin_panel/services/db.dart';
import 'package:admin_panel/widgets/common.dart';
import 'package:admin_panel/widgets/product_image.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final Stream<List<Product>> stream = Db.products();
  String search = "";
  String? categoryFilter;
  bool importing = false;

  Future<void> importBuiltIn() async {
    setState(() => importing = true);
    try {
      await Db.importBuiltInProducts();
      if (mounted) showMessage(context, "${builtInProducts.length} products imported");
    } catch (e) {
      if (mounted) showMessage(context, "Import failed: $e", error: true);
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  Future<void> delete(Product p) async {
    if (!await confirmAction(context, "Delete product", "Delete \"${p.name}\"? It disappears from the shop.", "Delete")) return;
    try {
      await Db.deleteProduct(p.id);
      if (mounted) showMessage(context, "\"${p.name}\" deleted");
    } catch (e) {
      if (mounted) showMessage(context, "Could not delete: $e", error: true);
    }
  }

  Widget productCard(Product p) {
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity, // fill the picture area even when there is no picture
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.imageBox(context), borderRadius: BorderRadius.circular(12)),
                  child: ProductImage(p.image),
                ),
                if (p.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: Text("-${p.discount}%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(p.category.toUpperCase(), style: TextStyle(fontSize: 11, color: AppColors.textFaint(context), letterSpacing: 1)),
          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Row(
            children: [
              // prices shrink to fit next to the buttons (big prices, narrow cards)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text("\$${p.finalPrice}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
                      if (p.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text("\$${p.price}", style: TextStyle(color: AppColors.textFaint(context), decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: "Edit",
                visualDensity: VisualDensity.compact,
                onPressed: () => showProductForm(context, product: p),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: "Delete",
                visualDensity: VisualDensity.compact,
                onPressed: () => delete(p),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: stream,
      builder: (context, snapshot) {
        List<Product> all = snapshot.data ?? [];
        List<Product> shown = all.where((p) {
          if (categoryFilter != null && p.category != categoryFilter) return false;
          return search.isEmpty || p.name.toLowerCase().contains(search.toLowerCase());
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: "Products",
              subtitle: "Changes appear in the shopping app right away",
              actions: [
                SizedBox(
                  width: isPhone(context) ? double.infinity : 220,
                  child: TextField(
                    onChanged: (v) => setState(() => search = v.trim()),
                    decoration: InputDecoration(
                      hintText: "Search products",
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.card(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                if (!isPhone(context)) const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
                  onPressed: () => showProductForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text("Add product"),
                ),
              ],
            ),
            if (all.isNotEmpty)
              ChipBar(
                chips: [null, ...categories].map((c) {
                  int n = c == null ? all.length : all.where((p) => p.category == c).length;
                  return ChoiceChip(
                    label: Text("${c ?? "All"} ($n)"),
                    selected: categoryFilter == c,
                    onSelected: (_) => setState(() => categoryFilter = c),
                  );
                }).toList(),
              ),
            const SizedBox(height: 14),
            Expanded(
              child: snapshot.hasError
                  ? EmptyState(icon: Icons.lock_outline, text: "Could not load products:\n${snapshot.error}")
                  : !snapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : all.isEmpty
                          ? EmptyState(
                              icon: Icons.inventory_2_outlined,
                              text: "No products in the database yet.\nThe shop is showing its ${builtInProducts.length} built-in products. "
                                  "Import them to edit their price, discount and details, or add your own.",
                              action: FilledButton.icon(
                                onPressed: importing ? null : importBuiltIn,
                                icon: importing
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.download_outlined),
                                label: const Text("Import built-in products"),
                              ),
                            )
                          : shown.isEmpty
                              ? const EmptyState(icon: Icons.search_off, text: "No products match")
                              : GridView.builder(
                                  padding: EdgeInsets.fromLTRB(pagePadding(context), 0, pagePadding(context), 28),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 260,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.78,
                                  ),
                                  itemCount: shown.length,
                                  itemBuilder: (context, i) => productCard(shown[i]),
                                ),
            ),
          ],
        );
      },
    );
  }
}
