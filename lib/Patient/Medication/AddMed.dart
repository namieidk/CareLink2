import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/Medication.dart';
import '../../models/doctor_profile.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _purposeController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _sideEffectsController = TextEditingController();

  List<String> _selectedTimes = ['08:00 AM'];
  String _selectedPeriod = 'Morning';
  String _selectedFrequency = 'Once daily';
  String? _selectedDoctorId;
  List<DoctorProfile> _doctors = [];
  bool _isLoading = false;
  bool _loadingDoctors = true;

  // Frequency options
  final List<String> _frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'Once weekly',
    'Twice weekly',
    'Three times weekly',
    'Once monthly',
    'As needed',
    'Before meals',
    'After meals',
    'With meals',
    'At bedtime',
    'In the morning',
    'In the evening',
    'Every other day',
    'Every 2 days',
    'Every 3 days',
    'Once every 2 weeks',
    'Once every 4 weeks',
    'On weekdays only',
    'On weekends only',
    'Monday, Wednesday, Friday',
    'Tuesday, Thursday',
    'Before physical activity',
    'After physical activity',
    'When symptoms occur',
    'As directed by doctor'
  ];

  // Color scheme
  static const Color primaryColor = Color(0xFFE91E63);
  static const Color backgroundColor = Color(0xFFfafafa);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF424242);
  static const Color textMuted = Color(0xFF757575);
  static const Color borderColor = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('doctor_profiles')
          .where('name', isNotEqualTo: null)
          .get();

      final List<DoctorProfile> doctors = snapshot.docs.map((doc) {
        return DoctorProfile.fromFirestore(doc);
      }).toList();

      setState(() {
        _doctors = doctors;
        _loadingDoctors = false;
        if (_doctors.isNotEmpty && _selectedDoctorId == null) {
          _selectedDoctorId = _doctors.first.id;
        }
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _loadingDoctors = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked.format(context);
      });
    }
  }

  void _addTimeSlot() {
    setState(() {
      _selectedTimes.add('08:00 AM');
    });
  }

  void _removeTimeSlot(int index) {
    if (_selectedTimes.length > 1) {
      setState(() {
        _selectedTimes.removeAt(index);
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a doctor'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      final selectedDoctor = _doctors.firstWhere(
        (doctor) => doctor.id == _selectedDoctorId,
        orElse: () => _doctors.first,
      );

      final medication = Medication(
        id: '',
        patientId: user.uid,
        name: _nameController.text.trim(),
        dose: _doseController.text.trim(),
        times: _selectedTimes,
        period: _selectedPeriod,
        frequency: _selectedFrequency,
        purpose: _purposeController.text.trim(),
        instructions: _instructionsController.text.trim(),
        sideEffects: _sideEffectsController.text.trim(),
        prescribedBy: selectedDoctor.name,
        prescribedById: _selectedDoctorId!,
        doctorSpecialty: selectedDoctor.specialty,
        doctorHospital: selectedDoctor.hospital,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('medications')
          .add(medication.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medication added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _purposeController.dispose();
    _instructionsController.dispose();
    _sideEffectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: primaryColor),
            padding: EdgeInsets.zero,
            iconSize: 20,
          ),
        ),
        title: Text(
          'Add Medication',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: _saveMedication,
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medication, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Medication',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Fill in the details below',
                          style: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildSectionHeader('Medication Details'),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Medication Name', 'e.g. Metformin', Icons.medication_outlined),
            const SizedBox(height: 16),
            _buildTextField(_doseController, 'Dose', 'e.g. 500mg', Icons.format_size),
            const SizedBox(height: 16),
            
            _buildSectionHeader('Schedule'),
            const SizedBox(height: 16),
            _buildTimeSlots(),
            const SizedBox(height: 12),
            _buildPeriodDropdown(),
            const SizedBox(height: 12),
            _buildFrequencyDropdown(),

            const SizedBox(height: 24),
            _buildSectionHeader('Additional Information'),
            const SizedBox(height: 16),
            _buildTextField(_purposeController, 'Purpose', 'e.g. Diabetes', Icons.healing),
            const SizedBox(height: 16),
            _buildTextField(_instructionsController, 'Instructions', 'e.g. With food', Icons.info_outline),
            const SizedBox(height: 16),
            _buildTextField(_sideEffectsController, 'Side Effects', 'e.g. Nausea', Icons.warning_amber_outlined),
            const SizedBox(height: 16),
            
            _buildDoctorDropdown(),

            const SizedBox(height: 32),
            Container(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveMedication,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.save, size: 20),
                label: Text(_isLoading ? 'Saving...' : 'Save Medication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (val) => val!.trim().isEmpty ? 'This field is required' : null,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withOpacity(0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      children: [
        ...List.generate(_selectedTimes.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: primaryColor.withOpacity(0.7)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedTimes[index],
                              style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_selectedTimes.length > 1)
                  IconButton(
                    onPressed: () => _removeTimeSlot(index),
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addTimeSlot,
          icon: Icon(Icons.add_circle_outline, color: primaryColor),
          label: Text('Add Another Time', style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPeriod,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Time of Day',
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: ['Morning', 'Afternoon', 'Evening', 'Night'].map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: TextStyle(color: textColor)),
      )).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedPeriod = value!;
        });
      },
      icon: Icon(Icons.keyboard_arrow_down, color: textMuted),
      dropdownColor: cardColor,
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFrequency,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Frequency',
        prefixIcon: Icon(Icons.repeat, color: primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: _frequencyOptions.map((frequency) => DropdownMenuItem(
        value: frequency,
        child: Text(
          frequency,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedFrequency = value!;
        });
      },
      icon: Icon(Icons.keyboard_arrow_down, color: textMuted),
      dropdownColor: cardColor,
      isExpanded: true,
      validator: (value) => value == null ? 'Please select frequency' : null,
    );
  }

  Widget _buildDoctorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prescribed By',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        _loadingDoctors
            ? Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_hospital, color: primaryColor.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Loading doctors...',
                        style: TextStyle(
                          fontSize: 16,
                          color: textMuted,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedDoctorId,
                  style: TextStyle(color: textColor, fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.local_hospital, color: primaryColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _doctors.map((doctor) => DropdownMenuItem(
                    value: doctor.id,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${doctor.name} - ${doctor.specialty}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedDoctorId = value;
                    });
                  },
                  icon: Icon(Icons.keyboard_arrow_down, color: textMuted),
                  dropdownColor: cardColor,
                  isExpanded: true,
                  validator: (value) => value == null ? 'Please select a doctor' : null,
                ),
              ),
      ],
    );
  }
}