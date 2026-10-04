import 'package:flutter/material.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/config.dart';
import 'package:admin_panel/models/product.dart';
import 'package:admin_panel/services/db.dart';
import 'package:admin_panel/services/image_upload.dart';
import 'package:admin_panel/widgets/common.dart';
import 'package:admin_panel/widgets/product_image.dart';

// Pictures bundled in the shopping app that can be used without uploading.
const List<String> builtInImages = [
  "images/headphone2.png", "images/headphone.PNG", "images/airpods.png", "images/airbads.png",
  "images/laptop2.png", "images/webcam.png", "images/watch2.png", "images/watch.png",
  "images/tv_smart.png", "images/tv_4k.png", "images/tv_oled.png",
];

// Opens the add/edit form. Returns true when saved.
Future<bool?> showProductForm(BuildContext context, {Product? product}) {
  return showDialog<bool>(context: context, builder: (c) => ProductForm(product: product));
}

class ProductForm extends StatefulWidget {
  final Product? product;

  const ProductForm({super.key, this.product});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController name = TextEditingController(text: widget.product?.name ?? "");
  late final TextEditingController price = TextEditingController(text: widget.product == null ? "" : "${widget.product!.price}");
  late final TextEditingController discount = TextEditingController(text: "${widget.product?.discount ?? 0}");
  late final TextEditingController detail = TextEditingController(text: widget.product?.detail ?? "");
  late String image = widget.product?.image ?? "";
  late String? category = categories.contains(widget.product?.category) ? widget.product!.category : null;
  bool saving = false;
  String? imageError;

  bool get editing => widget.product != null;

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    discount.dispose();
    detail.dispose();
    super.dispose();
  }

  void setImage(String? value) {
    if (value == null || value.isEmpty) return;
    setState(() {
      image = value;
      imageError = null;
    });
  }

  Future<void> upload() async {
    try {
      setImage(await ImageUpload.pick());
    } catch (e) {
      setState(() => imageError = "$e");
    }
  }

  Future<void> chooseBuiltIn() async {
    String? picked = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Choose a picture"),
        content: SizedBox(
          width: 460,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: builtInImages
                .map((path) => InkWell(
                      onTap: () => Navigator.pop(c, path),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.imageBox(context), borderRadius: BorderRadius.circular(12)),
                        child: Image.asset(path),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    setImage(picked);
  }

  Future<void> pasteLink() async {
    String? link = await showDialog<String>(context: context, builder: (c) => const _LinkDialog());
    if (link != null && link.startsWith("http")) setImage(link);
  }

  Future<void> save() async {
    bool valid = _formKey.currentState!.validate();
    if (image.isEmpty) setState(() => imageError = "Please add a picture");
    if (!valid || image.isEmpty) return;

    setState(() => saving = true);
    Product p = Product(
      id: widget.product?.id ?? "",
      name: name.text.trim(),
      image: image,
      price: int.parse(price.text.trim()),
      discount: int.tryParse(discount.text.trim()) ?? 0,
      category: category!,
      detail: detail.text.trim(),
    );
    try {
      editing ? await Db.updateProduct(p) : await Db.addProduct(p);
      if (!mounted) return;
      showMessage(context, editing ? "Product updated" : "Product added - it is now in the shop");
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, "Could not save product: $e", error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration deco(String label, {String? prefix, String? suffix}) => InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.field(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    int p = int.tryParse(price.text.trim()) ?? 0;
    int d = (int.tryParse(discount.text.trim()) ?? 0).clamp(0, 90);
    int finalPrice = (p * (100 - d) / 100).round();
    bool phone = isPhone(context);

    return Dialog(
      insetPadding: EdgeInsets.all(phone ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(phone ? 18 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(editing ? "Edit product" : "Add product", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // phone: picture on top of the fields; computer: side by side
                Flex(
                  direction: phone ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: phone ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    // picture
                    Column(
                      children: [
                        Container(
                          height: 200,
                          width: 200,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.imageBox(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: imageError != null ? Colors.red : AppColors.textFaint(context).withValues(alpha: 0.3)),
                          ),
                          child: image.isEmpty
                              ? Icon(Icons.add_photo_alternate_outlined, size: 54, color: AppColors.textFaint(context))
                              : ProductImage(image),
                        ),
                        if (imageError != null)
                          SizedBox(
                            width: 200,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(imageError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(onPressed: upload, icon: const Icon(Icons.upload_outlined), label: const Text("Upload picture")),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(onPressed: chooseBuiltIn, icon: const Icon(Icons.photo_library_outlined), label: const Text("Built-in picture")),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(onPressed: pasteLink, icon: const Icon(Icons.link), label: const Text("Picture link")),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24, height: 20),
                    // details
                    _MaybeExpanded(
                      expand: !phone,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: name,
                            decoration: deco("Product name"),
                            validator: (v) => (v == null || v.trim().isEmpty) ? "Enter the product name" : null,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: deco("Category"),
                            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => category = v),
                            validator: (v) => v == null ? "Choose a category" : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: price,
                                  decoration: deco("Price", prefix: "\$ "),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    int? n = int.tryParse(v?.trim() ?? "");
                                    return (n == null || n <= 0) ? "Enter a whole number above 0" : null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: discount,
                                  decoration: deco("Discount", suffix: "%"),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    int? n = int.tryParse(v?.trim() ?? "");
                                    return (n == null || n < 0 || n > 90) ? "0 to 90" : null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (p > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  Text("Customer pays: ", style: TextStyle(color: AppColors.textMuted(context))),
                                  Text("\$$finalPrice", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
                                  if (d > 0) ...[
                                    const SizedBox(width: 6),
                                    Text("\$$p", style: TextStyle(color: AppColors.textFaint(context), decoration: TextDecoration.lineThrough)),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: detail,
                            maxLines: 5,
                            decoration: deco("Details"),
                            validator: (v) => (v == null || v.trim().isEmpty) ? "Write a few words about the product" : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // buttons move onto their own lines if a phone is too narrow
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text("Cancel")),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16)),
                      onPressed: saving ? null : save,
                      icon: saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: Text(editing ? "Save changes" : "Add product"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Picture link"),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "https://..."),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Use")),
      ],
    );
  }
}

// Expanded inside a row; plain child inside the phone's scrolling column.
class _MaybeExpanded extends StatelessWidget {
  final bool expand;
  final Widget child;

  const _MaybeExpanded({required this.expand, required this.child});

  @override
  Widget build(BuildContext context) => expand ? Expanded(child: child) : child;
}
