import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class PublierScreen extends StatefulWidget {
  const PublierScreen({super.key});

  @override
  State<PublierScreen> createState() => _PublierScreenState();
}

class _PublierScreenState extends State<PublierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

            // ── Contenu ──────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _FormLogement(),
                  _FormArticle(),
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
  const _FormLogement();

  @override
  State<_FormLogement> createState() => _FormLogementState();
}

class _FormLogementState extends State<_FormLogement> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _prixController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _quartierController = TextEditingController();
  String _selectedType = 'Chambre';
  List<String> _selectedEquipements = [];
  bool _isLoading = false;
  int _nbPhotos = 0;

  final List<String> _equipements = [
    'Wifi', 'Eau courante', 'Électricité',
    'Meublé', 'Cuisine', 'Salon',
    'Sécurité', 'Parking',
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _prixController.dispose();
    _surfaceController.dispose();
    _quartierController.dispose();
    super.dispose();
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

            // ── Photos ──────────────────────────────────
            _buildSectionTitle('📷 Photos du logement'),
            const SizedBox(height: 4),
            Text(
              'Minimum 3 photos obligatoires',
              style: MboaTextStyles.caption.copyWith(
                color: MboaColors.danger,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final hasPhoto = index < _nbPhotos;
                  return GestureDetector(
                    onTap: () {
                      if (!hasPhoto && _nbPhotos == index) {
                        setState(() => _nbPhotos++);
                      }
                    },
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: hasPhoto
                            ? MboaColors.primary.withValues(alpha: 0.1)
                            : MboaColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasPhoto
                              ? MboaColors.primary
                              : MboaColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasPhoto
                                ? Icons.check_circle_rounded
                                : Icons.add_photo_alternate_outlined,
                            color: hasPhoto
                                ? MboaColors.primary
                                : MboaColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasPhoto
                                ? 'Photo ${index + 1}'
                                : index == 0
                                    ? 'Ajouter'
                                    : '+ Photo',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: hasPhoto
                                  ? MboaColors.primary
                                  : MboaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Type ────────────────────────────────────
            _buildSectionTitle('Type de logement'),
            const SizedBox(height: 12),
            Row(
              children: AppConstants.typesLogement.map((type) {
                final isSelected = _selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: type != AppConstants.typesLogement.last
                            ? 10
                            : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MboaColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
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

            // ── Titre ───────────────────────────────────
            _buildSectionTitle('Titre de l\'annonce'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex: Chambre meublée proche campus IUT',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 20),

            // ── Prix & Surface ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Prix / mois (FCFA)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _prixController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '20 000',
                          suffixText: 'FCFA',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

            // ── Quartier ─────────────────────────────────
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

            // ── Description ──────────────────────────────
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
                if (v.length < 20) return 'Minimum 20 caractères';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Équipements ──────────────────────────────
            _buildSectionTitle('Équipements disponibles'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipements.map((eq) {
                final isSelected = _selectedEquipements.contains(eq);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedEquipements.remove(eq);
                    } else {
                      _selectedEquipements.add(eq);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MboaColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? MboaColors.primary
                            : MboaColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      isSelected ? '✓  $eq' : eq,
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

            // ── Bouton publier ───────────────────────────
            SizedBox(
              width: double.infinity,
              height: MboaSizes.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _publier,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.publish_rounded, size: 20),
                label: Text(
                    _isLoading ? 'Publication...' : 'Publier le logement'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nbPhotos < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 3 photos requises'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Annonce publiée avec succès !'),
          backgroundColor: MboaColors.primary,
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _nbPhotos = 0;
        _selectedEquipements = [];
      });
    }
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
  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _prixController = TextEditingController();
  String _selectedCategorie = 'Literie';
  String _selectedEtat = 'Bon état';
  bool _negociable = false;
  bool _isLoading = false;
  int _nbPhotos = 0;

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _prixController.dispose();
    super.dispose();
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

            // ── Photos ──────────────────────────────────
            _buildSectionTitle('📷 Photos de l\'article'),
            const SizedBox(height: 4),
            Text(
              'Minimum 1 photo obligatoire',
              style: MboaTextStyles.caption.copyWith(
                color: MboaColors.danger,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final hasPhoto = index < _nbPhotos;
                  return GestureDetector(
                    onTap: () {
                      if (!hasPhoto && _nbPhotos == index) {
                        setState(() => _nbPhotos++);
                      }
                    },
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: hasPhoto
                            ? MboaColors.secondary.withValues(alpha: 0.1)
                            : MboaColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasPhoto
                              ? MboaColors.secondary
                              : MboaColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasPhoto
                                ? Icons.check_circle_rounded
                                : Icons.add_photo_alternate_outlined,
                            color: hasPhoto
                                ? MboaColors.secondary
                                : MboaColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasPhoto
                                ? 'Photo ${index + 1}'
                                : index == 0
                                    ? 'Ajouter'
                                    : '+ Photo',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: hasPhoto
                                  ? MboaColors.secondary
                                  : MboaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Catégorie ────────────────────────────────
            _buildSectionTitle('Catégorie'),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AppConstants.categoriesMarket.map((cat) {
                  final isSelected =
                      _selectedCategorie == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedCategorie = cat['label']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MboaColors.secondary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                              style: const TextStyle(fontSize: 14)),
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

            // ── État ─────────────────────────────────────
            _buildSectionTitle('État de l\'article'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.etatsArticle.map((etat) {
                final isSelected = _selectedEtat == etat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEtat = etat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MboaColors.accent
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
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

            // ── Titre ───────────────────────────────────
            _buildSectionTitle('Titre de l\'article'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex: Lit 2 places + matelas en bon état',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 20),

            // ── Prix ─────────────────────────────────────
            _buildSectionTitle('Prix (FCFA)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prixController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '15 000',
                      suffixText: 'FCFA',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requis' : null,
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
            const SizedBox(height: 20),

            // ── Description ──────────────────────────────
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
                if (v.length < 20) return 'Minimum 20 caractères';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Bouton publier ───────────────────────────
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
                    : const Icon(Icons.publish_rounded, size: 20),
                label: Text(
                    _isLoading ? 'Publication...' : 'Publier l\'article'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nbPhotos < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins 1 photo requise'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Article publié avec succès !'),
          backgroundColor: MboaColors.secondary,
        ),
      );
      _formKey.currentState!.reset();
      setState(() => _nbPhotos = 0);
    }
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