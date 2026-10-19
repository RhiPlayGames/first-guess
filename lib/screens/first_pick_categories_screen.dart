import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
      'surprise_me': 'Surprise Me',
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
      'surprise_me': 'assets/images/categories/surprise_me.webp',
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

  Future<void> _open(String category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FirstPickGameScreen(
          subcategory: category == 'surprise_me' ? null : category,
          categoryTitle: _title(category),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
    final entries = <MapEntry<String, int>>[
      const MapEntry<String, int>('surprise_me', 0),
      ...(_counts.entries.toList()
        ..sort((a, b) => _title(a.key).compareTo(_title(b.key)))),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        toolbarHeight: isDesktop ? 80 : 72,
        title: SizedBox(
          height: isDesktop ? 76 : 64,
          child: Image.asset(
            'assets/images/categories/category_headers/first_pick_logo.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: FirstGuessHomeButton()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1360 : 760),
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null || entries.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error ??
                            'No live First Pick categories were returned.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('RETRY'),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: Container(height: 1.5, color: AppColors.orange)),
                          const SizedBox(width: 10),
                          Text('CHOOSE A CATEGORY', style: TextStyle(
                            fontFamily: 'Oswald', fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.w600, letterSpacing: 0.5,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: Container(height: 1.5, color: AppColors.orange)),
                        ]),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = isDesktop ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entries.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: isDesktop ? 96 : 88,
                                  ),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return Material(
                                  color: AppColors.panel,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _open(entry.key),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 14, vertical: isDesktop ? 10 : 14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.orange,
                                          width: 1.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: isDesktop ? 58 : 60,
                                            height: isDesktop ? 58 : 60,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.orange, width: 1.4),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Image.asset(
                                              _image(entry.key),
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.quiz,
                                                    color: AppColors.orange,
                                                    size: 34,
                                                  ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: isDesktop ? 12 : 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _title(entry.key).toUpperCase(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Oswald',
                                                    fontSize: isDesktop ? 20 : 17,
                                                  ),
                                                ),

                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: isDesktop ? 118 : 94,
                                            height: 44,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              'PLAY',
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
