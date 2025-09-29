import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

class PracticeCalendarScreen extends ConsumerStatefulWidget {
  const PracticeCalendarScreen({super.key});

  @override
  ConsumerState<PracticeCalendarScreen> createState() =>
      _PracticeCalendarScreenState();
}

class _PracticeCalendarScreenState
    extends ConsumerState<PracticeCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  DateTime _today = DateTime.now();

  // Practice session data from Firebase
  Map<DateTime, PracticeSessionData> _practiceData = {};

  @override
  void initState() {
    super.initState();
    // Data will be loaded from Firebase via provider
  }

  void _loadPracticeDataFromProvider() async {
    try {
      final practiceMetadata = await ref.read(practiceSessionMetadataProvider.future);
      final Map<DateTime, PracticeSessionData> newData = {};

      for (final metadata in practiceMetadata) {
        final dateKey = DateTime(metadata.date.year, metadata.date.month, metadata.date.day);
        newData[dateKey] = PracticeSessionData(
          completedQuestions: metadata.completedQuestions,
          totalQuestions: metadata.totalQuestions,
          correctAnswers: (metadata.completedQuestions * metadata.accuracy).round(),
          lastActivity: metadata.date,
        );
      }

      if (mounted) {
        setState(() {
          _practiceData = newData;
        });
      }
    } catch (e) {
      print('❌ Error loading practice data: $e');
      // Keep empty data map to show "해당 날짜는 휴무!" for all dates
      if (mounted) {
        setState(() {
          _practiceData = {};
        });
      }
    }
  }

  void _refreshData() {
    // Invalidate the provider to force fresh data from Firebase
    ref.invalidate(practiceSessionMetadataProvider);
    // Reload data
    _loadPracticeDataFromProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPracticeDataFromProvider();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Daily Practice Calendar'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: _goToToday,
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Streak Statistics Card
          _buildStreakCard(),

          // Calendar View
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // Calendar Header
                  _buildCalendarHeader(),

                  // Calendar Grid
                  Expanded(
                    child: _buildCalendarGrid(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          _buildBottomActionButton(),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final currentStreak = _calculateCurrentStreak();
    final longestStreak = _calculateLongestStreak();
    final totalStudyDays = _practiceData.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3), // Blue
            Color(0xFF9C27B0), // Purple
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: currentStreak.toString(),
            label: '연속 공부',
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: Icons.emoji_events,
            value: longestStreak.toString(),
            label: '최고 기록',
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: Icons.menu_book,
            value: totalStudyDays.toString(),
            label: '공부 기간',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            _getMonthYearText(_focusedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar days
          Expanded(
            child: _buildCalendarDays(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final dayIndex = index - firstWeekday;

        if (dayIndex < 0 || dayIndex >= daysInMonth) {
          return const SizedBox.shrink(); // Empty cell
        }

        final date =
            DateTime(_focusedDate.year, _focusedDate.month, dayIndex + 1);
        return _buildCalendarDay(date);
      },
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    final practiceData =
        _practiceData[DateTime(date.year, date.month, date.day)];
    final isToday = _isSameDay(date, _today);
    final isSelected = _isSameDay(date, _selectedDate);
    final isFuture = date.isAfter(_today);

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.transparent;
    Color textColor = Colors.black87;
    Widget? statusIcon;

    if (isFuture) {
      // Future dates - grayed out
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.grey[400]!;
    } else if (practiceData != null) {
      if (practiceData.isCompleted) {
        if (practiceData.isPerfectScore) {
          // Perfect score - gold background with star
          backgroundColor = const Color(0xFFFFC107);
          textColor = Colors.white;
          statusIcon = const Icon(Icons.star, color: Colors.white, size: 12);
        } else {
          // Completed - green background
          backgroundColor = const Color(0xFF4CAF50);
          textColor = Colors.white;
        }
      } else {
        // In progress - orange background
        backgroundColor = const Color(0xFFFF9800);
        textColor = Colors.white;
      }
    }

    if (isToday) {
      borderColor = const Color(0xFF2196F3);
    }

    if (isSelected) {
      borderColor = const Color(0xFF9C27B0);
    }

    return GestureDetector(
      onTap: isFuture ? null : () => _selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: borderColor != Colors.transparent ? 2 : 0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: isToday || isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (statusIcon != null)
              Positioned(
                top: 2,
                right: 2,
                child: statusIcon,
              ),
            if (practiceData != null && !practiceData.isCompleted)
              Positioned(
                bottom: 2,
                left: 2,
                right: 2,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: practiceData.completedQuestions /
                        practiceData.totalQuestions,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButton() {
    final todayData =
        _practiceData[DateTime(_today.year, _today.month, _today.day)];

    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = AppColors.primaryColor;

    if (todayData == null) {
      buttonText = "Start Today's Practice";
      onPressed = _startTodaysPractice;
    } else if (!todayData.isCompleted) {
      buttonText =
          "Continue Practice (${todayData.completedQuestions}/${todayData.totalQuestions})";
      onPressed = _continueTodaysPractice;
      buttonColor = const Color(0xFFFF9800);
    } else {
      buttonText = "Today's Practice Complete ✓";
      onPressed = null;
      buttonColor = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    _showDateDetailsModal(date);
  }

  void _showDateDetailsModal(DateTime date) {
    final practiceData =
        _practiceData[DateTime(date.year, date.month, date.day)];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (practiceData == null) ...[
              const Icon(Icons.free_breakfast,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '오늘은 휴식일!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이 날짜에는 연습 문제가 없습니다.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.white,
                ),
                child: const Text('확인'),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailItem(
                    'Questions',
                    '${practiceData.completedQuestions}/${practiceData.totalQuestions}',
                    Icons.quiz,
                  ),
                  _buildDetailItem(
                    'Accuracy',
                    '${((practiceData.correctAnswers / practiceData.completedQuestions) * 100).round()}%',
                    Icons.track_changes,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (practiceData.isCompleted) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _retryPracticeForDate(date);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('Retry Practice'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _continuePracticeForDate(date);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                  ),
                  child: const Text('Continue Practice'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _goToToday() {
    setState(() {
      _focusedDate = _today;
      _selectedDate = _today;
    });
  }

  void _previousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
  }

  void _startTodaysPractice() {
    final dateString = _formatDateForApi(_today);
    context.push(
        '/part5/practice/session/firebase_${dateString.replaceAll('-', '_')}');
  }

  void _continueTodaysPractice() {
    final dateString = _formatDateForApi(_today);
    context.push(
        '/part5/practice/session/firebase_${dateString.replaceAll('-', '_')}');
  }

  void _startPracticeForDate(DateTime date) {
    final dateString = _formatDateForApi(date);
    context.push(
        '/part5/practice/session/firebase_${dateString.replaceAll('-', '_')}');
  }

  void _continuePracticeForDate(DateTime date) {
    final dateString = _formatDateForApi(date);
    context.push(
        '/part5/practice/session/firebase_${dateString.replaceAll('-', '_')}');
  }

  void _retryPracticeForDate(DateTime date) {
    final dateString = _formatDateForApi(date);
    context.push(
        '/part5/practice/session/firebase_${dateString.replaceAll('-', '_')}');
  }

  int _calculateCurrentStreak() {
    int streak = 0;
    DateTime checkDate = DateTime(_today.year, _today.month, _today.day);

    while (true) {
      final data = _practiceData[checkDate];
      if (data != null && data.isCompleted) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateLongestStreak() {
    int longestStreak = 0;
    int currentStreak = 0;

    final sortedDates = _practiceData.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final data = _practiceData[date];

      if (data != null && data.isCompleted) {
        currentStreak++;
        longestStreak =
            currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 0;
      }
    }

    return longestStreak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthYearText(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class PracticeSessionData {
  final int completedQuestions;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime lastActivity;

  PracticeSessionData({
    required this.completedQuestions,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.lastActivity,
  });

  bool get isCompleted => completedQuestions >= totalQuestions;
  bool get isPerfectScore => isCompleted && correctAnswers == totalQuestions;
  double get accuracy =>
      completedQuestions > 0 ? correctAnswers / completedQuestions : 0.0;
}
