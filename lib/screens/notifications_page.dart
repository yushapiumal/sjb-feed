import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statelink/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Set<String> _readIds = {};
  String? _memberId;

  @override
  void initState() {
    super.initState();
    _loadMemberId();
  }

  Future<void> _loadMemberId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _memberId = prefs.getString('member_id'));
  }

  Stream<QuerySnapshot> _notifStream() {
    Query q = _db
        .collection('notifications')
        .orderBy('createdAt', descending: true);
    return q.snapshots();
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'update':
        return Icons.system_update_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'alert':
        return Colors.red;
      case 'event':
        return AppColors.accentOrange;
      case 'update':
        return AppColors.primaryGreen;
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notifStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentOrange),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load notifications.',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];

          // filter: show global (no targetMemberId) + ones targeted to this member
          final visible = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final target = data['targetMemberId'];
            return target == null || target == '' || target == _memberId;
          }).toList();

          if (visible.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet.\nAdd documents to the\n"notifications" collection in Firestore.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final doc = visible[i];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = _readIds.contains(doc.id);
              final String type = data['type'] ?? '';

              return GestureDetector(
                onTap: () => setState(() => _readIds.add(doc.id)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : AppColors.primaryGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRead
                          ? Colors.transparent
                          : AppColors.primaryGreen.withOpacity(0.2),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _colorFor(type).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(type),
                          color: _colorFor(type),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? 'Notification',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            if ((data['message'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                data['message'],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              _timeAgo(data['createdAt']),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
