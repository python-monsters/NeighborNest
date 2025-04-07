import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StorefrontScreen extends StatefulWidget {
  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.reference().child('storefronts');
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _db.child(uid).onValue.listen((event) {
        final data = Map<String, dynamic>.from(event.snapshot.value ?? {});
        final list = data.entries.map((e) {
          final item = Map<String, dynamic>.from(e.value);
          return {'id': e.key, ...item};
        }).toList();
        setState(() => items = list);
      });
    }
  }

  void addItem(String title, double price, bool isAuction, double weight) {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final newItem = {
        'title': title,
        'price': price,
        'isAuction': isAuction,
        'weight': weight,
        'image': '',
      };
      _db.child(uid).push().set(newItem);
    }
  }

  void showAddItemDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final weightController = TextEditingController();
    bool isAuction = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Add Store Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: "Title")),
              TextField(controller: priceController, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              TextField(controller: weightController, decoration: InputDecoration(labelText: "Weight (oz)"), keyboardType: TextInputType.number),
              Row(
                children: [
                  Checkbox(value: isAuction, onChanged: (val) => setState(() => isAuction = val!)),
                  Text("Auction Item?")
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final price = double.tryParse(priceController.text) ?? 0;
                final weight = double.tryParse(weightController.text) ?? 0;
                addItem(title, price, isAuction, weight);
                Navigator.pop(context);
              },
              child: Text("Add"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Storefront")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              title: Text(item['title']),
              subtitle: Text("\$${item['price']}"),
              trailing: item['isAuction']
                  ? Text("Auction")
                  : ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Purchased ${item['title']} (mock)")),
                        );
                      },
                      child: Text("Buy Now"),
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddItemDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
