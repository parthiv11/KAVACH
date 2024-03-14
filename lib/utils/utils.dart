import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:steganograph/steganograph.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:android_x_storage/android_x_storage.dart';

import 'constants.dart';

final _androidXStorage = AndroidXStorage();

Future<KeyPair> generateAndSecureStoreKey() async {
  const secureStorage = FlutterSecureStorage();

  // Check if keys already exist
  var privateKey = await secureStorage.read(key: 'private_key');
  var publicKey = await secureStorage.read(key: 'public_key');
  if (privateKey != null && publicKey != null) {
    print('RSA key pair already exists.');
    return KeyPair(publicKey=publicKey, privateKey=privateKey);
  }
  

  // Generate RSA key pair
  var keyPair = await RSA.generate(KEY_LENGTH);

  // Store keys securely

  await secureStorage.write(key: 'private_key', value: keyPair.privateKey);
  await secureStorage.write(key: 'public_key', value: keyPair.publicKey);

  print('RSA key pair generated and stored successfully.');
  return keyPair;
}

Future<KeyPair> retrieveKeys() async {
  const secureStorage = FlutterSecureStorage();
  var privateKey = await secureStorage.read(key: 'private_key');
  var publicKey = await secureStorage.read(key: 'public_key');
  if (privateKey == null || publicKey == null) {
    throw Exception('RSA key pair not found.');
  }
  return KeyPair(publicKey=publicKey, privateKey=privateKey);
}

// TODO: verify hash is independent of exif data
Future<String> hashFile(File file) async { 

  Uint8List fileBytes= await file.readAsBytes();
  String fileString = fileBytes.toString();
  String hash = await RSA.hash(fileString, Hash.SHA256);
  return hash;
}

Future<String> signHash(String imageHash, String privateKey) async {
  String signature = await RSA.signPSS(imageHash, Hash.SHA256, SaltLength.AUTO, privateKey);
  return signature;
}

// function to hide publickey and signature in the image using steganograph package as json
Future<File> storeAndReturnHiddenImage(File image ) async {

  KeyPair keyPair = await retrieveKeys();
  String hash = await hashFile(image);
  String signature = await signHash(hash, keyPair.privateKey);
  final data = {
    'publicKey': keyPair.publicKey,
    'signature': signature,
  };
  final dataString = data.toString();
  final File? imageWithData =  await Steganograph.encode(
    image: image,
    message: dataString,
    encryptionKey: ENCRYPTION_KEY,
    outputFilePath: await _androidXStorage.getDCIMDirectory()
  );
  
  return imageWithData!;
}



Future<bool> verifySignature(String imageHash, String signature,
    String publicKey) async {
  bool isVerified = await RSA.verifyPSS(
      imageHash, signature, Hash.SHA256, SaltLength.AUTO, publicKey);
  return isVerified;
}

// function to extract publickey and signature and verify it from the image using steganograph package and return bool value
Future<bool> extractAndVerify(File image) async {
  // calculate image Hash 
  final String imageHash = await hashFile(image);
  final String? extractedData = await Steganograph.decode(
    image: image,
    encryptionKey: ENCRYPTION_KEY,
  );
  if (extractedData == null) {
    return false;
  }
  final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(extractedData));
  final String publicKey = data['publicKey'];
  final String signature = data['signature'];
  final bool isVerified = await verifySignature(imageHash, signature, publicKey);
  return isVerified;
}
