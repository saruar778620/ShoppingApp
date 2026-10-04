import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/pages/login.dart';
import 'package:shoppingapp/services/database.dart';

import '../widget/support_widget.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String? name, email, password;
  bool hidePassword = true;
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    namecontroller.dispose();
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  Future<void> registration() async {
    if (password != null && name != null && email != null) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email!, password: password!);

        // the account only works after the user clicks the link sent to their Gmail.
        // Send it first, so a problem saving the profile can never stop the email.
        await userCredential.user!.sendEmailVerification();

        String id = userCredential.user!.uid;
        Map<String, dynamic> userInfoMap={
          "Name": name,
          "Email": email,
          "id": id,
          "image": "",
        };
        try {
          await DatabaseMethods().addUserDetails(userInfoMap, id);
        } catch (e) {
          // profile can be saved later; the name falls back to the email at login
        }
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.mark_email_unread_outlined, size: 45, color: Colors.green),
            title: Text("Verify your email"),
            content: Text(
              "We sent a verification link to\n$email\n\nOpen your Gmail, click the link, then come back and log in. Check the Spam folder if you don't see it.",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("OK, go to Login")),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogIn()),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String message;
        if (e.code == 'weak-password') {
          message = "Password Provided is too Weak";
        } else if (e.code == 'email-already-in-use') {
          message = "Account already exists. Go to Login; if it is not verified you can resend the link there";
        } else if (e.code == 'too-many-requests') {
          message = "Too many tries, please wait a few minutes";
        } else if (e.code == 'invalid-email') {
          message = "Invalid Email Address";
        } else {
          message = e.message ?? "Registration Failed";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              message,
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
      } catch (e) {
        // anything else (network, Firebase setup...) must still be visible to the user
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Sign up failed: $e", style: TextStyle(fontSize: 16)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 35),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // rounded corners so the white picture sits nicely on the gradient
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('images/login.png'),
                ),
                Center(
                  child: Text('Sign Up', style: AppWidget.boldTextFeildStyle()),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Please enter the details below to continue',
                    textAlign: TextAlign.center,
                    style: AppWidget.lightTextFeildStyle().copyWith(fontSize: 17),
                  ),
                ),
                SizedBox(height: 10),
                Text('Name', style: AppWidget.semiBoldTextFeildStyle()),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(color: AppColors.field(context)),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Your Name';
                      }

                      return null;
                    },
                    controller: namecontroller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Name",
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text('Email', style: AppWidget.semiBoldTextFeildStyle()),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(color: AppColors.field(context)),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Your Email';
                      }

                      return null;
                    },
                    controller: emailcontroller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Email",
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text('Password', style: AppWidget.semiBoldTextFeildStyle()),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(color: AppColors.field(context)),
                  child: TextFormField(
                    obscureText: hidePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Your Password';
                      }

                      return null;
                    },
                    controller: passwordcontroller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Password",
                      suffixIcon: IconButton(
                        tooltip: hidePassword ? "Show password" : "Hide password",
                        onPressed: () => setState(() => hidePassword = !hidePassword),
                        icon: Icon(hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    if (_formkey.currentState!.validate()) {
                      setState(() {
                        name = namecontroller.text.trim();
                        email = emailcontroller.text.trim();
                        password = passwordcontroller.text;
                      });
                      registration();
                    }
                  },
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "SIGN UP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 13),
                // Wrap moves "Sign In" to the next line on narrow screens / large fonts
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Already have an account?   ",
                      style: AppWidget.lightTextFeildStyle(),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LogIn()),
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
