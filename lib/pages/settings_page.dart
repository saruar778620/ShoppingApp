import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/pages/login.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/services/database.dart';
import 'package:shoppingapp/services/shared_pref.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/widget/support_widget.dart';

const String appVersion = "1.0.0";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? name;
  final Set<String> openSections = {}; // sections the user has opened
  User? get user {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      return null; // Firebase not ready (e.g. in tests)
    }
  }

  @override
  void initState() {
    super.initState();
    loadName();
  }

  Future<void> loadName() async {
    String? saved = await SharedPreferenceHelper().getUserName();
    if (!mounted) return;
    setState(() {
      name = saved;
    });
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: error ? Colors.redAccent : Colors.green,
        content: Text(message, style: TextStyle(fontSize: 16))));
  }

  String authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return "Current password is wrong";
      case 'weak-password':
        return "New password is too weak, use at least 6 characters";
      case 'too-many-requests':
        return "Too many tries, please wait a few minutes";
      case 'network-request-failed':
        return "No internet connection";
      default:
        return e.message ?? "Something went wrong";
    }
  }

  // Firebase needs the current password before changing the password or deleting the account
  Future<void> reauthenticate(String password) async {
    AuthCredential credential = EmailAuthProvider.credential(email: user!.email!, password: password);
    await user!.reauthenticateWithCredential(credential);
  }

  void goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LogIn()),
      (route) => false,
    );
  }

  // ---------- account ----------

  Future<void> editName() async {
    String? newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _TextInputDialog(
        title: "Edit Name",
        initialText: name ?? "",
        hint: "Your name",
        actionLabel: "Save",
        capitalizeWords: true,
      ),
    );
    if (newName == null || newName.isEmpty || newName == name || user == null) return;
    try {
      await DatabaseMethods().updateUserName(user!.uid, newName);
      await SharedPreferenceHelper().saveUserName(newName);
      if (!mounted) return;
      setState(() {
        name = newName;
      });
      showMessage("Name updated");
    } catch (e) {
      if (!mounted) return;
      showMessage("Could not update name: $e", error: true);
    }
  }

  Future<void> changePassword() async {
    bool? changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ChangePasswordDialog(
        onSubmit: (current, newPassword) async {
          await reauthenticate(current);
          await user!.updatePassword(newPassword);
        },
        errorText: authError,
      ),
    );
    if (changed == true && mounted) showMessage("Password changed");
  }

  // ---------- shopping ----------

  Future<void> clearCart() async {
    if (Cart.count == 0) {
      showMessage("Your cart is already empty");
      return;
    }
    bool? ok = await confirm("Clear Cart", "Remove all ${Cart.count} item(s) from your cart?", "Clear");
    if (ok != true) return;
    Cart.clear();
    if (mounted) showMessage("Cart cleared");
  }

  // ---------- logout / delete ----------

  Future<void> logout() async {
    bool? ok = await confirm("Logout", "Do you want to log out?", "Logout");
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    await SharedPreferenceHelper().clear();
    Cart.reset();
    if (!mounted) return;
    goToLogin();
  }

  Future<void> deleteAccount() async {
    String? password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _TextInputDialog(
        title: "Delete Account",
        message: "This permanently deletes your account. Enter your password to confirm.",
        hint: "Password",
        actionLabel: "Delete",
        actionColor: Colors.red,
        obscure: true,
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 45),
      ),
    );
    if (password == null || password.isEmpty || user == null) return;
    try {
      // check the password first, so nothing is deleted if it is wrong
      await reauthenticate(password);
      String id = user!.uid;
      try {
        await DatabaseMethods().deleteUserDetails(id);
      } catch (e) {
        // the account itself is still deleted below
      }
      await user!.delete();
      await SharedPreferenceHelper().clear();
      Cart.reset();
      if (!mounted) return;
      goToLogin();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showMessage(authError(e), error: true);
    }
  }

  // ---------- support / about ----------

  void openInfoPage(String title, List<_InfoSection> sections) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => _InfoPage(title: title, sections: sections)));
  }

  void openHelp() {
    openInfoPage("Help & FAQ", const [
      _InfoSection("How do I buy a product?",
          "Open a product and tap Buy now, or tap the cart button on a product card. Then open the Cart tab and tap Confirm Order."),
      _InfoSection("How do I remove something from my cart?",
          "Open the Cart tab and tap the red delete icon next to the item. Tap UNDO if you removed it by mistake."),
      _InfoSection("Where can I see my orders?",
          "Open the Orders tab. Each order shows its status: Pending, On the way, Delivered or Cancelled."),
      _InfoSection("I did not get the verification email",
          "Check the Spam and Promotions folders. Only the newest email works: sending a new link makes the older links expire."),
      _InfoSection("I forgot my password",
          "On the login screen tap Forgot Password, enter your email, then paste the link from the email into the app and choose a new password."),
      _InfoSection("How do I switch to dark mode?",
          "Go to Profile > Settings > Appearance, or tap the moon button at the top of the home screen."),
    ]);
  }

  void openPrivacy() {
    openInfoPage("Privacy Policy", const [
      _InfoSection("What we store",
          "Your name and email address, and the orders you place (product, quantity, price, status and date). These are stored in Google Firebase."),
      _InfoSection("What stays on your phone",
          "Your cart and your appearance setting are saved only on this device."),
      _InfoSection("Your password",
          "Your password is handled by Firebase Authentication. The app never sees or stores it."),
      _InfoSection("Deleting your data",
          "You can delete your account any time from Settings > Delete Account. This removes your login and your profile."),
    ]);
  }

  // ---------- UI ----------

  Future<bool?> confirm(String title, String message, String action) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action)),
        ],
      ),
    );
  }

  Widget divider() => Divider(height: 1, indent: 56, color: AppColors.textFaint(context).withValues(alpha: 0.2));

  Widget group(List<Widget> tiles) {
    List<Widget> children = [];
    for (int i = 0; i < tiles.length; i++) {
      if (i > 0) children.add(divider());
      children.add(tiles[i]);
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.card(context), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  // A section that shows only its name until tapped, then opens its options below.
  Widget section(IconData icon, String title, String summary, List<Widget> tiles) {
    bool open = openSections.contains(title);
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.card(context), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => open ? openSections.remove(title) : openSections.add(title)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.accent, size: 22),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(summary, style: TextStyle(fontSize: 13, color: AppColors.textMuted(context))),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted(context)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: open
                ? Column(children: [for (Widget t in tiles) ...[divider(), t]])
                : SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget tile(IconData icon, String title, {String? subtitle, Widget? trailing, VoidCallback? onTap, Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.text(context)),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: AppColors.textMuted(context))),
      trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_right, color: AppColors.textFaint(context))),
    );
  }

  Widget appearancePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, mode, child) {
          return SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text("Light")),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text("Dark")),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android), label: Text("System")),
              ],
              selected: {mode},
              onSelectionChanged: (selected) => ThemeController.set(selected.first),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool verified = user?.emailVerified ?? false;
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text("Settings", style: AppWidget.boldTextFeildStyle()),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          section(Icons.person_outline, "Account", "Name, email, password", [
            tile(Icons.badge_outlined, "Name", subtitle: name ?? "-", onTap: editName,
                trailing: Icon(Icons.edit_outlined, color: AppColors.textFaint(context))),
            tile(Icons.mail_outline, "Email",
                subtitle: user?.email ?? "-",
                trailing: Icon(verified ? Icons.verified : Icons.error_outline,
                    color: verified ? Colors.green : Colors.orange)),
            tile(Icons.lock_outline, "Change Password", onTap: changePassword),
          ]),
          section(Icons.palette_outlined, "Appearance", "Light, dark or system theme", [
            appearancePicker(),
          ]),
          section(Icons.shopping_bag_outlined, "Shopping", "Cart", [
            ValueListenableBuilder<Map<String, int>>(
              valueListenable: Cart.items,
              builder: (context, value, child) => tile(Icons.remove_shopping_cart_outlined, "Clear Cart",
                  subtitle: "${Cart.count} item(s) in cart", onTap: clearCart),
            ),
          ]),
          section(Icons.support_agent_outlined, "Support", "Help, FAQ, privacy", [
            tile(Icons.help_outline, "Help & FAQ", onTap: openHelp),
            tile(Icons.privacy_tip_outlined, "Privacy Policy", onTap: openPrivacy),
          ]),
          section(Icons.info_outline, "About", "App version", [
            tile(Icons.new_releases_outlined, "App Version", trailing: Text(appVersion,
                style: TextStyle(color: AppColors.textMuted(context), fontSize: 15))),
          ]),
          SizedBox(height: 10),
          group([
            tile(Icons.logout, "Logout", onTap: logout),
            tile(Icons.delete_outline, "Delete Account", onTap: deleteAccount, color: Colors.red),
          ]),
        ],
      ),
    ));
  }
}

