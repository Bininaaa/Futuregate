import 'package:flutter/material.dart';

import '../chat/messages_inbox_screen.dart';

class ChatListScreen extends StatelessWidget {
  final bool embedded;

  const ChatListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return MessagesInboxScreen(embedded: embedded);
  }
}
