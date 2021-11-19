import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:v_lab/ui/home/home.dart';

class Workspace extends StatefulWidget {
  final String questionId, question, phone;
  final bool timer, answered;
  final int time;
  final DocumentSnapshot answerDoc;

  Workspace(this.questionId, this.question, this.timer, this.time, this.phone,
      this.answered, this.answerDoc);

  @override
  _WorkspaceState createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final _formKey = GlobalKey<FormState>();

  String _code, _language = 'kotlin';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Workspace'),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        actions: [
          if (widget.timer && !widget.answered)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Countdown(
                  seconds: widget.time * 60,
                  build: (BuildContext context, double time) => Text(
                    '${(time ~/ 60).toString()} : ${(time % 60).toInt().toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 18),
                  ),
                  interval: Duration(seconds: 1),
                  onFinished: () {
                    _showTimerAlert();
                  },
                ),
              ),
            ),
          if (widget.answered && widget.answerDoc.data()['grade'] == null)
            IconButton(
                icon: Icon(Icons.delete_sweep), onPressed: _showDeleteAlert)
        ],
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
                    key: _formKey,
                    initialValue: !widget.answered
                        ? ''
                        : widget.answerDoc.data()['answer'],
                    enabled: !widget.answered ? true : false,
                    minLines: !widget.answered ? 17 : 10,
                    maxLines: 50,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                        hintText: "//todo : add your code here",
                        hintStyle: TextStyle(color: Colors.white, fontSize: 20),
                        isCollapsed: true,
                        filled: false,
                        fillColor: Colors.blueGrey),
                    autofocus: false,
                    onChanged: (val) => _code = val,
                    validator: (val) {
                      if (val.length < 1) return 'Code cannot be empty';
                      return null;
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            if (!widget.answered)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.blue,
                    child: new DropdownButton<String>(
                      value: _language,
                      dropdownColor: Colors.blue,
                      focusColor: Colors.blue,
                      items: <String>['kotlin', 'java', 'c', 'cpp']
                          .map((String value) {
                        return new DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                            color: Colors.blue,
                            padding: EdgeInsets.all(5),
                            child: new Text(
                              value,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _language = value;
                        });
                      },
                    ),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green)),
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
                ],
              ),
            if (widget.answered)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: widget.answerDoc.data()['grade'] != null
                          ? Colors.green
                          : Colors.orangeAccent,
                    ),
                    child: Text(
                      widget.answerDoc.data()['grade'] != null
                          ? 'Grade : ${widget.answerDoc.data()['grade']}'
                          : 'Not Graded',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text('Comments', style: TextStyle(fontSize: 18)),
                  ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                          minHeight: 100),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          widget.answerDoc.data()['comment'] != null
                              ? widget.answerDoc.data()['comment']
                              : '',
                          style: TextStyle(fontSize: 18),
                        ),
                      )),
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
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: _submitAnswer, child: Text('Submit Answer'))
      ],
    );

    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }

  void _submitAnswer() async {
    Navigator.of(context).pop();
    setState(() {
      _isLoading = true;
    });

    await FirebaseFirestore.instance.collection('answers').add({
      'questionId': widget.questionId,
      'studentId': widget.phone,
      'answer': _code,
      'language': _language,
      'createdOn': Timestamp.now()
    });
    setState(() {
      _isLoading = false;
    });

    _showSubmitAlert();
  }

  void _showSubmitAlert() {
    AlertDialog alert = AlertDialog(
      title: Text('Submitted'),
      content: Text('Your answer has been successfully submitted.'),
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

  void _showTimerAlert() {
    AlertDialog alert = AlertDialog(
      title: Text('Time Over'),
      content: Text(
          'Time allocated for this question is over. Your work will be submitted now.'),
      actions: [ElevatedButton(onPressed: _submitAnswer, child: Text('OK'))],
    );

    showDialog(
        context: context,
        builder: (_) {
          return alert;
        },
        barrierDismissible: false);
  }

  void _showDeleteAlert() {
    AlertDialog alert = AlertDialog(
      title: Text('Delete'),
      content: Text('Are you sure you want to delete the answer'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red),
          ),
          onPressed: _deleteAnswer,
          child: Text(
            'DELETE',
          ),
        ),
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

  void _deleteAnswer() async {
    await FirebaseFirestore.instance
        .runTransaction((Transaction myTransaction) async {
      myTransaction.delete(widget.answerDoc.reference);
    });

    _gotoHome();
  }
}
