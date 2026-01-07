import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter/services.dart';

class SwipeButtonDemo extends StatelessWidget {
  final String? pageRoute;
  final String? buttonTitle;

  const SwipeButtonDemo({Key? key, this.pageRoute, this.buttonTitle})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Column(
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SlideAction(
              onSubmit: () {
                _callNumber("7827170170");
              },
              innerColor: Colors.white,
              outerColor: Colors.blue,
              sliderButtonIcon: Icon(
                Icons.chevron_right,
                size: 50.0,
                color: Colors.white,
              ),
              text: 'Report to NCW cell',
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.043,
              ),
              sliderRotate: false,
            ),
          ),
        ),
      ],
    );
  }

  _callNumber(number) async {
    await FlutterPhoneDirectCaller.callNumber(number);
  }
}
