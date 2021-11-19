import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v_lab/ui/home/home.dart';

class UserDetails extends StatefulWidget {
  final String phone;

  UserDetails([this.phone]);

  @override
  _UserDetailsState createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  FirebaseFirestore _firestore;
  final _formKey = GlobalKey<FormState>();
  var _nameController = TextEditingController();
  var _rollController = TextEditingController();

  Map<String, String> _userData;
  String _name, _rollNo, _role = 'student';

  @override
  void initState() {
    super.initState();

    Firebase.initializeApp().then((value) {
      _firestore = FirebaseFirestore.instance;
      _getUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top,
          padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'V - LAB',
                style: TextStyle(
                    fontSize: 40,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Details',
                            style: TextStyle(
                                fontSize: 26,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 50),
                          const Text('Name'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _nameController,
                            maxLines: 1,
                            keyboardType: TextInputType.name,
                            decoration: const InputDecoration(
                              hintText: 'Full Name',
                              fillColor: Colors.white,
                              filled: true,
                              labelStyle: const TextStyle(color: Colors.black),
                              border: const OutlineInputBorder(
                                borderRadius: const BorderRadius.all(
                                  const Radius.circular(10.0),
                                ),
                                borderSide:
                                    const BorderSide(color: Colors.black),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: const BorderRadius.all(
                                  const Radius.circular(10.0),
                                ),
                                borderSide:
                                    const BorderSide(color: Colors.black),
                              ),
                              prefixIcon: const Icon(
                                Icons.account_box_outlined,
                                color: Colors.black,
                              ),
                            ),
                            onChanged: (val) {
                              _name = val;
                            },
                            validator: (val) {
                              if (val.length < 1) return 'Name cannot be empty';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_role != 'teacher') Text('Roll Number'),
                          const SizedBox(height: 5),
                          if (_role != 'teacher')
                            TextFormField(
                              controller: _rollController,
                              maxLines: 1,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Roll Number',
                                fillColor: Colors.white,
                                filled: true,
                                labelStyle:
                                    const TextStyle(color: Colors.black),
                                border: const OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    const Radius.circular(10.0),
                                  ),
                                  borderSide:
                                      const BorderSide(color: Colors.black),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    const Radius.circular(10.0),
                                  ),
                                  borderSide:
                                      const BorderSide(color: Colors.black),
                                ),
                                prefixIcon: const Icon(
                                  Icons.account_box_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              onChanged: (val) {
                                _rollNo = val;
                              },
                              validator: (val) {
                                if (val.length < 1)
                                  return 'Roll Number cannot be empty';
                                return null;
                              },
                            ),
                          SizedBox(height: 30),
                          Center(
                            child: ElevatedButton(
                              onPressed: _saveUserData,
                              child: Text(
                                'Continue',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _getUserData() {
    Future<DocumentSnapshot> userSnapshot =
        _firestore.collection('users').doc(widget.phone).get();

    userSnapshot.then((snapshot) {
      if (snapshot.data() == null)
        debugPrint('User not found');
      else {
        setState(() {
          _name = snapshot.data()['name'];
          _rollNo = snapshot.data()['rollNo'];
          _role = snapshot.data()['role'] ?? 'student';

          debugPrint(_role);

          _nameController.text = _name;
          _rollController.text = _rollNo;
        });
      }
    });
  }

  void _saveUserData() async {
    if (_formKey.currentState.validate()) {
      _userData = {'name': _name, 'rollNo': _rollNo, 'role': _role};

      _firestore
          .collection('users')
          .doc(widget.phone)
          .set(_userData, SetOptions(merge: true))
          .then((value) {
        debugPrint('User details updated');
        _saveUser();
      });
    }
  }

  void _saveUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userName', _name);
    prefs.setString('userRollNo', _rollNo ?? '');
    prefs.setString('userRole', _role);

    _gotoHome();
  }

  void _gotoHome() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Home()));
  }
}
