import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/notif_services.dart';
import 'add_page.dart';

class DetailPage extends StatefulWidget {
  final Tugas tugas;
  const DetailPage({super.key, required this.tugas});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Tugas _tugas;

  @override
  void initState() {
    super.initState();
    _tugas = widget.tugas;
  }

  Color _getPrioritasColor(String prioritas) {
    switch (prioritas) {
      case 'Tinggi':
        return const Color(0xFFEF4444);
      case 'Sedang':
        return const Color(0xFFF59E0B);
      case 'Rendah':
        return const Color(0xFF22C55E);
      default:
        return Colors.grey;
    }
  }

  String _formatDeadline(String deadline) {
    try {
      final dt = DateTime.parse(deadline.replaceAll(' ', 'T'));
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return deadline;
    }
  }

  IconData _getMataKuliahIcon(String mataKuliah) {
    if (mataKuliah.toLowerCase().contains('komputer') ||
        mataKuliah.toLowerCase().contains('jaringan')) {
      return Icons.computer;
    } else if (mataKuliah.toLowerCase().contains('kimia')) {
      return Icons.science;
    } else if (mataKuliah.toLowerCase().contains('kecerdasan') ||
        mataKuliah.toLowerCase().contains('ai')) {
      return Icons.psychology;
    } else {
      return Icons.menu_book;
    }
  }

  Future<void> _toggleStatus() async {
    final newStatus =
        _tugas.status == 'Selesai' ? 'Belum Selesai' : 'Selesai';
    final updated = _tugas.copyWith(status: newStatus);
    await DBHelper.instance.updateTugas(updated);
    setState(() => _tugas = updated);
  }

  Future<void> _deleteTugas() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tugas?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${_tugas.namaTugas}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deleteTugas(_tugas.id!);
      await NotifServices.cancelTugasNotifications(_tugas.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priColor = _getPrioritasColor(_tugas.prioritas);
    final icon = _getMataKuliahIcon(_tugas.mataKuliah);
    final isSelesai = _tugas.status == 'Selesai';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Tugas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      isSelesai ? Icons.refresh : Icons.check_circle_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSelesai
                          ? 'Tandai Belum Selesai'
                          : 'Tandai Selesai',
                    ),
                  ],
                ),
                onTap: _toggleStatus,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF2563EB),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tugas.namaTugas,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: priColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _tugas.prioritas,
                      style: TextStyle(
                        color: priColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Detail info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.school_outlined,
                    label: 'Mata Kuliah',
                    value: _tugas.mataKuliah,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Deadline',
                    value: _formatDeadline(_tugas.deadline),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.timelapse_outlined,
                    label: 'Status',
                    valueWidget: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelesai
                            ? const Color(0xFF22C55E).withOpacity(0.12)
                            : const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tugas.status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelesai
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                  if (_tugas.deskripsi.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Deskripsi',
                      value: _tugas.deskripsi,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPage(tugasToEdit: _tugas),
                          ),
                        );
                        // Reload from DB
                        final all = await DBHelper.instance.getAllTugas();
                        final updated = all.firstWhere(
                          (t) => t.id == _tugas.id,
                          orElse: () => _tugas,
                        );
                        setState(() => _tugas = updated);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('EDIT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteTugas,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('HAPUS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              valueWidget ??
                  Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}