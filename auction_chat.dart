import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuctionChat extends StatefulWidget {
  final String auctionId;

  AuctionChat({required this.auctionId});

  @override
  _AuctionChatState createState() => _AuctionChatState();
}

class _AuctionChatState extends State<AuctionChat> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.reference();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _db
        .child("chats/auctions/${widget.auctionId}")
        .orderByChild("timestamp")
        .onValue
        .listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value ?? {});
      final msgList = data.entries
          .map((e) => Map<String, dynamic>.from(e.value))
          .toList();
      setState(() {
        messages = msgList;
      });
    });
  }

  void sendMessage() {
    final user = _auth.currentUser;
    if (_controller.text.trim().isEmpty || user == null) return;

    final msg = {
      'text': _controller.text.trim(),
      'sender': user.email ?? "anonymous",
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _db.child("chats/auctions/${widget.auctionId}").push().set(msg);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: messages.map((msg) {
              return ListTile(
                title: Text(msg['text']),
                subtitle: Text("From: ${msg['sender']}"),
              );
            }).toList(),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(labelText: "Type message"),
              ),
            ),
            IconButton(onPressed: sendMessage, icon: Icon(Icons.send)),
          ],
        )
      ],
    );
  }
}
