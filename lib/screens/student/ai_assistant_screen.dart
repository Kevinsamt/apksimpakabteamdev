import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Halo! Saya **Asisten AI SIMPAKAB** 🤖. \n\nAda yang bisa saya bantu hari ini? Tanyakan saja tentang ketersediaan atau fungsi alat laboratorium kami!',
      'isUser': false,
      'time': DateTime.now(),
    }
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

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
    final query = _messageController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({
        'text': query,
        'isUser': true,
        'time': DateTime.now(),
      });
      _isLoading = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai_assistant_python',
        body: {'query': query},
      );

      final data = response.data as Map<String, dynamic>?;
      String aiResponse = data != null && data['answer'] != null 
          ? data['answer'] 
          : 'Maaf, saya tidak mengerti maksud Anda.';

      if (mounted) {
        setState(() {
          _messages.add({
            'text': aiResponse,
            'isUser': false,
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': '⚠️ Maaf, terjadi gangguan koneksi ke server AI. Pastikan internet Anda stabil.',
            'isUser': false,
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
              child: const Icon(Icons.bolt_rounded, color: AppColors.primaryPink),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: AppTextStyles.bodyTextStrong.copyWith(fontSize: 16)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('Selalu Aktif', style: AppTextStyles.label.copyWith(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryPink.withValues(alpha: 0.02),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final bool isUser = msg['isUser'] == true;
                  final DateTime time = msg['time'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
                                child: const Icon(Icons.bolt_rounded, size: 15, color: AppColors.primaryPink),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.primaryPink : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: MarkdownBody(
                                  data: msg['text'],
                                  styleSheet: MarkdownStyleSheet(
                                    p: AppTextStyles.bodyText.copyWith(
                                      color: isUser ? Colors.white : AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    strong: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 40), // Spasi agar tidak mentok kiri
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 40, right: 8),
                          child: Text(
                            DateFormat('HH:mm').format(time),
                            style: AppTextStyles.label.copyWith(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
                    ),
                    const SizedBox(width: 8),
                    Text('Asisten sedang mengetik...', style: AppTextStyles.label.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: AppTextStyles.bodyText,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan Anda...',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPink, AppColors.darkPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
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
