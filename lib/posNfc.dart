import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_gb_pos_nfc/flutter_gb_pos_nfc.dart';

class PosNfc extends StatefulWidget {
  const PosNfc({Key? key}) : super(key: key);

  @override
  State<PosNfc> createState() => _PosNfcState();
}

class _PosNfcState extends State<PosNfc> {
  String? _cardID;
  TextEditingController testController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> cardRead() async {
    GBPosNfc.readCard().listen((PosNfcData cardInfo) {
      debugPrint('cardInfo $cardInfo');
      setState(() {
        _cardID = cardInfo.id;
        testController.text = cardInfo.id ?? "-";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            MaterialButton(
              child: const Text(
                "Read",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              onPressed: () async {
                cardRead();
              },
              color: Colors.green,
            ),
            Center(
              child: Text('Card ID: $_cardID\n'),
            ),
            TextField(
              controller: testController,
              maxLines: 8,
            ),
          ],
        ),
      ),
    );
  }
}