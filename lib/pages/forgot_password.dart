import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:flutter/services.dart';
import 'package:shoppingapp/widget/support_widget.dart';

// Pulls the reset code out of the link Firebase emails, e.g.
// https://xxx.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=ABC&apiKey=...
// It also works when Gmail wraps the link, or when only the code is pasted.
String? extractResetCode(String text) {
  String input = text.trim();
  if (input.isEmpty) return null;
  String decoded = input;
  // links can be URL-encoded more than once when wrapped by Gmail
  for (int i = 0; i < 3; i++) {
    try {
      decoded = Uri.decodeFull(decoded);
    } catch (e) {
      break;
    }
  }
  RegExpMatch? match = RegExp(r'oobCode=([^&\s#]+)').firstMatch(decoded);
  if (match != null) return match.group(1);
  // a bare code (no spaces, no link)
  if (!input.contains(' ') && !input.contains('/') && !input.contains('=')) return input;
  return null;
}

class ForgotPassword extends StatefulWidget {
  final String email;

  const ForgotPassword({super.key, this.email = ""});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController emailcontroller;
  final TextEditingController linkcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final TextEditingController confirmcontroller = TextEditingController();

  bool sending = false;
  bool linkSent = false;
  int cooldown = 0;
  Timer? timer;

  bool checkingLink = false;
  String? resetCode; // set once the pasted link is valid
  String? resetEmail;

  bool saving = false;
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    emailcontroller = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    timer?.cancel();
    emailcontroller.dispose();
    linkcontroller.dispose();
    passwordcontroller.dispose();
    confirmcontroller.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: error ? Colors.redAccent : Colors.green,
        content: Text(message, style: TextStyle(fontSize: 16))));
  }

  String errorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Invalid Email Address";
      case 'user-not-found':
        return "No account found for this email";
      case 'too-many-requests':
        return "Too many tries, please wait a few minutes";
      case 'expired-action-code':
        return "This link has expired. Send a new one";
      case 'invalid-action-code':
        return "This link is not valid or was already used. Use the newest email";
      case 'weak-password':
        return "Password is too weak, use at least 6 characters";
      case 'network-request-failed':
        return "No internet connection";
      default:
        return e.message ?? "Something went wrong";
    }
  }

  void startCooldown() {
    timer?.cancel();
    setState(() {
      cooldown = 60;
    });
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        cooldown--;
      });
      if (cooldown <= 0) t.cancel();
    });
  }

  Future<void> sendLink() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      sending = true;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailcontroller.text.trim());
      if (!mounted) return;
      setState(() {
        linkSent = true;
        resetCode = null;
        linkcontroller.clear();
      });
      startCooldown();
      showMessage("Reset link sent to ${emailcontroller.text.trim()}");
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showMessage(errorText(e), error: true);
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  Future<void> pasteLink() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      linkcontroller.text = data!.text!;
      await checkLink();
    }
  }

  Future<void> checkLink() async {
    String? code = extractResetCode(linkcontroller.text);
    if (code == null) {
      showMessage("Please paste the full link from the email", error: true);
      return;
    }
    setState(() {
      checkingLink = true;
    });
    try {
      String email = await FirebaseAuth.instance.verifyPasswordResetCode(code);
      if (!mounted) return;
      setState(() {
        resetCode = code;
        resetEmail = email;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showMessage(errorText(e), error: true);
    } finally {
      if (mounted) {
        setState(() {
          checkingLink = false;
        });
      }
    }
  }

  Future<void> savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      saving = true;
    });
    try {
      await FirebaseAuth.instance.confirmPasswordReset(code: resetCode!, newPassword: passwordcontroller.text);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.check_circle_outline, color: Colors.green, size: 50),
          title: Text("Password changed"),
          content: Text("You can now log in with your new password.", textAlign: TextAlign.center),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Go to Login")),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, resetEmail);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showMessage(errorText(e), error: true);
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.field(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget primaryButton(String text, VoidCallback? onPressed, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          disabledBackgroundColor: Colors.green.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Text(text, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget stepTitle(int number, String text) {
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.strong(context),
          child: Text("$number", style: TextStyle(color: AppColors.onStrong(context), fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 10),
        Expanded(child: Text(text, style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18))),
      ],
    );
  }

  // step 1: email
  Widget emailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stepTitle(1, "Enter your email"),
          SizedBox(height: 12),
          TextFormField(
            controller: emailcontroller,
            keyboardType: TextInputType.emailAddress,
            enabled: resetCode == null,
            decoration: fieldDecoration("Email", Icons.mail_outline),
            validator: (value) => (value == null || value.trim().isEmpty) ? "Please Enter Your Email" : null,
          ),
          SizedBox(height: 14),
          primaryButton(
            cooldown > 0 ? "Resend link in ${cooldown}s" : (linkSent ? "Send a new link" : "Send reset link"),
            cooldown > 0 ? null : sendLink,
            loading: sending,
          ),
        ],
      ),
    );
  }

  // step 2: paste the link from the email
  Widget linkStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepTitle(2, "Paste the link from your email"),
        SizedBox(height: 8),
        Text(
          "Open the newest email from us (check Spam too), long-press the link, choose Copy, then paste it here.",
          style: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
        ),
        SizedBox(height: 12),
        TextField(
          controller: linkcontroller,
          maxLines: 2,
          decoration: fieldDecoration("Paste reset link", Icons.link,
              suffix: IconButton(tooltip: "Paste", onPressed: pasteLink, icon: Icon(Icons.content_paste))),
        ),
        SizedBox(height: 14),
        primaryButton("Continue", checkLink, loading: checkingLink),
        SizedBox(height: 10),
        Text(
          "Or simply tap the link in the email and set your new password on the page that opens.",
          style: TextStyle(color: AppColors.textFaint(context), fontSize: 13),
        ),
      ],
    );
  }

  // step 3: choose the new password
  Widget passwordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stepTitle(2, "Set a new password"),
          SizedBox(height: 6),
          Text("For $resetEmail", style: TextStyle(color: AppColors.textMuted(context))),
          SizedBox(height: 12),
          TextFormField(
            controller: passwordcontroller,
            obscureText: hidePassword,
            decoration: fieldDecoration("New Password", Icons.lock_outline,
                suffix: IconButton(
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                  icon: Icon(hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                )),
            validator: (value) => (value == null || value.length < 6) ? "Use at least 6 characters" : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: confirmcontroller,
            obscureText: hidePassword,
            decoration: fieldDecoration("Confirm New Password", Icons.lock_outline),
            validator: (value) => value != passwordcontroller.text ? "Passwords do not match" : null,
          ),
          SizedBox(height: 18),
          primaryButton("Save New Password", savePassword, loading: saving),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.lock_reset, size: 48, color: Colors.green),
              ),
            ),
            SizedBox(height: 16),
            Center(child: Text("Forgot Password", style: AppWidget.boldTextFeildStyle())),
            SizedBox(height: 6),
            Center(
              child: Text("Reset your password in a few steps",
                  style: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
            ),
            SizedBox(height: 30),
            if (resetCode == null) ...[
              emailStep(),
              if (linkSent) ...[
                SizedBox(height: 30),
                linkStep(),
              ],
            ] else
              passwordStep(),
          ],
        ),
      ),
    ));
  }
}
