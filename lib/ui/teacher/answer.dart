import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:v_lab/ui/home/home.dart';

class Answer extends StatefulWidget {
  final String question;
  final DocumentSnapshot answerDoc;

  Answer(this.question, this.answerDoc);

  @override
  _AnswerState createState() => _AnswerState();
}

class _AnswerState extends State<Answer> {
  String _code, _language = 'kotlin', _comment, _grade;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _code = widget.answerDoc.data()['answer'];
    _language = widget.answerDoc.data()['language'];
    _comment = widget.answerDoc.data()['comment'] ?? '';
    _grade = widget.answerDoc.data()['grade'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workspace'),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.fromLTRB(15, 15, 15, 0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.question, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 15),
            ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: 200,
                  maxHeight: MediaQuery.of(context).size.height / 1.6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.blueGrey,
                ),
                padding: EdgeInsets.all(15),
                child: SingleChildScrollView(
                  child: TextFormField(
                    initialValue: _code ?? '',
                    enabled: false,
                    minLines: 10,
                    maxLines: 50,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        fillColor: Colors.blueGrey),
                    autofocus: false,
                    onChanged: (val) => _code = val,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // if (!widget.answered)
            Center(
              child: ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                onPressed: !_isLoading ? _compile : null,
                child: !_isLoading
                    ? Text(
                        'Compile',
                        style: TextStyle(fontSize: 18),
                      )
                    : Container(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: _comment,
                  minLines: 3,
                  maxLines: 20,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                      ),
                      hintText: 'Add your comments'),
                  style: TextStyle(fontSize: 18),
                  onChanged: (val) => _comment = val,
                ),
                SizedBox(height: 20),
                Text('Grade', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: _grade,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                      ),
                      hintText: 'Enter grade'),
                  style: TextStyle(fontSize: 18),
                  onChanged: (val) => _grade = val,
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.blue)),
                    onPressed: !_isLoading ? _submitGrade : null,
                    child: !_isLoading
                        ? Text(
                            'Submit',
                            style: TextStyle(fontSize: 18),
                          )
                        : Container(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _compile() async {
    setState(() {
      _isLoading = true;
    });
    var response =
        await Dio().post('https://api.jdoodle.com/v1/execute', data: {
      "clientId": "91a19c8cc079b8467ecdbaa6e9a6b96f",
      "clientSecret":
          "d7f364c5a3792858070ac9475c24906906ca46a90ffd2e83278a968ffa86a0ed",
      "script": _code,
      "language": _language
    });

    var jsonResponse = jsonDecode(response.toString());

    setState(() {
      _isLoading = false;
    });

    debugPrint(jsonResponse.toString());

    _showOutput(jsonResponse['output'], jsonResponse['statusCode']);
  }

  _showOutput(String output, int statusCode) {
    AlertDialog alert = AlertDialog(
      title: Text('Output'),
      content: Text(output),
      actions: [
        ElevatedButton(
            onPressed: () => Navigator.pop(context), child: Text('OK'))
      ],
    );

    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }

  _submitGrade() async {
    setState(() {
      _isLoading = true;
    });
    await FirebaseFirestore.instance
        .runTransaction((Transaction myTransaction) async {
      myTransaction.update(
          widget.answerDoc.reference, {'comment': _comment, 'grade': _grade});
    });

    setState(() {
      _isLoading = false;
    });

    _showSubmitAlert();
  }

  void _showSubmitAlert() {
    AlertDialog alert = AlertDialog(
      title: Text('Submitted'),
      content: Text('Grade/comments have been successfully submitted.'),
      actions: [
        ElevatedButton(
          child: Text('OK'),
          onPressed: _gotoHome,
        )
      ],
    );

    showDialog(
      context: context,
      builder: (_) {
        return alert;
      },
      barrierDismissible: false,
    );
  }

  void _gotoHome() {
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => Home()), (route) => false);
  }
}
