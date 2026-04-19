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

  final List<String> _quickQueries = [
    'Cara pinjam alat?',
    'Stok Tensimeter',
    'Limbah Medis apa?',
    'Jam buka Lab',
  ];

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

  Future<void> _sendMessage({String? customQuery}) async {
    final query = customQuery ?? _messageController.text.trim();
    if (query.isEmpty) return;

    if (customQuery == null) _messageController.clear();

    setState(() {
      _messages.add({
        'text': query,
        'isUser': true,
        'time': DateTime.now(),
      });
      _isLoading = true;
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
          : 'Maaf, saya sedang mempelajari data terbaru. Silakan tanya kembali beberapa saat lagi.';

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
            'text': '⚠️ Maaf Sekali Wak, koneksi AI sedang sibuk. Mohon cek internet Anda ya.',
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
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildChatBubble(_messages[index]),
            ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfacePink, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIMPAKAB AI', style: AppTextStyles.bodyTextStrong),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.statusActive, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Active Now', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.statusActive)),
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
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isUser = msg['isUser'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(radius: 14, backgroundColor: AppColors.surfacePink, child: const Icon(Icons.smart_toy_rounded, size: 14, color: AppColors.primaryPink)),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryPink : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: MarkdownBody(
                    data: msg['text'],
                    styleSheet: MarkdownStyleSheet(
                      p: AppTextStyles.bodyText.copyWith(color: isUser ? Colors.white : AppColors.textPrimary),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 40, right: isUser ? 8 : 0),
            child: Text(DateFormat('HH:mm').format(msg['time']), style: AppTextStyles.label.copyWith(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickQueries.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(_quickQueries[index], style: const TextStyle(fontSize: 11)),
            onPressed: () => _sendMessage(customQuery: _quickQueries[index]),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.primaryPink, width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink)),
          const SizedBox(width: 12),
          Text('Asisten sedang menganalisis...', style: AppTextStyles.label.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: AppColors.backgroundWhite, borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Tanyakan sesuatu...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryPink,
            child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: () => _sendMessage()),
          ),
        ],
      ),
    );
  }
}
