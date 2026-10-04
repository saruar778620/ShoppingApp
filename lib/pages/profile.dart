import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/pages/settings_page.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/pages/login.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/services/shared_pref.dart';
import 'package:shoppingapp/widget/support_widget.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? name, email;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    String? savedName = await SharedPreferenceHelper().getUserName();
    String? savedEmail = await SharedPreferenceHelper().getUserEmail();
    if (!mounted) return;
    setState(() {
      name = savedName;
      email = savedEmail ?? FirebaseAuth.instance.currentUser?.email;
    });
  }

  Future<void> openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
    // the name may have been changed in Settings
    loadUser();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await SharedPreferenceHelper().clear();
    Cart.reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LogIn()),
      (route) => false,
    );
  }

  Widget infoTile(IconData icon, String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 35),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppWidget.lightTextFeildStyle().copyWith(fontSize: 16)),
                Text(value, style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget actionTile(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 35),
            SizedBox(width: 15),
            Text(title, style: AppWidget.semiBoldTextFeildStyle()),
            Spacer(),
            Icon(Icons.arrow_forward_ios_outlined),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text("Profile", style: AppWidget.boldTextFeildStyle()),
        actions: [
          IconButton(tooltip: "Settings", onPressed: openSettings, icon: Icon(Icons.settings_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset("images/boy.jpg", height: 120, width: 120, fit: BoxFit.cover),
            ),
            SizedBox(height: 30),
            infoTile(Icons.person_outline, "Name", name ?? "-"),
            infoTile(Icons.mail_outline, "Email", email ?? "-"),
            actionTile(Icons.settings_outlined, "Settings", openSettings),
            actionTile(Icons.logout, "LogOut", logout),
          ],
        ),
      ),
    ));
  }
}
