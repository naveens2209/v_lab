import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:v_lab/ui/chat/chat.dart';

class ChatList extends StatefulWidget {
  final String userPhone, role;

  ChatList(this.userPhone, this.role);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<DocumentSnapshot> _users = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<DocumentSnapshot>>(
        future: _getUsers(),
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

  Widget _userCard(DocumentSnapshot userSnapshot) {
    return GestureDetector(
      onTap: () => _gotoChat(userSnapshot.id),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: Card(
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
                      userSnapshot.data()['name'],
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    if (widget.role == 'teacher')
                      Text(
                        'Roll : ${userSnapshot.data()['rollNo']}',
                        style: TextStyle(fontSize: 16),
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

  Future<List<DocumentSnapshot>> _getUsers() async {
    await FirebaseFirestore.instance
        .collection('users')
        .where('role', isNotEqualTo: widget.role)
        .get()
        .then((QuerySnapshot querySnapshot) {
      _users.clear();
      _users.addAll(querySnapshot.docs);
    });

    return _users;
  }

  _gotoChat(String senderId) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Chat(widget.userPhone, senderId, widget.role)));
  }
}
