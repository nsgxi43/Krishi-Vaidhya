import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';

class FertilizerCalculatorScreen extends StatefulWidget {
  const FertilizerCalculatorScreen({super.key});

  @override
  State<FertilizerCalculatorScreen> createState() => _FertilizerCalculatorScreenState();
}

class _FertilizerCalculatorScreenState extends State<FertilizerCalculatorScreen> {
  final _acreController = TextEditingController();
  String _selectedCrop = 'Wheat';
  final List<String> _crops = ['Wheat', 'Rice', 'Corn', 'Potato', 'Tomato'];

  // Results
  double _ureaBags = 0;
  double _dapBags = 0;
  double _mopBags = 0;
  bool _showResult = false;

  void _calculate() {
    final double acres = double.tryParse(_acreController.text) ?? 0;
    if (acres <= 0) return;

    // --- STANDARD NPK REQUIREMENTS (kg per acre) ---
    // These are approximate standards.
    double reqN = 0, reqP = 0, reqK = 0;

    switch (_selectedCrop) {
      case 'Wheat':  reqN = 50; reqP = 25; reqK = 20; break;
      case 'Rice':   reqN = 40; reqP = 20; reqK = 20; break;
      case 'Corn':   reqN = 60; reqP = 30; reqK = 20; break;
      case 'Potato': reqN = 60; reqP = 40; reqK = 40; break;
      case 'Tomato': reqN = 50; reqP = 25; reqK = 25; break;
    }

    // --- CALCULATION LOGIC ---
    // 1. Calculate Total Kg needed for the given acres
    double totalN = reqN * acres;
    double totalP = reqP * acres;
    double totalK = reqK * acres;

    // 2. Fulfill Phosphorus (P) using DAP (18% N, 46% P)
    // DAP needed (kg) = Total P / 0.46
    double dapKg = totalP / 0.46;
    
    // DAP also gives some Nitrogen (18% of DAP weight)
    double nFromDap = dapKg * 0.18;

    // 3. Fulfill remaining Nitrogen (N) using Urea (46% N)
    double remainingN = totalN - nFromDap;
    if (remainingN < 0) remainingN = 0;
    double ureaKg = remainingN / 0.46;

    // 4. Fulfill Potassium (K) using MOP (60% K)
    double mopKg = totalK / 0.60;

    // 5. Convert Kg to Bags (Standard bag = 50kg) & round up
    setState(() {
      _dapBags = (dapKg / 50).ceilToDouble();
      _ureaBags = (ureaKg / 50).ceilToDouble();
      _mopBags = (mopKg / 50).ceilToDouble();
      _showResult = true;
      
      // Hide keyboard
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'calc_title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- INPUT CARD ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop Dropdown
                  Text(AppTranslations.getText(langCode, 'select_crop'), style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCrop,
                        isExpanded: true,
                        items: _crops.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedCrop = newValue!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Acre Input
                  Text(AppTranslations.getText(langCode, 'enter_land'), style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _acreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      hintText: "e.g. 2.5",
                      suffixText: "Acres"
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: Text(
                        AppTranslations.getText(langCode, 'calculate'), 
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- RESULT SECTION ---
            if (_showResult) ...[
              Text(
                AppTranslations.getText(langCode, 'result_header'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              _buildResultCard(
                langCode,
                labelKey: 'res_urea', 
                count: _ureaBags, 
                color: Colors.blue
              ),
              _buildResultCard(
                langCode,
                labelKey: 'res_dap', 
                count: _dapBags, 
                color: Colors.orange
              ),
              _buildResultCard(
                langCode,
                labelKey: 'res_mop', 
                count: _mopBags, 
                color: Colors.red
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String langCode, {required String labelKey, required double count, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(Icons.shopping_bag, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppTranslations.getText(langCode, labelKey),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            "${count.toStringAsFixed(0)} ${AppTranslations.getText(langCode, 'bags')}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
        ],
      ),
    );
  }
}