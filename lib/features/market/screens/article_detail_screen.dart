import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/photo_viewer_fullscreen.dart';
import '../../profil/screens/profil_vendeur_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../chat/screens/chat_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isFavori = false;
  int _currentPhoto = 0;
  final PageController _photoPageController = PageController();
  Timer? _autoScrollTimer;
  List<Map<String, dynamic>> _avis = [];
  bool _isLoadingAvis = true;

  final List<String> _emojisPhotos = ['', '', '', ''];

  @override
  void initState() {
    super.initState();
    _verifierFavori();
    if (widget.article['accepte_avis'] == true) {
      _chargerAvis();
    } else {
      _isLoadingAvis = false;
    }
    final photos = widget.article['photos'] is List
        ? (widget.article['photos'] as List).where((p) => p != null).toList()
        : [];
    if (photos.length > 1) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_photoPageController.hasClients) return;
        final next = (_currentPhoto + 1) % photos.length;
        _photoPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _photoPageController.dispose();
    super.dispose();
  }

  Future<void> _verifierFavori() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('favoris')
          .select()
          .eq('user_id', user.id)
          .eq('article_id', widget.article['id'])
          .maybeSingle();
      if (mounted) setState(() => _isFavori = data != null);
    } catch (_) {}
  }

  Future<void> _toggleFavori() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour ajouter aux favoris'),
          backgroundColor: MboaColors.primary,
        ),
      );
      return;
    }
    final nouveauStatut = !_isFavori;
    setState(() => _isFavori = nouveauStatut);
    try {
      if (nouveauStatut) {
        await _supabase.from('favoris').insert({
          'user_id': user.id,
          'article_id': widget.article['id'],
        });
      } else {
        await _supabase
            .from('favoris')
            .delete()
            .eq('user_id', user.id)
            .eq('article_id', widget.article['id']);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavori = !nouveauStatut);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  Future<void> _chargerAvis() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 72));
      final data = await _supabase
          .from('avis')
          .select('*, auteur:users!auteur_id(nom)')
          .eq('annonce_id', widget.article['id'])
          .or('valide.eq.true,date_publication.lt.${cutoff.toIso8601String()}')
          .order('date_publication', ascending: false);
      if (mounted) {
        setState(() {
          _avis = List<Map<String, dynamic>>.from(data);
          _isLoadingAvis = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAvis = false);
    }
  }

  Future<void> _laisserAvis() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour laisser un avis'), backgroundColor: MboaColors.primary),
      );
      return;
    }
    final vendeurId = widget.article['vendeur_id'];
    if (vendeurId == null || vendeurId == userId) return;

    int noteSelectionnee = 5;
    final commentaireController = TextEditingController();

    final envoye = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusLg)),
          title: const Text('⭐ Laisser un avis',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Votre expérience avec cet article', style: MboaTextStyles.bodySm),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final valeur = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => noteSelectionnee = valeur),
                    icon: Icon(
                      valeur <= noteSelectionnee ? Icons.star_rounded : Icons.star_border_rounded,
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Envoyer')),
          ],
        ),
      ),
    );

    if (envoye != true) return;

    try {
      await _supabase.from('avis').insert({
        'auteur_id': userId,
        'cible_id': vendeurId,
        'annonce_id': widget.article['id'],
        'note': noteSelectionnee,
        'commentaire': commentaireController.text.trim(),
        'valide': false,
      });

      final avisData = await _supabase.from('avis').select('note').eq('cible_id', vendeurId);
      final notes = List<Map<String, dynamic>>.from(avisData);
      if (notes.isNotEmpty) {
        final total = notes.fold<int>(0, (sum, a) => sum + ((a['note'] ?? 0) as int));
        await _supabase.from('users').update({
          'note_globale': double.parse((total / notes.length).toStringAsFixed(1)),
          'nb_avis': notes.length,
        }).eq('id', vendeurId);
      }

      _chargerAvis();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci ! Votre avis sera visible dès validation par le vendeur (ou sous 72h).'),
            backgroundColor: MboaColors.verified,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi de l\'avis'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  Future<void> _appelerVendeur() async {
    var tel = widget.article['vendeur']?['telephone'];
    if (tel == null) {
      final vendeurId = widget.article['vendeur_id'];
      if (vendeurId != null) {
        try {
          final data = await _supabase.from('users').select('telephone').eq('id', vendeurId).single();
          tel = data['telephone'];
        } catch (_) {}
      }
    }
    if (tel == null || tel.toString().trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro non renseigné par le vendeur'), backgroundColor: MboaColors.primary),
        );
      }
      return;
    }
    final url = Uri.parse('tel:$tel');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  void _signalerArticle() {
    final raisons = [
      'Fausse annonce',
      'Arnaque',
      'Prix incorrect',
      'Contenu inapproprié',
      'Annonce dupliquée',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🚨 Signaler cet article',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
              const SizedBox(height: 14),
              ...raisons.map((r) => GestureDetector(
                    onTap: () async {
                      final userId = _supabase.auth.currentUser?.id;
                      Navigator.pop(context);
                      if (userId == null) return;
                      try {
                        await _supabase.from('signalements').insert({
                          'signaleur_id': userId,
                          'cible_type': 'annonce',
                          'cible_id': widget.article['id'],
                          'raison': r,
                          'statut': 'en-attente',
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signalement envoyé. Merci !'), backgroundColor: MboaColors.primary),
                          );
                        }
                      } catch (_) {}
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: MboaColors.border)),
                      ),
                      child: Text(r, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: MboaColors.text)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrix(int prix) {
    return prix
            .toString()
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            ) +
        ' FCFA';
  }

  String _getArticleDescription(Map<String, dynamic> a) {
    final description = a['description']?.toString().trim();
    return description != null && description.isNotEmpty
        ? description
        : 'Aucune description disponible.';
  }

  String _getArticleLocation(Map<String, dynamic> a) {
    final quartier = a['quartier']?.toString().trim();
    final ville = a['ville']?.toString().trim();
    final adresse = a['adresse_approx']?.toString().trim();

    if (quartier != null && quartier.isNotEmpty && ville != null && ville.isNotEmpty) {
      return '$quartier, $ville';
    }
    if (adresse != null && adresse.isNotEmpty) {
      return adresse;
    }
    if (quartier != null && quartier.isNotEmpty) {
      return quartier;
    }
    if (ville != null && ville.isNotEmpty) {
      return ville;
    }
    if (a['lat'] != null && a['lng'] != null) {
      return '${a['lat']}, ${a['lng']}';
    }
    return 'Localisation inconnue';
  }

  String _formatPublicationDate(dynamic publishedAt) {
    if (publishedAt == null) return 'Date inconnue';
    try {
      final date = publishedAt is String
          ? DateTime.parse(publishedAt)
          : publishedAt as DateTime;
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 1) {
        return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      }
      if (diff.inHours >= 1) {
        return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
      }
      if (diff.inMinutes >= 1) {
        return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
      }
      return 'À l’instant';
    } catch (_) {
      return 'Date inconnue';
    }
  }

  final _supabase = Supabase.instance.client;

  Future<void> _ouvrirChat() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour envoyer un message'),
          backgroundColor: MboaColors.primary,
        ),
      );
      return;
    }

    final article = widget.article;
    final vendeurId = article['vendeur_id'];

    if (vendeurId == null || vendeurId == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas vous contacter vous-même'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }

    try {
      final existing = await _supabase
          .from('conversations')
          .select()
          .contains('participants', [user.id, vendeurId])
          .eq('annonce_id', article['id'])
          .maybeSingle();

      String conversationId;

      if (existing != null) {
        conversationId = existing['id'];
      } else {
        final response = await _supabase
            .from('conversations')
            .insert({
              'participants': [user.id, vendeurId],
              'annonce_id': article['id'],
              'annonce_type': 'article',
              'non_lu': {user.id: 0, vendeurId: 0},
            })
            .select('id')
            .single();
        conversationId = response['id'];
      }

      Map<String, dynamic> autreUser = {};
      try {
        autreUser = await _supabase
            .from('users')
            .select('nom, photo_url, verified')
            .eq('id', vendeurId)
            .single();
      } catch (_) {
        final vendeur = article['vendeur'];
        if (vendeur is Map) {
          autreUser = Map<String, dynamic>.from(vendeur);
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: conversationId,
              autreUser: autreUser,
              autreId: vendeurId,
              sujet: '🛒 ${article['titre'] ?? 'Article'}',
              annonceId: article['id']?.toString(),
              annonceType: 'article',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    }
  }

  Color get _etatColor {
    switch (widget.article['etat']) {
      case 'Neuf':
        return MboaColors.verified;
      case 'Très bon état':
        return MboaColors.primary;
      case 'Bon état':
        return MboaColors.primaryLight;
      default:
        return MboaColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final emoji = a['emoji']?.toString() ?? '🛍';
    final photos = a['photos'] is List
        ? (a['photos'] as List).where((p) => p != null).map((p) => p.toString()).toList()
        : <String>[];
    final vendeurData = a['vendeur'];
    final vendeurNom = vendeurData is Map
        ? vendeurData['nom']?.toString() ?? 'Vendeur'
        : vendeurData?.toString() ?? 'Vendeur';
    final vendeurInitiales = vendeurNom
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();
    final vendeurVerified = vendeurData is Map
        ? vendeurData['verified'] == true
        : false;
    final vendeurNote = a['vendeurNote'] ??
        (vendeurData is Map ? vendeurData['note_globale'] : 0);
    final emojiValue = emoji;
    if (photos.isEmpty) {
      _emojisPhotos[0] = emojiValue;
      _emojisPhotos[1] = emojiValue;
      _emojisPhotos[2] = emojiValue;
      _emojisPhotos[3] = emojiValue;
    }

    return Scaffold(
      backgroundColor: MboaColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Galerie ──────────────────────────────
                _buildGalerie(a),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Titre & état ─────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              a['titre'],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: MboaColors.text,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _etatColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _etatColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              a['etat'],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _etatColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Catégorie
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MboaColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              a['categorie'],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MboaColors.secondary,
                              ),
                            ),
                          ),
                          if (a['negociable']) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: MboaColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '💬 Prix négociable',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: MboaColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Prix
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              MboaColors.accent,
                              MboaColors.secondary,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusLg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prix de vente',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrix(a['prix']),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (a['negociable'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Négociable',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Description ──────────────────
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          _getArticleDescription(a),
                          style: MboaTextStyles.body.copyWith(height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Vendeur ──────────────────────
                      _buildSectionTitle('👤 Vendeur'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilVendeurScreen(
                              vendeur: {
                                'id': a['vendeur_id'],
                                'nom': vendeurNom,
                                'initiales': vendeurInitiales,
                                'type': 'Commerçant',
                                'verified': vendeurVerified,
                              },
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                MboaSizes.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: MboaColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    vendeurInitiales,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendeurNom,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: MboaColors.text,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 13,
                                            color: MboaColors.boost),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${vendeurNote ?? 0}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: MboaColors.text,
                                          ),
                                        ),
                                        Text(
                                          '  ·  Voir le profil →',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: MboaColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Infos supplémentaires ────────
                      _buildSectionTitle('ℹ️ Informations'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('📦', 'Catégorie',
                                a['categorie']?.toString() ?? 'N/A'),
                            _buildInfoRow(
                                '🏷️', 'État', a['etat']?.toString() ?? 'N/A'),
                            _buildInfoRow('📍', 'Localisation',
                                _getArticleLocation(a)),
                            _buildInfoRow('📅', 'Publié',
                                _formatPublicationDate(a['date_publication']),
                                isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Avis (uniquement si le vendeur les autorise) ──
                      if (a['accepte_avis'] == true) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('⭐ Avis (${_avis.length})'),
                            GestureDetector(
                              onTap: _laisserAvis,
                              child: const Text(
                                'Laisser un avis',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: MboaColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _isLoadingAvis
                            ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
                            : _avis.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                                    ),
                                    child: Center(
                                      child: Text('Aucun avis pour le moment', style: MboaTextStyles.muted),
                                    ),
                                  )
                                : Column(
                                    children: _avis.map((avis) {
                                      final auteur = avis['auteur'] as Map<String, dynamic>? ?? {};
                                      final nom = auteur['nom'] ?? 'Utilisateur';
                                      final note = (avis['note'] ?? 0) as int;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(nom,
                                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                                                ),
                                                Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < note ? MboaColors.boost : MboaColors.border))),
                                              ],
                                            ),
                                            if ((avis['commentaire'] ?? '').toString().isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(avis['commentaire'], style: MboaTextStyles.body.copyWith(height: 1.5)),
                                            ],
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                      ],

                      const SizedBox(height: 12),

                      // Signaler
                      Center(
                        child: TextButton.icon(
                          onPressed: _signalerArticle,
                          icon: const Icon(Icons.flag_outlined,
                              size: 16, color: MboaColors.danger),
                          label: const Text(
                            'Signaler cet article',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: MboaColors.danger,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Boutons fixes ──────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _appelerVendeur,
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Appeler', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _ouvrirChat(),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: const Text('Contacter le vendeur', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Back button ────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: MboaColors.text),
              ),
            ),
          ),

          // ── Favori button ──────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: _toggleFavori,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _isFavori
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: MboaColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalerie(Map<String, dynamic> a) {
    final photos = a['photos'] is List
        ? (a['photos'] as List).where((p) => p != null).map((p) => p.toString()).toList()
        : <String>[];
    final displayCount = photos.isNotEmpty ? photos.length : 1;

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _photoPageController,
            itemCount: displayCount,
            onPageChanged: (i) => setState(() => _currentPhoto = i),
            itemBuilder: (context, index) {
              if (photos.isEmpty) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MboaColors.secondary.withValues(alpha: 0.4),
                        MboaColors.accent.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _emojisPhotos[index],
                      style: const TextStyle(fontSize: 100),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => PhotoViewerFullscreen.ouvrir(
                    context, photos, index,
                    placeholder: _emojisPhotos[0]),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    image: DecorationImage(
                      image: NetworkImage(photos[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPhoto + 1} / $displayCount',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (a['boosted'])
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: MboaColors.boost.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🔥 Annonce boostée',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: MboaColors.text,
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: MboaColors.textMuted,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MboaColors.text,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16),
      ],
    );
  }
}