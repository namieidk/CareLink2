import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Medication.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _purposeController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _doctorController = TextEditingController();

  String _selectedTime = '08:00 AM';
  String _selectedPeriod = 'Morning';
  bool _isLoading = false;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked.format(context);
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      await FirebaseFirestore.instance.collection('medications').add({
        'patientId': user.uid,
        'name': _nameController.text.trim(),
        'dose': _doseController.text.trim(),
        'time': _selectedTime,
        'period': _selectedPeriod,
        'frequency': _frequencyController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'sideEffects': _sideEffectsController.text.trim(),
        'prescribedBy': _doctorController.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication added successfully!'),
            backgroundColor: PatientMedicationScreen.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: PatientMedicationScreen.danger,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _frequencyController.dispose();
    _purposeController.dispose();
    _instructionsController.dispose();
    _sideEffectsController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientMedicationScreen.bg,
      appBar: AppBar(
        backgroundColor: PatientMedicationScreen.card,
        elevation: 0, // No shadow
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PatientMedicationScreen.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: PatientMedicationScreen.primary,
            ),
          ),
        ),
        title: const Text(
          'Add Medication',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: PatientMedicationScreen.text,
          ),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PatientMedicationScreen.primary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveMedication,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: PatientMedicationScreen.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(PatientMedicationScreen.p4),
          children: [
            _buildTextField(_nameController, 'Medication Name', 'e.g. Metformin', Icons.medication),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildTextField(_doseController, 'Dose', 'e.g. 500mg', Icons.format_size),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildTimePicker(),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildDropdown(
              'Time of Day',
              _selectedPeriod,
              ['Morning', 'Afternoon', 'Evening', 'Night'],
              (val) => setState(() => _selectedPeriod = val!),
            ),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildTextField(_frequencyController, 'Frequency', 'e.g. Twice daily', Icons.repeat),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildTextField(_purposeController, 'Purpose', 'e.g. Diabetes', Icons.healing),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildTextField(_instructionsController, 'Instructions', 'e.g. With food', Icons.info_outline),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildTextField(_sideEffectsController, 'Side Effects', 'e.g. Nausea', Icons.warning_amber_outlined),
            const SizedBox(height: PatientMedicationScreen.p3),
            _buildTextField(_doctorController, 'Prescribed By', 'e.g. Dr. Martinez', Icons.local_hospital),
            const SizedBox(height: PatientMedicationScreen.p6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveMedication,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Medication'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientMedicationScreen.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (val) => val!.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: PatientMedicationScreen.primary),
        filled: true,
        fillColor: PatientMedicationScreen.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PatientMedicationScreen.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PatientMedicationScreen.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: PatientMedicationScreen.primary.withOpacity(0.5), width: 2),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: PatientMedicationScreen.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PatientMedicationScreen.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: PatientMedicationScreen.primary),
            const SizedBox(width: 12),
            Text('Time: $_selectedTime', style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: PatientMedicationScreen.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.schedule, color: PatientMedicationScreen.primary),
        filled: true,
        fillColor: PatientMedicationScreen.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PatientMedicationScreen.border),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}