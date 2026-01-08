import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as location_package;
import 'package:url_launcher/url_launcher.dart';

import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ursafe/Dashboard/ContactScreens/phonebook_view.dart';

class SafeHome extends StatefulWidget {
  const SafeHome({super.key});

  @override
  _SafeHomeState createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  bool getHomeSafeActivated = false;
  List<String> numbers = [];
  var timer;

  checkGetHomeActivated() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      getHomeSafeActivated = prefs.getBool("getHomeSafe") ?? false;
    });
  }

  changeStateOfHomeSafe(value) async {
    if (value) {
      Fluttertoast.showToast(msg: "Service Activated in Background!");
    } else {
      Fluttertoast.showToast(msg: "Service Disabled!");
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      getHomeSafeActivated = value;
      prefs.setBool("getHomeSafe", value);
    });
  }

  @override
  void initState() {
    super.initState();
    checkGetHomeActivated();
    // if(getHomeSafeActivated){
    //   print("&&&&&&&&&&&&&&&&&&&*****************");
    //   Timer.periodic(Duration(seconds: 10), (Timer t) => sendPeriodicMsg());
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
      child: InkWell(
        onTap: () {
          showModelSafeHome(getHomeSafeActivated);
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: 180,
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ListTile(
                        title: Text("Get Home Safe"),
                        subtitle: Text("Share Location Periodically"),
                      ),
                      Visibility(
                        visible: getHomeSafeActivated,
                        child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Row(
                              children: [
                                SpinKitDoubleBounce(
                                  color: Colors.red,
                                  size: 15,
                                ),
                                SizedBox(width: 15),
                                Text("Currently Running...",
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 10)),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/route.jpg",
                      height: 140,
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  showModelSafeHome(bool processRunning) async {
    int selectedContact = -1;
    bool getHomeActivated = processRunning;
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height / 1.4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: Divider(
                            indent: 20,
                            endIndent: 20,
                          )),
                          Text("Get Home Safe"),
                          Expanded(
                              child: Divider(
                            indent: 20,
                            endIndent: 20,
                          )),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color(0xFFF5F4F6)),
                      child: SwitchListTile(
                        secondary: Lottie.asset("assets/routes.json"),
                        value: getHomeActivated,
                        onChanged: (val) async {
                          if (val && selectedContact == -1) {
                            Fluttertoast.showToast(
                                msg: "Please select one contact!");
                            return;
                          }
                          setModalState(() {
                            getHomeActivated = val;
                          });
                          if (getHomeActivated) {
                            changeStateOfHomeSafe(true);
                            startPeriodicLocationSharing(selectedContact);
                            Fluttertoast.showToast(
                                msg:
                                    "Get Home Safe activated - Location will be shared via WhatsApp every 15 minutes");
                          } else {
                            changeStateOfHomeSafe(false);
                            stopPeriodicLocationSharing();
                          }
                        },
                        subtitle: Text(
                            "Your location will be shared with one of your contacts every 15 minutes"),
                      ),
                    ),
                    Expanded(
                        child: FutureBuilder(
                            future: getSOSNumbers(),
                            builder: (context,
                                AsyncSnapshot<List<String>> snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data != null &&
                                  snapshot.data!.isNotEmpty) {
                                return ListView.separated(
                                    itemCount: snapshot.data!.length,
                                    separatorBuilder: (context, index) {
                                      return Divider(
                                        indent: 20,
                                        endIndent: 20,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      String contactData =
                                          snapshot.data![index];
                                      return ListTile(
                                        onTap: () {
                                          setModalState(() {
                                            selectedContact = index;
                                          });
                                        },
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              AssetImage("assets/user.png"),
                                        ),
                                        title:
                                            Text(contactData.split("***")[0]),
                                        subtitle:
                                            Text(contactData.split("***")[1]),
                                        trailing: selectedContact == index
                                            ? Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              )
                                            : null,
                                      );
                                    });
                              } else {
                                return ListTile(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhoneBook(),
                                      ),
                                    );
                                  },
                                  title: Text("No contact found!"),
                                  subtitle:
                                      Text("Please add atleast one Contact"),
                                  trailing: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.grey),
                                );
                              }
                            }))
                  ],
                ),
              );
            },
          );
        });
  }

  Future<List<String>> getSOSNumbers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    numbers = prefs.getStringList("numbers") ?? [];

    return numbers;
  }

  void startPeriodicLocationSharing(int selectedContactIndex) async {
    // Cancel any existing timer
    stopPeriodicLocationSharing();

    // Get the selected contact's phone number
    if (selectedContactIndex >= 0 && selectedContactIndex < numbers.length) {
      String contactData = numbers[selectedContactIndex];
      String phoneNumber = contactData.split("***")[1];

      // Start periodic timer (15 minutes = 900 seconds)
      timer = Timer.periodic(Duration(minutes: 15), (Timer t) async {
        try {
          // Get current location
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

          // Share location via WhatsApp
          await shareLocationOnWhatsApp(
              phoneNumber, position.latitude, position.longitude);
        } catch (e) {
          print("Error in periodic location sharing: $e");
        }
      });
    }
  }

  void stopPeriodicLocationSharing() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }

  Future<void> shareLocationOnWhatsApp(
      String phoneNumber, double latitude, double longitude) async {
    try {
      // Clean the phone number (remove any non-digit characters)
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // Create Google Maps URL
      String mapsUrl =
          "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

      // Create location sharing message
      String message = "🏠 GET HOME SAFE UPDATE 🏠\n\n"
          "I'm on my way home. My current location is:\n"
          "📍 $mapsUrl\n\n"
          "This is an automated location update.";

      // Encode the message for WhatsApp URL
      String encodedMessage = Uri.encodeComponent(message);

      // Create WhatsApp URL
      String whatsappUrl = "https://wa.me/$cleanedNumber?text=$encodedMessage";

      // Check if WhatsApp can be launched
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        print("Shared periodic location on WhatsApp with $cleanedNumber");
      } else {
        print("Could not launch WhatsApp for periodic sharing");
      }
    } catch (e) {
      print("Error sharing location on WhatsApp: $e");
    }
  }
}
