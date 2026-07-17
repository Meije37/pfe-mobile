import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Widget professionnel pour afficher la photo d'une réclamation.
///
/// Utilisation simple :
/// ```dart
/// ReclamationPhotoWidget(medias: reclamation['medias'])
/// ```
class ReclamationPhotoWidget extends StatefulWidget {
  const ReclamationPhotoWidget({
    super.key,
    required this.medias,
    this.height = 220,
    this.showLabel = true,
  });

  /// Liste des médias depuis l'API backend
  /// Exemple : [{"id": 1, "url": "/uploads/photo.jpg", "nomFichier": "photo.jpg"}]
  final List<dynamic> medias;

  /// Hauteur de la photo (par défaut 220)
  final double height;

  /// Afficher le titre "PHOTO" au-dessus
  final bool showLabel;

  @override
  State<ReclamationPhotoWidget> createState() =>
      _ReclamationPhotoWidgetState();
}

class _ReclamationPhotoWidgetState
    extends State<ReclamationPhotoWidget> {
  // Index de la photo affichée (si plusieurs photos)
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Pas de médias → ne rien afficher
    if (widget.medias.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Titre section ───────────────────────────────────────────
          if (widget.showLabel) ...[
            Row(children: [
              Icon(Icons.photo_outlined,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('PHOTO',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.textMuted, fontSize: 11)),
              if (widget.medias.length > 1) ...[
                const Spacer(),
                Text(
                  '${_currentIndex + 1} / ${widget.medias.length}',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ]),
            const SizedBox(height: 10),
          ],

          // ── Photo principale ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              // Tap → ouvre en plein écran
              onTap: () => _ouvrirPleinEcran(context, _currentIndex),
              child: _buildPhoto(
                widget.medias[_currentIndex],
                widget.height,
              ),
            ),
          ),

          // ── Miniatures si plusieurs photos ──────────────────────────
          if (widget.medias.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.medias.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: i == _currentIndex
                            ? AppColors.accent
                            : AppColors.border,
                        width: i == _currentIndex ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: _buildPhoto(widget.medias[i], 56,
                          showActions: false),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Indication tap pour plein écran ─────────────────────────
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.zoom_in,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Appuyez pour agrandir',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Construction de l'image depuis l'URL backend ──────────────────────
  Widget _buildPhoto(
    dynamic media,
    double height, {
    bool showActions = true,
  }) {
    // Construit l'URL complète depuis l'URL relative du backend
    // Backend retourne : "/uploads/nom_fichier.jpg"
    // Flutter construit : "http://10.0.2.2:8081/uploads/nom_fichier.jpg"
    final urlRelative = media['url'] as String? ?? '';
    final urlComplete = _buildUrl(urlRelative);

    if (urlComplete.isEmpty) return _buildErreur(height);

    return Image.network(
      urlComplete,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,

      // ── Chargement progressif ──────────────────────────────────────
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        final percent = progress.expectedTotalBytes != null
            ? progress.cumulativeBytesLoaded /
              progress.expectedTotalBytes!
            : null;

        return Container(
          height: height,
          color: AppColors.background,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(
                    value: percent,
                    color: AppColors.accent,
                    strokeWidth: 2.5,
                  ),
                ),
                if (percent != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        );
      },

      // ── Erreur de chargement ───────────────────────────────────────
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Erreur chargement photo : $urlComplete — $error');
        return _buildErreur(height);
      },
    );
  }

  // ── Widget d'erreur ───────────────────────────────────────────────────
  Widget _buildErreur(double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image_outlined,
            color: AppColors.textMuted.withOpacity(0.4), size: 32),
        const SizedBox(height: 8),
        Text('Photo non disponible',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text('Vérifiez votre connexion',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.textMuted, fontSize: 9)),
      ],
    ),
  );

  // ── Plein écran ───────────────────────────────────────────────────────
  void _ouvrirPleinEcran(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenPhoto(
          medias:       widget.medias,
          initialIndex: index,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Construction URL complète ─────────────────────────────────────────
  String _buildUrl(String urlRelative) {
    if (urlRelative.isEmpty) return '';

    // Déjà une URL complète
    if (urlRelative.startsWith('http')) return urlRelative;

    // URL relative → ajoute la base
    final base = AppConstants.mediaBaseUrl;
    final path = urlRelative.startsWith('/')
        ? urlRelative
        : '/$urlRelative';

    return '$base$path';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PLEIN ÉCRAN — vue immersive avec zoom et navigation
// ═══════════════════════════════════════════════════════════════════════
class _FullScreenPhoto extends StatefulWidget {
  const _FullScreenPhoto({
    required this.medias,
    required this.initialIndex,
  });

  final List<dynamic> medias;
  final int           initialIndex;

  @override
  State<_FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<_FullScreenPhoto> {
  late final PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl     = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.medias.length > 1
              ? 'Photo ${_currentIndex + 1} / ${widget.medias.length}'
              : 'Photo',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          // Indication zoom
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                'Pincez pour zoomer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [

          // ── PageView avec zoom par page ───────────────────────────
          PageView.builder(
            controller:    _pageCtrl,
            itemCount:     widget.medias.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            // ✅ physics à None quand on zoome — géré par InteractiveViewer
            physics: const ClampingScrollPhysics(),
            itemBuilder: (_, i) {
              final media       = widget.medias[i] as Map<String, dynamic>;
              final urlRelative = media['url'] as String? ?? '';
              final url = urlRelative.startsWith('http')
                  ? urlRelative
                  : '${AppConstants.mediaBaseUrl}$urlRelative';

              return _ZoomablePage(url: url);
            },
          ),

          // ── Points indicateurs ────────────────────────────────────
          if (widget.medias.length > 1)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.medias.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width:  i == _currentIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Widget de page zoomable — chaque photo a son propre TransformationController
// ═══════════════════════════════════════════════════════════════════════
class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({required this.url});
  final String url;

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  // ✅ TransformationController — contrôle le zoom programmatiquement
  final _transformCtrl = TransformationController();
  bool  _isZoomed      = false;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  // Double tap → zoom in/out
  void _onDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      // Zoom out — retour à la taille normale
      _transformCtrl.value = Matrix4.identity();
      setState(() => _isZoomed = false);
    } else {
      // Zoom in — centré sur le point touché
      final position = details.localPosition;
      const scale   = 2.5;

      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);

      final matrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);

      _transformCtrl.value = matrix;
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ Double tap pour zoom rapide
      onDoubleTapDown: _onDoubleTap,
      onDoubleTap: () {}, // nécessaire pour activer onDoubleTapDown
      child: InteractiveViewer(
        transformationController: _transformCtrl,
        // ✅ Paramètres zoom
        minScale:        0.5,
        maxScale:        5.0,
        // ✅ Permet le scroll quand dézoomé
        panEnabled:      true,
        scaleEnabled:    true,
        // ✅ Réinitialise _isZoomed quand l'utilisateur revient à scale 1
        onInteractionEnd: (details) {
          if (_transformCtrl.value.getMaxScaleOnAxis() <= 1.0) {
            setState(() => _isZoomed = false);
          } else {
            setState(() => _isZoomed = true);
          }
        },
        child: Center(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 48),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
              );
            },
          ),
        ),
      ),
    );
  }
}