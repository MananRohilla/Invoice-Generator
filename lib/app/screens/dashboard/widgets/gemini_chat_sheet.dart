// AI Chat Sheet — temporarily disabled.
// Uncomment the block below when re-enabling the Gemini chat feature.

/*
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/gemini_service.dart';

class GeminiChatSheet extends StatefulWidget {
  const GeminiChatSheet({super.key});

  @override
  State<GeminiChatSheet> createState() => _GeminiChatSheetState();
}

class _GeminiChatSheetState extends State<GeminiChatSheet> {
  final _service = GeminiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <GeminiMessage>[];
  bool _isLoading = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messages.add(const GeminiMessage(
      role: 'model',
      text:
          'Hi! I\'m InvoGen AI. Ask me anything about invoicing, GST, managing clients, or tracking payments.',
    ));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();
    setState(() {
      _messages.add(GeminiMessage(role: 'user', text: text));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await _service.sendMessage(text);
    setState(() {
      _messages.add(GeminiMessage(role: 'model', text: reply));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.cardGradientBlue),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('InvoGen AI',
                          style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      Text('Powered by Gemini',
                          style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_isLoading && i == _messages.length) {
                    return _TypingIndicator();
                  }
                  final msg = _messages[i];
                  return _MessageBubble(message: msg);
                },
              ),
            ),

            // Input
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 8,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) =>
                          setState(() => _hasText = v.trim().isNotEmpty),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about invoicing…',
                        hintStyle: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 13,
                            color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _hasText ? _send : null,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _hasText
                              ? AppColors.primary
                              : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
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

class _MessageBubble extends StatelessWidget {
  final GeminiMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: AppColors.cardGradientBlue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? AppColors.primary.withOpacity(0.2) : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  color: isUser ? AppColors.primary : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: AppColors.cardGradientBlue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const SizedBox(
              width: 30,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Dot(delay: 0),
                  _Dot(delay: 150),
                  _Dot(delay: 300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(
      parent: _ac,
      curve: Curves.easeInOut,
    ));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: AppColors.textHint, shape: BoxShape.circle),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }
}
*/
