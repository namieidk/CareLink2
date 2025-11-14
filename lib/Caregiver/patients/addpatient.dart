// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:country_state_city/country_state_city.dart' as csc;
// import '../patient.dart';

// class AddPatientScreen extends StatefulWidget {
//   const AddPatientScreen({super.key});

//   @override
//   State<AddPatientScreen> createState() => _AddPatientScreenState();
// }

// class _AddPatientScreenState extends State<AddPatientScreen> {
//   final _formKey = GlobalKey<FormState>();

//   // Controllers
//   final _firstNameCtrl = TextEditingController();
//   final _lastNameCtrl = TextEditingController();
//   final _ageCtrl = TextEditingController();
//   final _addressCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _conditionCtrl = TextEditingController();
//   final _bpCtrl = TextEditingController();
//   final _glucoseCtrl = TextEditingController();

//   // Dropdown selections
//   String? _selectedGender;
//   csc.Country? _selectedCountry;
//   String? _selectedCity;

//   String? _phoneNumber;
//   bool _isPhoneValid = false;
//   String? _photoPath;

//   Color _statusColor = const Color(0xFF4CAF50);
//   final List<TextEditingController> _medCtrls = [];
//   final List<Widget> _medFields = [];

//   final List<String> _genderOptions = ['Male', 'Female'];

//   // Countries & cities
//   List<csc.Country> _countries = [];
//   List<String> _availableCities = [];
//   bool _countriesLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadCountries();
//     _addMedField();
//   }

//   Future<void> _loadCountries() async {
//     try {
//       final countries = await csc.getAllCountries();
//       setState(() {
//         _countries = countries;
//         _countriesLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _countriesLoading = false;
//       });
//     }
//   }

//   Future<void> _loadCitiesForCountry(String? isoCode) async {
//     if (isoCode == null) {
//       setState(() => _availableCities = []);
//       return;
//     }
    
//     try {
//       // Use getCountryCities instead of getCities
//       final cities = await csc.getCountryCities(isoCode);
//       setState(() {
//         _selectedCity = null;
//         _availableCities = cities.map((city) => city.name).toList();
//       });
//     } catch (e) {
//       setState(() {
//         _selectedCity = null;
//         _availableCities = [];
//       });
//     }
//   }

