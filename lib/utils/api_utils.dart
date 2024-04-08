import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils.dart';

import 'dart:io';
import 'package:fast_rsa/fast_rsa.dart';

import 'constants.dart';

Future<void> createUser(String userId, String pubKey) async {
  var url = Uri.parse('${ENDPOINT}/api/post-pubkey');

  var data = {
    'userId': userId,
    'pubKey': pubKey,
  };

  var body = jsonEncode(data);

  var headers = {
    'Content-Type': 'application/json',
  };

  try {
    var response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 308) {

      var responseData = jsonDecode(response.body);
    } else {
      print('Key creation failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error creating key: $e');
  }
}

Future<void> createImage(String hash,String sign, String pubkey) async {
  var url = Uri.parse('${ENDPOINT}/api/post-image');

  var data = {
    'hash': hash,
    'signature': sign,
    'pubKey': pubkey
  };

  var body = jsonEncode(data);

  var headers = {
    'Content-Type': 'application/json',
  };

  try {
    var response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 308) {
      // Success or redirect, handle as needed
      print('Image creation successful');
      var responseData = jsonDecode(response.body);
      print('Response: $responseData');
    } else {
      print('Image creation failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error creating image: $e');
  }
}

Future<bool> doesSignatureExist(String hash) async {
  var url = Uri.parse('${ENDPOINT}/api/get-signature');

  var headers = {
    'Content-Type': 'application/json',
  };

  try {
    var response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'hash': hash}),
    );

    if (response.statusCode == 200 || response.statusCode == 308) {
      // Success or redirect, handle as needed
      var responseData = jsonDecode(response.body);
      return responseData['signature'] != 'null';
    } else {
      print('Failed to retrieve signature with status: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error retrieving signature: $e');
    return false;
  }
}

Future<bool> doesUserIdExist(String userId) async {
  var url = Uri.parse('${ENDPOINT}/api/get-pubkeys'); // Replace with the actual endpoint URL

  var headers = {
    'Content-Type': 'application/json',
  };

  try {
    var response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 308) {
      var responseData = jsonDecode(response.body);
      List<dynamic> pubKeys = responseData['pubKeys'];
      for (var pubKey in pubKeys) {
        if (pubKey['userId'] == userId) {
          return true; // userId found
        }
      }
      return false; // userId not found
    } else {
      print('Failed to retrieve pubKeys with status: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error retrieving pubKeys: $e');
    return false;
  }
}

Future<bool> verifyImage(File file) async {
  String hash = await hashFile(file);
  return await doesSignatureExist(hash);
}

Future<void> storeAndSaveHiddenImage(File file) async {
  KeyPair keyPair = await retrieveKeys();
  String hash = await hashFile(file);
  String signature = await signHash(hash, keyPair.privateKey);
  final Map<String, String> data = {
    'publicKey': keyPair.publicKey,
    'signature': signature,
    'hash': hash
  };
  final dataJson = jsonEncode(data);
  Directory dir = await getFolder();
  String path = '${dir.path}/${generateUniqueFileName()}.png';
  print(path);
  List<int> fileBytes = await file.readAsBytes();

  File outputFile = File(path);
  await outputFile.writeAsBytes(fileBytes);
  createImage(hash, signature, keyPair.publicKey);
}
