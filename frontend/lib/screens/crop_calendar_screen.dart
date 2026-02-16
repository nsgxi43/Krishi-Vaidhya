import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/crop_item.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../services/calendar_service.dart';
import '../providers/user_provider.dart';
import 'package:geolocator/geolocator.dart';

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

  // Hardcoded supported crops for Calendar
  final List<CropItem> _calendarCrops = [
    CropItem(nameKey: 'Tomato', imagePath: 'assets/images/tomato.png', color: Colors.red.shade50),
    CropItem(nameKey: 'Potato', imagePath: 'assets/images/potato.png', color: Colors.brown.shade50),
    CropItem(nameKey: 'Corn', imagePath: 'assets/images/corn.png', color: Colors.yellow.shade50),
  ];

  List<dynamic> _lifecycle = [];
  bool _isLoading = false;

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
                      items: _calendarCrops.map((crop) {
                        return DropdownMenuItem(
                          value: crop,
                          child: Row( // Added Row to show image + text
                            children: [
                              Image.asset(crop.imagePath, width: 24, height: 24),
                              const SizedBox(width: 10),
                              Text(crop.nameKey),
                            ],
                          ),
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
                        onPressed: _isLoading ? null : _generateSchedule,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
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
                  itemCount: _lifecycle.length,
                  itemBuilder: (context, index) {
                    final activity = _lifecycle[index];
                    final dateStr = activity['scheduledDate'];
                    final eventDate = DateTime.parse(dateStr);
                    final isPast = eventDate.isBefore(DateTime.now());
                    final isRescheduled = activity['status'] == 'rescheduled';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isRescheduled ? Colors.orange.shade200 : Colors.grey.shade200,
                        ),
                      ),
                      color: isPast ? Colors.green.shade50 : (isRescheduled ? Colors.orange.shade50 : Colors.white),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPast ? Colors.green : (isRescheduled ? Colors.orange : Colors.blue.withOpacity(0.1)),
                          child: Icon(
                            isRescheduled ? Icons.event_repeat : (isPast ? Icons.check : Icons.calendar_today), 
                            color: (isPast || isRescheduled) ? Colors.white : Colors.blue
                          ),
                        ),
                        title: Text(
                          activity['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                            color: isPast ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity['description']),
                            if (isRescheduled)
                              Text(
                                "Rescheduled: ${activity['reschedulingReason'] ?? 'Weather adjustment'}",
                                style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: Text(
                          dateFormat.format(eventDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPast ? Colors.green : (isRescheduled ? Colors.orange : Colors.grey),
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

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _generateSchedule() async {
    if (_selectedCrop == null) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sowingDateStr = DateFormat('yyyy-MM-dd').format(_sowingDate);

    // Get Location
    double lat = 0.0;
    double lng = 0.0;
    
    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (e) {
      print("Error getting location: $e");
    }

    final result = await CalendarService.generateCalendar(
      userId: userProvider.phone,
      crop: _selectedCrop!.nameKey, 
      sowingDate: sowingDateStr,
      lat: lat,
      lng: lng,
    );

    if (result != null && result['calendar'] != null) {
      setState(() {
        _lifecycle = result['calendar']['lifecycle'];
        _isGenerated = true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate schedule")),
      );
    }
  }
}