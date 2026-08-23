import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/service_detail_page.dart';
import 'package:servekeen/theme/palette.dart';

class AllServicesPage extends StatelessWidget {
  final List<Service> services;
  final String title;

  const AllServicesPage({
    super.key,
    required this.services,
    this.title = 'All Services',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0D1218)
        : AppPalette.softBlendBackground;
    final appBarSurface = isDark ? const Color(0xFF151F2A) : Colors.white;
    final cardSurface = isDark ? const Color(0xFF1B2836) : Colors.white;
    final mutedSurface = isDark
        ? const Color(0xFF223142)
        : Colors.grey.shade200;
    final textPrimary = isDark ? const Color(0xFFEAF2FC) : AppPalette.deepBlue;
    final textSecondary = isDark
        ? const Color(0xFFB4C3D5)
        : AppPalette.deepBlue.withAlpha(150);
    final brandColor = isDark
        ? const Color(0xFF75AFFF)
        : AppPalette.fusionPurple;
    final borderColor = isDark
        ? Colors.white.withAlpha(24)
        : AppPalette.deepBlue.withAlpha(26);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarSurface,
        foregroundColor: textPrimary,
      ),
      body: services.isEmpty
          ? Center(
              child: Text(
                'No services available',
                style: GoogleFonts.poppins(color: textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final imgPath = service.primaryImageUrl ?? '';
                final localAsset = service.localAssetImage;
                final tier = service.priceTier;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailPage(service: service),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                          child: Container(
                            width: 120,
                            height: 120,
                            color: mutedSurface,
                            child: imgPath.isNotEmpty
                                ? Image.network(
                                    imgPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        localAsset != null
                                        ? Image.asset(
                                            localAsset,
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(Icons.broken_image),
                                  )
                                : localAsset != null
                                ? Image.asset(localAsset, fit: BoxFit.contain)
                                : const Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.serviceName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service.companyName,
                                  style: GoogleFonts.poppins(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      service.price != null
                                          ? '₹${service.price!.toStringAsFixed(0)}'
                                          : 'Price on Request',
                                      style: GoogleFonts.poppins(
                                        color: brandColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (service.perPrice != null &&
                                        service.perPrice!.isNotEmpty)
                                      Text(
                                        ' / ${service.perPrice}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    if (tier != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: service.isPremium
                                              ? AppPalette.fusionPurple
                                              : mutedSurface,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          tier,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: service.isPremium
                                                ? Colors.white
                                                : textPrimary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (service.locations != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            service.locations!,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Removed map redirection; service taps open detail page directly
}
