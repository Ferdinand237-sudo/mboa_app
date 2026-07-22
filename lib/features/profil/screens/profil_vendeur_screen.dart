import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../logement/screens/logement_detail_screen.dart';
import '../../market/screens/article_detail_screen.dart';
import '../../chat/screens/chat_screen.dart';

class ProfilVendeurScreen extends StatefulWidget {
  final Map<String, dynamic> vendeur;
  const ProfilVendeurScreen({super.key, required this.vendeur});

  @override
  State<ProfilVendeurScreen> createState() => _ProfilVendeurScreenState();
}

class _ProfilVendeurScreenState extends State<ProfilVendeurScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  Map<String, dynamic>? _vendeur;
  bool _isLoading = true;
  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _avis = [];

  String? get _vendeurId => widget.vendeur['id']?.toString();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final id = _vendeurId;
    if (id == null) {
      setState(() {
        _vendeur = widget.vendeur;
        _isLoading = false;
      });
      return;
    }
    try {
      // Un avis est visible s'il a été validé par le propriétaire, ou
      // automatiquement après 72h sans action de sa part.
      final cutoff = DateTime.now().subtract(const Duration(hours: 72));
      final resultats = await Future.wait([
        _supabase.from('users').select().eq('id', id).single(),
        _supabase
            .from('logements')
            .select()
            .eq('proprietaire_id', id)
            .eq('statut', 'disponible')
            .order('date_publication', ascending: false),
        _supabase
            .from('articles')
            .select()
            .eq('vendeur_id', id)
            .eq('statut', 'disponible')
            .order('date_publication', ascending: false),
        _supabase
            .from('avis')
            .select('*, auteur:users!auteur_id(nom)')
            .eq('cible_id', id)
            .or('valide.eq.true,date_publication.lt.${cutoff.toIso8601String()}')
            .order('date_publication', ascending: false),
      ]);
      if (mounted) {
        setState(() {
          _vendeur = Map<String, dynamic>.from(resultats[0] as Map);
          _logements = List<Map<String, dynamic>>.from(resultats[1] as List);
          _articles = List<Map<String, dynamic>>.from(resultats[2] as List);
          _avis = List<Map<String, dynamic>>.from(resultats[3] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _vendeur = widget.vendeur;
          _isLoading = false;
        });
      }
    }
  }

  String get _initiales {
    final nom = (_vendeur?['nom'] ?? '').toString().trim();
    final parts = nom.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (nom.isNotEmpty) return nom[0].toUpperCase();
    return 'U';
  }

  String get _depuis {
    final dateStr = _vendeur?['date_inscription'];
    if (dateStr == null) return '—';
    try {
      return DateTime.parse(dateStr).year.toString();
    } catch (_) {
      return '—';
    }
  }

  void _voirPhoto(String? url, {required String placeholder}) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  errorBuilder: (_, __, ___) => Text(placeholder, style: const TextStyle(fontSize: 60)),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ouvrirItineraire() async {
    final lat = _vendeur?['lat'];
    final lng = _vendeur?['lng'];
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce commerçant n\'a pas encore renseigné l\'emplacement de sa boutique 🙏'),
          backgroundColor: MboaColors.primary,
        ),
      );
      return;
    }
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _appeler() async {
    final tel = _vendeur?['telephone'];
    if (tel == null || tel.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro non renseigné par ce contributeur'),
          backgroundColor: MboaColors.primary,
        ),
      );
      return;
    }
    final url = Uri.parse('tel:$tel');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  Future<void> _envoyerMessage() async {
    final user = _supabase.auth.currentUser;
    final id = _vendeurId;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour envoyer un message'), backgroundColor: MboaColors.primary),
      );
      return;
    }
    if (id == null || id == user.id) return;

    try {
      final existing = await _supabase
          .from('conversations')
          .select()
          .contains('participants', [user.id, id])
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'];
      } else {
        final response = await _supabase
            .from('conversations')
            .insert({
              'participants': [user.id, id],
              'non_lu': {user.id: 0, id: 0},
            })
            .select('id')
            .single();
        conversationId = response['id'];
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: conversationId,
              autreUser: _vendeur ?? {},
              autreId: id,
              sujet: '👤 Profil',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création de la conversation'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MboaColors.background,
        body: Center(child: CircularProgressIndicator(color: MboaColors.primary)),
      );
    }
    final v = _vendeur ?? widget.vendeur;
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: MboaColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: MboaColors.primaryGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () => _voirPhoto(v['photo_url'], placeholder: '👤'),
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                              ),
                              child: v['photo_url'] != null
                                  ? ClipOval(
                                      child: Image.network(v['photo_url'], fit: BoxFit.cover, width: 90, height: 90,
                                          errorBuilder: (_, __, ___) => Center(
                                              child: Text(_initiales,
                                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)))),
                                    )
                                  : Center(
                                      child: Text(_initiales,
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                                    ),
                            ),
                            if (v['verified'] == true)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: MboaColors.verified,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        v['nom'] ?? 'Contributeur',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v['nom_commerce'] ?? 'Contributeur Mboa',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat('${v['note_globale'] ?? 0}', '⭐ Note', Colors.white),
                            _buildDivider(),
                            _buildStat('${v['nb_avis'] ?? 0}', '💬 Avis', Colors.white),
                            _buildDivider(),
                            _buildStat(_depuis, '📅 Depuis', Colors.white),
                            _buildDivider(),
                            _buildStat('${_logements.length + _articles.length}', '📦 Annonces', Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: MboaColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('📦 Annonces (${_logements.length + _articles.length})', 0)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTabButton('⭐ Avis (${_avis.length})', 1)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _voirPhoto(v['photo_commerce'], placeholder: '🏪'),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [MboaColors.secondary.withValues(alpha: 0.3), MboaColors.accent.withValues(alpha: 0.2)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: v['photo_commerce'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(v['photo_commerce'], fit: BoxFit.cover, width: double.infinity,
                                  errorBuilder: (_, __, ___) => const Center(child: Text('🏪', style: TextStyle(fontSize: 50)))),
                            )
                          : const Center(child: Text('🏪', style: TextStyle(fontSize: 50))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('À propos',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: MboaColors.text)),
                  const SizedBox(height: 6),
                  Text(
                    (v['description_commerce'] ?? '').toString().isNotEmpty
                        ? v['description_commerce']
                        : 'Ce contributeur n\'a pas encore ajouté de description.',
                    style: MboaTextStyles.body.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _ouvrirItineraire,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MboaColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MboaColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: MboaColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Text('📍', style: TextStyle(fontSize: 18))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Emplacement boutique',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: MboaColors.text)),
                                Text(
                                  (v['emplacement_commerce'] ?? '').toString().isNotEmpty
                                      ? v['emplacement_commerce']
                                      : (v['lat'] != null ? 'Position GPS enregistrée' : 'Non renseigné par le commerçant'),
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: MboaColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (v['lat'] != null)
                            const Icon(Icons.directions_rounded, color: MboaColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildAnnonces(), _buildAvis()],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: _appeler,
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('Appeler', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: _envoyerMessage,
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('Envoyer un message', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? MboaColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnonces() {
    final total = _logements.length + _articles.length;
    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Aucune annonce publiée pour le moment', style: MboaTextStyles.muted, textAlign: TextAlign.center),
        ),
      );
    }
    final width = MediaQuery.of(context).size.width;
    final columns = AppConstants.gridColumns(width);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        if (index < _logements.length) {
          final l = _logements[index];
          final photos = l['photos'] as List? ?? [];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LogementDetailScreen(logement: l))),
            child: _buildAnnonceCard(l['titre'], l['prix'], photos, '🏠'),
          );
        }
        final a = _articles[index - _logements.length];
        final photos = a['photos'] as List? ?? [];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a))),
          child: _buildAnnonceCard(a['titre'], a['prix'], photos, '📦'),
        );
      },
    );
  }

  Widget _buildAnnonceCard(String? titre, dynamic prix, List photos, String emoji) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(MboaSizes.radiusLg), topRight: Radius.circular(MboaSizes.radiusLg)),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [MboaColors.secondary.withValues(alpha: 0.25), MboaColors.accent.withValues(alpha: 0.15)])),
              child: photos.isNotEmpty
                  ? Image.network(photos[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 44))))
                  : Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: MboaColors.text)),
                  const Spacer(),
                  Text('${(prix ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} F',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: MboaColors.accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvis() {
    final v = _vendeur ?? widget.vendeur;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _avis.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Text('${v['note_globale'] ?? 0}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 48, fontWeight: FontWeight.w800, color: MboaColors.text)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Icon(Icons.star_rounded, size: 24,
                        color: i < ((v['note_globale'] ?? 0) as num).round() ? MboaColors.boost : MboaColors.border),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${_avis.length} avis au total', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: MboaColors.textMuted)),
              ],
            ),
          );
        }
        final a = _avis[index - 1];
        final auteur = a['auteur'] as Map<String, dynamic>?;
        final nom = auteur?['nom'] ?? 'Utilisateur';
        final note = (a['note'] ?? 0) as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: MboaColors.primaryLight.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: Center(
                      child: Text(nom.toString().isNotEmpty ? nom[0].toUpperCase() : 'U',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(nom, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                  ),
                  Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < note ? MboaColors.boost : MboaColors.border))),
                ],
              ),
              if ((a['commentaire'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(a['commentaire'], style: MboaTextStyles.body.copyWith(height: 1.5)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: color.withValues(alpha: 0.75))),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2));
  }
}
