import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import 'chat_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedUsers = {};
  bool _isCreating = false;

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty || _selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup adı ve en az 2 kişi seçin')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final messageProvider = context.read<MessageProvider>();
      final currentUserId = authProvider.currentUser!.uid;
      
      final participants = [..._selectedUsers, currentUserId];
      final conversationId = await messageProvider.createOrGetConversation(participants);
      
      // Grup bilgilerini güncelle
      await messageProvider.updateGroupInfo(
        conversationId,
        _nameController.text,
        currentUserId,
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conversationId,
              otherUser: UserModel(
                uid: conversationId,
                email: '',
                username: _nameController.text,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Grup'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: const Text('Oluştur'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Grup Adı',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: UserRepository.getUserStream(currentUser.uid)
                  .asyncExpand((user) => UserRepository.searchUsers('')),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!
                    .where((u) => u.uid != currentUser.uid)
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUsers.contains(user.uid);

                    return CheckboxListTile(
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedUsers.add(user.uid);
                          } else {
                            _selectedUsers.remove(user.uid);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}