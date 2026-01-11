import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

// ignore: must_be_immutable
class FakeCallScreen extends StatefulWidget {
  static final String route = '/fakeCallScreen';

  late String fakeCallerName;

  FakeCallScreen({this.fakeCallerName = 'Unknown'});

  @override
  _FakeCallScreenState createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  late String fakeCallerName;
  late FlutterRingtonePlayer player;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fakeCallerName = widget.fakeCallerName;
    player = FlutterRingtonePlayer();
    player.play(
      fromAsset: 'assets/sounds/ringtone.mp3',
      looping: true,
      volume: 0.5,
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    player.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FloatingActionButton(
            heroTag: 1,
            backgroundColor: Colors.redAccent,
            onPressed: () {
              player.stop();
              Navigator.pop(context);
            },
            child: Icon(
              Icons.call_end_rounded,
            ),
          ),
          FloatingActionButton(
            heroTag: 2,
            backgroundColor: Color.fromRGBO(0, 250, 0, 0.9),
            onPressed: () {},
            child: Icon(
              Icons.phone,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: ExactAssetImage('assets/fakeCallBG.jpg'),
              fit: BoxFit.cover),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 100.0,
            ),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: Icon(
                Icons.person,
                size: 50.0,
                color: const Color.fromRGBO(253, 200, 4, 1.0),
              ),
            ),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(top: 10.0),
              child: Text(
                fakeCallerName,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

