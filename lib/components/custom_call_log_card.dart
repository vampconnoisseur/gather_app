import 'package:flutter/material.dart';

class CustomCallLogCard extends StatelessWidget {
  final String channelName;
  final String formattedJoinDate;
  final String formattedJoinTime;
  final String formattedLeftTime;
  final String callDuration;

  const CustomCallLogCard({
    super.key,
    required this.callDuration,
    required this.channelName,
    required this.formattedJoinDate,
    required this.formattedJoinTime,
    required this.formattedLeftTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.fromLTRB(15, 12, 15, 5),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 7,
        ),
        child: Column(
          children: [
            ListTile(
              title: Text('Channel: $channelName'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: $formattedJoinDate',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            'Duration: $callDuration',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Join Time: $formattedJoinTime\nLeft Time: $formattedLeftTime',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
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
