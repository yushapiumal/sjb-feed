import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:statelink/theme/app_theme.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _campaignsFuture = _fetchCampaigns();
  }

  Future<List<Map<String, dynamic>>> _fetchCampaigns() async {
    final snap = await _db
        .collection('campaigns')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _campaignsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentOrange),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load campaigns.',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            );
          }
          final campaigns = snapshot.data ?? [];

          return RefreshIndicator(
            color: AppColors.accentOrange,
            onRefresh: () async {
              setState(() => _campaignsFuture = _fetchCampaigns());
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accentOrange, Color(0xFFE07B00)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Support Our Movement',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your contribution fuels a better Sri Lanka.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                if (campaigns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.volunteer_activism,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No campaigns yet.\nAdd documents to the "campaigns"\ncollection in Firestore.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...campaigns.map((c) => _CampaignCard(campaign: c)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final String title = campaign['title'] ?? 'Campaign';
    final String description = campaign['description'] ?? '';
    final String imageUrl = campaign['imageUrl'] ?? '';
    final num goal = campaign['goal'] ?? 0;
    final num raised = campaign['raised'] ?? 0;
    final double progress = goal > 0
        ? (raised / goal).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final String donateUrl = campaign['donateUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 170,
                  color: const Color(0xFFF0F2F5),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.grey,
                    size: 48,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (goal > 0) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5C97E),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LKR ${_fmt(raised)} raised',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% of LKR ${_fmt(goal)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: donateUrl.isNotEmpty
                        ? () => _launchUrl(context, donateUrl)
                        : null,
                    icon: const Icon(Icons.favorite_rounded, size: 18),
                    label: Text(
                      'Donate Now',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  void _launchUrl(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: $url'),
        backgroundColor: AppColors.accentOrange,
      ),
    );
  }
}
