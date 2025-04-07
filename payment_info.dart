import 'package:flutter/material.dart';

class PaymentInfoScreen extends StatelessWidget {
  final cardController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Payment Info')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cardController,
              decoration: InputDecoration(labelText: 'Card number (mock)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Normally store via Stripe; here we just simulate
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(" Payment Info Saved (simulated)")),
                );
                Navigator.pop(context, true);
              },
              child: Text("Save & Continue"),
            )
          ],
        ),
      ),
    );
  }
}

