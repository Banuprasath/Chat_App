import 'package:chatapp/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      //Check new message in cloud and return data

      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('TimeStamp', descending: true)
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: const CircularProgressIndicator(),
          );
        }
        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found..'),
          );
        }
        if (chatSnapshots.hasError) {
          return const Center(
            child: Text('Oops Something went wrong '),
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
              final ChatMessage = loadedMessages[index].data();
              var name1 = ChatMessage['Username'];

              final nextChatMessage = index + 1 < loadedMessages.length
                  ? loadedMessages[index + 1].data()
                  : null;
              final currentMessageUsernameId = ChatMessage['UserId'];
              final nextMessageUsernameId =
                  nextChatMessage != null ? nextChatMessage['UserId'] : null;
              final nextUserIsSame =
                  nextMessageUsernameId == currentMessageUsernameId;
              if (nextUserIsSame) {
                return MessageBubble.next(
                  message: ChatMessage['Text'],
                  isMe: authenticatedUser.uid == currentMessageUsernameId,
                );
              } else {
                return MessageBubble.first(
                    userImage: ChatMessage['UserImage'],
                    username: ChatMessage['Username'],
                    message: ChatMessage['Text'],
                    isMe: authenticatedUser.uid == currentMessageUsernameId);
              }
            });
        //   Text(loadedMessages[index].data()['Text']));
      },
    );
  }
}
