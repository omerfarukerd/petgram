import 'package:flutter/material.dart';
import 'package:pet_gram/presentation/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';


class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? 'test-user';

    return ProfileScreen(userId: currentUserId);
  }
}