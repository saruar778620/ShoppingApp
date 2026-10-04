import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/models/product.dart';
import 'package:shoppingapp/pages/product_detaile.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/services/shared_pref.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/widget/price_tag.dart';
import 'package:shoppingapp/widget/product_image.dart';
import 'package:shoppingapp/widget/support_widget.dart';
import 'package:shoppingapp/widget/theme_toggle.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? name;
  String search = "";
  final TextEditingController searchController = TextEditingController();
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    loadUser();
    shopProducts.addListener(onProductsChanged);
  }

  // products added or edited in the admin panel show up right away
  void onProductsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> loadUser() async {
    String? savedName = await SharedPreferenceHelper().getUserName();
    if (!mounted) return;
    setState(() {
      name = savedName;
    });
  }

  List<Product> get filteredProducts {
    String query = search.trim();
    // while searching, look through every product, not just the selected category
    if (query.isNotEmpty) {
      return shopProducts.value.where((product) => matchesSearch(product, query)).toList();
    }
    return shopProducts.value.where((product) => selectedCategory == null || product.category == selectedCategory).toList();
  }

  void addToCart(Product product) {
    Cart.add(product);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
      content: Text("${product.name} added to cart", style: TextStyle(fontSize: 16)),
    ));
  }

  @override
  void dispose() {
    shopProducts.removeListener(onProductsChanged);
    searchController.dispose();
    super.dispose();
  }

  Widget searchBar() {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            search = value;
          });
        },
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
          hintText: 'Search Product',
          hintStyle: AppWidget.lightTextFeildStyle().copyWith(fontSize: 17),
          prefixIcon: Icon(Icons.search, color: AppColors.text(context)),
          suffixIcon: search.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: AppColors.textMuted(context)),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      search = "";
                    });
                  },
                ),
        ),
      ),
    );
  }

  Widget categoryList() {
    return ListView.builder(
      itemCount: categories.length+1,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        if (index == 0) {
          return CategoryTitle(
            name: 'All',
            selected: selectedCategory == null,
            onTap: () {
              setState(() {
                selectedCategory = null;
              });
            },
          );
        }
        Category category = categories[index-1];
        return CategoryTitle(
          name: category.name,
          image: category.image,
          selected: selectedCategory == category.name,
          onTap: () {
            setState(() {
              selectedCategory = category.name;
            });
          },
        );
      },
    );
  }

  // search bar + categories: stays stuck at the top while the products scroll under it
  Widget pinnedHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: searchBar(),
          ),
          SizedBox(height: 14),
          SizedBox(
            height: 24,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Categories', style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18)),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(height: 100, child: categoryList()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Product> items = filteredProducts;
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // greeting + banner: scrolls away
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0, left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Hey, ${name ?? "there"}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppWidget.boldTextFeildStyle()),
                                Text("Good to see you", style: AppWidget.lightTextFeildStyle()),
                              ],
                            ),
                          ),
                          // animated sun <-> moon switch
                          const ThemeToggleButton(),
                          SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset("images/boy.jpg", height: 60, width: 60, fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    const ProductBannerSlider(),
                  ],
                ),
              ),
            ),
            // search + categories: pinned
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: 218,
                background: AppColors.glass(context),
                child: pinnedHeader(),
              ),
            ),
            // products: scroll under the pinned header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      search.trim().isNotEmpty
                          ? "Search Results"
                          : (selectedCategory == null ? "All Products" : selectedCategory!),
                      style: AppWidget.semiBoldTextFeildStyle(),
                    ),
                    Text(
                      "${items.length} items",
                      style: TextStyle(color: AppColors.textMuted(context), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text("No product found", style: AppWidget.lightTextFeildStyle())),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: items.length,
                    (context, index) {
                      Product product = items[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProductDetaile(product: product)),
                          );
                        },
                        onAdd: () => addToCart(product),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color background;
  final Widget child;

  _PinnedHeaderDelegate({required this.height, required this.background, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // see-through until products start sliding under it, then frosted glass
    bool stuck = shrinkOffset > 0 || overlapsContent;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: stuck ? 18 : 0, sigmaY: stuck ? 18 : 0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: stuck ? background : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: stuck ? Colors.black.withValues(alpha: 0.06) : Colors.transparent),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // the header shows the search text and selected category, so always rebuild it
  @override
  bool shouldRebuild(_PinnedHeaderDelegate oldDelegate) => true;
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const ProductCard({super.key, required this.product, this.onTap, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.imageBox(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: ProductImage(product.image)),
                    if (product.hasDiscount)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: DiscountTag(discount: product.discount),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textFaint(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    product.name,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: PriceText(product: product),
                        ),
                      ),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.strong(context),
                          ),
                          child: Icon(Icons.add_shopping_cart, color: AppColors.onStrong(context), size: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTitle extends StatelessWidget {
  final String name;
  final String? image;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryTitle({super.key, required this.name, this.image, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        margin: EdgeInsets.only(right: 6.0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              height: 62,
              width: 62,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? Color(0xFFfd6f3e) : AppColors.imageBox(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow(context),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: image == null
                  ? Icon(Icons.apps_rounded, color: selected ? Colors.white : Colors.black87)
                  : Image.asset(image!, fit: BoxFit.contain),
            ),
            SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Color(0xFFfd6f3e) : AppColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//coursal banner sliding

class ProductBannerSlider extends StatelessWidget {
  const ProductBannerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> bannerData = [
      {
        "image": "images/watch2.png",
        "title": "Super Sale!",
        "subtitle": "Get 20% off on Apple Watches"
      },

      {
        "image": "images/headphone2.png",
        "title": "New Arrival",
        "subtitle": "Premium Sound, Ultimate Comfort"
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 150.0,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          autoPlayAnimationDuration: const Duration(milliseconds: 1000),
          enlargeCenterPage: true,
          viewportFraction: 1.0,
          autoPlayCurve: Curves.fastOutSlowIn,
        ),
        items: bannerData.map((data) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFfd6f3e), Colors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data["title"]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 150,
                        child: Text(
                          data["subtitle"]!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 15,
                  top: 15,
                  bottom: 15,
                  child: Image.asset(
                    data["image"]!,
                    fit: BoxFit.contain,
                    width: 90,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
