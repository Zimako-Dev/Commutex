import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/modern_widgets.dart';

class ResultPage extends StatelessWidget {
  final TripResult result;

  const ResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text("Trip Estimate")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Total Price Card
            SleekCard(
              color: Theme.of(context).colorScheme.primary,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      "Estimated Fare",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      currencyFormat.format(result.totalFare),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${result.distanceKm} km • ~${result.durationMinutes.toInt()} min",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Route Summary
            const SectionHeader(title: "Route Summary"),
            SleekCard(
              child: Column(
                children: [
                  _buildRouteStep(context, result.start, isFirst: true),
                  ...result.stops.map((stop) => _buildRouteStep(context, stop)),
                  _buildRouteStep(context, result.end, isLast: true),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Cost Breakdown
            const SectionHeader(title: "Cost Breakdown"),
            SleekCard(
              child: Column(
                children: [
                  ...result.breakdown.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          currencyFormat.format(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(result.totalFare),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Route saved to favorites!")),
                      );
                    },
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text("Save"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: "Share",
                    icon: Icons.share,
                     onPressed: () => _shareViaWhatsApp(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);
    final List<String> parts = [];
    parts.add('🚕 SmartTaxi Trip Details');
    parts.add('From: ${result.start.name}');
    if (result.stops.isNotEmpty) {
      final stopsText = result.stops.map((s) => s.name).join(' → ');
      parts.add('Stops: $stopsText');
    }
    parts.add('To: ${result.end.name}');
    parts.add('Distance: ${result.distanceKm.toStringAsFixed(1)} km');
    parts.add('Duration: ~${result.durationMinutes.toInt()} min');
    parts.add('Estimated Fare: ${currencyFormat.format(result.totalFare)}');
    parts.add('Shared via SmartTaxi 🇿🇦');

    final text = parts.join('\n');

    try {
      // Prefer native scheme on mobile; fall back to universal wa.me link.
      final whatsappUri = Uri(scheme: 'whatsapp', host: 'send', queryParameters: {'text': text});
      final waMeUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

      if (!kIsWeb && await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to web-friendly wa.me link
      final launched = await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
        }
      }
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to share. Please try again.')));
      }
    }
  }

  Widget _buildRouteStep(BuildContext context, Location loc, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isFirst ? Colors.green : (isLast ? Colors.red : Colors.grey),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    loc.type.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
