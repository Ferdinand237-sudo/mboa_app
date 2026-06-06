import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../market/screens/article_detail_screen.dart';

class ProfilVendeurScreen extends StatefulWidget {
  final Map<String, dynamic> vendeur;
  const ProfilVendeurScreen({super.key, required this.vendeur});

  @override
  State<ProfilVendeurScreen> createState() => _ProfilVendeurScreenState();
}

class _ProfilVendeurScreenState extends State<ProfilVendeurScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _annonces = [
    {
      'id': '1',
      'titre': 'Lit 2 places + matelas',
      'prix': 18000,
      'etat': 'Bon état',
      'categorie': 'Literie',
      'emoji': '🛏',
      'vendeur': 'Meublé Express',
      'vendeurNote': 4.7,
      'boosted': true,
      'negociable': true,
    },
    {
      'id': '2',
      'titre': 'Armoire 3 portes',
      'prix': 22000,
      'etat': 'Très bon état',
      'categorie': 'Mobilier',
      'emoji': '🗄️',
      'vendeur': 'Meublé Express',
      'vendeurNote': 4.7,
      'boosted': false,
      'negociable': false,
    },
    {
      'id': '3',
      'titre': 'Table basse salon',
      'prix': 8000,
      'etat': 'Bon état',
      'categorie': 'Mobilier',
      'emoji': '🪑',
      'vendeur': 'Meublé Express',
      'vendeurNote': 4.7,
      'boosted': false,
      'negociable': true,
    },
  ];

  final List<Map<String, dynamic>> _avis = [
    {
      'nom': 'Armel K.',
      'initiales': 'AK',
      'note': 5,
      'date': 'Mars 2025',
      'commentaire':
          'Vendeur très sérieux, articles conformes aux photos. Livraison rapide !',
    },
    {
      'nom': 'Sandra M.',
      'initiales': 'SM',
      'note': 4,
      'date': 'Fév. 2025',
      'commentaire':
          'Bonne qualité pour le prix. Je recommande la boutique.',
    },
    {
      'nom': 'Patrick N.',
      'initiales': 'PN',
      'note': 5,
      'date': 'Jan. 2025',
      'commentaire':
          'Excellent service ! Le mobilier est solide et bien fini.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendeur;
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: MboaColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: MboaColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                v['initiales'] ?? 'ME',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
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
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nom
                      Text(
                        v['nom'] ?? 'Vendeur',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Type
                      Text(
                        v['type'] ?? 'Commerçant',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stats
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat('4.7', '⭐ Note', Colors.white),
                            _buildDivider(),
                            _buildStat('47', '💬 Avis', Colors.white),
                            _buildDivider(),
                            _buildStat(
                                '2023', '📅 Depuis', Colors.white),
                            _buildDivider(),
                            _buildStat('12', '📦 Articles', Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tabs
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: '📦 Annonces'),
                Tab(text: '⭐ Avis'),
              ],
            ),
          ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(MboaSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos boutique
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MboaColors.secondary.withOpacity(0.3),
                            MboaColors.accent.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('🏪', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    const Text(
                      'À propos',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      v['description'] ??
                          'Spécialiste en mobilier étudiant depuis 2023. '
                              'Nous proposons des meubles de qualité à prix abordable '
                              'pour équiper votre logement. Livraison disponible.',
                      style: MboaTextStyles.body
                          .copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 12),

                    // Localisation boutique
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MboaColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MboaColors.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: MboaColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('📍',
                                  style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Emplacement boutique',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: MboaColors.text,
                                  ),
                                ),
                                Text(
                                  v['emplacement'] ??
                                      'Marché Central, Allée B, Stand 12 · Sangmelima',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: MboaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              side: const BorderSide(
                                  color: MboaColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Carte',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: MboaColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAnnonces(),
            _buildAvis(),
          ],
        ),
      ),

      // ── Bouton contact fixe ──────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('Appeler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('Envoyer un message'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnonces() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _annonces.length,
      itemBuilder: (context, index) {
        final a = _annonces[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: a),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(MboaSizes.radiusLg),
                    topRight: Radius.circular(MboaSizes.radiusLg),
                  ),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MboaColors.secondary.withOpacity(0.25),
                          MboaColors.accent.withOpacity(0.15),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(a['emoji'],
                          style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['titre'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MboaColors.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '${a['prix'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} F',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: MboaColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvis() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '4.7',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: MboaColors.text,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star_rounded,
                      size: 24,
                      color: i < 5
                          ? MboaColors.boost
                          : MboaColors.border,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '47 avis au total',
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
        final a = _avis[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MboaColors.primaryLight.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        a['initiales'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MboaColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['nom'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MboaColors.text,
                          ),
                        ),
                        Text(
                          a['date'],
                          style: MboaTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: i < a['note']
                            ? MboaColors.boost
                            : MboaColors.border,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                a['commentaire'],
                style: MboaTextStyles.body.copyWith(height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: color.withOpacity(0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.2),
    );
  }
}