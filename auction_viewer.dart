import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auction_chat.dart';

class AuctionViewerScreen extends StatefulWidget {
  @override
  _AuctionViewerScreenState createState() => _AuctionViewerScreenState();
}

class _AuctionViewerScreenState extends State<AuctionViewerScreen> {
  late DatabaseReference auctionRef;
  Map auctionData = {};
  String? auctionId;
  final bidController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auctionId = ModalRoute.of(context)!.settings.arguments as String;
    auctionRef = FirebaseDatabase.instance.ref('auctions/$auctionId');
    auctionRef.onValue.listen((event) {
      setState(() {
        auctionData = Map.from(event.snapshot.value ?? {});
      });
    });
  }

  void placeBid() {
    final user = FirebaseAuth.instance.currentUser;
    final currentBids = List.from(auctionData['bids'] ?? []);
    final bidAmount = double.tryParse(bidController.text) ?? 0;
    if (bidAmount > 0 && user != null) {
      currentBids.add({
        'user': user.email ?? "anonymous",
        'amount': bidAmount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      auctionRef.update({'bids': currentBids});
      bidController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = auctionData['timeLeft']?.toString() ?? '--';
    final itemName = auctionData['itemName'] ?? '';
    final isActive = auctionData['isActive'] == true;

    return Scaffold(
      appBar: AppBar(title: Text('Auction Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text("Item: $itemName", style: TextStyle(fontSize: 20)),
          Text("Time Left: $timeLeft s"),
          if (isActive)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: bidController,
                    decoration: InputDecoration(labelText: 'Bid \$'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: placeBid,
                ),
              ],
            ),
          if (!isActive)
            Text("Auction Ended", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Divider(),
          Expanded(
            child: ListView(
              children: ((auctionData['bids'] ?? []) as List)
                  .map<Widget>((bid) => ListTile(
                        title: Text("\$${bid['amount']}"),
                        subtitle: Text("${bid['user']}"),
                      ))
                  .toList(),
            ),
          ),
          Divider(),
          Expanded(
            child: AuctionChat(auctionId: auctionId!), // Live chat component
          ),
        ]),
      ),
    );
  }
}

