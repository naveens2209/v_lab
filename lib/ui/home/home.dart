import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v_lab/ui/chat/chat.dart';
import 'package:v_lab/ui/chat/chat_list.dart';
import 'package:v_lab/ui/login/login.dart';
import 'package:v_lab/ui/student/student_dashboard.dart';
import 'package:v_lab/ui/teacher/teacher_dashboard.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  FirebaseFirestore _firestore;

  String _userPhone, _role, _userName, _userRollNo;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _checkLogin();

    Firebase.initializeApp().then((value) {
      _firestore = FirebaseFirestore.instance;
      _getUserRole();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('V-LAB'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.message_rounded,
            ),
            onPressed: _gotoChat,
          ),
          IconButton(icon: Icon(Icons.exit_to_app_rounded), onPressed: _logout)
        ],
      ),
      body: SafeArea(
        child: Container(
          child: _role == null
              ? SizedBox()
              : _role == 'teacher'
                  ? _buildForTeacher()
                  : _buildForStudent(),
        ),
      ),
    );
  }

  Widget _buildForTeacher() {
    return TeacherDashboard(_userPhone);
  }

  Widget _buildForStudent() {
    return StudentDashboard(_userPhone);
  }

  void _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userPhone = prefs.getString('userPhone');
    _userName = prefs.getString('userName');
    _userRollNo = prefs.getString('userRollNo');

    if (_userName != null) {
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
      _gotoLogin();
    }
  }

  void _getUserRole() async {
    Future<DocumentSnapshot> userSnapshot =
        _firestore.collection('users').doc(_userPhone).get();

    userSnapshot.then((snapshot) {
      if (snapshot.data() == null) {
        debugPrint('User not found');
        _gotoLogin();
      } else {
        setState(() {
          _role = snapshot.data()['role'] ?? 'student';
          debugPrint(_role);
        });
      }
    });
  }

  void _gotoLogin() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Login()));
  }

  void _logout() {
    AlertDialog alert = AlertDialog(
      title: Text('Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red),
          ),
          onPressed: () {
            SharedPreferences.getInstance().then((prefs) => prefs.clear());
            _gotoLogin();
          },
          child: Text(
            'LOGOUT',
          ),
        ),
      ],
    );

    showDialog(
        context: context,
        builder: (_) {
          return alert;
        });
  }

  void _gotoChat() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatList(_userPhone, _role)));
  }
}
