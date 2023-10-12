import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({
    super.key,
    required this.meetingID,
    required this.uid,
    required this.userName,
    required this.photoURL,
  });

  final String meetingID;
  final String uid;
  final String userName;
  final String photoURL;

  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    _messageController.clear();

    FirebaseFirestore.instance.collection(widget.meetingID).add({
      'text': enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': widget.uid,
      'username': widget.userName,
      'userImage': widget.photoURL,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 6,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              placeholder: "Chat...",
            ),
          ),
          IconButton(
            iconSize: 35,
            color: Colors.black,
            icon: const Icon(
              Icons.send,
            ),
            onPressed: _submitMessage,
          ),
        ],
      ),
    );
  }
}
