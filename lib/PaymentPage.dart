import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';

import 'package:nfc_manager/platform_tags.dart';


class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _message = 'Scan your Visa card to read details';

  @override
  void initState() {
    super.initState();
    _startNfc();
  }

  void _startNfc() async {
    final nfc = NfcManager.instance;
    nfc.startSession(
      onDiscovered: (NfcTag tag) async {
        setState(() {
          _message = 'NFC Tag Detected!';
        });

        final data = tag.data;
        debugPrint('NFC Tag Data: $data');

        // Extract ISO-DEP
        final isoDep = IsoDep.from(tag);
        if (isoDep != null) {
          // Perform GPO (Get Processing Options)
          final gpoCommand = Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10]);
          final selectCommand = Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x02, 0x3F, 0x00]); // Example command

          final gpoResponse = await isoDep.transceive(data: gpoCommand);
          debugPrint('GPO Response: $gpoResponse');

          // Perform Read Record
          final readRecordCommand = Uint8List.fromList([0x00, 0xB2, 0x02, 0x14, 0x00]);
          final readRecordResponse = await isoDep.transceive(data: readRecordCommand);
          debugPrint('Read Record Response: $readRecordResponse');

          // Parse the responses
          final cardDetails = _parseCardData(gpoResponse, readRecordResponse);
          setState(() {
            debugPrint('Card Details: $cardDetails');
            _message = 'Card Details: $cardDetails';
          });
        }
      },
      onError: (NfcError error) {
        setState(() {
          _message = 'Error: ${error.message}';
        });
        throw error;
      },
    );
  }

  Map<String, dynamic> _parseCardData(Uint8List gpoResponse, Uint8List readRecordResponse) {
    final result = <String, dynamic>{};

    result['GPO Response'] = _bytesToHex(gpoResponse);
    result['Read Record Response'] = _bytesToHex(readRecordResponse);

    try {
      final recordData = _parseTLV(readRecordResponse);

      result['Issuer Authentication Data'] = recordData['8F'] ?? 'Not Available';
      result['Issuer Public Key Exponent'] = recordData['9F32'] ?? 'Not Available';
      result['Issuer Public Key Remainder'] = recordData['92'] ?? 'Not Available';

      // You can add additional parsing logic here based on the card data format

    } catch (e) {
      result['Error'] = 'Parsing error: ${e.toString()}';
    }

    return result;
  }

  Map<String, String> _parseTLV(Uint8List data) {
    final result = <String, String>{};
    int index = 0;

    while (index < data.length) {
      final tag = data[index];
      final length = data[index + 1];
      final value = data.sublist(index + 2, index + 2 + length);

      result[_bytesToHex(Uint8List.fromList([tag]))] = _bytesToHex(value);
      index += 2 + length;
    }

    // Debug output to show the parsed data
    print('Parsed TLV Data: $result');

    return result;
  }

  String _bytesToHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString().toUpperCase(); // Convert to uppercase for readability
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NFC Payment Page'),
      ),
      body: Center(
        child: Text(_message),
      ),
    );
  }
}
