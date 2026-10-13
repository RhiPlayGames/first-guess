import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_home_button.dart';
import 'first_pick_game_screen.dart';

class FirstPickCategoriesScreen extends StatefulWidget {
  const FirstPickCategoriesScreen({super.key});

  @override
  State<FirstPickCategoriesScreen> createState() =>
      _FirstPickCategoriesScreenState();
}

class _FirstPickCategoriesScreenState extends State<FirstPickCategoriesScreen> {
  Map<String, int> _counts = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      debugPrint(
        '[FIRST PICK CATEGORIES] project=${Firebase.app().options.projectId}',
      );
      // Temporary read-only diagnostic: check a document confirmed by Admin SDK.
      // A single-field query needs no category/status composite index.
      final snapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .where('category', isEqualTo: 'first_pick')
          .get(const GetOptions(source: Source.server));
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if ((data['status'] ?? '').toString() != 'live') continue;
        final key = (data['subcategory'] ?? '').toString().trim();
        if (key.isEmpty) continue;
        counts.update(key, (value) => value + 1, ifAbsent: () => 1);
      }
      debugPrint(
        '[FIRST PICK CATEGORIES] fetched=${snapshot.docs.length}, liveGroups=$counts',
      );
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _loading = false;
      });
    } on FirebaseException catch (e) {
      debugPrint('[FIRST PICK CATEGORIES] ${e.code}: ${e.message}');
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load categories (${e.code}).';
        _loading = false;
      });
    } catch (e) {
      debugPrint('[FIRST PICK CATEGORIES] unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load categories.';
        _loading = false;
      });
    }
  }

  static String _title(String key) {
    const titles = <String, String>{
      'books_authors': 'Books & Authors',
      'creative_world': 'Creative World',
      'food_drink': 'Food & Drink',
      'flavours_world': 'Food & Drink',
      'past_present': 'Past Worlds',
      'science_nature': 'Science & Nature',
      'watch_play': 'Watch & Play',
      'famous_people': 'Who Am I?',
      'famous_words': 'Famous Words',
    };
    return titles[key] ??
        key
            .split('_')
            .where((s) => s.isNotEmpty)
            .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
            .join(' ');
  }

  static String _image(String key) {
    // These are the same category artwork paths used by Classic First Guess.
    const paths = <String, String>{
      'animals': 'assets/images/categories/animals.webp',
      'books_authors': 'assets/images/categories/books_and_authors.webp',
      'countries': 'assets/images/categories/countries.webp',
      'creative_world': 'assets/images/categories/creative_world.webp',
      'famous_words': 'assets/images/categories/famous_words/famous_words.webp',
      'food_drink': 'assets/images/categories/food_and_drink.webp',
      'flavours_world': 'assets/images/categories/food_and_drink.webp',
      'music': 'assets/images/categories/music.webp',
      'past_present': 'assets/images/categories/past_and_present.webp',
      'science_nature': 'assets/images/categories/science_and_nature.webp',
      'sports': 'assets/images/categories/sports.webp',
      'watch_play': 'assets/images/categories/watch_and_play.webp',
      'famous_people': 'assets/images/categories/famous_people.webp',
    };
    if (paths.containsKey(key)) return paths[key]!;
    // Unknown keys keep a valid shared artwork rather than a missing image.
    return 'assets/images/categories/first_pick/firstpick_icon.webp';
  }

  Future<void> _open(String? category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FirstPickGameScreen(
          subcategory: category,
          categoryTitle: category == null ? 'Surprise Me' : _title(category),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
    final entries = _counts.entries.toList()
      ..sort((a, b) => _title(a.key).compareTo(_title(b.key)));
    final keys = <String?>[if (entries.isNotEmpty) null, ...entries.map((e) => e.key)];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        centerTitle: true,
        toolbarHeight: isDesktop ? 80 : 72,
        title: const Text('FIRST PICK', style: TextStyle(fontFamily: 'Oswald', fontSize: 28)),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: FirstGuessHomeButton()))],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1360 : double.infinity),
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _error != null || entries.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error ?? 'No live First Pick categories were returned.'),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('RETRY')),
                      ]))
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 16, isDesktop ? 24 : 16, 28),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [
                            const Expanded(child: _PickHeadingLine()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('CHOOSE A CATEGORY', style: AppTextStyles.category.copyWith(
                                color: AppColors.white, fontSize: isDesktop ? 22 : 18,
                                fontWeight: FontWeight.w600, letterSpacing: 0.5,
                              )),
                            ),
                            const Expanded(child: _PickHeadingLine(reverse: true)),
                          ]),
                          SizedBox(height: isDesktop ? 16 : 12),
                          if (!isDesktop)
                            Column(children: [for (final key in keys)
                              Padding(padding: const EdgeInsets.only(bottom: 12),
                                child: _PickCategoryCard(
                                  title: key == null ? 'Surprise Me' : _title(key),
                                  imagePath: key == null ? 'assets/images/categories/surprise_me.webp' : _image(key),
                                  onTap: () => _open(key),
                                )),
                            ])
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: keys.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 12, mainAxisExtent: 96,
                              ),
                              itemBuilder: (context, index) {
                                final key = keys[index];
                                return _PickCategoryCard(
                                  title: key == null ? 'Surprise Me' : _title(key),
                                  imagePath: key == null ? 'assets/images/categories/surprise_me.webp' : _image(key),
                                  onTap: () => _open(key),
                                );
                              },
                            ),
                        ]),
                      ),
          ),
        ),
      ),
    );
  }
}

class _PickHeadingLine extends StatelessWidget {
  const _PickHeadingLine({this.reverse = false});
  final bool reverse;
  @override
  Widget build(BuildContext context) => Container(
    height: 1.5,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
        end: reverse ? Alignment.centerLeft : Alignment.centerRight,
        colors: const [Colors.transparent, AppColors.orange],
      ),
      boxShadow: const [BoxShadow(color: Color(0x55FE5E02), blurRadius: 5)],
    ),
  );
}

class _PickCategoryCard extends StatelessWidget {
  const _PickCategoryCard({required this.title, required this.imagePath, required this.onTap});
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1200;
    final radius = isDesktop ? 16.0 : 22.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.orange, width: 1.8),
            boxShadow: const [BoxShadow(color: Color(0x2BFE5E02), blurRadius: 12, spreadRadius: 0.5)],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 14, vertical: isDesktop ? 10 : 14),
            child: Row(children: [
              Container(
                width: isDesktop ? 58 : 60, height: isDesktop ? 58 : 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(isDesktop ? 14 : 17),
                  border: Border.all(color: AppColors.orange, width: 1.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isDesktop ? 10 : 13),
                    child: Image.asset(imagePath, fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.quiz, color: AppColors.orange)),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 12 : 15),
              Expanded(child: Text(title.toUpperCase(), maxLines: 1,
                overflow: TextOverflow.ellipsis, style: AppTextStyles.category.copyWith(
                  color: AppColors.white, fontSize: isDesktop ? 20 : 17, letterSpacing: 0.15,
                ),
              )),
              SizedBox(width: isDesktop ? 12 : 10),
              Container(
                width: 118, height: 44, alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.orange,
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.orange, width: 1.2)),
                child: Text('PLAY', style: AppTextStyles.label.copyWith(
                  color: AppColors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
