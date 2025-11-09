import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../patient.dart'; // your Patient model

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();

  // Dropdown selections
  String? _selectedGender;
  String? _selectedCountry;
  String? _selectedCity;

  String? _phoneNumber;
  bool _isPhoneValid = false;
  String? _photoPath;

  Color _statusColor = const Color(0xFF4CAF50);
  final List<TextEditingController> _medCtrls = [];
  final List<Widget> _medFields = [];

  // Dropdown options
  final List<String> _genderOptions = ['Male', 'Female'];
  
  // Countries list
  final List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Argentina', 'Armenia',
    'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados',
    'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina',
    'Botswana', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cambodia',
    'Cameroon', 'Canada', 'Cape Verde', 'Central African Republic', 'Chad', 'Chile', 'China',
    'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic',
    'Denmark', 'Djibouti', 'Dominica', 'Dominican Republic', 'East Timor', 'Ecuador', 'Egypt',
    'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Ethiopia', 'Fiji', 'Finland',
    'France', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala',
    'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras', 'Hungary', 'Iceland', 'India',
    'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan', 'Jordan',
    'Kazakhstan', 'Kenya', 'Kiribati', 'North Korea', 'South Korea', 'Kuwait', 'Kyrgyzstan',
    'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania',
    'Luxembourg', 'Macedonia', 'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta',
    'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco',
    'Mongolia', 'Montenegro', 'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nauru', 'Nepal',
    'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'Norway', 'Oman', 'Pakistan',
    'Palau', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal',
    'Qatar', 'Romania', 'Russia', 'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia',
    'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe',
    'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia',
    'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 'South Sudan', 'Spain', 'Sri Lanka',
    'Sudan', 'Suriname', 'Swaziland', 'Sweden', 'Switzerland', 'Syria', 'Taiwan', 'Tajikistan',
    'Tanzania', 'Thailand', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey',
    'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom',
    'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu', 'Vatican City', 'Venezuela', 'Vietnam',
    'Yemen', 'Zambia', 'Zimbabwe'
  ];

  // Cities map - Philippines cities as example, you can add more countries
  final Map<String, List<String>> _citiesByCountry = {
    'Philippines': [
      'Manila', 'Quezon City', 'Caloocan', 'Davao City', 'Cebu City', 'Zamboanga City',
      'Taguig', 'Antipolo', 'Pasig', 'Cagayan de Oro', 'Parañaque', 'Valenzuela', 'Dasmariñas',
      'Las Piñas', 'Makati', 'Bacolod', 'General Santos', 'Bacoor', 'Iloilo City', 'Muntinlupa',
      'Cavite City', 'Baguio', 'San Jose del Monte', 'Mandaluyong', 'Calamba', 'Marikina',
      'Pasay', 'Malabon', 'Navotas', 'Batangas City', 'San Pedro', 'Mabalacat', 'Tarlac City',
      'Lapu-Lapu City', 'Mandaue', 'Angeles City', 'Tagum', 'Cabanatuan', 'Lucena', 'Olongapo'
    ],
    'United States': [
      'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio',
      'San Diego', 'Dallas', 'San Jose', 'Austin', 'Jacksonville', 'Fort Worth', 'Columbus',
      'Charlotte', 'San Francisco', 'Indianapolis', 'Seattle', 'Denver', 'Washington DC'
    ],
    'United Kingdom': [
      'London', 'Birmingham', 'Leeds', 'Glasgow', 'Sheffield', 'Manchester', 'Edinburgh',
      'Liverpool', 'Bristol', 'Cardiff', 'Belfast', 'Leicester', 'Coventry', 'Bradford',
      'Nottingham', 'Newcastle', 'Brighton', 'Southampton', 'Portsmouth', 'Reading'
    ],
    'Canada': [
      'Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Edmonton', 'Ottawa', 'Winnipeg',
      'Quebec City', 'Hamilton', 'Kitchener', 'London', 'Victoria', 'Halifax', 'Oshawa',
      'Windsor', 'Saskatoon', 'Regina', 'St. Catharines', 'Barrie', 'Kelowna'
    ],
    'Australia': [
      'Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Gold Coast', 'Canberra',
      'Newcastle', 'Wollongong', 'Logan City', 'Geelong', 'Hobart', 'Townsville', 'Cairns',
      'Darwin', 'Toowoomba', 'Ballarat', 'Bendigo', 'Albury', 'Launceston'
    ],
  };

  List<String> get _availableCities {
    if (_selectedCountry == null) return [];
    return _citiesByCountry[_selectedCountry] ?? ['Other'];
  }

  @override
  void initState() {
    super.initState();
    _addMedField(); // one field by default
  }

  void _addMedField() {
    final ctrl = TextEditingController();
    _medCtrls.add(ctrl);
    setState(() {
      _medFields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: 'Medication (dose)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                    ),
                  ),
                ),
              ),
              if (_medCtrls.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    final idx = _medCtrls.indexOf(ctrl);
                    setState(() {
                      _medCtrls.removeAt(idx);
                      _medFields.removeAt(idx);
                    });
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null ||
        _phoneNumber == null ||
        !_isPhoneValid ||
        _selectedCountry == null ||
        _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final meds = _medCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (meds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medication')),
      );
      return;
    }

    final patient = Patient(
      name: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
      age: int.parse(_ageCtrl.text),
      gender: _selectedGender!,
      phoneNumber: _phoneNumber!,
      address: '${_addressCtrl.text.trim()}, $_selectedCity, $_selectedCountry',
      email: _emailCtrl.text.trim(),
      condition: _conditionCtrl.text.trim(),
      medications: meds,
      nextMedication: 'Not set',
      bloodPressure: _bpCtrl.text.trim(),
      glucose: _glucoseCtrl.text.trim(),
      statusColor: _statusColor,
      photoPath: _photoPath,
    );

    Navigator.pop(context, patient);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _conditionCtrl.dispose();
    _bpCtrl.dispose();
    _glucoseCtrl.dispose();
    for (var c in _medCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C5CE7),
        title: const Text('Add New Patient', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                      child: _photoPath == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C5CE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionTitle('Personal Information'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: _inputDec('First Name', Icons.person_outline),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: _inputDec('Last Name', Icons.person_outline),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: _inputDec('Age', Icons.cake_outlined),
                      validator: (v) {
                        final age = int.tryParse(v ?? '');
                        if (age == null || age < 1 || age > 120) return 'Valid age (1-120)';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _inputDec('Gender', Icons.wc),
                      items: _genderOptions
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              IntlPhoneField(
                decoration: _inputDec('Phone Number', Icons.phone),
                initialCountryCode: 'PH',
                onChanged: (phone) {
                  setState(() {
                    _phoneNumber = phone.completeNumber;
                    _isPhoneValid = phone.number.isNotEmpty;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                decoration: _inputDec('Email Address', Icons.email_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v)) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Country and City Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownSearch<String>(
                      selectedItem: _selectedCountry,
                      items: _countries,
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search country...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                        constraints: BoxConstraints(maxHeight: 300),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: _inputDec('Country', Icons.public).copyWith(
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C5CE7)),
                        ),
                      ),
                      onChanged: (String? country) {
                        setState(() {
                          _selectedCountry = country;
                          _selectedCity = null;
                        });
                      },
                      validator: (String? v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownSearch<String>(
                      selectedItem: _selectedCity,
                      items: _availableCities,
                      enabled: _selectedCountry != null,
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search city...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                        constraints: BoxConstraints(maxHeight: 300),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: _inputDec('City', Icons.location_city).copyWith(
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C5CE7)),
                        ),
                      ),
                      onChanged: (String? city) => setState(() => _selectedCity = city),
                      validator: (String? v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressCtrl,
                decoration: _inputDec('Street Address', Icons.home_outlined),
                maxLines: 2,
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              _sectionTitle('Medical Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _conditionCtrl,
                decoration: _inputDec('Medical Condition', Icons.local_hospital_outlined),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bpCtrl,
                      decoration: _inputDec('Blood Pressure', Icons.favorite),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _glucoseCtrl,
                      decoration: _inputDec('Glucose', Icons.water_drop),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _sectionTitle('Status Indicator'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _colorOption(const Color(0xFF4CAF50), 'Healthy'),
                  _colorOption(const Color(0xFFFFA726), 'Warning'),
                  _colorOption(const Color(0xFFEF5350), 'Critical'),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Medications', style: TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF6C5CE7)),
                    onPressed: _addMedField,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._medFields,
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Save Patient',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  Widget _colorOption(Color color, String label) => GestureDetector(
        onTap: () => setState(() => _statusColor = color),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _statusColor == color ? Colors.black : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: _statusColor == color ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6C5CE7),
        ),
      );
}