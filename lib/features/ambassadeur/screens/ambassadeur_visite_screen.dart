import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

// Formulaire de visite terrain. Pas d'abonnement realtime sur cet écran
// (demande explicite : batterie/data limitées en terrain). Brouillon local
// (SharedPreferences + photo copiée dans le répertoire documents de l'app)
// pour survivre à une coupure réseau, avec envoi automatique au retour de
// connexion via Connectivity().onConnectivityChanged.
class AmbassadeurVisiteScreen extends StatefulWidget {
  final Map<String, dynamic> verification;
  const AmbassadeurVisiteScreen({super.key, required this.verification});

  @override
  State<AmbassadeurVisiteScreen> createState() => _AmbassadeurVisiteScreenState();
}

class _AmbassadeurVisiteScreenState extends State<AmbassadeurVisiteScreen> {
  final _supabase = Supabase.instance.client;
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  bool? _conformiteBien;
  String? _typeJustificatif;
  double? _lat;
  double? _lng;
  File? _photo;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;
  bool _brouillonRestaure = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool get _peutModifier => widget.verification['statut'] == 'assignee';
  String get _cleBrouillon => 'brouillon_visite_${widget.verification['id']}';

  @override
  void initState() {
    super.initState();
    if (_peutModifier) {
      _chargerBrouillon();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _chargerBrouillon() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cleBrouillon);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _conformiteBien = data['conformiteBien'] as bool?;
        _typeJustificatif = data['typeJustificatif'] as String?;
        _notesController.text = data['notes'] as String? ?? '';
        _lat = (data['lat'] as num?)?.toDouble();
        _lng = (data['lng'] as num?)?.toDouble();
        final photoPath = data['photoPath'] as String?;
        if (photoPath != null && File(photoPath).existsSync()) {
          _photo = File(photoPath);
        }
        _brouillonRestaure = true;
      });
    } catch (_) {}
  }

  Future<void> _sauvegarderBrouillon() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'conformiteBien': _conformiteBien,
      'typeJustificatif': _typeJustificatif,
      'notes': _notesController.text,
      'lat': _lat,
      'lng': _lng,
      'photoPath': _photo?.path,
    };
    await prefs.setString(_cleBrouillon, jsonEncode(data));
  }

  Future<void> _effacerBrouillon() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleBrouillon);
  }

  Future<void> _choisirPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    // Copie dans le répertoire documents de l'app pour que le brouillon
    // survive à une coupure/relance (le cache d'image_picker n'est pas garanti persistant).
    final dir = await getApplicationDocumentsDirectory();
    final destination = '${dir.path}/attestation_${widget.verification['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final copie = await File(picked.path).copy(destination);
    if (!mounted) return;
    setState(() => _photo = copie);
    await _sauvegarderBrouillon();
  }

  Future<void> _obtenirPosition() async {
    setState(() => _isGettingLocation = true);
    try {
      final serviceActive = await Geolocator.isLocationServiceEnabled();
      if (!serviceActive) {
        if (mounted) _snack('Activez la localisation de votre téléphone', MboaColors.danger);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _snack('Permission de localisation refusée', MboaColors.danger);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) _snack('Autorisez la localisation dans les paramètres de l\'app', MboaColors.danger);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      await _sauvegarderBrouillon();
    } catch (e) {
      if (mounted) _snack('Erreur de localisation : ${e.toString()}', MboaColors.danger);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _soumettre() async {
    if (_conformiteBien == null) {
      _snack('Indique si le bien est conforme', MboaColors.danger);
      return;
    }
    if (_typeJustificatif == null) {
      _snack('Sélectionne le type de justificatif', MboaColors.danger);
      return;
    }
    if (_photo == null) {
      _snack('Ajoute une photo de l\'attestation', MboaColors.danger);
      return;
    }

    await _sauvegarderBrouillon();

    final results = await Connectivity().checkConnectivity();
    final horsLigne = results.every((r) => r == ConnectivityResult.none);
    if (horsLigne) {
      _snack('Hors ligne : brouillon enregistré, envoi automatique au retour de connexion', MboaColors.boost);
      _ecouterReconnexion();
      return;
    }

    await _envoyerAuServeur();
  }

  void _ecouterReconnexion() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final horsLigne = results.every((r) => r == ConnectivityResult.none);
      if (!horsLigne && mounted && _photo != null && !_isSubmitting) {
        _connectivitySub?.cancel();
        _envoyerAuServeur();
      }
    });
  }

  Future<void> _envoyerAuServeur() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final ambassadeurId = _supabase.auth.currentUser!.id;
      final verificationId = widget.verification['id'] as String;
      final fileName = '$ambassadeurId/${verificationId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from(AppConstants.bucketAttestations).upload(fileName, _photo!);

      await _supabase.from(AppConstants.tableVerificationsTerrain).update({
        'conformite_bien': _conformiteBien,
        'type_justificatif': _typeJustificatif,
        'notes': _notesController.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'attestation_path': fileName,
        'statut': AppConstants.statutVerificationVisiteEffectuee,
        'date_visite': DateTime.now().toIso8601String(),
      }).eq('id', verificationId);

      await _effacerBrouillon();

      if (mounted) {
        _snack('✅ Visite envoyée à l\'administration', MboaColors.primary);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('Erreur lors de l\'envoi : ${e.toString()}', MboaColors.danger);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _voirAttestation() async {
    try {
      final res = await _supabase.functions.invoke('get-attestation-url', body: {
        'verificationId': widget.verification['id'],
      });
      final url = (res.data as Map?)?['url'] as String?;
      if (url != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(child: Image.network(url)),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Impossible de charger l\'attestation', MboaColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proprietaire = widget.verification['proprietaire'] as Map<String, dynamic>?;
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(proprietaire?['nom'] ?? 'Visite terrain',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _peutModifier ? _buildFormulaire() : _buildLectureSeule(),
        ),
      ),
    );
  }

  Widget _buildLectureSeule() {
    final v = widget.verification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoLigne('Statut', (v['statut'] as String?) ?? ''),
        if (v['conformite_bien'] != null) _infoLigne('Bien conforme', v['conformite_bien'] == true ? 'Oui' : 'Non'),
        if (v['type_justificatif'] != null) _infoLigne('Justificatif', v['type_justificatif'] as String),
        if ((v['notes'] as String?)?.isNotEmpty == true) _infoLigne('Notes', v['notes'] as String),
        if (v['date_visite'] != null) _infoLigne('Date de visite', v['date_visite'] as String),
        const SizedBox(height: 20),
        if (v['attestation_path'] != null)
          ElevatedButton.icon(
            onPressed: _voirAttestation,
            icon: const Icon(Icons.description_outlined),
            label: const Text('Voir l\'attestation'),
            style: ElevatedButton.styleFrom(backgroundColor: MboaColors.primary, foregroundColor: Colors.white),
          ),
      ],
    );
  }

  Widget _infoLigne(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MboaTextStyles.caption),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: MboaColors.text)),
        ],
      ),
    );
  }

  Widget _buildFormulaire() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_brouillonRestaure)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MboaColors.boost.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MboaSizes.radiusLg)),
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: MboaColors.boost, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Brouillon restauré depuis ta dernière visite non envoyée',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: MboaColors.text)),
                ),
              ],
            ),
          ),
        _buildSectionTitle('✅ Conformité du bien'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _choixConformite(true, 'Conforme')),
            const SizedBox(width: 10),
            Expanded(child: _choixConformite(false, 'Non conforme')),
          ],
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('📄 Type de justificatif présenté'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.typesJustificatif.map((type) {
            final isSelected = _typeJustificatif == type;
            return GestureDetector(
              onTap: () {
                setState(() => _typeJustificatif = type);
                _sauvegarderBrouillon();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? MboaColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border, width: 1.5),
                ),
                child: Text(type,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MboaColors.text)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('📝 Notes'),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          onChanged: (_) => _sauvegarderBrouillon(),
          decoration: const InputDecoration(hintText: 'Observations complémentaires (optionnel)'),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('📍 Position de la visite'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isGettingLocation ? null : _obtenirPosition,
          icon: _isGettingLocation
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location_rounded, size: 18),
          label: Text(_lat != null ? 'Position enregistrée ✓' : 'Ma position'),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('📸 Photo/scan de l\'attestation'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _choisirPhoto,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
              border: Border.all(color: MboaColors.border),
            ),
            child: _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                    child: Image.file(_photo!, fit: BoxFit.cover, width: double.infinity),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: MboaColors.textMuted, size: 32),
                        SizedBox(height: 8),
                        Text('Prendre une photo', style: TextStyle(fontFamily: 'Poppins', color: MboaColors.textMuted)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: MboaSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _soumettre,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Envoyer la visite'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _choixConformite(bool valeur, String label) {
    final isSelected = _conformiteBien == valeur;
    return GestureDetector(
      onTap: () {
        setState(() => _conformiteBien = valeur);
        _sauvegarderBrouillon();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (valeur ? MboaColors.verified : MboaColors.danger) : Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          border: Border.all(color: isSelected ? (valeur ? MboaColors.verified : MboaColors.danger) : MboaColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : MboaColors.text)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text));
  }
}
