import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

class Reader extends StatefulWidget {
  const Reader({super.key});

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  String _readFromNfcTag = "";
  String _nfcData="";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Reader'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: startNfcSession,
          child: const Text('Start NFC Reading'),
        ),
      ),
    );
  }


  void _startNfcSession() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        debugPrint('STARTING');
        print('NFC TAG ${tag.data}');
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('NFC Data::  \t ${tag.data}')));
        final isoDep = IsoDep.from(tag);
        final nfcA = NfcA.from(tag);
        if (nfcA != null && false) {
          debugPrint('NfcA Tag Detected: ${nfcA.identifier}');
          debugPrint('ATQA: ${nfcA.atqa}');
          debugPrint('SAK: ${nfcA.sak}');
          debugPrint('Max Transceive Length: ${nfcA.maxTransceiveLength}');
          debugPrint('Timeout: ${nfcA.timeout}');

          // Example: Sending a simple command using NfcA
          Uint8List command = Uint8List.fromList([0x30, 0x00]); // Exa
          Uint8List nfcACommand = Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10]);  // Read command for a block of data
          // Uint8List respn = await nfcA.transceive(data: command);
          // print('respn $respn');

          // nfcA.transceive(data: command).then((response) {
          //   debugPrint('NfcA Response: $response');
          //
          //   // Uint8List gpoCommand = Uint8List.fromList([0x80, 0xA8, 0x00, 0x00, 0x02, 0x83, 0x00, 0x00]);
          //   // nfcA.transceive(data: gpoCommand).then((response) {
          //   //       debugPrint('GPO Response: $response');
          //   //
          //   //       // Process the GPO response to extract card data (e.g., PAN, expiration date, cryptogram)
          //   //     }).catchError((e){
          //   //       debugPrint('error Response:$e');
          //   //     });
          //     }).catchError((e) {
          //       print('HELLO');
          //       debugPrint('Error communicating with card: $e');
          //     });
        }

        // Check if the tag is of type NfcF
        else if (isoDep != null) {
          debugPrint('IsoDep Tag Detected: ${isoDep.identifier}');
          debugPrint('Historical Bytes: ${isoDep.historicalBytes}');
          debugPrint('Supports Extended Length APDU: ${isoDep.isExtendedLengthApduSupported}');
          debugPrint('Max Transceive Length: ${isoDep.maxTransceiveLength}');
          debugPrint('Timeout: ${isoDep.timeout}');


          // Select the Visa application on the card
          Uint8List selectAidCommand = Uint8List.fromList([
            0x00, 0xA4, 0x04, 0x00, // SELECT command
            0x07,                   // Length of AID
            0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10 // AID for Visa
          ]);

          // Example: Sending an APDU command using IsoDep
          Uint8List apduCommand = Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10]);
          isoDep.transceive(data: apduCommand).then((response) async {
            debugPrint('~1 APDU Response for AID selection: $response');

            //
            // try {
            //   // Sending a command after selecting the application
            //   Uint8List readCommand = Uint8List.fromList([0x00, 0xB0, 0x00, 0x00, 0x10]); // Example: Read Binary command
            //   Uint8List readResponse = await isoDep.transceive(data: readCommand);
            //
            //   // Typically, the response will contain data followed by a status word
            //   if (readResponse.length > 2) {
            //     Uint8List data = readResponse.sublist(0, readResponse.length - 2);
            //     Uint8List statusWord = readResponse.sublist(readResponse.length - 2);
            //
            //     if (statusWord[0] == 0x90 && statusWord[1] == 0x00) {
            //       // Success, handle the data
            //       debugPrint('Data: $data');
            //     } else {
            //       // Handle different status words
            //       debugPrint('Unexpected status word: $statusWord');
            //     }
            //   }
            // } catch (e) {
            //   debugPrint('Error during IsoDep communication: $e');
            // }

            // Assuming the AID was selected successfully, proceed to read card data
            Uint8List gpoCommand = Uint8List.fromList([0x00, 0xB0, 0x00, 0x00, 0x10]);
            isoDep.transceive(data: gpoCommand).then((response) {
              debugPrint('GPO Response: $response');

              // Process the GPO response to extract card data (e.g., PAN, expiration date, cryptogram)
            }).catchError((e){
              debugPrint('~error Response:$e');
            });
          }).catchError((e) {
            print('HELLO');
            debugPrint('Error communicating with card: $e');
          });
        }
       else {
          debugPrint('Unknown NFC tag type.');
        }
      } on PlatformException catch (e) {
        debugPrint('Error handling NFC tag: $e');
        if (e.code == 'io_exception') {
          debugPrint('qq1');
          setState(() {
            _nfcData = 'NFC Tag was lost. Please try again.';
          });
          _startNfcSession(); // Retry starting the session
        } else {
          debugPrint('qq2');
          setState(() {
            _nfcData = 'Error: ${e.message}';
          });
        }
      }
    });
  }

  void startNfcSession() {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          var isoDep = IsoDep.from(tag);

          print('INITIAL:: ${tag.data}');
          if (isoDep != null) {
            // Select command example
            Uint8List selectCommand = Uint8List.fromList([
              0x00, 0xA4, 0x04, 0x00, 0x07,
              0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10
            ]);

            Uint8List response = await isoDep.transceive(data: selectCommand);
            print('selectCommand response:: $response');

            if (response[response.length - 2] == 0x90 &&
                response[response.length - 1] == 0x00) {

                print( 'Card selected successfully');

            //     --------------------------------
                Uint8List gpoCommand = Uint8List.fromList([
                  0x00, 0xB2, 0x02, 0x14, 0x02, // CLA, INS, P1, P2, Lc
                  0x83, 0x00,                    // GPO command template
                  0x00
                ]);
                Uint8List readRecordCommand = Uint8List.fromList([
                  0x00, 0xB2, 0x02, 0x14, 0x00  // CLA, INS, P1, P2, Le (read record)
                ]);

                try {
                  Uint8List response = await isoDep.transceive(data: gpoCommand);
                  print("get processing options:: $response");
                  if (response[response.length - 2] == 0x90 && response[response.length - 1] == 0x00) {
                    print("GPO Response: ${response.sublist(0, response.length - 2)}");
                    parsingData(response);
                  } else {
                    print("Failed to get processing options");
                  }
                } catch (e) {
                  print("Error during GPO transceive: $e");
                }

            //   ----------------------------------

            } else {

              print( 'Failed to select card');

            }
          } else {

              print( 'IsoDep not found');

          }
        } catch (e) {
            print( 'Error: $e');

        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );
  }


  // Helper function to parse TLV data
  void parseTLV(Uint8List data) {
    int index = 0;

    print('--------------------------------------------------');
    while (index < data.length) {
      // Read the tag (1 or 2 bytes)
      int tag = data[index];
      index++;

      if (tag == 0x9F || tag == 0x5F) {
        // 2-byte tag
        tag = (tag << 8) + data[index];
        index++;
      }

      // Read the length
      int length = data[index];
      index++;

      // Read the value
      Uint8List value = data.sublist(index, index + length);
      index += length;

      // Print out the tag and value in hex
      print('Tag: ${tag.toRadixString(16)}, Value: ${value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}');

      // Further processing based on the tag
      if (tag == 0x8F) {
        // Issuer Authentication Data
        print('Issuer Authentication Data: ${value}');
      } else if (tag == 0x9F32) {
        // Issuer Public Key Exponent
        print('Issuer Public Key Exponent: ${value}');
      } else if (tag == 0x92) {
        // Issuer Public Key Remainder
        print('Issuer Public Key Remainder: ${value}');
      }
      // Continue processing other tags as needed
    }
    print('--------------------------------------------------');
  }

