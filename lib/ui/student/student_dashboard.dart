import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:v_lab/ui/student/workspace.dart';

class StudentDashboard extends StatefulWidget {
  final String phone;

  const StudentDashboard(this.phone);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<DocumentSnapshot> _questions = [];
  List<DocumentSnapshot> _answers = [];
  List<String> _answeredQuestions = [];

  @override
  void initState() {
    super.initState();

    _getQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<DocumentSnapshot>>(
        future: _getQuestions(),
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
                    const Text(
                      'Questions',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return _questionCard(snapshot.data[index]);
                        }),
                  ],
                ),
              ),
            );
          }
        });
  }

  Widget _questionCard(DocumentSnapshot snapshot) {
    String question = snapshot.data()['question'];
    bool timer = snapshot.data()['timer'];
    int time = snapshot.data()['time'] ?? 0;
    var date = DateFormat.yMMMd().add_jm().format(
        DateTime.parse(snapshot.data()['createdOn'].toDate().toString()));

    bool answered = false;
    DocumentSnapshot answerDoc;

    if (_answeredQuestions.contains(snapshot.id)) {
      answered = true;
      answerDoc = _answers
          .firstWhere((element) => element.data()['questionId'] == snapshot.id);
      debugPrint(answerDoc.data().toString());
    }

    return GestureDetector(
      onTap: () {
        _gotoWorkspace(snapshot.id, question, timer, time, answered, answerDoc);
      },
      child: Card(
        color: answered ? Colors.white60 : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Container(
          margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      question,
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              if (timer) const SizedBox(height: 10),
              if (timer)
                Text(
                  'Time : $time minutes',
                  style: TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 10),
              Text(
                date.toString(),
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<DocumentSnapshot>> _getQuestions() async {
    await FirebaseFirestore.instance
        .collection('questions')
        .orderBy('createdOn', descending: true)
        .get()
        .then((QuerySnapshot querySnapshot) {
      _questions.clear();
      _questions.addAll(querySnapshot.docs);
    });

    await _getAnswers();

    return _questions;
  }

  _getAnswers() async {
    await FirebaseFirestore.instance
        .collection('answers')
        .where('studentId', isEqualTo: widget.phone)
        .get()
        .then((QuerySnapshot querySnapshot) {
      _answeredQuestions.clear();
      _answers.clear();
      _answers.addAll(querySnapshot.docs);

      querySnapshot.docs.forEach((doc) {
        _answeredQuestions.add(doc.data()['questionId']);
      });
    });

    return _questions;
  }

  _gotoWorkspace(String id, String question, bool timer, int time,
      bool answered, DocumentSnapshot answerDoc) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Workspace(
                id, question, timer, time, widget.phone, answered, answerDoc)));
  }
}
