import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AdminAnnoncesScreen extends StatefulWidget {
  const AdminAnnoncesScreen({super.key});

  @override
  State<AdminAnnoncesScreen> createState() =>
      _AdminAnnoncesScreenState();
}

class _AdminAnnoncesScreenState extends State<AdminAnnoncesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _articles = [];
  bool _isLoadingLogements = true;
  bool _isLoadingArticles = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerLogements();
    _chargerArticles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerLogements() async {
    try {
      final data = await _supabase
          .from('logements')
          .select('*, proprietaire:users!proprietaire_id(nom, email)')
          .order('date_publication', ascending: false);
      if (mounted) {
        setState(() {
          _logements = List<Map<String, dynamic>>.from(data);
          _isLoadingLogements = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLogements = false);
    }
  }

  Future<void> _chargerArticles() async {
    try {
      final data = await _supabase
          .from('articles')
          .select('*, vendeur:users!vendeur_id(nom, email)')
          .order('date_publication', ascending: false);
      if (mounted) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(data);
          _isLoadingArticles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingArticles = false);
    }
  }

  Future<void> _toggleBoost(
      String table, String id, bool current) async {
    await _supabase
        .from(table)
        .update({'boosted': !current})
        .eq('id', id);
    if (table == 'logements') {
      _chargerLogements();
    } else {
      _chargerArticles();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !current
                ? '🔥 Annonce boostée !'
                : 'Boost retiré',
          ),
          backgroundColor: !current
              ? MboaColors.boost
              : MboaColors.textMuted,
        ),
      );
    }
  }

  Future<void> _supprimerAnnonce(
      String table, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          '🗑 Supprimer',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Es-tu sûr de vouloir supprimer cette annonce ? Cette action est irréversible.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MboaColors.danger,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.from(table).delete().eq('id', id);
      if (table == 'logements') {
        _chargerLogements();
      } else {
        _chargerArticles();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce supprimée'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _changerStatut(
      String table, String id, String statut) async {
    await _supabase
        .from(table)
        .update({'statut': statut})
        .eq('id', id);
    if (table == 'logements') {
      _chargerLogements();
    } else {
      _chargerArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Annonces',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_logements.length + _articles.length} annonces au total',
                    style: MboaTextStyles.muted,
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: MboaColors.primary,
                    indicatorWeight: 3,
                    labelColor: MboaColors.primary,
                    unselectedLabelColor: MboaColors.textMuted,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      Tab(text: '🏠 Logements (${_logements.length})'),
                      Tab(text: '🛒 Articles (${_articles.length})'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Contenu ──────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Logements
                  _isLoadingLogements
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: MboaColors.primary),
                        )
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _chargerLogements,
                          child: _logements.isEmpty
                              ? _buildEmpty(
                                  'Aucun logement publié')
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _logements.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildAnnonceCard(
                                    annonce: _logements[index],
                                    table: 'logements',
                                    isLogement: true,
                                  ),
                                ),
                        ),

                  // Tab Articles
                  _isLoadingArticles
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: MboaColors.primary),
                        )
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _chargerArticles,
                          child: _articles.isEmpty
                              ? _buildEmpty('Aucun article publié')
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _articles.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildAnnonceCard(
                                    annonce: _articles[index],
                                    table: 'articles',
                                    isLogement: false,
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

  Widget _buildAnnonceCard({
    required Map<String, dynamic> annonce,
    required String table,
    required bool isLogement,
  }) {
    final isBoosted = annonce['boosted'] ?? false;
    final statut = annonce['statut'] ?? 'disponible';
    final vendeur = isLogement
        ? annonce['proprietaire']
        : annonce['vendeur'];
    final signalements = annonce['signalements'] ?? 0;

    Color statutColor;
    switch (statut) {
      case 'disponible':
        statutColor = MboaColors.verified;
        break;
      case 'reserve':
      case 'vendu':
        statutColor = MboaColors.textMuted;
        break;
      default:
        statutColor = MboaColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        border: Border.all(
          color: isBoosted
              ? MboaColors.boost.withValues(alpha: 0.4)
              : signalements > 0
                  ? MboaColors.danger.withValues(alpha: 0.3)
                  : MboaColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titre & statut ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce['titre'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (vendeur != null)
                      Text(
                        'Par ${vendeur['nom'] ?? 'Inconnu'}',
                        style: MboaTextStyles.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          statutColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statut,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statutColor,
                      ),
                    ),
                  ),
                  if (isBoosted) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: MboaColors.boost.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🔥 Boost',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: MboaColors.boost,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Infos ────────────────────────────────
          Row(
            children: [
              if (isLogement) ...[
                _buildInfoChip(
                  '💰',
                  '${annonce['prix'] ?? 0} F',
                  MboaColors.primary,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  '📍',
                  annonce['quartier'] ?? '',
                  MboaColors.textMuted,
                ),
              ] else ...[
                _buildInfoChip(
                  '💰',
                  '${annonce['prix'] ?? 0} F',
                  MboaColors.accent,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  '📦',
                  annonce['categorie'] ?? '',
                  MboaColors.secondary,
                ),
              ],
              const Spacer(),
              if (signalements > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MboaColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          size: 12, color: MboaColors.danger),
                      const SizedBox(width: 4),
                      Text(
                        '$signalements signal.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: MboaColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Actions ──────────────────────────────
          Row(
            children: [
              // Boost
              Expanded(
                child: _buildAdminBtn(
                  icon: isBoosted
                      ? Icons.rocket_rounded
                      : Icons.rocket_launch_outlined,
                  label: isBoosted ? 'Boosté' : 'Booster',
                  color: MboaColors.boost,
                  filled: isBoosted,
                  onTap: () => _toggleBoost(
                      table, annonce['id'], isBoosted),
                ),
              ),
              const SizedBox(width: 8),
              // Statut
              Expanded(
                child: _buildAdminBtn(
                  icon: statut == 'disponible'
                      ? Icons.pause_circle_outlined
                      : Icons.play_circle_outlined,
                  label: statut == 'disponible'
                      ? 'Suspendre'
                      : 'Activer',
                  color: statut == 'disponible'
                      ? MboaColors.textMuted
                      : MboaColors.verified,
                  filled: false,
                  onTap: () => _changerStatut(
                    table,
                    annonce['id'],
                    statut == 'disponible'
                        ? 'reserve'
                        : 'disponible',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Supprimer
              GestureDetector(
                onTap: () =>
                    _supprimerAnnonce(table, annonce['id']),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MboaColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MboaColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: MboaColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: filled
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭',
              style: TextStyle(fontSize: 50)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MboaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}