import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerConversations();
  }

  Future<void> _chargerConversations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _supabase
          .from('conversations')
          .select('*')
          .contains('participants', [user.id])
          .order('dernier_message_date', ascending: false);

      if (data.isEmpty) {
        if (mounted) {
          setState(() {
            _conversations = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Extraire tous les IDs des autres participants pour une seule requête groupée
      final idsParticipants = data.map((conv) {
        final parts = List<String>.from(conv['participants']);
        return parts.firstWhere((id) => id != user.id, orElse: () => user.id);
      }).toSet().toList();

      // Récupérer tous les profils en une seule fois (Optimisation N+1)
      final usersData = await _supabase
          .from('users')
          .select('id, nom, photo_url, verified')
          .filter('id', 'in', idsParticipants);

      final mapUsers = {for (var u in usersData) u['id']: u};

      final enriched = <Map<String, dynamic>>[];
      for (final conv in data) {
        final autreId = List<String>.from(conv['participants'])
            .firstWhere((id) => id != user.id, orElse: () => user.id);
        
        enriched.add({
          ...conv,
          'autre_user': mapUsers[autreId] ?? {'nom': 'Utilisateur'},
          'autre_id': autreId,
        });
      }

      if (mounted) {
        setState(() {
          _conversations = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatHeure(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Hier';
      } else if (diff.inDays < 7) {
        const jours = [
          '', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
        ];
        return jours[date.weekday];
      }
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  String _getInitiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (nom.isNotEmpty) return nom[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
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
                  if (_conversations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MboaColors.primary
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_conversations.length} conversation${_conversations.length > 1 ? 's' : ''}',
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

            // ── Contenu ──────────────────────────────
            Expanded(
              child: user == null
                  ? _buildNotConnected()
                  : _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: MboaColors.primary),
                        )
                      : _conversations.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: MboaColors.primary,
                              onRefresh:
                                  _chargerConversations,
                              child: ListView.separated(
                                itemCount:
                                    _conversations.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(
                                  height: 1,
                                  indent: 80,
                                  endIndent: 20,
                                ),
                                itemBuilder:
                                    (context, index) =>
                                        _buildConversationTile(
                                  _conversations[index],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
      Map<String, dynamic> conv) {
    final autreUser = conv['autre_user']
        as Map<String, dynamic>? ?? {};
    final nom = autreUser['nom'] ?? 'Utilisateur';
    final isVerified =
        autreUser['verified'] == true;
    final nonLu = conv['non_lu'];
    final userId =
        _supabase.auth.currentUser?.id ?? '';
    int nbNonLu = 0;
    if (nonLu is Map) {
      nbNonLu = (nonLu[userId] ?? 0) as int;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: conv['id'],
              autreUser: autreUser,
              autreId: conv['autre_id'],
              sujet: conv['annonce_type'] == 'logement'
                  ? '🏠 Logement'
                  : '🛒 Article',
            ),
          ),
        );
        _chargerConversations();
      },
      child: Container(
        color: nbNonLu > 0
            ? MboaColors.primary.withValues(alpha: 0.03)
            : Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: MboaColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitiales(nom),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
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
                          color: MboaColors.border),
                    ),
                    child: const Center(
                      child: Text('💬',
                          style:
                              TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            nom,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: nbNonLu > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: MboaColors.text,
                            ),
                          ),
                          if (isVerified) ...[
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
                        _formatHeure(
                            conv['dernier_message_date']),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: nbNonLu > 0
                              ? MboaColors.primary
                              : MboaColors.textMuted,
                          fontWeight: nbNonLu > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv['dernier_message'] ??
                              'Conversation démarrée',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: nbNonLu > 0
                                ? MboaColors.text
                                : MboaColors.textMuted,
                            fontWeight: nbNonLu > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (nbNonLu > 0) ...[
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
                              '$nbNonLu',
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

  Widget _buildNotConnected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬',
                style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'Vos conversations',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MboaColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour envoyer des messages aux vendeurs et propriétaires',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: MboaColors.textMuted,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
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
          const Text('💬',
              style: TextStyle(fontSize: 60)),
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
            'Contacte un vendeur depuis une annonce\npour démarrer une conversation',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: MboaColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ÉCRAN DE CONVERSATION TEMPS RÉEL
// ════════════════════════════════════════════════════════════
class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> autreUser;
  final String autreId;
  final String sujet;
  final String? annonceId;
  final String? annonceType;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.autreUser,
    required this.autreId,
    required this.sujet,
    this.annonceId,
    this.annonceType,
  });

  @override
  State<ConversationScreen> createState() =>
      ConversationScreenState();
}

class ConversationScreenState extends State<ConversationScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerMessages();
    _ecouterMessages();
    _marquerLus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _supabase.removeChannel(
      _supabase.channel('conv_${widget.conversationId}'),
    );
    super.dispose();
  }

  Future<void> _chargerMessages() async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('date_envoi', ascending: true);

      if (mounted) {
        setState(() {
          _messages =
              List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

 void _ecouterMessages() {
    _supabase
        .channel('conv_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord['conversation_id'] ==
                widget.conversationId) {
              if (mounted) {
                setState(() {
                  _messages.add(
                      Map<String, dynamic>.from(newRecord));
                });
                _scrollToBottom();
                _marquerLus();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _marquerLus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase
          .from('messages')
          .update({'lu': true})
          .eq('conversation_id',
              widget.conversationId)
          .neq('expediteur_id', userId);
    } catch (_) {}
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

  Future<void> _envoyerMessage() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'expediteur_id': userId,
        'texte': texte,
      });

      await _supabase
          .from('conversations')
          .update({
            'dernier_message': texte,
            'dernier_message_date':
                DateTime.now().toIso8601String(),
          })
          .eq('id', widget.conversationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur d\'envoi'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    }
  }

  String _getInitiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (nom.isNotEmpty) return nom[0].toUpperCase();
    return 'U';
  }

  String _formatHeure(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _ouvrirFormulaireAvis() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    int noteSelectionnee = 5;
    final commentaireController = TextEditingController();

    final envoye = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          ),
          title: const Text(
            '⭐ Laisser un avis',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: MboaColors.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre expérience avec ${widget.autreUser['nom'] ?? 'cet utilisateur'}',
                style: MboaTextStyles.bodySm,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final valeur = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(
                        () => noteSelectionnee = valeur),
                    icon: Icon(
                      valeur <= noteSelectionnee
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: MboaColors.boost,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentaireController,
                maxLines: 3,
                style: MboaTextStyles.bodySm,
                decoration: InputDecoration(
                  hintText: 'Votre commentaire (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MboaSizes.radiusMd),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );

    if (envoye != true) return;

    try {
      await _supabase.from('avis').insert({
        'auteur_id': userId,
        'cible_id': widget.autreId,
        'annonce_id': widget.annonceId,
        'note': noteSelectionnee,
        'commentaire': commentaireController.text.trim(),
        'valide': true,
      });

      await _recalculerNoteGlobale(widget.autreId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre avis !'),
            backgroundColor: MboaColors.verified,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'avis'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _recalculerNoteGlobale(String cibleId) async {
    final avisData = await _supabase
        .from('avis')
        .select('note')
        .eq('cible_id', cibleId)
        .eq('valide', true);

    final notes = List<Map<String, dynamic>>.from(avisData);
    if (notes.isEmpty) return;

    final total = notes.fold<int>(
        0, (sum, a) => sum + ((a['note'] ?? 0) as int));
    final moyenne = total / notes.length;

    await _supabase.from('users').update({
      'note_globale': double.parse(moyenne.toStringAsFixed(1)),
      'nb_avis': notes.length,
    }).eq('id', cibleId);
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        _supabase.auth.currentUser?.id ?? '';
    final nom =
        widget.autreUser['nom'] ?? 'Utilisateur';
    final isVerified =
        widget.autreUser['verified'] == true;

    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: MboaColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Laisser un avis',
            onPressed: _ouvrirFormulaireAvis,
            icon: const Icon(
              Icons.star_rate_rounded,
              color: MboaColors.boost,
            ),
          ),
        ],
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
                  _getInitiales(nom),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: MboaColors.verified),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
                16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MboaColors.primary
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.sujet,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MboaColors.primary,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: MboaColors.primary),
                  )
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Démarrez la conversation 👋',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: MboaColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) =>
                            _buildMessage(
                                _messages[index],
                                userId),
                      ),
          ),

          // Barre saisie
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
                16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MboaColors.background,
                      borderRadius:
                          BorderRadius.circular(24),
                      border: Border.all(
                          color: MboaColors.border),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller:
                                _messageController,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'Écrire un message...',
                              border: InputBorder.none,
                              enabledBorder:
                                  InputBorder.none,
                              focusedBorder:
                                  InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(
                                      vertical: 12),
                            ),
                            style: MboaTextStyles.body,
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: (_) =>
                                _envoyerMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _envoyerMessage,
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

  Widget _buildMessage(
      Map<String, dynamic> msg, String userId) {
    final isMoi = msg['expediteur_id'] == userId;
    final nom =
        widget.autreUser['nom'] ?? 'U';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMoi
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
                  _getInitiales(nom),
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
                color: isMoi
                    ? MboaColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      Radius.circular(isMoi ? 16 : 4),
                  bottomRight:
                      Radius.circular(isMoi ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.06),
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
                    msg['texte'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isMoi
                          ? Colors.white
                          : MboaColors.text,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatHeure(
                            msg['date_envoi']),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: isMoi
                              ? Colors.white
                                  .withValues(alpha: 0.7)
                              : MboaColors.textMuted,
                        ),
                      ),
                      if (isMoi) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg['lu'] == true
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 13,
                          color: msg['lu'] == true
                              ? Colors.white
                              : Colors.white
                                  .withValues(alpha: 0.6),
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