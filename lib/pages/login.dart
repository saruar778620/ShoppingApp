import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/pages/bottomnav.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/pages/forgot_password.dart';
import 'package:shoppingapp/pages/signup.dart';
import 'package:shoppingapp/services/database.dart';
import 'package:shoppingapp/services/shared_pref.dart';
import 'package:shoppingapp/widget/support_widget.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email="", password="";
  bool hidePassword = true;
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  Future<void> userLogin()async{
    try{
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      User user = userCredential.user!;
      await user.reload();
      if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
        if (!mounted) return;
        bool resend = await showNotVerifiedDialog(user);
        if (resend) await resendVerification(user);
        await FirebaseAuth.instance.signOut();
        return;
      }
      String id = user.uid;
      Map<String, dynamic>? userInfo;
      try {
        userInfo = await DatabaseMethods().getUserDetails(id);
      } catch (e) {
        userInfo = null;
      }
      await Cart.load(id);
      await SharedPreferenceHelper().saveUserId(id);
      await SharedPreferenceHelper().saveUserName(userInfo?["Name"] ?? email.split("@").first);
      await SharedPreferenceHelper().saveUserEmail(email);
      await SharedPreferenceHelper().saveUserImage(userInfo?["image"] ?? "");
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BottomNav()));
    }on FirebaseAuthException catch (e){
      if (!mounted) return;
      String message;
      if(e.code=='user-not-found'){
        message = "No User Found for that Email";
      }
      else if(e.code=='wrong-password' || e.code=='invalid-credential'){
        message = "Wrong Email or Password";
      }
      else if(e.code=='invalid-email'){
        message = "Invalid Email Address";
      }
      else{
        message = e.message ?? "Login Failed";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(message,style: TextStyle(fontSize: 20),)));
    }
  }

  // returns true when the user asks for the link to be sent again
  Future<bool> showNotVerifiedDialog(User user)async{
    bool? resend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.mark_email_unread_outlined, size: 45, color: Colors.orange),
        title: Text("Email not verified"),
        content: Text(
          "Please open the link we sent to\n${user.email}\nthen log in again. Check the Spam folder too.\n\n"
          "Only the NEWEST email works: sending a new link makes the older links expire.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text("Resend link")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text("OK")),
        ],
      ),
    );
    return resend ?? false;
  }

  Future<void> resendVerification(User user)async{
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text("New link sent. Use only this newest email, older links no longer work",style: TextStyle(fontSize: 16),)));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.code == 'too-many-requests'
              ? "Too many tries, please wait a few minutes"
              : (e.message ?? "Could not send link"),style: TextStyle(fontSize: 18),)));
    }
  }

  Future<void> resetPassword()async{
    String? changedEmail = await Navigator.push<String>(context, MaterialPageRoute(
        builder: (context) => ForgotPassword(email: emailcontroller.text.trim())));
    // after a successful reset, fill in the email so the user only types the new password
    if (changedEmail != null && mounted) {
      emailcontroller.text = changedEmail;
      passwordcontroller.clear();
    }
  }
  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 40,left: 20,right: 20,bottom: 35),
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
                Center(child: Text('Sign In',style:AppWidget.boldTextFeildStyle(),)),
                SizedBox(height: 20,),
                SizedBox(
                  width: double.infinity,
                  child: Text('Please enter the details below to continue',
                    textAlign: TextAlign.center,
                    style: AppWidget.lightTextFeildStyle().copyWith(fontSize: 17),),
                ),
                SizedBox(height: 10,),
                Text('Email',style:AppWidget.semiBoldTextFeildStyle(),),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: AppColors.field(context),
                  ),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Your Email';
                      }

                      return null;
                    },
                    controller: emailcontroller,
                    decoration: InputDecoration(border: InputBorder.none,hintText: "Email"),
                  ),
                ),
                SizedBox(height: 10,),
                Text('Password',style:AppWidget.semiBoldTextFeildStyle(),),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: AppColors.field(context),
                  ),
                  child: TextFormField(
                    obscureText: hidePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Your password';
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
                SizedBox(height: 15,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: resetPassword,
                      child: Text('Forgot Password',style: TextStyle(color: Colors.green,fontSize: 18,fontWeight: FontWeight.w500),),
                    ),
                  ],
                ),
                SizedBox(height: 40,),
                GestureDetector(
                  onTap: (){
                    if(_formkey.currentState!.validate()){
                      setState(() {
                        email=emailcontroller.text.trim();
                        password=passwordcontroller.text;
                      });
                      userLogin();
                    }
                  },
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width/2,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,borderRadius: BorderRadius.circular(20)
                      ),
                        child: Center(child: Text("LOGIN",style: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold),))),
                  ),
                ),
                SizedBox(height: 13,),
                // Wrap moves "Sign Up" to the next line on narrow screens / large fonts
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text("Don't have an account?   ",style: AppWidget.lightTextFeildStyle(),),
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> const Signup()));
                      },
                        child: Text('Sign Up',style: TextStyle(color: Colors.green,fontSize: 18,fontWeight: FontWeight.w500),)),
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
