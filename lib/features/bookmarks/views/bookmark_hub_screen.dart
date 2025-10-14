import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/providers/app_providers.dart';

class BookmarkHubScreen extends ConsumerWidget {
  const BookmarkHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Bookmark Hub',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF3E0),
                      Color(0xFFFFE0B2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bookmark,
                        color: Color(0xFFFF9600),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        '중요한 문제를 저장하고\n나중에 복습하세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE65100),
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Statistics Card
              favoritesAsync.when(
                loading: () => _buildStatsCard(0, 0),
                error: (error, stack) => _buildStatsCard(0, 0),
                data: (favorites) {
                  final List<String> favoritesList = favorites.toList();

                  final part5Count = favoritesList.where((String id) {
                    return id.startsWith('Part5_') || !id.startsWith('Part6_');
                  }).length;

                  final part6Count = favoritesList.where((String id) {
                    return id.startsWith('Part6_');
                  }).length;

                  return _buildStatsCard(part5Count, part6Count);
                },
              ),

              const SizedBox(height: 32),

              // Section Header
              _buildSectionHeader(
                'Review by Part',
                Icons.menu_book,
                const Color(0xFFFF9600),
              ),
              const SizedBox(height: 16),

              // Parts Grid
              _buildPartsGrid(context, favoritesAsync),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int part5Count, int part6Count) {
    final totalCount = part5Count + part6Count;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9600),
            Color(0xFFFFB74D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9600).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '총 북마크한 문제',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Part 5', part5Count),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem('Part 6', part6Count),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPartsGrid(BuildContext context, AsyncValue favoritesAsync) {
    return favoritesAsync.when(
      loading: () => _buildPartsGridContent(context, 0, 0),
      error: (error, stack) => _buildPartsGridContent(context, 0, 0),
      data: (favorites) {
        final List<String> favoritesList = favorites.toList();

        final part5Count = favoritesList.where((String id) {
          return id.startsWith('Part5_') || !id.startsWith('Part6_');
        }).length;

        final part6Count = favoritesList.where((String id) {
          return id.startsWith('Part6_');
        }).length;

        return _buildPartsGridContent(context, part5Count, part6Count);
      },
    );
  }

  Widget _buildPartsGridContent(BuildContext context, int part5Count, int part6Count) {
    final parts = [
      _BookmarkPartInfo(
        partNumber: 5,
        title: 'Part 5',
        subtitle: 'Grammar & Vocabulary',
        icon: Icons.edit_note,
        color: const Color(0xFF1CB0F6),
        bookmarkCount: part5Count,
      ),
      _BookmarkPartInfo(
        partNumber: 6,
        title: 'Part 6',
        subtitle: 'Reading Comprehension',
        icon: Icons.article,
        color: const Color(0xFF42A5F5),
        bookmarkCount: part6Count,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        return _buildPartCard(context, parts[index]);
      },
    );
  }

  Widget _buildPartCard(BuildContext context, _BookmarkPartInfo partInfo) {
    final hasBookmarks = partInfo.bookmarkCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasBookmarks
            ? () => _navigateToPart(context, partInfo.partNumber)
            : () => _showNoBookmarksDialog(context, partInfo.title),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasBookmarks
                  ? [
                      partInfo.color,
                      partInfo.color.withOpacity(0.7),
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[400]!,
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: hasBookmarks
                    ? partInfo.color.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        partInfo.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      partInfo.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Subtitle
                    Text(
                      partInfo.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasBookmarks ? '${partInfo.bookmarkCount} 문제' : '없음',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Star icon for no bookmarks
              if (!hasBookmarks)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark_border,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPart(BuildContext context, int partNumber) {
    if (partNumber == 5) {
      context.push('/bookmarks/part5');
    } else if (partNumber == 6) {
      context.push('/bookmarks/part6');
    }
  }

  void _showNoBookmarksDialog(BuildContext context, String partName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.bookmark_border, color: Color(0xFFFF9600), size: 28),
            SizedBox(width: 12),
            Text(
              '북마크 없음',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$partName에 북마크한 문제가 없습니다.\n중요한 문제를 북마크하세요! 📚',
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkPartInfo {
  final int partNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int bookmarkCount;

  _BookmarkPartInfo({
    required this.partNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bookmarkCount,
  });
}
