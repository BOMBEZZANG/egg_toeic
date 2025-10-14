import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExamHubScreen extends ConsumerWidget {
  const ExamHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Exam Mode',
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
                      Color(0xFFE3F2FD),
                      Color(0xFFBBDEFB),
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
                        Icons.assignment_rounded,
                        color: Color(0xFF1976D2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        '실전처럼 시험을 치르고\n실력을 점검하세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0D47A1),
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Reading Section Header
              _buildSectionHeader(
                'Reading Section',
                Icons.menu_book,
                const Color(0xFF4ECDC4),
              ),
              const SizedBox(height: 16),

              // Reading Parts (5-7)
              _buildReadingPartsGrid(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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

  Widget _buildReadingPartsGrid(BuildContext context) {
    final readingParts = [
      _PartInfo(
        partNumber: 5,
        title: 'Part 5',
        subtitle: 'Incomplete Sentences',
        description: '30 Questions',
        icon: Icons.edit_note,
        color: const Color(0xFF4ECDC4),
        isAvailable: true,
        availableRounds: 10,
      ),
      _PartInfo(
        partNumber: 6,
        title: 'Part 6',
        subtitle: 'Text Completion',
        description: '16 Questions',
        icon: Icons.article,
        color: const Color(0xFF45B7D1),
        isAvailable: true,
        availableRounds: 5,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: readingParts.length,
      itemBuilder: (context, index) {
        return _buildPartCard(context, readingParts[index]);
      },
    );
  }

  Widget _buildPartCard(BuildContext context, _PartInfo partInfo) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: partInfo.isAvailable
            ? () => _navigateToPart(context, partInfo.partNumber)
            : () => _showComingSoonDialog(context, partInfo.title),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: partInfo.isAvailable
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
                color: partInfo.isAvailable
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
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        partInfo.isAvailable && partInfo.availableRounds > 0
                            ? '${partInfo.availableRounds} Rounds'
                            : partInfo.description,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lock icon or "Soon" badge for unavailable parts
              if (!partInfo.isAvailable)
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
                      Icons.lock,
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
      // Navigate to Part 5 exam level/round selection
      context.push('/part5/exam-levels');
    } else if (partNumber == 6) {
      // Navigate to Part 6 exam round selection
      context.push('/part6/exam-rounds');
    } else {
      // For future implementation
      _showComingSoonDialog(context, 'Part $partNumber');
    }
  }

  void _showComingSoonDialog(BuildContext context, String partName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.construction, color: Color(0xFFFF9800), size: 28),
            SizedBox(width: 12),
            Text(
              '준비 중',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$partName 시험 기능을 열심히 준비하고 있어요!\n조금만 기다려주세요 😊',
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

class _PartInfo {
  final int partNumber;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final int availableRounds;

  _PartInfo({
    required this.partNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.isAvailable,
    this.availableRounds = 0,
  });
}
