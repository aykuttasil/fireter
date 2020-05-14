import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';

final Firestore _fireStore = Firestore.instance;
FirebaseUser _loggedInUser;

class ChatScreen extends StatefulWidget {
  static const id = 'chat';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String messageText;
  TextEditingController messageTextController = TextEditingController();

  getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        _loggedInUser = user;
        print(user.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStreams(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                      messageTextController.clear();

                      await _fireStore.collection('messages').add({
                        'text': messageText,
                        'sender': _loggedInUser.email,
                        'createdDate': FieldValue.serverTimestamp()
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageModel implements Comparable<MessageModel> {
  Timestamp createdDate;
  String text;
  String sender;

  MessageModel({this.text, this.sender, this.createdDate});

  factory MessageModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    return MessageModel(
      text: snapshot.data['text'],
      sender: snapshot.data['sender'],
      createdDate: snapshot.data['createdDate'] ?? Timestamp.now(),
    );
  }

  @override
  int compareTo(MessageModel other) {
    return other.createdDate.millisecondsSinceEpoch -
        createdDate.millisecondsSinceEpoch;
  }
}

class MessageStreams extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var listMessage = <MessageModel>[];
        snapshot.data.documents.forEach((element) {
          listMessage.add(MessageModel.fromDocumentSnapshot(element));
        });

        listMessage.sort();

        var widgetList = listMessage
            .map((e) => MessageBubble(
                  text: e.text,
                  sender: e.sender,
                  isMe: e.sender == _loggedInUser.email,
                ))
            .toList();

        return Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            reverse: true,
            children: widgetList,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;

  MessageBubble({this.text, this.sender, this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          Material(
            elevation: 5.0,
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
            color: isMe ? Colors.lightBlue : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15.0,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
