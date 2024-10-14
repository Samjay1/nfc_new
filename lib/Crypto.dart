import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';

import 'package:nfc_manager/platform_tags.dart';

class Crypto extends StatefulWidget {
  @override
  _CryptoState createState() => _CryptoState();
}

class _CryptoState extends State<Crypto> {
  String cardDetails = '';

  @override
  void initState() {
    super.initState();
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var isoDep = IsoDep.from(tag);
      if (isoDep != null) {
        // Step 1: Select Payment Application
        Uint8List selectCommand = Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10, 0x00]);
        var selectResponse = await isoDep.transceive(data: selectCommand);
        debugPrint('Select Response: ${_parseResponse(selectResponse)}');
        debugPrint('Select Response 1: $selectResponse');

        // Step 2: Send GPO Command
        Uint8List gpoCommand2 = Uint8List.fromList([
          0x80, // CLA
          0xA8, // INS
          0x00, // P1
          0x00, // P2
          0x00  // Lc = 0, indicating no data
        ]);
        Uint8List gpoCommand = Uint8List.fromList([
          0x00, 0xB2, 0x02, 0x14, 0x02, // CLA, INS, P1, P2, Lc
          0x83, 0x00,                    // GPO command template
          0x00
        ]);
        Uint8List gpoCommand1 = Uint8List.fromList([0x80, 0xA8, 0x00, 0x00, 0x02, 0x83, 0x00, 0x00]);
        var gpoResponse = await isoDep.transceive(data: gpoCommand);
        debugPrint('GPO Response 1: ${gpoResponse}');
        debugPrint('GPO Response: ${_parseResponse(gpoResponse)}');


        // Step 3: Read Records
        //
        // for (int i = 1; i <= 10; i++) {
        //   Uint8List readRecordCommand = Uint8List.fromList([0x00, 0xB2, int.parse('0x$i'), 0x14, 0x00]);
        //   var readRecordResponse = await isoDep.transceive(data: readRecordCommand);
        //   debugPrint("Record $i Response: $readRecordResponse");
        //   debugPrint('0x00, 0xB2,0x$i 0x14, 0x00');
        //   // var parsedData = _parseTLV(readRecordResponse);
        //   // debugPrint('Parsed Data $i: $parsedData');
        // }

        Uint8List readRecordCommand = Uint8List.fromList([0x00, 0xB2,0x02 ,0x14, 0x00]); // Example record command
        var recordResponse = await isoDep.transceive(data: readRecordCommand);
        // var parsedData = _parseTLV(recordResponse);
        debugPrint('Parsed Data1: $recordResponse');
        // debugPrint('Parsed Data: $parsedData');
        var cardData = _parseCardData(recordResponse);
        debugPrint('$cardData');


        setState(() {
          // cardDetails = parsedData.toString();
        });
      }
    });
  }

  String _parseResponse(Uint8List response) {
    return response.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }


  Map<String, String> _parseCardData(Uint8List response) {
    Map<String, String> cardDetails = {};

    // First-level TLV parsing
    Map<String, String> parsedTLV = _parseTLV(response);

    // Look for tag '70' in the parsed response, which may contain relevant data
    if (parsedTLV.containsKey('70')) {
      // Extract and parse the content inside tag 70
      Uint8List innerResponse = _hexStringToUint8List(parsedTLV['70']!);
      print('innerResponse $innerResponse');
      Map<String, String> innerTLV = _parseTLV1(innerResponse);

      // Now extract specific tags from this inner TLV structure
      cardDetails['Issuer Authentication Data'] = innerTLV['8F'] ?? 'Not Available';
      cardDetails['Issuer Public Key Exponent'] = innerTLV['9F32'] ?? 'Not Available';
      cardDetails['Issuer Public Key Remainder'] = innerTLV['92'] ?? 'Not Available';
    }

    // Include the Status Word
    cardDetails['Status Word'] = parsedTLV['Status Word'] ?? 'Unknown';

    return cardDetails;
  }

// Helper function to convert hex string back to Uint8List
  Uint8List _hexStringToUint8List(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  Map<String, String> _parseTLV1(Uint8List response) {
    Map<String, String> parsedData = {};
    int index = 0;

    while (index < response.length) {
      // Parse tag (1 or 2 bytes)
      String tag = response[index].toRadixString(16).padLeft(2, '0');
      index += 1;

      // Parse length (handle multi-byte length)
      int length = response[index];
      index += 1;

      if (length > 127) {
        int numberOfLengthBytes = length & 0x7F;
        length = 0;
        for (int i = 0; i < numberOfLengthBytes; i++) {
          length = (length << 8) + response[index];
          index += 1;
        }
      }

      // Ensure index + length doesn't exceed response bounds
      if (index + length > response.length) {
        throw RangeError('Invalid TLV length: Exceeds response bounds');
      }

      // Parse value
      String value = response.sublist(index, index + length).map((byte) {
        return byte.toRadixString(16).padLeft(2, '0');
      }).join();
      parsedData[tag] = value;

      // Move to the next tag
      index += length;
    }

    return parsedData;
  }



  Map<String, String> _parseTLV(Uint8List response) {
    Map<String, String> parsedData = {};
    int index = 0;

    // Status word typically comes at the end, so check for it
    if (response.length >= 2) {
      int sw1 = response[response.length - 2];
      int sw2 = response[response.length - 1];
      parsedData["Status Word"] = sw1.toRadixString(16).padLeft(2, '0') +
          sw2.toRadixString(16).padLeft(2, '0');
    }

    while (index < response.length - 2) {  // Adjust to avoid parsing the status word
      // Parse the tag
      String tag = response[index].toRadixString(16).padLeft(2, '0');
      index++;

      // Some tags are two bytes long, so we check if the next byte is part of the tag
      if ((response[index] & 0x1F) == 0x1F) {
        tag += response[index].toRadixString(16).padLeft(2, '0');
        index++;
      }

      // Parse the length
      int length = response[index];
      index++;

      // If the length is more than 127 (0x80), it uses multiple bytes to encode the length
      if (length > 0x80) {
        int numberOfBytes = length & 0x7F; // Mask to get the number of length bytes
        length = 0;
        for (int i = 0; i < numberOfBytes; i++) {
          length = (length << 8) | response[index];
          index++;
        }
      }

      // Parse the value
      String value = response.sublist(index, index + length).map((byte) {
        return byte.toRadixString(16).padLeft(2, '0');
      }).join();
      parsedData[tag.toUpperCase()] = value;

      // Move index to the next TLV field
      index += length;
    }

    debugPrint('parsedData $parsedData');
    return parsedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NFC Reader')),
      body: Center(
        child: Text('Card Details: $cardDetails'),
      ),
    );
  }
}
