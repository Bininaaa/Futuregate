import 'package:flutter/material.dart';

import '../chat/conversation_screen.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;
  final String otherName;
  final String recipientId;
  final String otherRole;
  final String contextLabel;
  final String fallbackProfileHeadline;
  final String fallbackProfileAbout;
  final String fallbackProfileLocation;
  final String fallbackProfileWebsite;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    this.recipientId = '',
    this.otherRole = '',
    this.contextLabel = '',
    this.fallbackProfileHeadline = '',
    this.fallbackProfileAbout = '',
    this.fallbackProfileLocation = '',
    this.fallbackProfileWebsite = '',
  });

  @override
  Widget build(BuildContext context) {
    return ConversationScreen(
      conversationId: conversationId,
      otherName: otherName,
      recipientId: recipientId,
      otherRole: otherRole,
      contextLabel: contextLabel,
      fallbackProfileHeadline: fallbackProfileHeadline,
      fallbackProfileAbout: fallbackProfileAbout,
      fallbackProfileLocation: fallbackProfileLocation,
      fallbackProfileWebsite: fallbackProfileWebsite,
    );
  }
}
