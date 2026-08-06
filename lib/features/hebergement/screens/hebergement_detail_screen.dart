import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/photo_viewer_fullscreen.dart';

class HebergementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> hebergement;
  const HebergementDetailScreen({super.key, required this.hebergement});

  @override
  State<HebergementDetailScreen> createState() => _HebergementDetailScreenState();
}

class _HebergementDetailScreenState extends State<HebergementDetailScreen> {
  final _supabase = Supabase.instance.client;
  int _currentPhoto = 0;

  List<Map<String, dynamic>> _avis = [];
  bool _isLoadingAvis = true;
  double _noteProprietaire = 0;
  int _nbAvisProprietaire = 0;
  Map<String, dynamic>? _proprietaire;

  // Affiché immédiatement en local (widget.hebergement reste figé sur la
  // valeur au moment de l'ouverture) pendant que l'incrément atomique part
  // côté serveur — même pattern que logement/article_detail_screen.
  late int _vues = (widget.hebergement['vues'] ?? 0) as int;

  @override
  void initState() {
    super.initState();
    _incrementerVues();
    _chargerAvis();
    _chargerProprietaire();
  }

  Future<void> _incrementerVues() async {
    final id = widget.hebergement['id'];
    if (id == null) return;
    try {
      await _supabase.rpc('increment_vues_hebergement', params: {'p_id': id});
      if (mounted) setState(() => _vues++);
    } catch (_) {}
  }

  Future<void> _chargerProprietaire() async {
    final proprietaireId = widget.hebergement['proprietaire_id'];
    if (proprietaireId == null) return;
    try {
      final data = await _supabase
          .from('users')
          .select('nom, nom_commerce, photo_commerce, verified, note_globale, nb_avis, telephone')
          .eq('id', proprietaireId)
          .single();
      if (mounted) {
        setState(() {
          _proprietaire = data;
          _noteProprietaire = (data['note_globale'] ?? 0).toDouble();
          _nbAvisProprietaire = (data['nb_avis'] ?? 0) as int;
        });
      }
    } catch (_) {}
  }

