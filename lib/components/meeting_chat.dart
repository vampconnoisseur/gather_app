import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gather_app/components/message_bubble.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({
    super.key,
    required this.isDirector,
    required this.meetingID,
    required this.uid,
  });

  final String uid;
  final String meetingID;
  final bool isDirector;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(meetingID)
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.'),
          );
        }

        if (chatSnapshots.hasError) {
          return const Center(
            child: Text('Something went wrong...'),
          );
        }

        final loadedMessages = chatSnapshots.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;

            final currentMessageUserId = chatMessage['userId'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['userId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;

            if (nextUserIsSame) {
              return MessageBubble.next(
                messageID: loadedMessages[index].id,
                meetingID: meetingID,
                isDirector: isDirector,
                isDeleted: chatMessage['isDeleted'],
                message: chatMessage['text'],
                isMe: uid == currentMessageUserId,
              );
            } else {
              return MessageBubble.first(
                meetingID: meetingID,
                messageID: loadedMessages[index].id,
                isDirector: isDirector,
                isDeleted: chatMessage['isDeleted'],
                userImage: chatMessage['userImage'],
                username: chatMessage['username'],
                message: chatMessage['text'],
                isMe: uid == currentMessageUserId,
              );
            }
          },
        );
      },
    );
  }
}
