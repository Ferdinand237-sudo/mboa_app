import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/mixins/realtime_table_mixin.dart';
import '../../../core/widgets/mboa_cached_image.dart';

class AdminSignalementsScreen extends StatefulWidget {
  // Appelé à chaque nouveau signalement reçu en temps réel — le parent
  // (AdminScreen) décide s'il doit afficher un badge sur l'onglet
  // (uniquement si cet écran n'est pas l'onglet actif à ce moment-là).
  final VoidCallback? onNouvelElement;
  const AdminSignalementsScreen({super.key, this.onNouvelElement});

  @override
  State<AdminSignalementsScreen> createState() =>
      _AdminSignalementsScreenState();
}

class _AdminSignalementsScreenState extends State<AdminSignalementsScreen>
    with RealtimeTableMixin<AdminSignalementsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _signalements = [];
  bool _isLoading = true;
  String _filtre = 'en-attente';
  bool _seulementIa = false;
  // Photos que l'admin exclut avant de republier — vide par défaut (toutes
  // les photos passent), clé = id du signalement.
  final Map<String, Set<String>> _photosExclues = {};

  // Minimum de photos exigé à la publication (publier_screen.dart) :
  // republier avec moins reviendrait à contourner cette règle par la bande.
  static const _photosMin = {'logements': 3, 'articles': 1};

  @override
  void initState() {
    super.initState();
    _chargerSignalements();
    // Un nouveau signalement (utilisateur ou detection_ia) doit apparaître
    // instantanément. Comme pour admin_verifications_screen, le payload
    // realtime n'a pas la jointure signaleur:users(...) : on recharge la
    // liste filtrée plutôt que de fusionner un payload incomplet.
    subscribeToTable(
      channelName: 'admin_signalements',
      table: AppConstants.tableSignalements,
      event: PostgresChangeEvent.insert,
      onChange: (payload) {
        _chargerSignalements();
        widget.onNouvelElement?.call();
      },
    );
  }

  @override
  void dispose() {
    disposeRealtimeChannels();
    super.dispose();
  }

  Future<void> _chargerSignalements() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('signalements')
          .select('*, signaleur:users!signaleur_id(nom, email)');

      if (_filtre != 'tous') {
        query = query.eq('statut', _filtre);
      }
      if (_seulementIa) {
        query = query.eq('raison', AppConstants.raisonDetectionIa);
      }

      final data = await query
          .order('date_signalement', ascending: false);

      final signalements = List<Map<String, dynamic>>.from(data);
      await _chargerPhotosAnnonces(signalements);

      if (mounted) {
        setState(() {
          _signalements = signalements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Un cible_id d'annonce peut être un logement ou un article : deux
  // requêtes groupées plutôt qu'un aller-retour par signalement. Sans ça,
  // l'admin devait juger une détection IA "à vérifier" sans jamais voir
  // les photos en cause — voir HISTORIQUE_PROJET_MBOA.md.
  Future<void> _chargerPhotosAnnonces(
      List<Map<String, dynamic>> signalements) async {
    final idsAnnonces = signalements
        .where((s) => (s['cible_type'] ?? 'annonce') == 'annonce')
        .map((s) => s['cible_id'] as String)
        .toList();
    if (idsAnnonces.isEmpty) return;

    final logements = await _supabase
        .from('logements')
        .select('id, photos')
        .filter('id', 'in', idsAnnonces);
    final articles = await _supabase
        .from('articles')
        .select('id, photos')
        .filter('id', 'in', idsAnnonces);

    final photosParId = <String, List<String>>{};
    final tableParId = <String, String>{};
    for (final l in logements) {
      photosParId[l['id']] = List<String>.from(l['photos'] ?? []);
      tableParId[l['id']] = 'logements';
    }
    for (final a in articles) {
      photosParId[a['id']] = List<String>.from(a['photos'] ?? []);
      tableParId[a['id']] = 'articles';
    }

    for (final s in signalements) {
      s['_photos'] = photosParId[s['cible_id']] ?? const <String>[];
      s['_annonceTable'] = tableParId[s['cible_id']];
    }

    await _chargerDiagnosticsPhotos(signalements, idsAnnonces);
  }

  static const _labelCategorie = {
    'pornographie': 'Pornographie',
    'violence': 'Violence',
    'stupefiants': 'Stupéfiants',
  };

  // Dernière analyse moderate-annonce par annonce (triée décroissant, on ne
  // garde que la première rencontrée par annonce_id) : construit le
  // diagnostic par photo (clé = url) à partir de photos_fraude/
  // photos_categories/photos_ignorees, pour que l'admin voie QUELLE photo
  // précisément a déclenché la détection IA, pas juste un verdict global.
  Future<void> _chargerDiagnosticsPhotos(
      List<Map<String, dynamic>> signalements, List<String> idsAnnonces) async {
    if (idsAnnonces.isEmpty) return;
    final moderations = await _supabase
        .from('moderation_ia')
        .select('annonce_id, photos_fraude, photos_categories, photos_ignorees, created_at')
        .filter('annonce_id', 'in', idsAnnonces)
        .order('created_at', ascending: false);

    final diagnosticsParId = <String, Map<String, Map<String, dynamic>>>{};
    for (final m in moderations) {
      final annonceId = m['annonce_id'] as String;
      if (diagnosticsParId.containsKey(annonceId)) continue; // déjà la plus récente
      final diag = <String, Map<String, dynamic>>{};
      Map<String, dynamic> entree(String url) =>
          diag.putIfAbsent(url, () => {'fraude': false, 'categories': <String>[], 'ignoree': false});

      for (final f in List<Map<String, dynamic>>.from(m['photos_fraude'] ?? [])) {
        entree(f['url'] as String)['fraude'] = true;
      }
      for (final c in List<Map<String, dynamic>>.from(m['photos_categories'] ?? [])) {
        final e = entree(c['url'] as String);
        for (final cle in _labelCategorie.keys) {
          if (c[cle] == true) (e['categories'] as List<String>).add(_labelCategorie[cle]!);
        }
      }
      for (final ig in List<Map<String, dynamic>>.from(m['photos_ignorees'] ?? [])) {
        entree(ig['url'] as String)['ignoree'] = true;
      }
      diagnosticsParId[annonceId] = diag;
    }

    for (final s in signalements) {
      s['_diagnosticsPhotos'] = diagnosticsParId[s['cible_id']] ?? const {};
    }
  }

  List<String> _photosRestantes(Map<String, dynamic> signalement) {
    final photos = List<String>.from(signalement['_photos'] ?? const []);
    final exclues = _photosExclues[signalement['id']];
    if (exclues == null || exclues.isEmpty) return photos;
    return photos.where((p) => !exclues.contains(p)).toList();
  }

  // Désactive "Résoudre" tant que l'admin n'a pas laissé au moins le
  // minimum de photos requis pour ce type d'annonce.
  bool _peutResoudre(Map<String, dynamic> signalement) {
    final photos = List<String>.from(signalement['_photos'] ?? const []);
    final table = signalement['_annonceTable'] as String?;
    if (signalement['cible_type'] != 'annonce' || photos.isEmpty || table == null) {
      return true;
    }
    return _photosRestantes(signalement).length >= _photosMin[table]!;
  }

  Future<void> _traiterSignalement(
      String id, String statut) async {
    await _supabase
        .from('signalements')
        .update({'statut': statut})
        .eq('id', id);
    _chargerSignalements();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            statut == 'traite'
                ? '✅ Signalement traité'
                : '❌ Signalement rejeté',
          ),
          backgroundColor: statut == 'traite'
              ? MboaColors.verified
              : MboaColors.textMuted,
        ),
      );
    }
  }

  // Boutons "Résoudre" / "Ignorer" : contrairement à Suspendre/Supprimer,
  // l'admin ne prend ici aucune autre action sur l'annonce — il juge le
  // signalement infondé (souvent une détection IA en a_verifier/bloque).
  // Sans republication explicite, logements.statut_moderation /
  // articles.statut_moderation restait bloqué pour toujours : l'annonce
  // n'apparaissait plus jamais côté app ni dans le tableau de gestion du
  // vendeur, alors même que le signalement affichait "Traité".
  Future<void> _resoudreOuIgnorerSignalement(
      Map<String, dynamic> signalement, String statut) async {
    await _traiterSignalement(signalement['id'], statut);
    if (signalement['cible_type'] == 'annonce') {
      final photos = List<String>.from(signalement['_photos'] ?? const []);
      await _republierAnnonceSiBloquee(
        signalement['cible_id'],
        photosAConserver: photos.isNotEmpty ? _photosRestantes(signalement) : null,
      );
    }
  }

  // photosAConserver (si fourni) retire du même mouvement les photos que
  // l'admin a exclues avant de laisser passer l'annonce.
  Future<void> _republierAnnonceSiBloquee(String cibleId,
      {List<String>? photosAConserver}) async {
    final updates = <String, dynamic>{'statut_moderation': 'publie'};
    if (photosAConserver != null) updates['photos'] = photosAConserver;
    try {
      final logement = await _supabase
          .from('logements')
          .select('id')
          .eq('id', cibleId)
          .maybeSingle();
      if (logement != null) {
        await _supabase.from('logements').update(updates).eq('id', cibleId);
        return;
      }
    } catch (_) {}
    try {
      final article = await _supabase
          .from('articles')
          .select('id')
          .eq('id', cibleId)
          .maybeSingle();
      if (article != null) {
        await _supabase.from('articles').update(updates).eq('id', cibleId);
      }
    } catch (_) {}
  }

  Future<void> _supprimerAnnonce(
      String cibleId, String cibleType, String signalementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          '🗑 Supprimer l\'annonce',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Cette action supprimera définitivement l\'annonce signalée.',
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
      final table = cibleType == 'annonce'
          ? 'logements'
          : 'utilisateurs';
      if (cibleType == 'annonce') {
        // Essayer logements d'abord puis articles
        try {
          await _supabase
              .from('logements')
              .delete()
              .eq('id', cibleId);
        } catch (_) {
          await _supabase
              .from('articles')
              .delete()
              .eq('id', cibleId);
        }
      } else {
        await _supabase
            .from(table)
            .delete()
            .eq('id', cibleId);
      }
      await _traiterSignalement(signalementId, 'traite');
    }
  }

  Future<String?> _trouverProprietaireId(String cibleId) async {
    try {
      final logement = await _supabase
          .from('logements')
          .select('proprietaire_id')
          .eq('id', cibleId)
          .maybeSingle();
      if (logement != null) return logement['proprietaire_id'] as String?;
    } catch (_) {}
    try {
      final article = await _supabase
          .from('articles')
          .select('vendeur_id')
          .eq('id', cibleId)
          .maybeSingle();
      if (article != null) return article['vendeur_id'] as String?;
    } catch (_) {}
    return null;
  }

  Future<void> _suspendreAnnonce(
      String cibleId, String cibleType, String signalementId) async {
    final raisonController = TextEditingController();
    final raison = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          '⏸ Suspendre l\'annonce',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'L\'annonce sera masquée du public. Explique la raison au '
              'propriétaire, il recevra ce message directement.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: MboaColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: raisonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex : Photos non conformes au bien réel, merci de corriger.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, raisonController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: MboaColors.boost),
            child: const Text('Suspendre et prévenir'),
          ),
        ],
      ),
    );

    if (raison == null || raison.isEmpty) return;

    final table = cibleType == 'annonce' ? 'logements' : null;
    try {
      var suspendu = false;
      if (table != null) {
        try {
          await _supabase.from('logements').update({'statut': 'suspendu'}).eq('id', cibleId);
          suspendu = true;
        } catch (_) {}
        if (!suspendu) {
          await _supabase.from('articles').update({'statut': 'suspendu'}).eq('id', cibleId);
        }
      }

      final proprietaireId = await _trouverProprietaireId(cibleId);
      final admin = _supabase.auth.currentUser;
      if (proprietaireId != null && admin != null) {
        final response = await _supabase
            .from('conversations')
            .insert({
              'participants': [admin.id, proprietaireId],
              'non_lu': {admin.id: 0, proprietaireId: 1},
            })
            .select('id')
            .single();
        await _supabase.from('messages').insert({
          'conversation_id': response['id'],
          'expediteur_id': admin.id,
          'texte':
              '⚠️ Une de vos annonces a été suspendue par l\'administration Mboa.\n\nRaison : $raison',
        });
        await _supabase.from('conversations').update({
          'dernier_message': '⚠️ Annonce suspendue : $raison',
          'dernier_message_date': DateTime.now().toIso8601String(),
        }).eq('id', response['id']);
      }

      await _traiterSignalement(signalementId, 'traite');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Annonce suspendue, propriétaire prévenu'),
            backgroundColor: MboaColors.boost,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suspension'), backgroundColor: MboaColors.danger),
        );
      }
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🚨 Signalements',
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
                          color: MboaColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_signalements.where((s) => s['statut'] == 'en-attente').length} en attente',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MboaColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filtres
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'en-attente',
                        'traite',
                        'rejete',
                        'tous',
                      ].map((f) {
                        final isSelected = _filtre == f;
                        final label = f == 'en-attente'
                            ? '⏳ En attente'
                            : f == 'traite'
                                ? '✅ Traités'
                                : f == 'rejete'
                                    ? '❌ Rejetés'
                                    : '📋 Tous';
                        return GestureDetector(
                          onTap: () {
                            setState(() => _filtre = f);
                            _chargerSignalements();
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MboaColors.primary
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? MboaColors.primary
                                    : MboaColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : MboaColors.text,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filtre origine IA
                  GestureDetector(
                    onTap: () {
                      setState(() => _seulementIa = !_seulementIa);
                      _chargerSignalements();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _seulementIa
                            ? MboaColors.primary.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _seulementIa ? MboaColors.primary : MboaColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _seulementIa ? Icons.check_circle_rounded : Icons.smart_toy_outlined,
                            size: 14,
                            color: _seulementIa ? MboaColors.primary : MboaColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '🤖 Détections IA uniquement',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _seulementIa ? MboaColors.primary : MboaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Liste ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: MboaColors.primary),
                    )
                  : _signalements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text('🎉',
                                  style:
                                      TextStyle(fontSize: 50)),
                              const SizedBox(height: 12),
                              Text(
                                _filtre == 'en-attente'
                                    ? 'Aucun signalement en attente'
                                    : 'Aucun signalement',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: MboaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _chargerSignalements,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _signalements.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _buildSignalementCard(
                                    _signalements[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Vignette d'une photo d'annonce : bordure rouge (pleine) si l'IA a
  // détecté un problème précis sur CETTE photo (fraude ou catégorie
  // Gemini), bordure orange pointillée si elle n'a jamais pu être
  // analysée (trop lourde) — l'absence de badge ne veut alors pas dire
  // "photo propre". Appui long affiche le détail exact via Tooltip.
  Widget _buildPhotoVignette(Map<String, dynamic> signalement, String url) {
    final id = signalement['id'] as String;
    final exclue = _photosExclues[id]?.contains(url) ?? false;
    final diag = (signalement['_diagnosticsPhotos']
            as Map<String, dynamic>?)?[url] as Map<String, dynamic>?;
    final categories = List<String>.from(diag?['categories'] ?? const []);
    final fraude = diag?['fraude'] == true;
    final ignoree = diag?['ignoree'] == true;
    final suspecte = fraude || categories.isNotEmpty;

    final messages = [
      if (fraude) '🔁 Photo réutilisée d\'une autre annonce',
      ...categories.map((c) => '🚫 Détecté : $c'),
      if (ignoree) '⚠️ Non analysée par l\'IA (photo trop lourde)',
    ];

    final vignette = GestureDetector(
      onTap: () => setState(() {
        final exclues = _photosExclues.putIfAbsent(id, () => {});
        if (exclues.contains(url)) {
          exclues.remove(url);
        } else {
          exclues.add(url);
        }
      }),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: exclue
                    ? null
                    : suspecte
                        ? Border.all(color: MboaColors.danger, width: 2)
                        : ignoree
                            ? Border.all(color: MboaColors.boost, width: 2)
                            : null,
              ),
              child: Opacity(
                opacity: exclue ? 0.4 : 1,
                child: MboaCachedImage(url: url),
              ),
            ),
          ),
          if (!exclue && (suspecte || ignoree))
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: suspecte ? MboaColors.danger : MboaColors.boost,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    suspecte ? (fraude ? '🔁' : '🚫') : '⚠️',
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
              ),
            ),
          if (exclue)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
        ],
      ),
    );

    if (messages.isEmpty) return vignette;
    return Tooltip(message: messages.join(' · '), child: vignette);
  }

  Widget _buildSignalementCard(
      Map<String, dynamic> signalement) {
    final statut = signalement['statut'] ?? 'en-attente';
    final signaleur = signalement['signaleur'];
    final cibleType = signalement['cible_type'] ?? 'annonce';
    final estDetectionIa = signalement['raison'] == AppConstants.raisonDetectionIa;
    final peutResoudre = _peutResoudre(signalement);

    Color statutColor;
    switch (statut) {
      case 'traite':
        statutColor = MboaColors.verified;
        break;
      case 'rejete':
        statutColor = MboaColors.textMuted;
        break;
      default:
        statutColor = MboaColors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        border: Border.all(
          color: statut == 'en-attente'
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
          // ── En-tête ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (estDetectionIa ? MboaColors.primary : MboaColors.danger)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(estDetectionIa ? '🤖' : '🚩',
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        estDetectionIa
                            ? '🤖 Détection IA — Annonce'
                            : cibleType == 'annonce'
                                ? '📋 Annonce signalée'
                                : cibleType == 'utilisateur'
                                    ? '👤 Utilisateur signalé'
                                    : '⭐ Avis signalé',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MboaColors.text,
                        ),
                      ),
                      if (estDetectionIa)
                        const Text(
                          'Analyse automatique Mboa',
                          style: MboaTextStyles.caption,
                        )
                      else if (signaleur != null)
                        Text(
                          'Par ${signaleur['nom'] ?? 'Inconnu'}',
                          style: MboaTextStyles.caption,
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statut == 'en-attente'
                      ? '⏳ En attente'
                      : statut == 'traite'
                          ? '✅ Traité'
                          : '❌ Rejeté',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statutColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Raison ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MboaColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Raison : ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    Text(
                      estDetectionIa
                          ? 'Détection automatique (modération IA)'
                          : (signalement['raison'] ?? ''),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: estDetectionIa ? MboaColors.primary : MboaColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (signalement['description'] != null &&
                    signalement['description'].isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    signalement['description'],
                    style: MboaTextStyles.bodySm,
                  ),
                ],
              ],
            ),
          ),

          // ── Photos de l'annonce ────────────────────
          if (cibleType == 'annonce' &&
              (signalement['_photos'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Text(
              '📷 Photos de l\'annonce — touche pour exclure une photo avant de republier',
              style: MboaTextStyles.caption,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in List<String>.from(signalement['_photos']))
                  _buildPhotoVignette(signalement, url),
              ],
            ),
            if ((signalement['_diagnosticsPhotos'] as Map?)?.values.any((d) =>
                    d['fraude'] == true ||
                    (d['categories'] as List).isNotEmpty ||
                    d['ignoree'] == true) ==
                true) ...[
              const SizedBox(height: 4),
              const Text(
                '🔁 réutilisée · 🚫 contenu détecté · ⚠️ non analysée (appui long sur une photo pour le détail)',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: MboaColors.textMuted),
              ),
            ],
            if (!_peutResoudre(signalement)) ...[
              const SizedBox(height: 4),
              Text(
                'Garde au moins ${_photosMin[signalement['_annonceTable']] ?? 1} photo(s) pour republier.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MboaColors.danger,
                ),
              ),
            ],
          ],

          // ── Actions ──────────────────────────────
          if (statut == 'en-attente') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                // Rejeter le signalement
                Expanded(
                  child: GestureDetector(
                    onTap: () => _resoudreOuIgnorerSignalement(
                        signalement, 'rejete'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 9),
                      decoration: BoxDecoration(
                        color: MboaColors.textMuted
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: MboaColors.border,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.thumb_down_outlined,
                              size: 14,
                              color: MboaColors.textMuted),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Ignorer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: MboaColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Traiter sans supprimer
                Expanded(
                  child: GestureDetector(
                    onTap: peutResoudre
                        ? () => _resoudreOuIgnorerSignalement(
                            signalement, 'traite')
                        : null,
                    child: Opacity(
                      opacity: peutResoudre ? 1 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 9),
                        decoration: BoxDecoration(
                          color: MboaColors.verified
                              .withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color: MboaColors.verified
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 14,
                                color: MboaColors.verified),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Résoudre',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: MboaColors.verified,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (cibleType == 'annonce') ...[
                  const SizedBox(width: 8),
                  // Suspendre l'annonce et prévenir le propriétaire
                  GestureDetector(
                    onTap: () => _suspendreAnnonce(
                      signalement['cible_id'],
                      cibleType,
                      signalement['id'],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: MboaColors.boost
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MboaColors.boost
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(Icons.pause_circle_outline_rounded,
                          size: 16, color: MboaColors.boost),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // Supprimer l'annonce
                GestureDetector(
                  onTap: () => _supprimerAnnonce(
                    signalement['cible_id'],
                    cibleType,
                    signalement['id'],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: MboaColors.danger
                          .withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: MboaColors.danger
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: MboaColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}