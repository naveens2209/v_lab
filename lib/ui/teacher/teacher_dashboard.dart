import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:v_lab/ui/teacher/student_list.dart';

class TeacherDashboard extends StatefulWidget {
  final String phone;

  const TeacherDashboard(this.phone);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _formKey = GlobalKey<FormState>();

  List<DocumentSnapshot> _questions = [];
  String _newQuestion;
  bool _timer = false;
  int _time;

  @override
  void initState() {
    super.initState();

    _getQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestionPopup,
        child: Icon(Icons.add, size: 40),
      ),
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

    return GestureDetector(
      onTap: () => _gotoAnswers(snapshot.id, question),
      child: Card(
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
                  SizedBox(width: 10),
                  PopupMenuButton(
                    onSelected: (String value) {
                      switch (value) {
                        case 'Edit':
                          _editQuestion(snapshot, question, timer, time);
                          break;
                        case 'Delete':
                          _deleteQuestion(snapshot);
                          break;
                      }
                    },
                    child: Icon(Icons.more_horiz),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Delete',
                        child: Text('Delete'),
                      )
                    ],
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
        .where('teacher_id', isEqualTo: widget.phone)
        .orderBy('createdOn', descending: true)
        .get()
        .then((QuerySnapshot querySnapshot) {
      _questions.clear();
      _questions.addAll(querySnapshot.docs);
    });

    return _questions;
  }

  void _addQuestionPopup(
      [DocumentSnapshot snapshot, String question, bool timer, int time]) {
    _newQuestion = question ?? '';
    _timer = timer ?? false;
    _time = time;
    AlertDialog alert = AlertDialog(
      title: Text('New Question'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Question'),
                    TextFormField(
                      initialValue: question ?? '',
                      maxLines: 3,
                      decoration: const InputDecoration(
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
                      ),
                      onChanged: (val) {
                        _newQuestion = val;
                      },
                      validator: (val) {
                        if (val.length < 1) return 'Question cannot be empty';
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Text('Timed question'),
                        Switch(
                            value: _timer,
                            onChanged: (value) {
                              setState(() {
                                _timer = !_timer;
                              });
                            }),
                      ],
                    ),
                    if (_timer) Text('Time in minutes'),
                    if (_timer)
                      TextFormField(
                        initialValue: time.toString() ?? '',
                        maxLines: 1,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
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
                        ),
                        onChanged: (val) {
                          _time = int.tryParse(val);
                        },
                        validator: (val) {
                          var s = int.tryParse(val);
                          if (s == null) return 'Invalid';
                          return null;
                        },
                      ),
                    Center(
                      child: question == null
                          ? ElevatedButton(
                              onPressed: _addQuestion,
                              child: Text('Add Question'))
                          : ElevatedButton(
                              onPressed: () => _updateQuestion(snapshot),
                              child: Text('Update Question')),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    showDialog(
        context: context,
        useRootNavigator: false,
        builder: (context) {
          return alert;
        });
  }

  void _addQuestion() async {
    var isValid = _formKey.currentState.validate();

    if (isValid) {
      await FirebaseFirestore.instance.collection('questions').add({
        'question': _newQuestion,
        'teacher_id': widget.phone,
        'timer': _timer,
        if (_timer) 'time': _time,
        'createdOn': Timestamp.now()
      });

      Navigator.of(context).pop();
      setState(() {});
    }
  }

  void _editQuestion(
      DocumentSnapshot snapshot, String question, bool timer, int time) {
    _addQuestionPopup(snapshot, question, timer, time);
  }

  void _deleteQuestion(DocumentSnapshot snapshot) async {
    await FirebaseFirestore.instance
        .runTransaction((Transaction myTransaction) async {
      myTransaction.delete(snapshot.reference);
    });

    setState(() {});
  }

  void _updateQuestion(DocumentSnapshot snapshot) async {
    await FirebaseFirestore.instance
        .runTransaction((Transaction myTransaction) async {
      myTransaction.update(snapshot.reference, {
        'question': _newQuestion,
        'teacher_id': widget.phone,
        'timer': _timer,
        if (_timer) 'time': _time,
        'createdOn': Timestamp.now()
      });
    });
    Navigator.of(context).pop();
    setState(() {});
  }

  void _gotoAnswers(String questionId, String question) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => StudentList(questionId, question)));
  }
}