// A dialog with one text field. It owns its controller and disposes it only after
// the dialog is fully closed, so closing it (Cancel or Save) never hits a disposed controller.
class _TextInputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String initialText;
  final String hint;
  final String actionLabel;
  final Color? actionColor;
  final bool obscure;
  final bool capitalizeWords;
  final Widget? icon;

  const _TextInputDialog({
    required this.title,
    this.message,
    this.initialText = "",
    required this.hint,
    required this.actionLabel,
    this.actionColor,
    this.obscure = false,
    this.capitalizeWords = false,
    this.icon,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: widget.icon,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            SizedBox(height: 12),
          ],
          TextField(
            controller: controller,
            autofocus: true,
            obscureText: widget.obscure,
            textCapitalization: widget.capitalizeWords ? TextCapitalization.words : TextCapitalization.none,
            decoration: InputDecoration(hintText: widget.hint),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        TextButton(
          onPressed: () => Navigator.pop(context, widget.obscure ? controller.text : controller.text.trim()),
          child: Text(widget.actionLabel, style: TextStyle(color: widget.actionColor)),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function(String current, String newPassword) onSubmit;
  final String Function(FirebaseAuthException) errorText;

  const _ChangePasswordDialog({required this.onSubmit, required this.errorText});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController current = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  bool hide = true;
  bool saving = false;
  String? error;

  @override
  void dispose() {
    current.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSubmit(current.text, newPassword.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        error = widget.errorText(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Change Password"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: current,
              obscureText: hide,
              decoration: InputDecoration(labelText: "Current password"),
              validator: (v) => (v == null || v.isEmpty) ? "Enter your current password" : null,
            ),
            TextFormField(
              controller: newPassword,
              obscureText: hide,
              decoration: InputDecoration(
                labelText: "New password",
                suffixIcon: IconButton(
                  onPressed: () => setState(() => hide = !hide),
                  icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? "Use at least 6 characters" : null,
            ),
            TextFormField(
              controller: confirmPassword,
              obscureText: hide,
              decoration: InputDecoration(labelText: "Confirm new password"),
              validator: (v) => v != newPassword.text ? "Passwords do not match" : null,
            ),
            if (error != null) ...[
              SizedBox(height: 12),
              Text(error!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: Text("Cancel")),
        TextButton(
          onPressed: saving ? null : submit,
          child: saving
              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text("Save"),
        ),
      ],
    );
  }
}

class _InfoSection {
  final String title;
  final String body;

  const _InfoSection(this.title, this.body);
}

class _InfoPage extends StatelessWidget {
  final String title;
  final List<_InfoSection> sections;

  const _InfoPage({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: AppWidget.semiBoldTextFeildStyle()),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: sections
            .map((s) => Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.card(context), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text(s.body, style: TextStyle(fontSize: 15, color: AppColors.textMuted(context), height: 1.4)),
                    ],
                  ),
                ))
            .toList(),
      ),
    ));
  }
}
