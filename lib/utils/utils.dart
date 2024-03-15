import 'dart:convert';
import 'package:image/image.dart' as img;

import 'dart:io';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:steganograph/steganograph.dart';
import 'dart:typed_data';
import 'package:android_x_storage/android_x_storage.dart';

import 'constants.dart';

final _androidXStorage = AndroidXStorage();
const secureStorage = FlutterSecureStorage();


storeUser(String user) async{
  await secureStorage.write(key: 'userId', value: user);

}
Future<KeyPair> generateAndSecureStoreKey(  ) async {


  // Check if keys already exist
  var privateKey = await secureStorage.read(key: 'private_key');
  var publicKey = await secureStorage.read(key: 'public_key');
  if (privateKey != null && publicKey != null) {
    return KeyPair(publicKey=publicKey, privateKey=privateKey);
  }
  

  // Generate RSA key pair
  var keyPair = await RSA.generate(KEY_LENGTH);


  // Store keys securely

  await secureStorage.write(key: 'private_key', value: keyPair.privateKey);
  await secureStorage.write(key: 'public_key', value: keyPair.publicKey);

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
  List<int> fileBytes = await file.readAsBytes();

  img.Image? image = img.decodeImage(fileBytes);

  if (image != null) {
    // Convert the image to bytes
    String fileString = Uint8List.fromList(img.encodePng(image)).toString();
    String hash = await RSA.hash(fileString, Hash.SHA256);
  // String hash= calculateDHashFromFile(file).toString();
  return hash;
}
  return '';}

Future<String> signHash(String imageHash, String privateKey) async {
  String signature = await RSA.signPSS(imageHash, Hash.SHA256, SaltLength.AUTO, privateKey);
  return signature;
}

// function to hide publickey and signature in the image using steganograph package as json
Future<File> storeAndReturnHiddenImage(File image ) async {

  KeyPair keyPair = await retrieveKeys();
  String? hash = await hashFile(image);
  String signature = await signHash(hash, keyPair.privateKey);
  final Map<String, String> data = {
    'publicKey': keyPair.publicKey,
    'signature': signature,
    'hash': hash
  };
  final dataJson = jsonEncode(data);
  Directory dir = await getFolder();
  String path = '${dir.path}/${generateUniqueFileName()}.png';
  final File? imageWithData =  await Steganograph.encode(
    image: image,
    message: dataJson,
    encryptionKey: ENCRYPTION_KEY,
    outputFilePath: path
    );
  
  return imageWithData!;
}

Future<bool> verifySignature(String imageHash, String signature,
    String publicKey) async {
  try {
    bool isVerified = await RSA.verifyPSS(
        imageHash, signature, Hash.SHA256, SaltLength.AUTO, publicKey);
    return isVerified;
  }
  on RSAException catch (e){

    print(e.cause);

  }
  return false;

}

// function to extract publickey and signature and verify it from the image using steganograph package and return bool value
Future<bool> extractAndVerify(File image) async {
  // calculate image Hash

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
  final String hash = data['hash'];
  KeyPair k = await retrieveKeys();
  String s=await RSA.signPSS(hash,Hash.SHA256, SaltLength.AUTO, k.privateKey);
  final bool isVerified = await verifySignature(hash, signature, publicKey);
  return isVerified;
}

getFolder() async{
  const folderName="KAVACH";
  String? dcimFolder = await _androidXStorage.getDCIMDirectory();
  final path= Directory("$dcimFolder/$folderName");
  if ((await path.exists())){
    return path;
  }
  path.create();
  return path;
  }

String generateUniqueFileName() {
  String randomString = Random().nextInt(1000000).toString();
  DateTime now = DateTime.now();
  String timestamp = "${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}";
  String uniqueFileName = "file_$timestamp-$randomString";
  return uniqueFileName;
}

Uint64List calculateDHashFromFile(File imageFile) {
  // Load the image from the file
  img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;

  // Resize the image to a fixed size (e.g., 9x8) for consistency
  img.Image resizedImage = img.copyResize(image, width: 9, height: 8);

  // Convert the image to grayscale
  img.grayscale(resizedImage);

  // Calculate the differences between adjacent pixels
  Uint64List hash = Uint64List(64);
  int index = 0;
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      int leftPixel = resizedImage.getPixel(x, y);
      int rightPixel = resizedImage.getPixel(x + 1, y);
      hash[index] = (leftPixel < rightPixel) ? 1 : 0;
      index++;
    }
  }

  return hash;
}
