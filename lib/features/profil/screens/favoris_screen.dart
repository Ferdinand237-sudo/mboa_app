import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../logement/screens/logement_detail_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _favoris = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerFavoris();
  }

  Future<void> _chargerFavoris() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('favoris')
          .select(
              '*, logement:logements(*, proprietaire:users!proprietaire_id(nom, verified))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _favoris = List<Map<String, dynamic>>.from(data)
              .where((f) => f['logement'] != null)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _retirerFavori(String logementId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('favoris')
          .delete()
          .eq('user_id', user.id)
          .eq('logement_id', logementId);
      if (mounted) {
        setState(() => _favoris.removeWhere(
            (f) => f['logement']['id'] == logementId));
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

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return p.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            ) +
        ' FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: MboaColors.background,
        elevation: 0,
        title: const Text(
          '❤️ Mes favoris',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: MboaColors.text,
          ),
        ),
        iconTheme: const IconThemeData(color: MboaColors.text),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: MboaColors.primary),
            )
          : _favoris.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _favoris.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _buildFavoriCard(_favoris[index]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Aucun favori pour l\'instant',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MboaColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des logements à vos favoris en appuyant sur le cœur',
              textAlign: TextAlign.center,
              style: MboaTextStyles.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriCard(Map<String, dynamic> favori) {
    final l = favori['logement'] as Map<String, dynamic>;
    final proprietaire =
        l['proprietaire'] as Map<String, dynamic>? ?? {};
    final photos = l['photos'] as List? ?? [];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LogementDetailScreen(logement: l),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(MboaSizes.radiusLg),
                bottomLeft: Radius.circular(MboaSizes.radiusLg),
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: MboaColors.cardGradient,
                ),
                child: photos.isNotEmpty
                    ? Image.network(
                        photos[0],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child:
                              Text('🏠', style: TextStyle(fontSize: 36)),
                        ),
                      )
                    : const Center(
                        child:
                            Text('🏠', style: TextStyle(fontSize: 36)),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l['titre'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrix(l['prix']),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: MboaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: MboaColors.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            l['quartier'] ?? 'Sangmelima',
                            style: MboaTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (proprietaire['verified'] == true)
                          const Text('✅', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _retirerFavori(l['id']),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MboaColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: MboaColors.danger,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
