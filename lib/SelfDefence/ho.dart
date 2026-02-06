import 'package:flutter/material.dart';

class Ho extends StatelessWidget {
  final List<String> techniques = [
    '1. Palm Strike: Strike the attacker\'s nose with the heel of your palm.',
    '2. Elbow Strike: Use your elbow to strike the attacker\'s face or ribs.',
    '3. Knee Strike: Bring your knee up into the attacker\'s groin or stomach.',
    '4. Groin Kick: Kick the attacker in the groin area.',
    '5. Eye Gouge: Use your fingers to poke the attacker\'s eyes.',
    '6. Throat Strike: Strike the attacker\'s throat with your hand or elbow.',
    '7. Wrist Grab Escape: Twist your wrist to break free from a grab.',
    '8. Bear Hug Escape: Step on the attacker\'s foot and strike backwards.'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        title: Text(
          "Self Defence Techniques",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Learn these essential self-defense techniques:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              ...techniques.map((technique) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      technique,
                      style: TextStyle(fontSize: 16),
                    ),
                  )),
              SizedBox(height: 20.0),
              Text(
                'Remember: The best defense is awareness and prevention. Practice these techniques regularly.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
