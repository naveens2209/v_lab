import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v_lab/ui/user_details/user_details.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _otpForm = GlobalKey<FormState>();
  final _phoneForm = GlobalKey<FormState>();

  FirebaseAuth _auth;

  bool _codeSent = false,
      _isLoading = false,
      hasError = false,
      _authSuccess = false;
  String status, _verificationID, _resendToken, _statusText, _phone, _otp;

  @override
  void initState() {
    super.initState();

    Firebase.initializeApp().then((value) {
      _auth = FirebaseAuth.instance;
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
                    height: MediaQuery.of(context).size.height / 1.8,
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 28,
                              color: Colors.black,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              !_codeSent ? _showPhoneField() : _showOtpField(),
                              const SizedBox(height: 50),
                              ElevatedButton(
                                onPressed: _sendOrVerifyOtp,
                                child: _isLoading
                                    ? Container(
                                        width: 25,
                                        height: 25,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              new AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ))
                                    : Text(
                                        !_codeSent ? 'Send OTP' : 'Verify OTP',
                                        style: TextStyle(fontSize: 18),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _showPhoneField() {
    return Form(
      key: _phoneForm,
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          hintText: 'Enter 10 digit mobile number',
          fillColor: Colors.white,
          filled: true,
          labelStyle: const TextStyle(color: Colors.black),
          border: const OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              const Radius.circular(10.0),
            ),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              const Radius.circular(10.0),
            ),
            borderSide: const BorderSide(color: Colors.black),
          ),
          prefixIcon: const Icon(
            Icons.phone_iphone_rounded,
            color: Colors.black,
          ),
        ),
        onChanged: (val) {
          _phone = val;
        },
        validator: (val) {
          if (val.length != 10) return 'Enter valid mobile number';
          return null;
        },
      ),
    );
  }

  _showOtpField() {
    return Form(
      key: _otpForm,
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          hintText: 'Enter 6 digit OTP',
          fillColor: Colors.white,
          filled: true,
          labelStyle: const TextStyle(color: Colors.black),
          focusedBorder: const OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              const Radius.circular(10.0),
            ),
            borderSide: const BorderSide(color: Colors.black),
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Colors.black,
          ),
        ),
        onChanged: (val) {
          _otp = val;
        },
        validator: (val) {
          if (val.length < 6) return 'Enter valid OTP';
          return null;
        },
      ),
    );
  }

  void _sendOrVerifyOtp() {
    // !_codeSent ?  _sendOTP(_phone) : _signInWithOTP(_otp);

    if (!_codeSent) {
      if (_phoneForm.currentState.validate()) _sendOTP(_phone);
    } else {
      if (_otpForm.currentState.validate()) _signInWithOTP(_otp);
    }
  }

  Future _sendOTP(String mobile) async {
    setState(() {
      _isLoading = true;
    });
    _auth.verifyPhoneNumber(
      phoneNumber: '+91' + mobile,
      timeout: Duration(seconds: 60),
      verificationCompleted: (AuthCredential authCredential) {
        debugPrint('VerificationComplete');
        _auth
            .signInWithCredential(authCredential)
            .then((UserCredential result) {
          _onAuthenticationSuccessful();
        }).catchError((e) {
          print(e);
        });
      },
      verificationFailed: (FirebaseAuthException authException) {
        print(authException.message);
        setState(() {
          status = authException.message;
        });

        _onAuthenticationFailed();
      },
      codeSent: (String verificationId, int forceResendingToken) async {
        // _resendToken = forceResendingToken;
        _verificationID = verificationId;
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        debugPrint('OTP SEND ');
        final snackBar = SnackBar(content: Text('Code send'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        verificationId = verificationId;
        print(verificationId);
        print("Timeout");
        final snackBar = SnackBar(
            content: Text('Auto retrieval timed out. Enter OTP manually'));
        if (!_authSuccess) ScaffoldMessenger.of(context).showSnackBar(snackBar);
        // _scaffoldKey.currentState!.showSnackBar(snackBar);
      },
    );
  }

  void _signInWithOTP(String smsCode) async {
    setState(() {
      _isLoading = true;
    });
    final snackBar = SnackBar(content: Text('Verifying code'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    AuthCredential _authCredential = PhoneAuthProvider.credential(
        verificationId: _verificationID, smsCode: smsCode);
    _auth.signInWithCredential(_authCredential).then((value) {
      setState(() {
        status = 'Authentication successful';
        _onAuthenticationSuccessful();
      });
    }).catchError((error) {
      setState(() {
        status = 'Authentication failed, please try later';
      });
      _onAuthenticationFailed();
    });
  }

  void _onAuthenticationFailed() {
    setState(() {
      _isLoading = false;
    });
    final snackBar = SnackBar(content: Text(status + ''));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _onAuthenticationSuccessful() {
    debugPrint('Auth Success');
    setState(() {
      _authSuccess = true;
      _isLoading = false;
    });

    _saveUser();
    // _updateUserPhone(widget.userToken, widget.phone);
  }

  void _saveUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userPhone', '+91' + _phone);

    _gotoUserDetails();
  }

  void _gotoUserDetails() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => UserDetails('+91' + _phone)));
  }
}
