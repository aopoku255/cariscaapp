import 'package:cbfapp/models/ongoing_model.dart';
import 'package:cbfapp/services/ongoing_service.dart';
import 'package:cbfapp/theme/colors.dart';
import 'package:cbfapp/widgets/MainText.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeOngoing extends StatefulWidget {
  const HomeOngoing({super.key});

  @override
  State<HomeOngoing> createState() => _HomeOngoingState();
}

class _HomeOngoingState extends State<HomeOngoing>
    with TickerProviderStateMixin {
  late Future<ParallelSessionsResponse> _sessionsFuture;
  late AnimationController _animationController;
  final ParallelSessionsService _service = ParallelSessionsService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _sessionsFuture = _service.fetchOngoingSessions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Helper to combine session date and time strings into a DateTime
    DateTime _combineDateAndTime(DateTime date, String timeStr) {
      // Try common time formats returned by the API
      try {
        final parsed = DateFormat('h:mm a').parse(timeStr);
        return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
      } catch (_) {}

      try {
        final parsed = DateFormat('HH:mm').parse(timeStr);
        return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
      } catch (_) {}

      // Fallback: return date at midnight to avoid crashing
      return DateTime(date.year, date.month, date.day);
    }

    bool _isSessionActive(SessionData sd) {
      final sessionDate = sd.session.date;
      final start = _combineDateAndTime(sessionDate, sd.starttime);
      final end = _combineDateAndTime(sessionDate, sd.endtime);
      final now = DateTime.now();

      // If the end time is before the start time assume it crosses midnight and add a day
      DateTime adjustedEnd = end;
      if (!adjustedEnd.isAfter(start)) {
        adjustedEnd = adjustedEnd.add(const Duration(days: 1));
      }

      return now.isAfter(start) && now.isBefore(adjustedEnd);
    }

    String formatDate(String isoDateString) {
      final date = DateTime.parse(isoDateString);
      return DateFormat("MMM d").format(date);
    }

    return FutureBuilder<ParallelSessionsResponse>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
          return const Center(child: Text('No ongoing sessions'));
        }

        final sessions = snapshot.data!.data;

        // Filter to only sessions that are active right now
        final activeSessions = sessions.where((s) => _isSessionActive(s)).toList();

        if (activeSessions.isEmpty) {
          return const Center(child: Text('No ongoing sessions'));
        }

        final Map<String, List<SessionData>> groupedSessions = {};
        for (var session in activeSessions) {
          final sessionId = session.session.id.toString();
          if (!groupedSessions.containsKey(sessionId)) {
            groupedSessions[sessionId] = [];
          }
          groupedSessions[sessionId]!.add(session);
        }

        final groupedList = groupedSessions.entries.toList();

        // Only show the first matching group (per request: show the one that matches current time)
        final displayList = groupedList.isNotEmpty ? [groupedList.first] : <MapEntry<String, List<SessionData>>>[];

        return SizedBox(
          height: 240,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
               children: List.generate(displayList.length, (index) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                    )),
                     child: _buildSessionCard(displayList[index], formatDate),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(
      MapEntry<String, List<SessionData>> entry, Function(String) formatDate) {
    final sessionGroup = entry.value;
    final firstSession = sessionGroup[0];
    final sessionCount = sessionGroup.length;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          "/program-details",
          arguments: entry.value,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16, left: 4),
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeepBlue.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient background with blur effect
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDeepBlue.withValues(alpha: 0.85),
                    AppColors.primaryColor.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            // Overlay for depth
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            // Live badge
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    MainText(
                      text: 'LIVE NOW',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time and date badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: MainText(
                          text:
                              formatDate(firstSession.session.date.toString()),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: MainText(
                          text:
                              "${_formatTime(firstSession.starttime)} - ${_formatTime(firstSession.endtime)}",
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Session type label
                  MainText(
                    text: firstSession.name,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 8),
                  // Topic/Title
                  Expanded(
                    child: MainText(
                      text: firstSession.topic ?? firstSession.name,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Speaker avatars
                  if (firstSession.speakers.isNotEmpty)
                    SizedBox(
                      height: 32,
                      child: Stack(
                        children: List.generate(
                          firstSession.speakers.length > 2
                              ? 3
                              : firstSession.speakers.length,
                          (index) {
                            final showMore =
                                firstSession.speakers.length > 2 && index == 2;
                            return Positioned(
                              left: index * 20,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: showMore
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryDeepBlue,
                                        ),
                                        child: Center(
                                          child: MainText(
                                            text:
                                                '+${firstSession.speakers.length - 2}',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : (firstSession.speakers[index].image != null
                                        ? CircleAvatar(
                                            backgroundImage: AssetImage(
                                                firstSession.speakers[index].image!),
                                            backgroundColor: Colors.grey[300],
                                          )
                                        : CircleAvatar(
                                            backgroundColor: Colors.grey[300],
                                            child: Text(
                                              (firstSession.speakers[index].fname?.isNotEmpty ?? false)
                                                  ? firstSession.speakers[index].fname![0]
                                                  : '?',
                                              style: const TextStyle(color: Colors.black87),
                                            ),
                                          )),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Sessions count if multiple
                  if (sessionCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryDeepBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              AppColors.primaryDeepBlue.withValues(alpha: 0.25),
                        ),
                      ),
                      child: MainText(
                        text: '$sessionCount Presentations',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDeepBlue,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      // Try 24-hour format first
      final parsedTime = DateFormat("HH:mm").parse(time);
      return DateFormat("hh:mm a").format(parsedTime);
    } catch (_) {
      try {
        // Try 12-hour format with AM/PM
        final parsedTime = DateFormat("h:mm a").parse(time);
        return DateFormat("hh:mm a").format(parsedTime);
      } catch (e) {
        return time;
      }
    }
  }
}
