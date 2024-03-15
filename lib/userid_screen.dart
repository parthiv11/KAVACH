import 'package:flutter/material.dart';
import 'package:kavach/camera_screen.dart';
import 'utils/utils.dart';
import 'utils/api_utils.dart';
import 'package:camera/camera.dart';
import 'package:fast_rsa/fast_rsa.dart';

class UserHomepage extends StatefulWidget {
  const UserHomepage({Key? key}) : super(key: key);

  @override
  _UserHomepageState createState() => _UserHomepageState();
}

class _UserHomepageState extends State<UserHomepage> {
  bool navigate = false;
  bool notFirstTime = false;
  bool showSuccessMessage = false;
  bool navigateToNextPage = false;
  String navigateMessage = "Keys successfully generated.";
  String username = "";

  @override
  void initState() {
    super.initState();
    print("not first time");
    print(notFirstTime);
    if (notFirstTime) {
      navigateToNextPage = true;
    }
    print("init");
    print(navigateToNextPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KAVACH')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset(
            //   'assets/KAVACH.jpg',
            //   width: 400,
            //   height: 250,
            //   fit: BoxFit.fitWidth,
            // ),
            TextField(
              onChanged: (value) {
                setState(() {
                  username = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter username',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: username.isEmpty ? null : () async {
                bool truth = await doesUserIdExist(username);
                if (!truth) {
                  storeUser(username);
                  generateAndSecureStoreKey();
                  KeyPair k = await retrieveKeys();
                  createUser(username, k.publicKey);
                  final cameras = await availableCameras();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CameraScreen(cameras: cameras),
                    ),
                  );
                }
              },
              child: Text("Generate Key "),
            ),
          ],
        ),
      ),
    );
  }
}
