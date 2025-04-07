import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = FirebaseDatabase.instance.reference().child('auctions');
  List<Map<String, dynamic>> activeAuctions = [];

  @override
  void initState() {
    super.initState();
    db.onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value ?? {});
      final auctionList = data.entries
          .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
          .where((a) => a['isActive'] == true)
          .toList();
      setState(() {
        activeAuctions = auctionList;
      });
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NeighborNest Auctions'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
          IconButton(
            icon: Icon(Icons.store),
            onPressed: () => Navigator.pushNamed(context, '/storefront'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: activeAuctions.length,
        itemBuilder: (context, index) {
          final auction = activeAuctions[index];
          return Card(
            child: ListTile(
              title: Text(auction['itemName']),
              subtitle: Text("Time Left: ${auction['timeLeft']}s"),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/auction-viewer',
                      arguments: auction['id']);
                },
                child: Text("Join"),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/auction-host'),
        label: Text("Host Auction"),
        icon: Icon(Icons.gavel),
      ),
    );
  }
}

