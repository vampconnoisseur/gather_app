import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:gather_app/components/call_log_item.dart';
import 'package:gather_app/components/custom_call_log_card.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

class CallLogsScreen extends StatelessWidget {
  final String uid;

  const CallLogsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('meetings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(
                    color: Colors.black,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Loading logs...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(
                    color: Colors.black,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Loading logs...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No call logs available.',
                  ),
                ],
              ),
            );
          }

          List<CallLogItem> callLogItems = [];

          for (var document in snapshot.data!.docs) {
            Map<String, dynamic> data = document.data();

            int userID = data['uid'] ?? '';
            String channelName = data['channel'] ?? '';

            DateTime joinTime = data['join_time']?.toDate() ?? DateTime.now();
            DateTime leftTime = data['left_time']?.toDate() ?? DateTime.now();
            Duration callDuration = leftTime.difference(joinTime);

            String formattedJoinDate =
                DateFormat('dd-MM-yyyy').format(joinTime);
            String formattedJoinTime = DateFormat('HH:mm:ss').format(joinTime);
            String formattedLeftTime = DateFormat('HH:mm:ss').format(leftTime);
            String formattedCallDuration =
                '${callDuration.inHours}h ${callDuration.inMinutes.remainder(60)}m';

            if (uid == userID.toString()) {
              callLogItems.add(
                CallLogItem(
                  joinTime: joinTime,
                  child: CustomCallLogCard(
                    channelName: channelName,
                    callDuration: formattedCallDuration,
                    formattedJoinDate: formattedJoinDate,
                    formattedJoinTime: formattedJoinTime,
                    formattedLeftTime: formattedLeftTime,
                  ),
                ),
              );
            }
          }

          callLogItems.sort((a, b) => b.joinTime.compareTo(a.joinTime));

          List<Widget> sortedCallLogItems =
              callLogItems.map((item) => item.child).toList();

          if (sortedCallLogItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No call logs available.',
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: sortedCallLogItems.length,
            itemBuilder: (context, index) {
              return sortedCallLogItems[index];
            },
          );
        },
      ),
    );
  }
}
