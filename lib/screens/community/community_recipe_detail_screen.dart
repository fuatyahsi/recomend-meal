import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/community_recipe_model.dart';
import '../../models/rating_model.dart';
import '../../models/tried_recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/community_recipe_service.dart';
import '../../services/rating_service.dart';
import '../../services/tried_recipe_service.dart';
import '../../widgets/rating_stars_widget.dart';

class CommunityRecipeDetailScreen extends StatefulWidget {
  final CommunityRecipe recipe;
  const CommunityRecipeDetailScreen({super.key, required this.recipe});

  @override
  State<CommunityRecipeDetailScreen> createState() =>
      _CommunityRecipeDetailScreenState();
}

class _CommunityRecipeDetailScreenState
    extends State<CommunityRecipeDetailScreen> {
  final _recipeService = CommunityRecipeService();
  final _ratingService = RatingService();
  final _triedService = TriedRecipeService();

  bool _isLiked = false;
  int _likeCount = 0;
  List<RecipeRating> _ratings = [];
  List<TriedRecipe> _triedPhotos = [];
  int _userRating = 0;
  bool _isUploadingTried = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.recipe.totalLikes;
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    bool liked = false;
    List<RecipeRating> ratings = [];
    int userRatingVal = 0;
    List<TriedRecipe> triedPhotos = [];

    try {
      liked = await _recipeService.isLikedByUser(
          widget.recipe.id, auth.currentUser!.uid);
    } catch (e) {
      debugPrint('LoadData: isLikedByUser error: $e');
    }

    try {
      ratings = await _ratingService.getRecipeRatings(widget.recipe.id);
    } catch (e) {
      debugPrint('LoadData: getRecipeRatings error: $e');
    }

    try {
      final userRating = await _ratingService.getUserRating(
          widget.recipe.id, auth.currentUser!.uid);
      userRatingVal = userRating?.rating ?? 0;
    } catch (e) {
      debugPrint('LoadData: getUserRating error: $e');
    }

    try {
      triedPhotos = await _triedService.getTriedPhotos(widget.recipe.id);
      debugPrint('LoadData: Got ${triedPhotos.length} tried photos for recipe ${widget.recipe.id}');
    } catch (e) {
      debugPrint('LoadData: getTriedPhotos error: $e');
    }

    if (mounted) {
      setState(() {
        _isLiked = liked;
        _ratings = ratings;
        _userRating = userRatingVal;
        _triedPhotos = triedPhotos;
      });
    }
  }

  Future<void> _submitTriedPhoto() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 900,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!mounted) return;

    // Yorum dialogu
    final commentController = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTr ? 'Denedim!' : 'I Tried It!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(picked.path), height: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: isTr ? 'Bir yorum ekle (isteğe bağlı)' : 'Add a comment (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTr ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isTr ? 'Paylaş' : 'Share'),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    setState(() => _isUploadingTried = true);

    try {
      final result = await _triedService.submitTriedRecipe(
        recipeId: widget.recipe.id,
        userId: auth.currentUser!.uid,
        userDisplayName: auth.currentUser!.displayName,
        imageFile: File(picked.path),
        comment: commentController.text.trim(),
      );

      if (result != null) {
        setState(() {
          _triedPhotos.insert(0, result);
          _isUploadingTried = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTr ? 'Fotoğrafın paylaşıldı!' : 'Photo shared!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isUploadingTried = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTr ? 'Yükleme başarısız' : 'Upload failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingTried = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTr
                ? 'Yükleme hatası: $e'
                : 'Upload error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final liked = await _recipeService.toggleLike(
        widget.recipe.id, auth.currentUser!.uid);
    final refreshedRecipe = await _recipeService.getRecipeById(widget.recipe.id);
    if (!mounted) return;
    setState(() {
      _isLiked = liked;
      _likeCount = refreshedRecipe?.totalLikes ?? _likeCount;
    });
    await auth.refreshUser();
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final rating = RecipeRating(
      id: '',
      recipeId: widget.recipe.id,
      userId: auth.currentUser!.uid,
      userDisplayName: auth.currentUser!.displayName,
      userPhotoURL: auth.currentUser!.photoURL,
      rating: _userRating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _ratingService.addOrUpdateRating(rating);
    await auth.refreshUser();
    _commentController.clear();
    await _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.languageCode;
    final isTr = locale == 'tr';
    final recipe = widget.recipe;
    final steps = recipe.getSteps(locale);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(recipe.getName(locale),
                  style: const TextStyle(
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                    child: Text(recipe.imageEmoji,
                        style: const TextStyle(fontSize: 72))),
              ),
            ),
            actions: [
              // Like button
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                ),
                onPressed: _toggleLike,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author & stats
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Text(recipe.userDisplayName.isNotEmpty
                            ? recipe.userDisplayName[0].toUpperCase()
                            : '?'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recipe.userDisplayName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              '${isTr ? "Beğeni" : "Likes"}: $_likeCount',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (recipe.totalRatings > 0)
                        RatingStarsWidget(
                            rating: recipe.averageRating, size: 18),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(recipe.getDescription(locale),
                      style: theme.textTheme.bodyLarge),

                  const SizedBox(height: 20),

                  // Info chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InfoChip(Icons.timer_outlined, isTr ? 'Hazırlık' : 'Prep',
                          '${recipe.prepTimeMinutes} ${isTr ? "dk" : "min"}'),
                      _InfoChip(Icons.local_fire_department, isTr ? 'Pişirme' : 'Cook',
                          '${recipe.cookTimeMinutes} ${isTr ? "dk" : "min"}'),
                      _InfoChip(Icons.people_outline, isTr ? 'Porsiyon' : 'Servings',
                          '${recipe.servings}'),
                      _InfoChip(Icons.signal_cellular_alt, isTr ? 'Zorluk' : 'Difficulty',
                          recipe.getDifficultyText(locale)),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Steps
                  Text(isTr ? 'Hazırlanış' : 'Preparation',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  ...steps.map((step) => _StepRow(step: step, isTr: isTr)),

                  const Divider(height: 40),

                  // Rating Section
                  Text(isTr ? 'Puan Ver' : 'Rate This Recipe',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Center(
                    child: InteractiveRatingStars(
                      currentRating: _userRating,
                      onRatingChanged: (r) => setState(() => _userRating = r),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _commentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: isTr ? 'Yorum yaz (opsiyonel)' : 'Write a comment (optional)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _userRating > 0 ? _submitRating : null,
                      child: Text(isTr ? 'Puanla' : 'Submit Rating'),
                    ),
                  ),

                  const Divider(height: 40),

                  // "Denedim" Fotoğrafları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${isTr ? "Denedim" : "I Tried It"} (${_triedPhotos.length})',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isUploadingTried ? null : _submitTriedPhoto,
                        icon: _isUploadingTried
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_a_photo, size: 18),
                        label: Text(
                          isTr ? 'Ben de Denedim' : 'I Tried It Too',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_triedPhotos.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          isTr
                              ? 'Bu tarifi deneyen yok henüz. İlk sen dene!'
                              : 'No one has tried this yet. Be the first!',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _triedPhotos.length,
                        itemBuilder: (context, index) {
                          final tried = _triedPhotos[index];
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: tried.imageUrl,
                                    height: 140,
                                    width: 160,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      height: 140,
                                      color: Colors.grey.shade200,
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      height: 140,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tried.userDisplayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (tried.comment.isNotEmpty)
                                  Text(
                                    tried.comment,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const Divider(height: 40),

                  // Reviews list
                  Text(
                    '${isTr ? "Yorumlar" : "Reviews"} (${_ratings.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_ratings.isEmpty)
                    Center(
                      child: Text(
                        isTr ? 'Henüz yorum yok' : 'No reviews yet',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    )
                  else
                    ..._ratings.map((r) => _ReviewCard(rating: r)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final CommunityRecipeStep step;
  final bool isTr;
  const _StepRow({required this.step, required this.isTr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text('${step.stepNumber}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(step.instruction, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final RecipeRating rating;
  const _ReviewCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(rating.userDisplayName.isNotEmpty
                      ? rating.userDisplayName[0]
                      : '?'),
                ),
                const SizedBox(width: 8),
                Text(rating.userDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                RatingStarsWidget(
                    rating: rating.rating.toDouble(),
                    size: 14,
                    showValue: false),
              ],
            ),
            if (rating.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rating.comment),
            ],
          ],
        ),
      ),
    );
  }
}
