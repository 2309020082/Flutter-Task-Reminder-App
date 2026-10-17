import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/notif_services.dart';

class AddPage extends StatefulWidget {
  final Tugas? tugasToEdit;
  const AddPage({super.key, this.tugasToEdit});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _namaTugasController = TextEditingController();
  final _mataKuliahController = TextEditingController();
  final _deskripsiController = TextEditingController();

  String _selectedPrioritas = 'Tinggi';
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  bool get _isEditMode => widget.tugasToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final t = widget.tugasToEdit!;
      _namaTugasController.text = t.namaTugas;
      _mataKuliahController.text = t.mataKuliah;
      _deskripsiController.text = t.deskripsi;
      _selectedPrioritas = t.prioritas;
      try {
        _selectedDeadline = DateTime.parse(t.deadline.replaceAll(' ', 'T'));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _namaTugasController.dispose();
    _mataKuliahController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _selectedDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDeadlineDisplay(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveTugas() async {
    if (_namaTugasController.text.trim().isEmpty) {
      _showError('Nama tugas tidak boleh kosong');
      return;
    }
    if (_mataKuliahController.text.trim().isEmpty) {
      _showError('Mata kuliah tidak boleh kosong');
      return;
    }
    if (_selectedDeadline == null) {
      _showError('Pilih deadline terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    final deadlineStr =
        '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')} ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}';

    try {
      if (_isEditMode) {
        final updated = widget.tugasToEdit!.copyWith(
          namaTugas: _namaTugasController.text.trim(),
          mataKuliah: _mataKuliahController.text.trim(),
          deadline: deadlineStr,
          prioritas: _selectedPrioritas,
          deskripsi: _deskripsiController.text.trim(),
        );
        await DBHelper.instance.updateTugas(updated);
        // Batalkan notif lama lalu jadwalkan ulang
        await NotifServices.cancelTugasNotifications(updated.id!);
        await NotifServices.scheduleDeadlineNotification(
          id: updated.id!,
          namaTugas: updated.namaTugas,
          mataKuliah: updated.mataKuliah,
          deadline: _selectedDeadline!,
        );
      } else {
        final tugas = Tugas(
          namaTugas: _namaTugasController.text.trim(),
          mataKuliah: _mataKuliahController.text.trim(),
          deadline: deadlineStr,
          prioritas: _selectedPrioritas,
          deskripsi: _deskripsiController.text.trim(),
        );
        final id = await DBHelper.instance.insertTugas(tugas);
        // Jadwalkan 3 notifikasi: H-1, 1 jam sebelum, tepat deadline
        await NotifServices.scheduleDeadlineNotification(
          id: id,
          namaTugas: tugas.namaTugas,
          mataKuliah: tugas.mataKuliah,
          deadline: _selectedDeadline!,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Tugas' : 'Tambah Tugas',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nama Tugas'),
            _buildTextField(
              controller: _namaTugasController,
              hint: 'Contoh: Tugas UI/UX',
            ),
            const SizedBox(height: 20),
            _buildLabel('Mata Kuliah'),
            _buildTextField(
              controller: _mataKuliahController,
              hint: 'Contoh: Interaksi Manusia Komputer',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            _buildLabel('Deadline'),
            _buildDeadlinePicker(),
            const SizedBox(height: 20),
            _buildLabel('Prioritas'),
            _buildPrioritasPicker(),
            const SizedBox(height: 20),
            _buildLabel('Deskripsi (Opsional)'),
            _buildTextField(
              controller: _deskripsiController,
              hint: 'Tambahkan deskripsi tugas...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return GestureDetector(
      onTap: _pickDeadline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _selectedDeadline != null
                  ? _formatDeadlineDisplay(_selectedDeadline!)
                  : 'Pilih tanggal & waktu',
              style: TextStyle(
                fontSize: 14,
                color: _selectedDeadline != null
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritasPicker() {
    final options = ['Tinggi', 'Sedang', 'Rendah'];
    final colors = {
      'Tinggi': const Color(0xFFEF4444),
      'Sedang': const Color(0xFFF59E0B),
      'Rendah': const Color(0xFF22C55E),
    };

    return Row(
      children: options.map((opt) {
        final isSelected = _selectedPrioritas == opt;
        final color = colors[opt]!;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt != 'Rendah' ? 10 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPrioritas = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTugas,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'SIMPAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}