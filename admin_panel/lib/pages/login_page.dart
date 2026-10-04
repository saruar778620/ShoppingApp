import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/theme/app_background.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/theme/theme_toggle.dart';
import 'package:admin_panel/config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController(text: ownerEmail);
  final TextEditingController passwordController = TextEditingController();
  bool hidePassword = true;
  bool busy = false;
  String? message;
  bool messageIsError = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void show(String text, {bool error = true}) {
    setState(() {
      message = text;
      messageIsError = error;
    });
  }

  String authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return "Wrong email or password. First time here? Use \"Create owner account\".";
      case 'email-already-in-use':
        return "The owner account already exists. Just log in (or use Forgot password).";
      case 'weak-password':
        return "Password is too weak, use at least 6 characters.";
      case 'too-many-requests':
        return "Too many tries, please wait a few minutes.";
      case 'network-request-failed':
        return "No internet connection.";
      default:
        return e.message ?? "Something went wrong.";
    }
  }

  bool checkOwnerEmail() {
    if (emailController.text.trim().toLowerCase() != ownerEmail.toLowerCase()) {
      show("Only the owner account ($ownerEmail) can use the admin panel.");
      return false;
    }
    return true;
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      show(authError(e));
    } catch (e) {
      show("$e");
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> login() => run(() async {
        if (!checkOwnerEmail()) return;
        UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        User user = credential.user!;
        await user.reload();
        if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
          await user.sendEmailVerification();
          await FirebaseAuth.instance.signOut();
          show("Your email is not verified yet. We sent a new link to $ownerEmail. "
              "Open the newest email, click the link, then log in again.");
        }
        // when verified, AuthGate switches to the panel automatically
      });

  Future<void> createAccount() => run(() async {
        if (!checkOwnerEmail()) return;
        if (passwordController.text.length < 6) {
          show("Choose a password with at least 6 characters, then tap Create owner account.");
          return;
        }
        UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        await credential.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        show("Owner account created. We sent a verification link to $ownerEmail. "
            "Click it (check Spam too), then come back and log in.", error: false);
      });

  Future<void> forgotPassword() => run(() async {
        if (!checkOwnerEmail()) return;
        await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
        show("Password reset link sent to $ownerEmail. Open it, set a new password, then log in.", error: false);
      });

  InputDecoration field(String label, IconData icon, {Widget? suffix}) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.field(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      // sun <-> moon switch in the top right corner
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: ThemeToggleButton(size: 46),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.shadow(context), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.admin_panel_settings_outlined, size: 44, color: accent),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text("Admin Panel", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text("Shopping App owner login",
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: field("Owner email", Icons.mail_outline),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    onSubmitted: (_) => busy ? null : login(),
                    decoration: field("Password", Icons.lock_outline,
                        suffix: IconButton(
                          tooltip: hidePassword ? "Show password" : "Hide password",
                          onPressed: () => setState(() => hidePassword = !hidePassword),
                          icon: Icon(hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        )),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (messageIsError ? Colors.red : Colors.green).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message!, style: TextStyle(color: messageIsError ? Colors.red.shade700 : Colors.green.shade800)),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: busy ? null : login,
                      child: busy
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text("Log in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // wraps onto two lines on narrow phones
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: busy ? null : forgotPassword, child: const Text("Forgot password")),
                      TextButton(onPressed: busy ? null : createAccount, child: const Text("Create owner account")),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
