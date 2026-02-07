import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../providers/language_provider.dart';
import '../utils/translations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _sowingDate;
  String _selectedCrop = 'Tomato'; // Default
  final List<String> _crops = ['Tomato', 'Potato', 'Wheat', 'Corn', 'Rice'];
  
  // Schedule Data
  List<Map<String, dynamic>> _schedule = [];

  void _generateSchedule() {
    if (_sowingDate == null) return;

    final start = _sowingDate!;
    _schedule.clear();

    // -- LOGIC: Simple Farming Timeline --
    // 1. Sowing (Day 0)
    _schedule.add({
      'day': 0,
      'date': start,
      'titleKey': 'activity_sow',
      'descKey': 'desc_sow',
      'icon': Icons.grass,
      'color': Colors.green,
    });

    // 2. Irrigation (Day 3)
    _schedule.add({
      'day': 3,
      'date': start.add(const Duration(days: 3)),
      'titleKey': 'activity_water',
      'descKey': 'desc_water',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    });

    // 3. Fertilizing (Day 15)
    _schedule.add({
      'day': 15,
      'date': start.add(const Duration(days: 15)),
      'titleKey': 'activity_fert',
      'descKey': 'desc_fert',
      'icon': Icons.science,
      'color': Colors.purple,
    });

    // 4. Harvest (Day 90 - Approx 3 months)
    _schedule.add({
      'day': 90,
      'date': start.add(const Duration(days: 90)),
      'titleKey': 'activity_harvest',
      'descKey': 'desc_harvest',
      'icon': Icons. agriculture,
      'color': Colors.orange,
    });

    setState(() {}); // Refresh UI
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _sowingDate) {
      setState(() {
        _sowingDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final dateFormat = DateFormat.yMMMd(); // e.g., "Oct 12, 2025"

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'calendar_title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- INPUT SECTION ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  // Crop Dropdown
                  Row(
                    children: [
                      const Icon(Icons.local_florist, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCrop,
                            isExpanded: true,
                            items: _crops.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (newValue) => setState(() => _selectedCrop = newValue!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Date Picker
                  InkWell(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.getText(langCode, 'sowing_date'),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              Text(
                                _sowingDate == null ? "-- / -- / --" : dateFormat.format(_sowingDate!),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.edit, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(AppTranslations.getText(langCode, 'generate_schedule'),
                        style: const TextStyle(color: Colors.white)
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- TIMELINE SECTION ---
            if (_schedule.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppTranslations.getText(langCode, 'your_plan'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _schedule.length,
                  itemBuilder: (context, index) {
                    final item = _schedule[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Column
                          SizedBox(
                            width: 60,
                            child: Column(
                              children: [
                                Text(
                                  DateFormat.MMM().format(item['date']), // "Oct"
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                Text(
                                  DateFormat.d().format(item['date']),   // "12"
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                          // Timeline Line
                          Column(
                            children: [
                              Container(
                                width: 2,
                                height: 10,
                                color: Colors.grey.shade300,
                              ),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: item['color'].withOpacity(0.2),
                                child: Icon(item['icon'], size: 16, color: item['color']),
                              ),
                              Container(
                                width: 2,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Details Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.getText(langCode, item['titleKey']),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppTranslations.getText(langCode, item['descKey']),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}