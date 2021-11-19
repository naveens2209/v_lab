import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  final String userPhone, receiverPhone, role;

  Chat(this.userPhone, this.receiverPhone, this.role);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  String _newMessage = 'test', _senderId, _receiverId, _documentId;
  TextEditingController _messageController = new TextEditingController();
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    super.initState();

    if (widget.role == 'student') {
      _documentId = widget.userPhone + widget.receiverPhone;
    } else
      _documentId = widget.receiverPhone + widget.userPhone;

    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Chat'),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
        ),
        body: SafeArea(child: _buildBody()));
  }

  Widget _buildBody() {
    return Container(
      height: MediaQuery.of(context).size.height,
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat')
                    .doc(_documentId)
                    .collection('messages')
                    .orderBy('createdOn')
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                        child: const CircularProgressIndicator());
                  else {
                    return new ListView(
                      controller: _scrollController,
                      reverse: true,
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      children: snapshot.data.docs.reversed
                          .map((DocumentSnapshot document) {
                        return Container(
                          decoration: BoxDecoration(
                              color: Color(0xFFd0e1f7),
                              borderRadius: BorderRadius.circular(10)),
                          margin: document['senderId'] == widget.userPhone
                              ? EdgeInsets.fromLTRB(50, 5, 0, 5)
                              : EdgeInsets.fromLTRB(0, 5, 50, 5),
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          child: Text(
                            document['message'],
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Expanded(
                    child: TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                      ),
                      hintText: 'Type a message'),
                  style: TextStyle(fontSize: 18),
                  onChanged: (val) => _newMessage = val,
                )),
                const SizedBox(width: 15),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.green),
                  child: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_newMessage.length > 0) {
      _messageController.text = '';
      await FirebaseFirestore.instance
          .collection('chat')
          .doc(_documentId)
          .collection('messages')
          .add({
        'message': _newMessage,
        'senderId': widget.userPhone,
        'createdOn': Timestamp.now()
      });
    }
  }
}
