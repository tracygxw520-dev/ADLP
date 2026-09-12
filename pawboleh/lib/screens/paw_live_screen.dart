import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.username,
    required this.message,
    required this.color,
    this.isAi = false,
  });

  final String id;
  final String username;
  final String message;
  final Color color;
  final bool isAi;
}

/// Paw Live Screen (AI Livestreamer)
/// Features dynamic Product Context controllers (Name, Fabric, Fit, Price, Colors)
/// and real-time chat powered by OpenAI GPT-4o-mini & Express backend.
class PawLiveView extends StatefulWidget {
  const PawLiveView({super.key, required this.onExit});

  final VoidCallback onExit;

  @override
  State<PawLiveView> createState() => _PawLiveViewState();
}

class _PawLiveViewState extends State<PawLiveView> with SingleTickerProviderStateMixin {
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _questionController = TextEditingController();

  // Dynamic Product Context Controllers
  final TextEditingController _nameController = TextEditingController(text: 'Handcrafted Leather Wallet');
  final TextEditingController _fabricController = TextEditingController(text: 'Full-Grain Genuine Leather');
  final TextEditingController _fitController = TextEditingController(text: 'Compact Ergonomic Bifold');
  final TextEditingController _priceController = TextEditingController(text: '\$40');
  final TextEditingController _colorsController = TextEditingController(text: 'Vintage Tan & Onyx Black');

  late final AnimationController _pulseController;
  bool _obsCaptureMode = false;
  bool _isAiResponding = false;
  final String _streamStatus = 'LIVE · OpenAI Stream Host';

  final List<_ChatMessage> _chatMessages = [
    const _ChatMessage(
      id: 'welcome',
      username: 'Gema AI Host',
      message: 'Welcome to today’s livestream! Ask me anything about our handcrafted collection.',
      color: Color(0xFFF59E0B),
      isAi: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _questionController.dispose();
    _nameController.dispose();
    _fabricController.dispose();
    _fitController.dispose();
    _priceController.dispose();
    _colorsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildProductContext() {
    return {
      'name': _nameController.text.trim(),
      'fabric': _fabricController.text.trim(),
      'fit': _fitController.text.trim(),
      'price': _priceController.text.trim(),
      'colors': _colorsController.text.trim(),
      'stock': 5,
    };
  }

  Future<void> _sendCustomerQuestion(String questionText) async {
    final text = questionText.trim();
    if (text.isEmpty || _isAiResponding) return;

    // 1. Add User Question to Chat Feed
    setState(() {
      _chatMessages.add(_ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: 'You (Customer)',
        message: text,
        color: const Color(0xFF38BDF8),
      ));
      _isAiResponding = true;
      _questionController.clear();
    });

    _scrollToBottom();

    // 2. Trigger OpenAI API via ApiService
    try {
      final response = await ApiService.sendPawLiveChat(
        productContext: _buildProductContext(),
        customerQuestion: text,
      );

      if (!mounted) return;

      final aiReply = response['reply'] as String? ?? 'Thank you for asking!';

      // 3. Add AI Response to Chat Feed
      setState(() {
        _chatMessages.add(_ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: 'Gema AI Host',
          message: aiReply,
          color: const Color(0xFFF59E0B),
          isAi: true,
        ));
        _isAiResponding = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Paw Live Connection Error: $e');

      if (!mounted) return;

      setState(() => _isAiResponding = false);

      // Display SnackBar alert in UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paw Live Network Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Stream Canvas
          const _ObsStreamVideoCanvas(),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Main Layout
          Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      if (!_obsCaptureMode)
                        InkWell(
                          onTap: widget.onExit,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrowLeft300, color: Colors.white, size: 20),
                          ),
                        ),
                      if (!_obsCaptureMode) const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _streamStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (!_obsCaptureMode)
                            const Text(
                              'OpenAI gpt-4o-mini Stream Host',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _obsCaptureMode = !_obsCaptureMode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _obsCaptureMode ? Colors.redAccent : Colors.white24,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: Icon(
                          _obsCaptureMode ? LucideIcons.eyeOff300 : LucideIcons.video300,
                          size: 16,
                        ),
                        label: Text(
                          _obsCaptureMode ? 'Exit OBS Mode' : 'OBS Clean Mode',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dynamic Product Context Controllers Panel
              if (!_obsCaptureMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.sliders300, color: AppColors.gold, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Product AI Context (Editable for OpenAI)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildContextInput('Name', _nameController)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildContextInput('Fabric', _fabricController)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildContextInput('Fit', _fitController)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildContextInput('Price', _priceController)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Live Scrollable Chat Feed
              Container(
                height: _obsCaptureMode ? 340 : 220,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  controller: _chatScrollController,
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: msg.isAi ? Colors.amber.withValues(alpha: 0.25) : Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: msg.isAi ? Colors.amberAccent : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${msg.username}: ',
                                  style: TextStyle(
                                    color: msg.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: msg.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Custom Question Input Field & Submit Button
              if (!_obsCaptureMode)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    color: Colors.black45,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _questionController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Ask host about fabric, fit, price, or custom question...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                              filled: true,
                              fillColor: Colors.white12,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: _sendCustomerQuestion,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => _sendCustomerQuestion(_questionController.text),
                          icon: _isAiResponding
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(LucideIcons.send300, size: 18),
                          style: IconButton.styleFrom(backgroundColor: AppColors.gold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.gold, fontSize: 10),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        filled: true,
        fillColor: Colors.black38,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}

class _ObsStreamVideoCanvas extends StatelessWidget {
  const _ObsStreamVideoCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF31103F), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withValues(alpha: 0.15),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Icon(LucideIcons.user300, color: Colors.amber, size: 96),
            ),
            const SizedBox(height: 16),
            const Text(
              'OPENAI GPT-4o-mini LIVESTREAM HOST',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready for OBS Capture · Dynamic Product Context Enabled',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
