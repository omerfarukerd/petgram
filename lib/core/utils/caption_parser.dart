import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pet_gram/data/repositories/user_repository.dart';
import 'package:pet_gram/presentation/screens/hashtag/hashtag_feed_screen.dart';
import 'package:pet_gram/presentation/profile/profile_screen.dart';

class CaptionParser {
  final String text;
  final BuildContext context;

  CaptionParser(this.text, this.context);

  List<InlineSpan> parseText() {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(r"([@#][a-zA-Z0-9_]+)");

    text.splitMapJoin(
      regex,
      onMatch: (Match match) {
        final String tag = match.group(0)!;
        if (tag.startsWith('#')) {
          final hashtag = tag.substring(1);
          spans.add(
            TextSpan(
              text: tag,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.normal),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HashtagFeedScreen(hashtag: hashtag),
                    ),
                  );
                },
            ),
          );
        } else if (tag.startsWith('@')) {
          final username = tag.substring(1);
          spans.add(
            TextSpan(
              text: tag,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final user = await UserRepository.getUserByUsername(username);
                  if (user != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: user.uid),
                      ),
                    );
                  }
                },
            ),
          );
        }
        return '';
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(text: text));
        return '';
      },
    );

    return spans;
  }
}