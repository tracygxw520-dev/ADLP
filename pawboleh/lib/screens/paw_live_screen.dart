import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  const _ChatMessage(this.username, this.message, this.color);
  final String username;
  final String message;
  final Color color;
}

/// Paw Live tab content — a livestream control surface with viewer chat,
/// admin quick-reply chips, and a message composer. Rendered as a tab
/// body inside MainShell (no own Scaffold; the shell paints black behind
/// the live tab).
class PawLiveView extends StatefulWidget {
  const PawLiveView({super.key});

  @override
  State<PawLiveView> createState() => _PawLiveViewState();
}

class _PawLiveViewState extends State<PawLiveView>
    with SingleTickerProviderStateMixin {
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  late final AnimationController _pulseController;

  final List<_ChatMessage> _chatMessages = const [
    _ChatMessage('deniyanti', 'Boleh DM saya harga tak?', Color(0xFF60A5FA)),
    _ChatMessage('camry', 'How now, size L available?', Color(0xFFF472B6)),
    _ChatMessage('siti_amira', 'Is this available in size M?', Color(0xFFFBBF24)),
    _ChatMessage('aina.boutique', 'Does it come with the shawl?', Color(0xFF34D399)),
    _ChatMessage('zul.hakim', 'Price for bundle of 2?', Color(0xFF60A5FA)),
    _ChatMessage('mira_wardrobe', 'Fast ship to Penang?', Color(0xFFF472B6)),
  ];

  final List<String> _quickReplies = const [
    'Ready stock',
    'Bundle promo',
    'Size chart',
    'Fabric detail',
    'Discount code',
    'Admin',
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
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleQuickReply(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI host cued: "$label"'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    // Demo data is static; wire this to a real chat/message store in production.
    _messageController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _LiveVideoPlaceholder(),

        // Scrim for legibility of overlays
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
        ),

        // Top bar: title + LIVE badge + viewer count
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Paw Live',
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontSize: 17),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glow = 6 + (_pulseController.value * 10);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.liveRed,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.liveRed.withValues(alpha: 0.6),
                            blurRadius: glow,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: AppTextStyles.chipLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                const Icon(Icons.remove_red_eye_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text('1.2K', style: AppTextStyles.chatMessage.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),

        // Scrolling viewer chat feed, lower half of the screen
        Positioned(
          left: 0,
          right: 90,
          bottom: 220,
          top: MediaQuery.of(context).size.height * 0.42,
          child: _ChatFeed(controller: _chatScrollController, messages: _chatMessages),
        ),

        // Pinned bottom panel: admin quick-reply chips + message composer
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin quick-reply',
                    style: AppTextStyles.chipLabel.copyWith(color: Colors.white70, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickReplies.asMap().entries.map((entry) {
                      final isFirst = entry.key == 0;
                      final label = entry.value;
                      return ActionChip(
                        label: Text(
                          label,
                          style: AppTextStyles.chipLabel.copyWith(
                            color: isFirst ? AppColors.textPrimary : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: isFirst ? Colors.white : Colors.white.withValues(alpha: 0.16),
                        side: BorderSide(color: Colors.white.withValues(alpha: isFirst ? 0 : 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        onPressed: () => _handleQuickReply(label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Send a message...',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Send voice cue',
                          child: InkWell(
                            onTap: _sendMessage,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.mic_rounded, color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder for the AI avatar livestream video feed.
class _LiveVideoPlaceholder extends StatelessWidget {
  const _LiveVideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Live video feed of AI digital avatar in a fashion boutique',
      image: true,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D2A26), Color(0xFF1A1816)],
          ),
        ),
        child: Center(
          child: Icon(Icons.person_outline_rounded, color: Colors.white.withValues(alpha: 0.16), size: 160),
        ),
      ),
    );
  }
}

class _ChatFeed extends StatelessWidget {
  const _ChatFeed({required this.controller, required this.messages});

  final ScrollController controller;
  final List<_ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Viewer chat feed',
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black, Colors.black],
            stops: [0.0, 0.15, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: controller,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[messages.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${msg.username}  ',
                        style: AppTextStyles.chatUsername.copyWith(color: msg.color),
                      ),
                      TextSpan(text: msg.message, style: AppTextStyles.chatMessage),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