  Future<void> _chargerAvis() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 72));
      final data = await _supabase
          .from('avis')
          .select('*, auteur:users!auteur_id(nom)')
          .eq('annonce_id', widget.hebergement['id'])
          .or('valide.eq.true,date_publication.lt.${cutoff.toIso8601String()}')
          .order('date_publication', ascending: false);
      if (mounted) {
        setState(() {
          _avis = List<Map<String, dynamic>>.from(data);
          _isLoadingAvis = false;
        });
      }
    } catch (_) {
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
    final proprietaireId = widget.hebergement['proprietaire_id'];
    if (proprietaireId == null || proprietaireId == userId) return;

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
              Text('Votre séjour dans cet établissement', style: MboaTextStyles.bodySm),
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
        'cible_id': proprietaireId,
        'annonce_id': widget.hebergement['id'],
        'note': noteSelectionnee,
        'commentaire': commentaireController.text.trim(),
        'valide': false,
      });
      _chargerAvis();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci ! Votre avis sera visible dès validation par l\'établissement (ou sous 72h).'),
            backgroundColor: MboaColors.verified,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi de l\'avis'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  Future<void> _demanderReservation() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour réserver'), backgroundColor: MboaColors.primary),
      );
      return;
    }
    final proprietaireId = widget.hebergement['proprietaire_id'];
    if (proprietaireId == null || proprietaireId == userId) return;

    DateTimeRange? plage;
    int nbPersonnes = 1;
    final messageController = TextEditingController();

    final envoyer = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(MboaSizes.radiusXl)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📅 Demander une réservation',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
                const SizedBox(height: 4),
                Text(
                  'L\'établissement confirmera ou refusera ta demande — le paiement se fait directement avec lui.',
                  style: MboaTextStyles.caption,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: sheetContext,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      initialDateRange: plage,
                    );
                    if (picked != null) setSheetState(() => plage = picked);
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    plage == null
                        ? 'Choisir les dates'
                        : '${plage!.start.day}/${plage!.start.month} → ${plage!.end.day}/${plage!.end.month}',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Personnes', style: MboaTextStyles.bodySm),
                    const Spacer(),
                    IconButton(
                      onPressed: nbPersonnes > 1 ? () => setSheetState(() => nbPersonnes--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: MboaColors.primary,
                    ),
                    Text('$nbPersonnes',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => setSheetState(() => nbPersonnes++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: MboaColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Message pour l\'établissement (optionnel)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: MboaSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: plage == null ? null : () => Navigator.pop(sheetContext, true),
                    child: const Text('Envoyer la demande'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (envoyer != true || plage == null) return;

    try {
      await _supabase.from(AppConstants.tableReservations).insert({
        'hebergement_id': widget.hebergement['id'],
        'visiteur_id': userId,
        'proprietaire_id': proprietaireId,
        'date_debut': plage!.start.toIso8601String().split('T').first,
        'date_fin': plage!.end.toIso8601String().split('T').first,
        'nb_personnes': nbPersonnes,
        'message': messageController.text.trim().isEmpty ? null : messageController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande envoyée ! Suis sa réponse dans Profil > Mes réservations.'),
            backgroundColor: MboaColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  String _libelleType(String? valeur) {
    final match = AppConstants.typesEtablissement.firstWhere(
      (t) => t['valeur'] == valeur,
      orElse: () => {'icon': '🏨', 'label': 'Établissement'},
    );
    return '${match['icon']} ${match['label']}';
  }

  String _getInitiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1 ? '${parts[0][0]}${parts[1][0]}'.toUpperCase() : parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hebergement;
    final photos = h['photos'] as List? ?? [];
    final equipements = h['equipements'] as List? ?? [];
    final nomEtablissement = _proprietaire?['nom_commerce'] ?? _proprietaire?['nom'] ?? 'Établissement';

    return Scaffold(
      backgroundColor: MboaColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Galerie ──────────────────────────
                SizedBox(
                  height: 280,
                  child: photos.isEmpty
                      ? Container(
                          decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                          child: const Center(child: Text('🏨', style: TextStyle(fontSize: 56))),
                        )
                      : PageView.builder(
                          itemCount: photos.length,
                          onPageChanged: (i) => setState(() => _currentPhoto = i),
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => PhotoViewerFullscreen.ouvrir(context, photos, i, placeholder: '🏨'),
                            child: Image.network(
                              photos[i],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(child: Text('🏨', style: TextStyle(fontSize: 56))),
                            ),
                          ),
                        ),
                ),
                if (photos.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(photos.length, (i) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _currentPhoto ? MboaColors.primary : MboaColors.border,
                          ),
                        );
                      }),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(h['titre'] ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: MboaColors.text)),
                          ),
                          if (_proprietaire?['verified'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: MboaColors.verified.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                              child: const Text('✅ Vérifié',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: MboaColors.verified)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_libelleType(h['type_etablissement']), style: MboaTextStyles.muted),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatPrix(h['prix']),
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: MboaColors.primary)),
                          Text('👤 ${h['capacite_personnes'] ?? 1} pers. max', style: MboaTextStyles.bodySm),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Établissement ──────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: MboaColors.primaryLight.withValues(alpha: 0.3), shape: BoxShape.circle),
                              child: Center(
                                child: Text(_getInitiales(nomEtablissement),
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: MboaColors.primary)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nomEtablissement,
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                                  Text('⭐ $_noteProprietaire ($_nbAvisProprietaire avis)', style: MboaTextStyles.caption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text('Description', style: MboaTextStyles.h4),
                      const SizedBox(height: 8),
                      Text(h['description'] ?? '', style: MboaTextStyles.body),
                      const SizedBox(height: 20),

                      if (equipements.isNotEmpty) ...[
                        Text('Équipements', style: MboaTextStyles.h4),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: equipements.map((e) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: MboaColors.border)),
                                child: Text('$e', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: MboaColors.text)),
                              )).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Avis ────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('⭐ Avis (${_avis.length})', style: MboaTextStyles.h4),
                          GestureDetector(
                            onTap: _laisserAvis,
                            child: const Text('Laisser un avis',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: MboaColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isLoadingAvis
                          ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
                          : _avis.isEmpty
                              ? Center(child: Text('Aucun avis pour le moment', style: MboaTextStyles.muted))
                              : Column(children: _avis.map((a) => _buildAvisCard(a)).toList()),
                      const SizedBox(height: 8),
                      Center(child: Text('👁 $_vues vues', style: MboaTextStyles.muted)),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Boutons fixes ─────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_rounded, color: MboaColors.text),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: MboaSizes.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _demanderReservation,
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Demander une réservation'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avis) {
    final auteur = avis['auteur'] as Map<String, dynamic>? ?? {};
    final nom = auteur['nom'] ?? 'Utilisateur';
    final note = (avis['note'] ?? 0) as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: MboaColors.primaryLight.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: Center(
                  child: Text(_getInitiales(nom),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: MboaColors.primary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(nom, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
              ),
              Text('★' * note, style: const TextStyle(color: MboaColors.boost, fontSize: 12)),
            ],
          ),
          if ((avis['commentaire'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(avis['commentaire'], style: MboaTextStyles.bodySm),
          ],
        ],
      ),
    );
  }
}
