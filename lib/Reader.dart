import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

class Reader extends StatefulWidget {
  const Reader({super.key});

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Reader'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startNFCReading,
          child: const Text('Start NFC Reading'),
        ),
      ),
    );
  }

  void _startNFCReading() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();

      //We first check if NFC is available on the device.
      if (isAvailable) {
        NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
          print(tag.data['isodep']);
          print(tag.data['nfcb']);

          IsoDep? isoDep = IsoDep.from(tag);
          print(isoDep?.historicalBytes);
        });

        //If NFC is available, start an NFC session and listen for NFC tags to be discovered.
        // NfcManager.instance.startSession(
        //   onDiscovered: (NfcTag tag) async {
        //     // Process NFC tag, When an NFC tag is discovered, print its data to the console.
        //     debugPrint('NFC Tag Detected: ${tag.data}');
        //     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('NFC Tag Detected: ${tag.data}')));
        //   },
        // );
      } else {
        debugPrint('NFC not available.');
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC not available.')));
      }
    } catch (e) {
      debugPrint('Error reading NFC: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading NFC: $e')));
    }
  }
}
