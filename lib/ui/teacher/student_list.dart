import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:v_lab/ui/teacher/answer.dart';

class StudentList extends StatefulWidget {
  final String questionId, question;

  const StudentList(this.questionId, this.question);

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  List<DocumentSnapshot> _answers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Answers'),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<DocumentSnapshot>>(
        future: _getAnswers(),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: const CircularProgressIndicator());
          } else {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return _userCard(snapshot.data[index]);
                        }),
                  ],
                ),
              ),
            );
          }
        });
  }

  Widget _userCard(DocumentSnapshot answerDoc) {
    return FutureBuilder<DocumentSnapshot>(
        future: _getUserDetails(answerDoc.data()['studentId']),
        builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          } else {
            return GestureDetector(
              onTap: () => _gotoAnswer(widget.question, answerDoc),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: Card(
                  // color: answerDoc.data()['grade'] != null
                  //     ? Colors.white60
                  //     : Colors.white,
                  elevation: 3,
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          clipBehavior: Clip.hardEdge,
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueGrey,
                          ),
                          child: Image.network(
                            'https://picsum.photos/id/${Random().nextInt(100)}/200/200?blur',
                            fit: BoxFit.fill,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userSnapshot.data.data()['name'],
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Roll : ${userSnapshot.data.data()['rollNo']}',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            if (answerDoc.data()['grade'] != null)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.green,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Grade : ${answerDoc.data()['grade']}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        });
  }

  Future<List<DocumentSnapshot>> _getAnswers() async {
    await FirebaseFirestore.instance
        .collection('answers')
        .where('questionId', isEqualTo: widget.questionId)
        .orderBy('createdOn', descending: true)
        .get()
        .then((QuerySnapshot querySnapshot) {
      _answers.clear();
      _answers.addAll(querySnapshot.docs);
    });

    return _answers;
  }

  Future<DocumentSnapshot> _getUserDetails(String userId) async {
    debugPrint(userId);
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
  }

  _gotoAnswer(String question, DocumentSnapshot answerDoc) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => Answer(question, answerDoc)));
  }
}
