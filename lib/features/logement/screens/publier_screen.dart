import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/mixins/refreshable_state.dart';

// Attend le résultat de l'analyse de modération IA (moderate-annonce) sur la
// ligne fraîchement insérée, via un canal realtime ciblé sur son id — fermé
// dès réception de la mise à jour ou au bout de 20s (l'annonce reste
// `en_attente` : l'analyse se terminera en arrière-plan, l'utilisateur sera
// simplement informé qu'elle est toujours en cours).
Future<String?> attendreDecisionModeration(
  SupabaseClient supabase,
  String table,
  String id,
) async {
  final completer = Completer<String?>();
  final channel = supabase.channel('moderation_${table}_$id');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: table,
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: id,
    ),
    callback: (payload) {
      final statut = payload.newRecord['statut_moderation'] as String?;
      if (statut != null && statut != 'en_attente' && !completer.isCompleted) {
        completer.complete(statut);
      }
    },
  ).subscribe();

  final decision = await completer.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => null,
  );
  await supabase.removeChannel(channel);
  return decision;
}

void afficherResultatModeration(
  BuildContext context,
  String? decision,
  String libelle,
) {
  final String message;
  final Color couleur;
  switch (decision) {
    case 'publie':
      message = '✅ $libelle publié avec succès !';
      couleur = MboaColors.primary;
      break;
    case 'a_verifier':
      message = '🔍 $libelle enregistré, en cours de vérification avant publication.';
      couleur = MboaColors.boost;
      break;
    case 'bloque':
      message = '⛔ $libelle refusé par la modération. Consultez "Gestion" pour plus de détails.';
      couleur = MboaColors.danger;
      break;
    default:
      message = '⏳ $libelle enregistré, analyse en cours. Vous serez notifié une fois validée.';
      couleur = MboaColors.boost;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: couleur, duration: const Duration(seconds: 4)),
  );
}

class PublierScreen extends StatefulWidget {
  const PublierScreen({super.key});

  @override
  State<PublierScreen> createState() => _PublierScreenState();
}

