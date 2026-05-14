import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/service_detail_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: services.isEmpty
          ? const Center(child: Text('No services available'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final imgPath = service.primaryImageUrl ?? '';
                final tier = service.priceTier;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ServiceDetailPage(service: service)),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[200],
                            child: imgPath.isNotEmpty
                                ? Image.network(
                                    imgPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.image, size: 40, color: Colors.grey),
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
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service.companyName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
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
                                      service.price != null ? '₹${service.price!.toStringAsFixed(0)}' : 'Price on Request',
                                      style: GoogleFonts.poppins(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (service.perPrice != null && service.perPrice!.isNotEmpty)
                                      Text(
                                        ' / ${service.perPrice}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                      ),
                                    if (tier != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: service.isPremium ? Colors.deepPurple : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          tier,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: service.isPremium ? Colors.white : Colors.black87,
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
                                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            service.locations!,
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
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
