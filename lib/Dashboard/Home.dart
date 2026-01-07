import 'dart:math';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gosecure/Dashboard/ContactScreens/phonebook_view.dart';
import 'package:gosecure/Dashboard/DashWidgets/Scream.dart';
import 'package:gosecure/Dashboard/Dashboard.dart';
import 'package:gosecure/Dashboard/Settings/SettingsScreen.dart';
import 'package:gosecure/Fake%20call/fake.dart';
import 'package:gosecure/SelfDefence/ho.dart';
import 'package:gosecure/SwipeButton.dart';
import 'package:gosecure/Dashboard/Articles%20-%20SafeCarousel/AllArticles.dart';
import 'package:gosecure/Dashboard/DashWidgets/BookCab.dart';
import 'package:gosecure/Dashboard/DashWidgets/DashAppbar.dart';
import 'package:gosecure/Dashboard/DashWidgets/Emergency.dart';
import 'package:gosecure/Dashboard/DashWidgets/LiveSafe.dart';
import 'package:gosecure/Dashboard/Articles%20-%20SafeCarousel/SafeCarousel.dart';
import 'package:gosecure/Dashboard/DashWidgets/OtherFeature.dart';
import 'package:gosecure/Dashboard/DashWidgets/SafeHome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../HiddenCamera/detection.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var battery = Battery();
  var batteryPercentage = 0;
  var alertState = false;
  final player = AudioPlayer();
  int check = 1;
  int quoteIndex = 0;

  // String _alanSdkKey = '6e9af97f9e4cb20c7996be56c8ddc53a2e956eca572e1d8b807a3e2338fdd0dc/stage';
  @override
  void initState() {
    super.initState();
    // _checkOpening();
    alertState = false;
    getRandomInt(false);
  }

  getRandomInt(fromClick) {
    Random rnd = Random();

    quoteIndex = rnd.nextInt(4);
    if (mounted && fromClick) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // if(check==1){
    //   Future.delayed(Duration.zero, () => showLocAlert(context));
    //   setState(() {
    //     check++;
    //   });
    // }
    // if(batteryPercentage<=15){
    //   showAlert(context);
    // }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashAppbar(
          getRandomInt: getRandomInt,
          quoteIndex: quoteIndex,
        ),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: [
              SafeCarousel(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllArticles(),
                    ),
                  );
                },
                child: Align(
                    alignment: Alignment.topRight,
                    child: Text("See More", textAlign: TextAlign.end)),
              ),
              // Text("${batteryPercentage}"),
              // SizedBox(height: 1),
              SizedBox(
                height: MediaQuery.of(context).size.height / 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (alertState) {
                          player.stop();
                          setState(() {
                            alertState = false;
                          });
                        } else {
                          player.play(AssetSource('emergency.mp3'));
                          setState(() {
                            alertState = true;
                          });
                        }
                      },
                      child: AvatarGlow(
                        glowColor: Colors.redAccent.shade700,
                        duration: Duration(milliseconds: 2000),
                        repeat: true,
                        child: Material(
                          // Replace this child with your own
                          elevation: 8.0,
                          shape: CircleBorder(),
                          child: CircleAvatar(
                            backgroundColor: Colors.redAccent[100],
                            child: Image.asset(
                              'assets/siren.png',
                              height: 60,
                            ),
                            radius: 40.0,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(left: 0),
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFD8080),
                                Color(0xFFFB8580),
                                Color(0xFFFBD079),
                              ],
                            ),
                          ),
                          width: MediaQuery.of(context).size.width / 1.8,
                          // color: Colors.orange,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.arrow_left,
                                size: 37,
                                color: Colors.white,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 42.0),
                                child: Text(
                                  "Danger Siren",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Emergency",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Emergency(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Other Features",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OtherFeature(),
              // SizedBox(
              //   height: MediaQuery.of(context).size.height/6,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       GestureDetector(
              //         onTap: (){
              //           Navigator.of(context).push(MaterialPageRoute(builder: (context) => Fake()));
              //         },
              //         child: AvatarGlow(
              //           glowColor: Colors.blue,
              //           endRadius: 90.0,
              //           duration: Duration(milliseconds: 2000),
              //           repeat: true,
              //           showTwoGlows: true,
              //           repeatPauseDuration: Duration(milliseconds: 100),
              //           child: Material(     // Replace this child with your own
              //             elevation: 8.0,
              //             shape: CircleBorder(),
              //             child: CircleAvatar(
              //               backgroundColor: Colors.blueAccent[100],
              //               child: Image.asset(
              //                 'assets/call.png',
              //                 height: 60,
              //               ),
              //               radius: 40.0,
              //             ),
              //           ),
              //         ),
              //       ),
              //       Expanded(
              //         child: Container(
              //             padding: EdgeInsets.all(10),
              //             margin: EdgeInsets.only(left: 0),
              //             height: 60,
              //             decoration: BoxDecoration(
              //               borderRadius: BorderRadius.only(topLeft: Radius.circular(20),bottomLeft: Radius.circular(20)),
              //               gradient: LinearGradient(
              //                 begin: Alignment.topLeft,
              //                 end: Alignment.bottomRight,
              //                 colors: [
              //                   Color(0xFFFD8080),
              //                   Color(0xFFFB8580),
              //                   Color(0xFFFBD079),
              //                 ],
              //               ),
              //             ),
              //             width: MediaQuery.of(context).size.width/1.8,
              //             // color: Colors.orange,
              //             child: Row(
              //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //               children: [
              //                 Icon(Icons.arrow_left,size: 37,color: Colors.white,),
              //                 Padding(
              //                   padding: const EdgeInsets.only(right: 42.0),
              //                   child: Text("Fake Call",style: TextStyle(color: Colors.white,fontSize: 17,fontWeight: FontWeight.bold,),textAlign: TextAlign.right,),
              //                 ),
              //               ],
              //             )
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 10, top: 10),
                child: Text(
                  "Book Cab",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              BookCab(),

              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 10, top: 10),
                child: Text(
                  "Explore LiveSafe",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              LiveSafe(),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 10, top: 10),
                child: Text(
                  "Be Nirbhaya With",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Scream(),
              SafeHome(),
              SwipeButtonDemo(
                pageRoute: "/fifth",
                buttonTitle: "Swipe to report incident",
              ),
              Image.asset(
                "assets/bk_women.png",
                height: MediaQuery.of(context).size.height / 7,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showLocAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Arm - Hands Free'),
          content: Text(
            'We have provided you a personalized conversational AI to automate your interactions and provide personalized experience',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // void showAlert(BuildContext context) {
  //   showDialog(
  //       // barrierColor: Colors.red,
  //       context: context,
  //       builder: (context) => AlertDialog(
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.all(Radius.circular(32.0))),
  //             title: Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 GlowText("Battery Alert",
  //                     style: TextStyle(
  //                         fontSize: 22,
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w800),
  //                     textAlign: TextAlign.center,
  //                     glowColor: Colors.blue),
  //                 Icon(
  //                   Icons.battery_alert_rounded,
  //                   size: 34,
  //                   color: Colors.white,
  //                 )
  //               ],
  //             ),
  //             backgroundColor: Colors.red,
  //             content: SizedBox(
  //               height: MediaQuery.of(context).size.height / 7.5,
  //               child: Column(
  //                 children: [
  //                   Padding(
  //                     padding: const EdgeInsets.all(8.0),
  //                     child: Text("Charge your phone now!!",
  //                         style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.white,
  //                             fontSize: 18),
  //                         textAlign: TextAlign.start),
  //                   ),
  //                   SizedBox(
  //                     height: 32,
  //                   ),
  //                   Row(
  //                     children: [
  //                       Text("We need power to secure you",
  //                           style: TextStyle(
  //                               fontWeight: FontWeight.bold,
  //                               color: Colors.white,
  //                               fontSize: 16),
  //                           textAlign: TextAlign.center),
  //                       Icon(
  //                         Icons.admin_panel_settings,
  //                         size: 32,
  //                         color: Colors.white,
  //                       )
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ));
  // }
  openMap(String location) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$location';

    try {
      if (await canLaunchUrl(Uri.parse(googleUrl))) {
        await launchUrl(Uri.parse(googleUrl));
      } else {
        throw 'Could not launch $googleUrl';
      }
    } catch (e) {
      debugPrint(e.toString());
      Fluttertoast.showToast(
          msg: "Something went wrong! Call emergency numbers.");
    }
  }

  _callNumber(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  _openrl(String url) async {
    // List<Application> apps = await DeviceApps.getInstalledApplications();
    // DeviceApps.openApp("com.ubercab");
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
