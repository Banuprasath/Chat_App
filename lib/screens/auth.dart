import 'package:chatapp/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chatapp/firebase_options.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
    //throw UnimplementedError();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _formkey = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedItem;
  var _isAuth = false;
  var _enteredUsername = '';
  void _submit() async {
    final isValid = _formkey.currentState!.validate();
    if (!isValid || !_isLogin && _selectedItem == null) {
      //show error message
      return null;
      //uncheck null if error occurs
    }

    _formkey.currentState!.save();
    // print(_enteredEmail);
    // print(_enteredPassword);
    try {
      setState(() {
        _isAuth = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        print(userCredentials); //Allow user to Login
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedItem!);
        final imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl
        });
        print(imageUrl);
      }
    } on FirebaseAuthException catch (error) {
      var x = error;
      if (error.code == 'email-already-in-use') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message ?? 'Authentication Failed'),
      ));
      setState(() {
        _isAuth = false;
      });
      // TODO
    }
    ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(top: 30, bottom: 20, left: 20, right: 20),
              width: 200,
              child: Image.asset('assets/chat.png'),
            ),
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formkey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLogin)
                        UserImagePicker(onPickImage: (pickedImage) {
                          _selectedItem = pickedImage;
                        }),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'EmailAddress',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please Enter Valid Email Acdress';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredEmail = value!;
                        },
                      ),
                      if (!_isLogin)
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Username'),
                          // enableSuggestions: false,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length < 4) {
                              return 'Please Enter a valid username atleast length of 4';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredUsername = value!;
                          },
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'The password need to be 6 letter long';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredPassword = value!;
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (_isAuth) const CircularProgressIndicator(),
                      if (!_isAuth)
                        ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.background),
                            child: Text(_isLogin ? 'Login' : 'Signup')),
                      if (!_isAuth)
                        TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin
                                ? 'Create an account'
                                : 'I have an account'))
                    ],
                  ),
                ),
              ),
            )
          ],
        )),
      ),
    );
  }
}
