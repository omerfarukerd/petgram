import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class MessageInfoScreen extends StatefulWidget {
  final MessageModel message;

  const MessageInfoScreen({super.key, required this.message});

  @override
  State<MessageInfoScreen> createState() => _MessageInfoScreenState();
}

class _MessageInfoScreenState extends State<MessageInfoScreen> {
  late Future<List<UserModel>> _readUsersFuture;

  @override
  void initState() {
    super.initState();
    final userIds = widget.message.readBy.keys.toList();
    _readUsersFuture = UserRepository.getMultipleUsers(userIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesaj Bilgisi'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.message.text ?? "Medya",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Okuyanlar (${widget.message.readBy.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          FutureBuilder<List<UserModel>>(
            future: _readUsersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const ListTile(title: Text('Okuyan kimse yok.'));
              }

              final users = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final readTimestamp = widget.message.readBy[user.uid];
                  final readTime = readTimestamp != null
                      ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(readTimestamp))
                      : '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Text(user.username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(user.username),
                    subtitle: Text('Okundu: $readTime'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}