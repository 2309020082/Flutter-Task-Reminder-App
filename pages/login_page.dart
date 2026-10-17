import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _namaController = TextEditingController();
  final _npmController = TextEditingController();
  final _prodiController = TextEditingController();
  bool _isLoading = false;
  String? _errorNama;
  String? _errorNpm;

  @override
  void dispose() {
    _namaController.dispose();
    _npmController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  Future<void> _simpanProfil() async {
    setState(() {
      _errorNama = _namaController.text.trim().isEmpty ? 'Nama tidak boleh kosong' : null;
      _errorNpm = _npmController.text.trim().isEmpty ? 'NPM tidak boleh kosong' : null;
    });

    if (_errorNama != null || _errorNpm != null) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _namaController.text.trim());
    await prefs.setString('user_npm', _npmController.text.trim());
    await prefs.setString('user_prodi', _prodiController.text.trim());
    await prefs.setBool('is_logged_in', true);

    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tugas Kuliah',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lengkapi profilmu untuk memulai',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Buat Profil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Data ini hanya tersimpan di perangkatmu',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),

          // Nama
          _buildLabel('Nama Lengkap *'),
          _buildTextField(
            controller: _namaController,
            hint: 'Masukkan nama lengkap',
            icon: Icons.person_outline,
            errorText: _errorNama,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // NIM
          _buildLabel('NIM *'),
          _buildTextField(
            controller: _npmController,
            hint: 'Masukkan NPM',
            icon: Icons.badge_outlined,
            errorText: _errorNpm,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Prodi
          _buildLabel('Program Studi (Opsional)'),
          _buildTextField(
            controller: _prodiController,
            hint: 'Contoh: Teknik Informatika',
            icon: Icons.account_balance_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 32),

          // Tombol Mulai
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _simpanProfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Mulai Sekarang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}