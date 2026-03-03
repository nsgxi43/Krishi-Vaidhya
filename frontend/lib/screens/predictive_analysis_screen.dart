import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prediction_alert.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../utils/translations.dart';

class PredictiveAnalysisScreen extends StatefulWidget {
  const PredictiveAnalysisScreen({super.key});

  @override
  State<PredictiveAnalysisScreen> createState() => _PredictiveAnalysisScreenState();
}

class _PredictiveAnalysisScreenState extends State<PredictiveAnalysisScreen> {
  PredictionResponse? _response;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.phone;

      // Get user location
      double lat = 12.9716;
      double lng = 77.5946;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 10));
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        // Use default Bangalore coordinates
      }

      final result = await ApiService.fetchPredictionAlerts(userId, lat, lng);
      setState(() {
        _response = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          AppTranslations.getText(langCode, 'pred_title'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _fetchAlerts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? _buildLoading(langCode)
          : _error != null
              ? _buildError(langCode)
              : _buildBody(langCode),
    );
  }

  Widget _buildLoading(String langCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.green),
          ),
          const SizedBox(height: 20),
          Text(
            AppTranslations.getText(langCode, 'pred_analyzing'),
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getText(langCode, 'pred_analyzing_sub'),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String langCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(AppTranslations.getText(langCode, 'pred_error'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchAlerts,
            icon: const Icon(Icons.refresh),
            label: Text(AppTranslations.getText(langCode, 'pred_retry')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String langCode) {
    final r = _response!;
    final hasMessage = r.message != null && r.message!.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      color: Colors.green,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          _buildSummaryCard(r, langCode),
          const SizedBox(height: 16),

          // Crops being monitored
          _buildCropsChip(r.cropsMonitored, langCode),
          const SizedBox(height: 16),

          // Message if no crops or no alerts
          if (hasMessage && r.alerts.isEmpty)
            _buildInfoBanner(r.message!, langCode)
          else if (r.alerts.isEmpty)
            _buildNoAlerts(langCode)
          else ...[
            Text(
              AppTranslations.getText(langCode, 'pred_alerts_header'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...r.alerts.map((alert) => _buildAlertCard(alert, langCode)),
          ],
        ],
      ),
    );
  }

  // ── Summary Card ───────────────────────────────────────────────────
  Widget _buildSummaryCard(PredictionResponse r, String langCode) {
    final high = r.summary.highRisk;
    final medium = r.summary.mediumRisk;
    final low = r.summary.lowRisk;

    Color headerColor;
    IconData headerIcon;
    String headerText;

    if (high > 0) {
      headerColor = Colors.red.shade700;
      headerIcon = Icons.warning_amber_rounded;
      headerText = AppTranslations.getText(langCode, 'pred_risk_high_banner');
    } else if (medium > 0) {
      headerColor = Colors.orange.shade700;
      headerIcon = Icons.info_outline;
      headerText = AppTranslations.getText(langCode, 'pred_risk_medium_banner');
    } else if (low > 0) {
      headerColor = Colors.green.shade700;
      headerIcon = Icons.check_circle_outline;
      headerText = AppTranslations.getText(langCode, 'pred_risk_low_banner');
    } else {
      headerColor = Colors.green.shade700;
      headerIcon = Icons.verified;
      headerText = AppTranslations.getText(langCode, 'pred_all_clear');
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor.withOpacity(0.15), headerColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(headerIcon, color: headerColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  headerText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: headerColor),
                ),
              ),
            ],
          ),
          if (r.summary.totalAlerts > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _riskBadge(high, AppTranslations.getText(langCode, 'pred_high'), Colors.red),
                _riskBadge(medium, AppTranslations.getText(langCode, 'pred_medium'), Colors.orange),
                _riskBadge(low, AppTranslations.getText(langCode, 'pred_low'), Colors.green),
              ],
            ),
          ],
          // Weather row
          if (r.weather != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (r.weather!.icon != null)
                  Image.network('https:${r.weather!.icon}', width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 24)),
                const SizedBox(width: 8),
                Text(
                  '${r.weather!.tempC?.toStringAsFixed(1) ?? '--'}°C  •  ${r.weather!.condition ?? '--'}  •  ${AppTranslations.getText(langCode, 'pred_humidity')} ${r.weather!.humidity ?? '--'}%',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _riskBadge(int count, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Crops Chip Row ─────────────────────────────────────────────────
  Widget _buildCropsChip(List<String> crops, String langCode) {
    if (crops.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        Text('${AppTranslations.getText(langCode, 'pred_monitoring')}: ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        ...crops.map((c) => Chip(
              label: Text(c, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.green.shade50,
              side: BorderSide(color: Colors.green.shade200),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )),
      ],
    );
  }

  // ── No Alerts ──────────────────────────────────────────────────────
  Widget _buildNoAlerts(String langCode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.shield, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            AppTranslations.getText(langCode, 'pred_no_alerts'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getText(langCode, 'pred_no_alerts_desc'),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Info Banner ────────────────────────────────────────────────────
  Widget _buildInfoBanner(String msg, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: Colors.blue.shade900))),
        ],
      ),
    );
  }

  // ── Alert Card ─────────────────────────────────────────────────────
  Widget _buildAlertCard(DiseaseAlert alert, String langCode) {
    Color riskColor;
    IconData riskIcon;

    switch (alert.riskLevel) {
      case 'high':
        riskColor = Colors.red;
        riskIcon = Icons.warning_amber_rounded;
        break;
      case 'medium':
        riskColor = Colors.orange;
        riskIcon = Icons.info_outline;
        break;
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle_outline;
    }

    String vectorLabel;
    IconData vectorIcon;
    switch (alert.vector) {
      case 'airborne':
        vectorLabel = AppTranslations.getText(langCode, 'pred_airborne');
        vectorIcon = Icons.air;
        break;
      case 'waterborne':
        vectorLabel = AppTranslations.getText(langCode, 'pred_waterborne');
        vectorIcon = Icons.water_drop;
        break;
      case 'insect':
        vectorLabel = AppTranslations.getText(langCode, 'pred_insect');
        vectorIcon = Icons.bug_report;
        break;
      case 'contact':
        vectorLabel = AppTranslations.getText(langCode, 'pred_contact');
        vectorIcon = Icons.pan_tool;
        break;
      default:
        vectorLabel = AppTranslations.getText(langCode, 'pred_wind');
        vectorIcon = Icons.air;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(riskIcon, color: riskColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.diseaseName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: riskColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppTranslations.getText(langCode, 'pred_affects')} ${alert.crop}  •  ${alert.caseCount} ${AppTranslations.getText(langCode, 'pred_cases_nearby')}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                // Risk score pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${(alert.riskScore * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Summary
                if (alert.aiSummary != null && alert.aiSummary!.isNotEmpty) ...[
                  Text(alert.aiSummary!, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                  const SizedBox(height: 14),
                ],

                // Spread info
                Row(
                  children: [
                    Icon(vectorIcon, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      '${AppTranslations.getText(langCode, 'pred_spread')}: $vectorLabel',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(alert.spreadDescription, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),

                // Weather warning
                if (alert.weatherFavorsSpread && alert.weatherFactors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud, size: 16, color: Colors.amber.shade800),
                            const SizedBox(width: 6),
                            Text(
                              AppTranslations.getText(langCode, 'pred_weather_warning'),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...alert.weatherFactors.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontSize: 12)),
                                  Expanded(child: Text(f, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],

                // Prevention tips
                if (alert.prevention.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    AppTranslations.getText(langCode, 'pred_prevention'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 6),
                  ...alert.prevention.take(4).map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3))),
                          ],
                        ),
                      )),
                ],

                // Expandable treatments
                const SizedBox(height: 8),
                _TreatmentExpander(alert: alert, langCode: langCode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Treatment Expander Widget ────────────────────────────────────────
class _TreatmentExpander extends StatefulWidget {
  final DiseaseAlert alert;
  final String langCode;
  const _TreatmentExpander({required this.alert, required this.langCode});

  @override
  State<_TreatmentExpander> createState() => _TreatmentExpanderState();
}

class _TreatmentExpanderState extends State<_TreatmentExpander> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final langCode = widget.langCode;

    if (alert.chemicalTreatments.isEmpty && alert.organicTreatments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                AppTranslations.getText(langCode, 'pred_treatments'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (alert.chemicalTreatments.isNotEmpty) ...[
            Text(AppTranslations.getText(langCode, 'pred_chemical'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 4),
            ...alert.chemicalTreatments.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.science, size: 12, color: Colors.purple),
                      const SizedBox(width: 6),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
          ],
          if (alert.organicTreatments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(AppTranslations.getText(langCode, 'pred_organic'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 4),
            ...alert.organicTreatments.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, size: 12, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
          ],
        ],
      ],
    );
  }
}
