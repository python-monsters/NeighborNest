import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuctionHostScreen extends StatefulWidget {
  @override
  _AuctionHostScreenState createState() => _AuctionHostScreenState();
}

class _AuctionHostScreenState extends State<AuctionHostScreen> {
  final itemController = TextEditingController();
  final weightController = TextEditingController();
  final db = FirebaseDatabase.instance.reference().child('auctions');
  final uid = FirebaseAuth.instance.currentUser?.uid;

  int remaining = 0;
  Timer? timer;
  bool isRunning = false;
  String auctionId = "";

  void startAuction(int seconds) {
    setState(() {
      remaining = seconds;
      isRunning = true;
    });

    final newRef = db.push();
    auctionId = newRef.key!;
    newRef.set({
      'itemName': itemController.text,
      'weight': double.tryParse(weightController.text) ?? 1.0,
      'isActive': true,
      'timeLeft': seconds,
      'bids': [],
      'sellerId': uid,
    });

    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (remaining <= 0) {
        t.cancel();
        db.child(auctionId).update({'isActive': false});
        setState(() => isRunning = false);
      } else {
        setState(() => remaining--);
        db.child(auctionId).update({'timeLeft': remaining});
      }
    });
  }

  void endAuctionNow() {
    timer?.cancel();
    db.child(auctionId).update({'isActive': false});
    setState(() => isRunning = false);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Host Auction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: itemController,
            decoration: InputDecoration(labelText: 'Item Title'),
          ),
          TextField(
            controller: weightController,
            decoration: InputDecoration(labelText: 'Weight (oz)'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          DropdownButton<int>(
            value: 60,
            onChanged: isRunning ? null : (val) => startAuction(val!),
            items: [30, 60, 120].map((v) => DropdownMenuItem(
              value: v,
              child: Text("Start $v sec Auction"),
            )).toList(),
          ),
          if (isRunning)
            Column(
              children: [
                SizedBox(height: 16),
                Text("Time Remaining: $remaining s", style: TextStyle(fontSize: 22)),
                ElevatedButton.icon(
                  onPressed: endAuctionNow,
                  icon: Icon(Icons.cancel),
                  label: Text("End Early"),
                )
              ],
            )
        ]),
      ),
    );
  }
}
