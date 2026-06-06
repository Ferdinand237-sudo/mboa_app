import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'nom': 'Jean-Paul M.',
      'initiales': 'JP',
      'dernierMsg': 'La chambre est toujours disponible !',
      'heure': '10:23',
      'nonLu': 2,
      'verified': true,
      'sujet': 'Chambre meublée - Centre ville',
      'emoji': '🏠',
    },
    {
      'id': '2',
      'nom': 'Meublé Express',
      'initiales': 'ME',
      'dernierMsg': 'Oui on livre à domicile 😊',
      'heure': 'Hier',
      'nonLu': 0,
      'verified': true,
      'sujet': 'Armoire 3 portes',
      'emoji': '🗄️',
    },
    {
      'id': '3',
      'nom': 'Marie T.',
      'initiales': 'MT',
      'dernierMsg': 'Vous pouvez visiter demain à 14h',
      'heure': 'Hier',
      'nonLu': 1,
      'verified': false,
      'sujet': 'Studio moderne - Nkol-Eton',
      'emoji': '🏢',
    },
    {
      'id': '4',
      'nom': 'Aminata D.',
      'initiales': 'AD',
      'dernierMsg': 'D\'accord je vous attends !',
      'heure': 'Lun',
      'nonLu': 0,
      'verified': false,
      'sujet': 'Table de travail + chaise',
      'emoji': '🪑',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💬 Messages',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.text,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MboaColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_conversations.where((c) => c['nonLu'] > 0).length} non lus',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Liste conversations ───────────────────────────
            Expanded(
              child: _conversations.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 80,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        return _buildConversationTile(
                            _conversations[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv) {
    final hasUnread = conv['nonLu'] > 0;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ConversationScreen(conversation: conv),
        ),
      ),
      child: Container(
        color: hasUnread
            ? MboaColors.primary.withValues(alpha: 0.03)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: MboaColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      conv['initiales'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Icône annonce
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: MboaColors.border, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        conv['emoji'],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            conv['nom'],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: MboaColors.text,
                            ),
                          ),
                          if (conv['verified']) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: MboaColors.verified,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        conv['heure'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: hasUnread
                              ? MboaColors.primary
                              : MboaColors.textMuted,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv['sujet'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: MboaColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv['dernierMsg'],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: hasUnread
                                ? MboaColors.text
                                : MboaColors.textMuted,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: MboaColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${conv['nonLu']}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💬', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MboaColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tes conversations apparaîtront ici',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: MboaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ÉCRAN DE CONVERSATION
// ════════════════════════════════════════════════════════════
class _ConversationScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  const _ConversationScreen({required this.conversation});

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'texte': 'Bonjour ! La chambre est-elle toujours disponible ?',
      'moi': false,
      'heure': '10:15',
      'lu': true,
    },
    {
      'texte': 'Oui toujours disponible ! Vous pouvez visiter quand vous voulez.',
      'moi': true,
      'heure': '10:18',
      'lu': true,
    },
    {
      'texte': 'Super ! Quel est le montant de la caution ?',
      'moi': false,
      'heure': '10:20',
      'lu': true,
    },
    {
      'texte': 'La caution est d\'un mois de loyer soit 20 000 FCFA.',
      'moi': true,
      'heure': '10:21',
      'lu': true,
    },
    {
      'texte': 'La chambre est toujours disponible !',
      'moi': true,
      'heure': '10:23',
      'lu': false,
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'texte': _messageController.text.trim(),
        'moi': false,
        'heure': 'Maintenant',
        'lu': false,
      });
      _messageController.clear();
    });
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

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: MboaColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: MboaColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conv['initiales'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      conv['nom'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    if (conv['verified']) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: MboaColors.verified),
                    ],
                  ],
                ),
                const Text(
                  '● En ligne',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: MboaColors.verified,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: MboaColors.text),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MboaColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  conv['emoji'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    conv['sujet'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MboaColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Barre de saisie
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MboaColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: MboaColors.border),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Écrire un message...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: MboaTextStyles.body,
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: MboaColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMoi = msg['moi'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMoi) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: MboaColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.conversation['initiales'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMoi ? MboaColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMoi ? 16 : 4),
                  bottomRight: Radius.circular(isMoi ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMoi
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['texte'],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isMoi ? Colors.white : MboaColors.text,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg['heure'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: isMoi
                              ? Colors.white.withValues(alpha: 0.7)
                              : MboaColors.textMuted,
                        ),
                      ),
                      if (isMoi) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg['lu']
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 13,
                          color: msg['lu']
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}