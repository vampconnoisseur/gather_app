import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble.first({
    super.key,
    required this.isDeleted,
    required this.isDirector,
    required this.meetingID,
    required this.messageID,
    required this.userImage,
    required this.username,
    required this.message,
    required this.isMe,
  }) : isFirstInSequence = true;

  const MessageBubble.next({
    super.key,
    required this.isDeleted,
    required this.isDirector,
    required this.meetingID,
    required this.messageID,
    required this.message,
    required this.isMe,
  })  : isFirstInSequence = false,
        userImage = null,
        username = null;

  final bool isFirstInSequence;
  final bool isDirector;
  final bool isDeleted;
  final String messageID;
  final String meetingID;
  final String? userImage;
  final String? username;
  final String message;

  final bool isMe;

  void deleteMessage() {
    FirebaseFirestore.instance.collection(meetingID).doc(messageID).update({
      'text': "Message deleted by the director.",
      'isDeleted': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: (isDirector && !isDeleted)
          ? () {
              showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return CupertinoAlertDialog(
                      title: const Text("Delete message?"),
                      actions: <Widget>[
                        TextButton(
                            child: const Text("No"),
                            onPressed: () {
                              Navigator.pop(context);
                            }),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            deleteMessage();
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    );
                  });
            }
          : null,
      child: Stack(
        children: [
          if (userImage != null)
            Positioned(
              top: 15,
              right: isMe ? 0 : null,
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  userImage!,
                ),
                backgroundColor: Colors.grey,
                radius: 23,
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 46),
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (isFirstInSequence) const SizedBox(height: 18),
                    if (username != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 13,
                          right: 13,
                        ),
                        child: Text(
                          username!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: !isMe && isFirstInSequence
                              ? Radius.zero
                              : const Radius.circular(12),
                          topRight: isMe && isFirstInSequence
                              ? Radius.zero
                              : const Radius.circular(12),
                          bottomLeft: const Radius.circular(12),
                          bottomRight: const Radius.circular(12),
                        ),
                      ),
                      constraints: const BoxConstraints(maxWidth: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          height: 1.3,
                          fontStyle:
                              isDeleted ? FontStyle.italic : FontStyle.normal,
                          color: Colors.white,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
