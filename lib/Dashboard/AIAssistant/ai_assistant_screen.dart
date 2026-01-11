import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhira/design_system.dart';
import 'package:abhira/constants.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isInitialized = false;

  // Gemini AI instance
  GenerativeModel? _model;
  ChatSession? _chatSession;

  // Safety-focused system prompt
  final String _systemPrompt = '''
You are Abhira, an AI safety assistant for women. Your primary role is to provide safety advice, emergency guidance, and support for women's safety concerns.

Key guidelines:
- Always prioritize user safety and well-being
- Provide clear, actionable safety advice
- Be empathetic and supportive
- Know emergency numbers: Police (100), Ambulance (102), Fire (101)
- Encourage seeking professional help when needed
- Never provide medical or legal advice beyond general safety tips
- Be culturally sensitive and aware of women's safety issues
- Focus on prevention, awareness, and empowerment

Available features you can help with:
- Safety tips and advice
- Emergency contact information
- Self-defense techniques
- Location-based safety information
- General wellness and mental health support
- App feature explanations

Keep responses concise but helpful. Always end with an offer to help further.
  ''';

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeAI() async {
    try {
      // Use the API key provided
      const apiKey = 'AIzaSyBDlmB4m1SlxiGw_H0eQ70OchnyWyfXUzc';

      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.text(_systemPrompt),
      );

      _chatSession = _model?.startChat();

      setState(() {
        _isInitialized = true;
      });

      // Add welcome message
      _addBotMessage(
          '👋 Hi! I\'m Abhira, your AI safety assistant. How can I help you stay safe today?');
    } catch (e) {
      debugPrint('AI initialization error: $e');
      _addBotMessage(
          '❌ Sorry, I\'m having trouble connecting. Please try again later.');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('chat_history') ?? [];

      for (int i = 0; i < history.length; i += 3) {
        if (i + 2 < history.length) {
          final timestamp = DateTime.parse(history[i]);
          final isUser = history[i + 1] == 'user';
          final text = history[i + 2];

          _messages.add(ChatMessage(
            text: text,
            isUser: isUser,
            timestamp: timestamp,
          ));
        }
      }

      setState(() {});
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = <String>[];

      // Save last 50 messages to avoid storage bloat
      final recentMessages = _messages.length > 50
          ? _messages.sublist(_messages.length - 50)
          : _messages;

      for (final message in recentMessages) {
        history.addAll([
          message.timestamp.toIso8601String(),
          message.isUser ? 'user' : 'bot',
          message.text,
        ]);
      }

      await prefs.setStringList('chat_history', history);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_isInitialized) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      if (_chatSession != null) {
        final response = await _chatSession!.sendMessage(Content.text(message));

        if (response.text != null && response.text!.isNotEmpty) {
          setState(() {
            _messages.add(ChatMessage(text: response.text!, isUser: false));
            _isTyping = false;
          });
        } else {
          throw Exception('Empty response from AI');
        }
      } else {
        throw Exception('AI not initialized');
      }
    } catch (e) {
      debugPrint('AI response error: $e');
      setState(() {
        _messages.add(ChatMessage(
          text:
              '❌ Sorry, I\'m having trouble responding right now. Please try again.',
          isUser: false,
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
    _saveChatHistory();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content:
            const Text('Are you sure you want to clear all chat messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('chat_history');

              setState(() {
                _messages.clear();
                _addBotMessage(
                    '👋 Hi! I\'m Abhira, your AI safety assistant. How can I help you stay safe today?');
              });

              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.destructive,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abhira AI',
                  style: AppTypography.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your Safety Assistant',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: AppColors.textSecondary),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Abhira AI',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about safety, emergencies, or self-defense',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildQuickSuggestions(),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      {
        'text': 'Safety tips for walking alone at night',
        'action': () => _sendQuickAdvice('walking alone at night')
      },
      {
        'text': 'What should I do in an emergency?',
        'action': () => _sendQuickAdvice('emergency response')
      },
      {
        'text': 'How to respond to harassment?',
        'action': () => _sendQuickAdvice('responding to harassment')
      },
      {
        'text': 'Self-defense techniques',
        'action': () => _sendQuickAdvice('basic self-defense')
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions
          .map((suggestion) => ActionChip(
                label: Text(suggestion['text'] as String),
                onPressed: suggestion['action'] as VoidCallback,
                backgroundColor: AppColors.surface,
                side: BorderSide(color: AppColors.border),
              ))
          .toList(),
    );
  }

  Future<void> _sendQuickAdvice(String topic) async {
    final message = 'Give me advice about $topic';
    _messageController.text = message;
    await _sendMessage();
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Abhira is typing...',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                message.text,
                style: AppTypography.body.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me about safety...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
              tooltip: 'Send Message',
            ),
          ),
        ],
      ),
    );
  }
}