//   void _addMedField() {
//     final ctrl = TextEditingController();
//     _medCtrls.add(ctrl);
//     setState(() {
//       _medFields.add(
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextFormField(
//                   controller: ctrl,
//                   decoration: InputDecoration(
//                     labelText: 'Medication (dose)',
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
//                     ),
//                   ),
//                 ),
//               ),
//               if (_medCtrls.length > 1)
//                 IconButton(
//                   icon: const Icon(Icons.remove_circle, color: Colors.red),
//                   onPressed: () {
//                     final idx = _medCtrls.indexOf(ctrl);
//                     setState(() {
//                       _medCtrls.removeAt(idx);
//                       _medFields.removeAt(idx);
//                     });
//                   },
//                 ),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Future<void> _pickImage() async {
//     try {
//       final picker = ImagePicker();
//       final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
//       if (picked != null) setState(() => _photoPath = picked.path);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to pick image')),
//       );
//     }
//   }

//   void _save() {
//     if (!_formKey.currentState!.validate()) return;

//     if (_selectedGender == null ||
//         _phoneNumber == null ||
//         !_isPhoneValid ||
//         _selectedCountry == null ||
//         _selectedCity == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     final meds = _medCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
//     if (meds.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Add at least one medication')),
//       );
//       return;
//     }

//     final patient = Patient(
//       name: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
//       age: int.parse(_ageCtrl.text),
//       gender: _selectedGender!,
//       phoneNumber: _phoneNumber!,
//       address: '${_addressCtrl.text.trim()}, $_selectedCity, ${_selectedCountry!.name}',
//       email: _emailCtrl.text.trim(),
//       condition: _conditionCtrl.text.trim(),
//       medications: meds,
//       nextMedication: 'Not set',
//       bloodPressure: _bpCtrl.text.trim(),
//       glucose: _glucoseCtrl.text.trim(),
//       statusColor: _statusColor,
//       photoPath: _photoPath,
//     );

//     Navigator.pop(context, patient);
//   }

//   @override
//   void dispose() {
//     _firstNameCtrl.dispose();
//     _lastNameCtrl.dispose();
//     _ageCtrl.dispose();
//     _addressCtrl.dispose();
//     _emailCtrl.dispose();
//     _conditionCtrl.dispose();
//     _bpCtrl.dispose();
//     _glucoseCtrl.dispose();
//     for (var c in _medCtrls) c.dispose();
//     super.dispose();
//   }

//   String _countryDisplay(csc.Country? c) => c == null ? '' : '${c.flag ?? ''} ${c.name}';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF6C5CE7),
//         title: const Text('Add New Patient', style: TextStyle(color: Colors.white)),
//         iconTheme: const IconThemeData(color: Colors.white),
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Photo
//               Center(
//                 child: Stack(
//                   children: [
//                     CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.grey[300],
//                       backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
//                       child: _photoPath == null
//                           ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                           : null,
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: InkWell(
//                         onTap: _pickImage,
//                         child: Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: const BoxDecoration(
//                             color: Color(0xFF6C5CE7),
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               _sectionTitle('Personal Information'),
//               const SizedBox(height: 16),

//               // First / Last name
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _firstNameCtrl,
//                       decoration: _inputDec('First Name', Icons.person_outline),
//                       validator: (v) => v!.trim().isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _lastNameCtrl,
//                       decoration: _inputDec('Last Name', Icons.person_outline),
//                       validator: (v) => v!.trim().isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // Age / Gender
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _ageCtrl,
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [
//                         FilteringTextInputFormatter.digitsOnly,
//                         LengthLimitingTextInputFormatter(3),
//                       ],
//                       decoration: _inputDec('Age', Icons.cake_outlined),
//                       validator: (v) {
//                         final age = int.tryParse(v ?? '');
//                         if (age == null || age < 1 || age > 120) return 'Valid age (1-120)';
//                         return null;
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: _inputDec('Gender', Icons.wc),
//                       items: _genderOptions
//                           .map((g) => DropdownMenuItem(value: g, child: Text(g)))
//                           .toList(),
//                       onChanged: (v) => setState(() => _selectedGender = v),
//                       validator: (v) => v == null ? 'Required' : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // Phone
//               IntlPhoneField(
//                 decoration: _inputDec('Phone Number', Icons.phone),
//                 initialCountryCode: 'PH',
//                 onChanged: (phone) {
//                   setState(() {
//                     _phoneNumber = phone.completeNumber;
//                     _isPhoneValid = phone.number.isNotEmpty;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16),

//               // Email
//               TextFormField(
//                 controller: _emailCtrl,
//                 decoration: _inputDec('Email Address', Icons.email_outlined),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return 'Required';
//                   final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//                   if (!emailRegex.hasMatch(v)) return 'Invalid email';
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),

//               // Country / City
//               Row(
//                 children: [
//                   Expanded(
//                     child: DropdownSearch<csc.Country>(
//                       selectedItem: _selectedCountry,
//                       items: _countries,
//                       itemAsString: _countryDisplay,
//                       popupProps: PopupProps.menu(
//                         showSearchBox: true,
//                         searchFieldProps: const TextFieldProps(
//                           decoration: InputDecoration(
//                             hintText: 'Search country...',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.all(Radius.circular(12)),
//                             ),
//                           ),
//                         ),
//                         loadingBuilder: (context, _) {
//                           if (_countriesLoading) {
//                             return const Padding(
//                               padding: EdgeInsets.all(16),
//                               child: Center(child: CircularProgressIndicator()),
//                             );
//                           }
//                           return const SizedBox.shrink();
//                         },
//                         emptyBuilder: (context, _) => const Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Center(child: Text('No countries found')),
//                         ),
//                         itemBuilder: (context, country, isSelected) {
//                           return ListTile(
//                             leading: Text(country.flag ?? '',
//                                 style: const TextStyle(fontSize: 24)),
//                             title: Text(country.name),
//                             selected: isSelected,
//                           );
//                         },
//                         constraints: const BoxConstraints(maxHeight: 300),
//                       ),
//                       dropdownDecoratorProps: DropDownDecoratorProps(
//                         dropdownSearchDecoration: _inputDec('Country', Icons.public).copyWith(
//                           suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C5CE7)),
//                         ),
//                       ),
//                       onChanged: (csc.Country? country) {
//                         setState(() {
//                           _selectedCountry = country;
//                           _selectedCity = null;
//                           _availableCities = [];
//                         });
//                         if (country != null) _loadCitiesForCountry(country.isoCode);
//                       },
//                       validator: (csc.Country? v) => v == null ? 'Required' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: DropdownSearch<String>(
//                       selectedItem: _selectedCity,
//                       items: _availableCities,
//                       enabled: _selectedCountry != null && _availableCities.isNotEmpty,
//                       popupProps: const PopupProps.menu(
//                         showSearchBox: true,
//                         searchFieldProps: TextFieldProps(
//                           decoration: InputDecoration(
//                             hintText: 'Search city...',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.all(Radius.circular(12)),
//                             ),
//                           ),
//                         ),
//                         constraints: BoxConstraints(maxHeight: 300),
//                       ),
//                       dropdownDecoratorProps: DropDownDecoratorProps(
//                         dropdownSearchDecoration: _inputDec('City', Icons.location_city).copyWith(
//                           suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C5CE7)),
//                         ),
//                       ),
//                       onChanged: (String? city) => setState(() => _selectedCity = city),
//                       validator: (String? v) => v == null ? 'Required' : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // Street address
//               TextFormField(
//                 controller: _addressCtrl,
//                 decoration: _inputDec('Street Address', Icons.home_outlined),
//                 maxLines: 2,
//                 validator: (v) => v!.trim().isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 24),

//               _sectionTitle('Medical Information'),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: _conditionCtrl,
//                 decoration: _inputDec('Medical Condition', Icons.local_hospital_outlined),
//                 validator: (v) => v!.trim().isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 16),

//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _bpCtrl,
//                       decoration: _inputDec('Blood Pressure', Icons.favorite),
//                       validator: (v) => v!.trim().isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _glucoseCtrl,
//                       decoration: _inputDec('Glucose', Icons.water_drop),
//                       validator: (v) => v!.trim().isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               _sectionTitle('Status Indicator'),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _colorOption(const Color(0xFF4CAF50), 'Healthy'),
//                   _colorOption(const Color(0xFFFFA726), 'Warning'),
//                   _colorOption(const Color(0xFFEF5350), 'Critical'),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Medications', style: TextStyle(fontWeight: FontWeight.w600)),
//                   IconButton(
//                     icon: const Icon(Icons.add_circle, color: Color(0xFF6C5CE7)),
//                     onPressed: _addMedField,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               ..._medFields,
//               const SizedBox(height: 32),

//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _save,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF6C5CE7),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: const Text(
//                     'Save Patient',
//                     style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper Widgets
//   InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       );

//   Widget _colorOption(Color color, String label) => GestureDetector(
//         onTap: () => setState(() => _statusColor = color),
//         child: Column(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: color,
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: _statusColor == color ? Colors.black : Colors.transparent,
//                   width: 3,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: _statusColor == color ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       );

//   Widget _sectionTitle(String text) => Text(
//         text,
//         style: const TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF6C5CE7),
//         ),
//       );
// }