class _PublierScreenState extends State<PublierScreen>
    with SingleTickerProviderStateMixin, RefreshableState {
  TabController? _tabController;
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _peutLogement = false;
  bool _peutArticle = false;
  bool _compteActifPublication = true;

  @override
  void initState() {
    super.initState();
    _chargerPermissions();
  }

  @override
  Future<void> refresh() => _chargerPermissions();

  Future<void> _chargerPermissions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('users')
          .select('sous_roles, compte_actif_publication')
          .eq('id', userId)
          .single();
      final sousRoles = List<String>.from(data['sous_roles'] ?? []);
      final peutLogement = sousRoles.contains('proprietaire');
      final peutArticle = sousRoles.contains('commercant') || sousRoles.contains('vendeur_independant');
      if (mounted) {
        setState(() {
          _peutLogement = peutLogement;
          _peutArticle = peutArticle;
          _compteActifPublication = data['compte_actif_publication'] ?? true;
          if (peutLogement && peutArticle) {
            _tabController = TabController(length: 2, vsync: this);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MboaColors.background,
        body: Center(child: CircularProgressIndicator(color: MboaColors.primary)),
      );
    }

    if (!_peutLogement && !_peutArticle) {
      return Scaffold(
        backgroundColor: MboaColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                const Text(
                  'Aucune permission de publication',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ton compte contributeur ne dispose pas encore des droits de publication. Contacte l\'administrateur.',
                  style: MboaTextStyles.muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Un seul type autorisé : on affiche directement le formulaire, sans onglets.
    if (!(_peutLogement && _peutArticle)) {
      return Scaffold(
        backgroundColor: MboaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text(
                  _peutLogement ? '🏠 Publier un logement' : '🛒 Publier un article',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: MboaColors.text),
                ),
              ),
              Expanded(
                child: _peutLogement
                    ? _FormLogement(compteActifPublication: _compteActifPublication)
                    : const _FormArticle(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '➕ Publier',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choisis le type d\'annonce à publier',
                    style: MboaTextStyles.muted,
                  ),
                  const SizedBox(height: 16),
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
                    tabs: const [
                      Tab(text: '🏠 Logement'),
                      Tab(text: '🛒 Article'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FormLogement(compteActifPublication: _compteActifPublication),
                  const _FormArticle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FORMULAIRE LOGEMENT
// ════════════════════════════════════════════════════════════
class _FormLogement extends StatefulWidget {
  final bool compteActifPublication;
  const _FormLogement({required this.compteActifPublication});

  @override
  State<_FormLogement> createState() => _FormLogementState();
}

class _FormLogementState extends State<_FormLogement> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _prixController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _quartierController = TextEditingController();

  String _selectedType = 'Chambre';
  List<String> _selectedEquipements = [];
  List<File> _photos = [];
  bool _isLoading = false;
  bool _analyseEnCours = false;
  double? _lat;
  double? _lng;
  bool _isGettingLocation = false;
  List<Map<String, dynamic>> _lieuxPublics = [];

  @override
  void initState() {
    super.initState();
    _chargerLieuxPublics();
  }

  Future<void> _chargerLieuxPublics() async {
    try {
      final data = await _supabase.from('lieux_publics').select('nom, lat, lng');
      if (mounted) setState(() => _lieuxPublics = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  List<MapEntry<String, double>> get _lieuxProches {
    if (_lat == null || _lng == null) return [];
    final distances = _lieuxPublics.map((l) {
      final d = Geolocator.distanceBetween(_lat!, _lng!, l['lat'], l['lng']);
      return MapEntry(l['nom'] as String, d);
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return distances.take(3).toList();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _prixController.dispose();
    _surfaceController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  Future<void> _ajouterPhoto() async {
    if (_photos.length >= AppConstants.maxPhotosLogement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum ${AppConstants.maxPhotosLogement} photos'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _supprimerPhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _obtenirPosition() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceActive = await Geolocator.isLocationServiceEnabled();
      if (!serviceActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activez la localisation de votre téléphone'),
              backgroundColor: MboaColors.danger,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission de localisation refusée'),
                backgroundColor: MboaColors.danger,
              ),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Autorisez la localisation dans les paramètres de l\'app'),
              backgroundColor: MboaColors.danger,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );
      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signal GPS trop faible. Réessaie en extérieur ou près d\'une fenêtre.'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation : ${e.toString()}'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<List<String>> _uploadPhotos() async {
    final userId = _supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Uploads en parallèle (au lieu d'un par un) : réduit fortement le
    // temps de publication vu que les photos sont déjà compressées à
    // l'étape de sélection (image_picker maxWidth/imageQuality) et donc
    // légères — le goulot d'étranglement est la latence réseau par
    // requête, pas la bande passante.
    return Future.wait(_photos.asMap().entries.map((entry) async {
      final fileName = '$userId/${timestamp}_${entry.key}.jpg';
      await _supabase.storage
          .from(AppConstants.bucketLogements)
          .upload(fileName, entry.value)
          .timeout(const Duration(seconds: 30));
      return _supabase.storage
          .from(AppConstants.bucketLogements)
          .getPublicUrl(fileName);
    }));
  }

  Future<void> _publier() async {
    if (!widget.compteActifPublication) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérification terrain en cours : publication indisponible pour le moment'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_photos.length < AppConstants.minPhotosLogement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Minimum ${AppConstants.minPhotosLogement} photos requises'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload photos
      final photoUrls = await _uploadPhotos();

      // Insérer dans Supabase
      final insere = await _supabase.from(AppConstants.tableLogements).insert({
        'titre': _titreController.text.trim(),
        'description': _descController.text.trim(),
        'type': _selectedType,
        'prix': int.parse(
            _prixController.text.trim().replaceAll(' ', '')),
        'surface': _surfaceController.text.isNotEmpty
            ? double.parse(_surfaceController.text.trim())
            : null,
        'photos': photoUrls,
        'equipements': _selectedEquipements,
        'quartier': _quartierController.text.trim(),
        'ville': AppConstants.defaultVille,
        'lat': _lat,
        'lng': _lng,
        'proprietaire_id':
            _supabase.auth.currentUser!.id,
        'statut': AppConstants.statutDisponible,
        'boosted': false,
        'vues': 0,
        'signalements': 0,
        'note_globale': 0.0,
        'nb_avis': 0,
      }).select('id').single();

      // Attend le résultat de l'analyse de modération IA (moderate-annonce)
      if (mounted) setState(() => _analyseEnCours = true);
      final decision = await attendreDecisionModeration(
        _supabase,
        AppConstants.tableLogements,
        insere['id'] as String,
      );

      if (mounted) {
        afficherResultatModeration(context, decision, 'Logement');
        // Reset formulaire
        _formKey.currentState!.reset();
        setState(() {
          _photos = [];
          _selectedEquipements = [];
          _selectedType = 'Chambre';
          _lat = null;
          _lng = null;
        });
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Envoi des photos trop lent. Vérifie ta connexion et réessaie.'),
            backgroundColor: MboaColors.danger,
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _analyseEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            if (!widget.compteActifPublication) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MboaColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                  border: Border.all(color: MboaColors.danger.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, color: MboaColors.danger, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vérification terrain en cours. Un ambassadeur Mboa doit visiter '
                        'ton logement avant que tu puisses publier une annonce. Tu peux '
                        'préparer ton annonce dès maintenant, la publication se débloquera '
                        'automatiquement une fois la vérification validée par l\'administration.',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: MboaColors.text),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Photos ──────────────────────────────
            _buildSectionTitle('📷 Photos du logement'),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: MboaTextStyles.caption,
                children: [
                  TextSpan(
                    text:
                        'Minimum ${AppConstants.minPhotosLogement} photos · ',
                    style: const TextStyle(
                        color: MboaColors.danger),
                  ),
                  TextSpan(
                    text:
                        '${_photos.length}/${AppConstants.maxPhotosLogement} ajoutées',
                    style: const TextStyle(
                        color: MboaColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Photos ajoutées
                  ..._photos.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin:
                              const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () =>
                                _supprimerPhoto(entry.key),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: MboaColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Bouton ajouter
                  if (_photos.length <
                      AppConstants.maxPhotosLogement)
                    GestureDetector(
                      onTap: _ajouterPhoto,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: MboaColors.primary
                              .withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: MboaColors.primary
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons
                                  .add_photo_alternate_outlined,
                              color: MboaColors.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _photos.isEmpty
                                  ? 'Ajouter'
                                  : '+ Photo',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MboaColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Type ────────────────────────────────
            _buildSectionTitle('Type de logement'),
            const SizedBox(height: 12),
            Row(
              children:
                  AppConstants.typesLogement.map((type) {
                final isSelected = _selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: type !=
                                AppConstants.typesLogement.last
                            ? 10
                            : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MboaColors.primary
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? MboaColors.primary
                              : MboaColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : MboaColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Titre ───────────────────────────────
            _buildSectionTitle('Titre de l\'annonce'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Ex: Chambre meublée proche campus IUT',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 20),

            // ── Prix & Surface ───────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Prix / mois (FCFA)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _prixController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '20000',
                          suffixText: 'FCFA',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Requis';
                          if (int.tryParse(v
                                  .replaceAll(' ', '')) ==
                              null) return 'Invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Surface (m²)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _surfaceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '14',
                          suffixText: 'm²',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Quartier ─────────────────────────────
            _buildSectionTitle('Quartier'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quartierController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Ex: Mvog-Ada',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 20),

            // ── Position GPS ─────────────────────────
            _buildSectionTitle('📍 Position GPS'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(MboaSizes.radiusLg),
                border: Border.all(color: MboaColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_lat != null && _lng != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: MboaColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: MboaColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_lieuxProches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _lieuxProches.map((e) {
                          final distance = e.value < 1000
                              ? '${e.value.round()} m'
                              : '${(e.value / 1000).toStringAsFixed(1)} km';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MboaColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '📍 ${e.key} · $distance',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: MboaColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGettingLocation
                          ? null
                          : _obtenirPosition,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MboaColors.primary,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded,
                              size: 18),
                      label: Text(_lat != null
                          ? 'Actualiser ma position'
                          : 'Ma position'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Description ──────────────────────────
            _buildSectionTitle('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Décrivez votre logement : état général, règles, disponibilité...',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (v.length < 20)
                  return 'Minimum 20 caractères';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Équipements ──────────────────────────
            _buildSectionTitle('Équipements disponibles'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.equipements.map((eq) {
                final isSelected = _selectedEquipements
                    .contains(eq['label']);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedEquipements
                          .remove(eq['label']);
                    } else {
                      _selectedEquipements.add(eq['label']!);
                    }
                  }),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                      isSelected
                          ? '✓  ${eq['label']}'
                          : '${eq['icon']}  ${eq['label']}',
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
            const SizedBox(height: 32),

            // ── Bouton publier ───────────────────────
            SizedBox(
              width: double.infinity,
              height: MboaSizes.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || !widget.compteActifPublication) ? null : _publier,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.publish_rounded,
                        size: 20),
                label: Text(_isLoading
                    ? (_analyseEnCours
                        ? 'Analyse en cours...'
                        : 'Publication en cours...')
                    : 'Publier le logement'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: MboaColors.text,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FORMULAIRE ARTICLE MARKETPLACE
// ════════════════════════════════════════════════════════════
class _FormArticle extends StatefulWidget {
  const _FormArticle();

  @override
  State<_FormArticle> createState() => _FormArticleState();
}

class _FormArticleState extends State<_FormArticle> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _prixController = TextEditingController();

  String _selectedCategorie = 'Literie';
  String _selectedEtat = 'Bon état';
  bool _negociable = false;
  bool _accepteAvis = false;
  List<File> _photos = [];
  bool _isLoading = false;
  bool _analyseEnCours = false;

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _ajouterPhoto() async {
    if (_photos.length >= AppConstants.maxPhotosArticle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum ${AppConstants.maxPhotosArticle} photos'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _supprimerPhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<List<String>> _uploadPhotos() async {
    final userId = _supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return Future.wait(_photos.asMap().entries.map((entry) async {
      final fileName = '$userId/${timestamp}_${entry.key}.jpg';
      await _supabase.storage
          .from(AppConstants.bucketArticles)
          .upload(fileName, entry.value)
          .timeout(const Duration(seconds: 30));
      return _supabase.storage
          .from(AppConstants.bucketArticles)
          .getPublicUrl(fileName);
    }));
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.length < AppConstants.minPhotosArticle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins 1 photo requise'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final photoUrls = await _uploadPhotos();

      final insere = await _supabase.from(AppConstants.tableArticles).insert({
        'titre': _titreController.text.trim(),
        'description': _descController.text.trim(),
        'categorie': _selectedCategorie,
        'etat': _selectedEtat,
        'prix': int.parse(
            _prixController.text.trim().replaceAll(' ', '')),
        'negociable': _negociable,
        'accepte_avis': _accepteAvis,
        'photos': photoUrls,
        'vendeur_id': _supabase.auth.currentUser!.id,
        'statut': AppConstants.statutDisponible,
        'boosted': false,
        'vues': 0,
        'signalements': 0,
      }).select('id').single();

      // Attend le résultat de l'analyse de modération IA (moderate-annonce)
      if (mounted) setState(() => _analyseEnCours = true);
      final decision = await attendreDecisionModeration(
        _supabase,
        AppConstants.tableArticles,
        insere['id'] as String,
      );

      if (mounted) {
        afficherResultatModeration(context, decision, 'Article');
        _formKey.currentState!.reset();
        setState(() {
          _photos = [];
          _selectedCategorie = 'Literie';
          _selectedEtat = 'Bon état';
          _negociable = false;
          _accepteAvis = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Envoi des photos trop lent. Vérifie ta connexion et réessaie.'),
            backgroundColor: MboaColors.danger,
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _analyseEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Photos ──────────────────────────────
            _buildSectionTitle('📷 Photos de l\'article'),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: MboaTextStyles.caption,
                children: [
                  const TextSpan(
                    text: 'Minimum 1 photo · ',
                    style:
                        TextStyle(color: MboaColors.danger),
                  ),
                  TextSpan(
                    text:
                        '${_photos.length}/${AppConstants.maxPhotosArticle} ajoutées',
                    style: const TextStyle(
                        color: MboaColors.secondary,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._photos.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin:
                              const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () =>
                                _supprimerPhoto(entry.key),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: MboaColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_photos.length <
                      AppConstants.maxPhotosArticle)
                    GestureDetector(
                      onTap: _ajouterPhoto,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: MboaColors.secondary
                              .withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: MboaColors.secondary
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons
                                  .add_photo_alternate_outlined,
                              color: MboaColors.secondary,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _photos.isEmpty
                                  ? 'Ajouter'
                                  : '+ Photo',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MboaColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Catégorie ────────────────────────────
            _buildSectionTitle('Catégorie'),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    AppConstants.categoriesMarket.map((cat) {
                  final isSelected =
                      _selectedCategorie == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(() =>
                        _selectedCategorie = cat['label']!),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      margin:
                          const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MboaColors.secondary
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? MboaColors.secondary
                              : MboaColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(cat['icon']!,
                              style: const TextStyle(
                                  fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            cat['label']!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : MboaColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── État ─────────────────────────────────
            _buildSectionTitle('État de l\'article'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AppConstants.etatsArticle.map((etat) {
                final isSelected = _selectedEtat == etat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedEtat = etat),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MboaColors.accent
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? MboaColors.accent
                            : MboaColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      etat,
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
            const SizedBox(height: 20),

            // ── Titre ───────────────────────────────
            _buildSectionTitle('Titre de l\'article'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Ex: Lit 2 places + matelas en bon état',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 20),

            // ── Prix ─────────────────────────────────
            _buildSectionTitle('Prix (FCFA)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prixController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '15000',
                      suffixText: 'FCFA',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Requis';
                      if (int.tryParse(
                              v.replaceAll(' ', '')) ==
                          null) return 'Invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Switch(
                      value: _negociable,
                      onChanged: (v) =>
                          setState(() => _negociable = v),
                      activeColor: MboaColors.primary,
                    ),
                    const Text(
                      'Négociable',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MboaColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _accepteAvis,
                  onChanged: (v) => setState(() => _accepteAvis = v),
                  activeColor: MboaColors.primary,
                ),
                const Expanded(
                  child: Text(
                    'Autoriser les avis et notes sur cet article (utile pour un article vendu en série)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MboaColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Description ──────────────────────────
            _buildSectionTitle('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Décrivez l\'article : dimensions, marque, raison de la vente...',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (v.length < 20)
                  return 'Minimum 20 caractères';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Bouton publier ───────────────────────
            SizedBox(
              width: double.infinity,
              height: MboaSizes.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _publier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MboaColors.secondary,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.publish_rounded,
                        size: 20),
                label: Text(_isLoading
                    ? (_analyseEnCours
                        ? 'Analyse en cours...'
                        : 'Publication en cours...')
                    : 'Publier l\'article'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: MboaColors.text,
      ),
    );
  }
}