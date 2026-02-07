import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import '../models/crop_item.dart';
import '../models/calendar_event.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';

class CropCalendarScreen extends StatefulWidget {
  final List<CropItem> myCrops;

  const CropCalendarScreen({super.key, required this.myCrops});

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  CropItem? _selectedCrop;
  DateTime _sowingDate = DateTime.now();
  bool _isGenerated = false;

  // DUMMY LOGIC: In a real app, this would come from a database based on the crop type
  final List<CalendarEvent> _standardEvents = [
    CalendarEvent(titleKey: 'activity_sow', descriptionKey: 'desc_sow', daysAfterSowing: 0, icon: Icons.grass, color: Colors.green),
    CalendarEvent(titleKey: 'activity_water', descriptionKey: 'desc_water', daysAfterSowing: 3, icon: Icons.water_drop, color: Colors.blue),
    CalendarEvent(titleKey: 'activity_fert', descriptionKey: 'desc_fert', daysAfterSowing: 15, icon: Icons.science, color: Colors.purple),
    CalendarEvent(titleKey: 'activity_water', descriptionKey: 'desc_water', daysAfterSowing: 21, icon: Icons.water_drop, color: Colors.blue),
    CalendarEvent(titleKey: 'activity_harvest', descriptionKey: 'desc_harvest', daysAfterSowing: 90, icon: Icons.agriculture, color: Colors.orange),
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _sowingDate = picked;
        _isGenerated = false; // Reset if date changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final dateFormat = DateFormat('d MMM yyyy', langCode); // Localized Date

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'calendar_title')),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Inputs ---
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Crop Dropdown
                    DropdownButtonFormField<CropItem>(
                      decoration: InputDecoration(
                        labelText: AppTranslations.getText(langCode, 'select_crop'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _selectedCrop,
                      items: widget.myCrops.map((crop) {
                        return DropdownMenuItem(
                          value: crop,
                          child: Text(crop.nameKey), // Note: You might need to translate this dynamically
                        );
                      }).toList(),
                      onChanged: (val) => setState(() {
                        _selectedCrop = val;
                        _isGenerated = false;
                      }),
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${AppTranslations.getText(langCode, 'sowing_date')}: ${dateFormat.format(_sowingDate)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Colors.green),
                          onPressed: _pickDate,
                        )
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedCrop != null) {
                            setState(() => _isGenerated = true);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                        child: Text(
                          AppTranslations.getText(langCode, 'generate_schedule'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // --- 2. Timeline List ---
            if (_isGenerated) ...[
              Text(
                AppTranslations.getText(langCode, 'your_plan'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _standardEvents.length,
                  itemBuilder: (context, index) {
                    final event = _standardEvents[index];
                    final eventDate = _sowingDate.add(Duration(days: event.daysAfterSowing));
                    final isPast = eventDate.isBefore(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isPast ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                      ),
                      color: isPast ? Colors.green.shade50 : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPast ? Colors.green : event.color.withOpacity(0.1),
                          child: Icon(event.icon, color: isPast ? Colors.white : event.color),
                        ),
                        title: Text(
                          AppTranslations.getText(langCode, event.titleKey),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                            color: isPast ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Text(AppTranslations.getText(langCode, event.descriptionKey)),
                        trailing: Text(
                          dateFormat.format(eventDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPast ? Colors.green : Colors.grey,
                            fontSize: 12
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}