// The value under tag 0x70
  Uint8List value = Uint8List.fromList([
    0x8f, 0x01, 0x09, 0x9f, 0x32, 0x01, 0x03,
    0x92, 0x23, 0xdb, 0x1c, 0xe8, 0xf3, 0x78,
    0xcd, 0xec, 0xa8, 0x5a, 0x3e, 0xce, 0xc1,
    0x3c, 0x4c, 0xfd, 0x7f, 0xd5, 0x58, 0x33,
    0x92, 0xdc, 0x31, 0x5b, 0x9f, 0xfe, 0xdc,
    0x65, 0xf3, 0x2a, 0x89, 0x74, 0xad, 0x82,
    0x2e, 0x99
  ]);

// Parse the value from tag 0x70


  void parsingData(data){
    // Assume `response` contains the APDU response as a Uint8List
    Uint8List response = Uint8List.fromList(data);

// Helper function to convert Uint8List to hex string
    String bytesToHex(Uint8List bytes) {
      return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    }

// Parse the response (TLV format)
    int index = 0;
    while (index < response.length) {
      // Read the tag (1 or 2 bytes)
      int tag = response[index];
      index++;

      // Some tags might have 2 bytes (handle if needed)
      if (tag == 0x9F || tag == 0x5F) {
        tag = (tag << 8) + response[index];
        index++;
      }

      // Read the length of the data field
      int length = response[index];
      index++;

      // Read the value (data) based on the length
      Uint8List value = response.sublist(index, index + length);
      index += length;

      // Print the tag and value in hex
      print('Tag: ${tag.toRadixString(16)}, Value: ${bytesToHex(value)}');

      // Process specific tags (example: PAN, expiration date, etc.)
      if (tag == 0x5A) {
        // Primary Account Number (PAN)
        String pan = bytesToHex(value);
        print('PAN: $pan');
      } else if (tag == 0x5F24) {
        // Expiration Date (YYMM)
        String expirationDate = bytesToHex(value);
        print('Expiration Date: $expirationDate');
      } else if (tag == 0x57) {
        // Track 2 Equivalent Data (can include PAN and expiration date)
        String track2Data = bytesToHex(value);
        print('Track 2 Equivalent Data: $track2Data');
      }
    }
    parseTLV(value);
  }

  void handleNfcB(NfcB nfcB) async {
    try {
      // Example: Process NfcB tag (implement as needed)
      debugPrint('NfcB tag detected: ${nfcB.identifier}');
    } catch (e) {
      debugPrint('Error reading NfcB tag: $e');
    }
  }

  void handleNfcF(NfcF nfcF) async {
    try {
      // Example: Process NfcF tag (implement as needed)
      debugPrint('NfcF tag detected: ${nfcF.manufacturer}');
    } catch (e) {
      debugPrint('Error reading NfcF tag: $e');
    }
  }

  void handleNfcV(NfcV nfcV) async {
    try {
      // Example: Send a command using NfcV
      Uint8List command = Uint8List.fromList([0x20, 0x01]); // Example command
      Uint8List response = await nfcV.transceive(data: command);
      debugPrint('NfcV response: $response');
    } catch (e) {
      debugPrint('Error reading NfcV tag: $e');
    }
  }
  void _startNFCReading() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();

      //We first check if NFC is available on the device.
      if (isAvailable) {
        // _readNfcTag();
        _startNfcSession();
        // If NFC is available, start an NFC session and listen for NFC tags to be discovered.
        // NfcManager.instance.startSession(
        //   onDiscovered: (NfcTag tag) async {
        //     Ndef? ndef = Ndef.from(tag);
        //     print('ndef $ndef');
        //     IsoDep? isoDep = IsoDep.from(tag);
        //     print(isoDep?.historicalBytes);
        //    },
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



  void _readNfcTag() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag badge) async {
      var ndef = Ndef.from(badge);

      print('BARGE DATA::${badge.data}');
      if (ndef != null && ndef.cachedMessage != null) {
        String tempRecord = "";
        for (var record in ndef.cachedMessage!.records) {
          tempRecord =
          "$tempRecord ${String.fromCharCodes(record.payload.sublist(record.payload[0] + 1))}";
        }

        print('tempRecord $tempRecord');

        setState(() {
          _readFromNfcTag = tempRecord;
        });
      } else {
        print('NO NDEF');
        // Show a snackbar for example
      }

      NfcManager.instance.stopSession();
    });
  }
}


