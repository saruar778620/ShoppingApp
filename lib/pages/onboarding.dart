import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/pages/signup.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 50.0,),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset("images/headphone.PNG"),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text('Explore\nThe Best\nProducts',
                  style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              SizedBox(height: 15.0,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Signup()),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.all(20.0),
                      padding: EdgeInsets.all(30.0),
                      decoration: BoxDecoration(color: AppColors.strong(context),shape: BoxShape.circle),
                      child: Text(
                          'NEXT',
                          style: TextStyle(
                              color: AppColors.onStrong(context),
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold
                          ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
