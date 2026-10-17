import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../services/notif_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Tugas> _allTugas = [];
  Map<String, int> _perMataKuliah = {};
  bool _isLoading = true;
  bool _notifEnabled = true;

  String _userName = '';
  String _userNim = '';
  String _userProdi = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _userNim = prefs.getString('user_nim') ?? '';
      _userProdi = prefs.getString('user_prodi') ?? '';
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tugas = await DBHelper.instance.getAllTugas();
    final perMK = await DBHelper.instance.getTugasPerMataKuliah();
    setState(() {
      _allTugas = tugas;
      _perMataKuliah = perMK;
      _isLoading = false;
    });
  }

  int get _selesai => _allTugas.where((t) => t.status == 'Selesai').length;
  int get _belumSelesai => _allTugas.where((t) => t.status == 'Belum Selesai').length;

  String get _initials {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
  }

  void _showEditDialog() {
    final namaCtrl = TextEditingController(text: _userName);
    final nimCtrl = TextEditingController(text: _userNim);
    final prodiCtrl = TextEditingController(text: _userProdi);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogLabel('Nama Lengkap'),
              _dialogField(namaCtrl, 'Nama lengkap', Icons.person_outline,
                  TextCapitalization.words),
              const SizedBox(height: 12),
              _dialogLabel('NIM'),
              _dialogField(nimCtrl, 'NIM', Icons.badge_outlined,
                  TextCapitalization.none,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _dialogLabel('Program Studi'),
              _dialogField(prodiCtrl, 'Program studi', Icons.account_balance_outlined,
                  TextCapitalization.words),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final nama = namaCtrl.text.trim();
              if (nama.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', nama);
              await prefs.setString('user_nim', nimCtrl.text.trim());
              await prefs.setString('user_prodi', prodiCtrl.text.trim());
              setState(() {
                _userName = nama;
                _userNim = nimCtrl.text.trim();
                _userProdi = prodiCtrl.text.trim();
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _dialogLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
      );

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    TextCapitalization cap, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: cap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Profilmu akan dihapus dari perangkat ini. Data tugas tetap tersimpan.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _showEditDialog,
            tooltip: 'Edit Profil',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    if (_perMataKuliah.isNotEmpty) ...[
                      _buildMataKuliahSection(),
                      const SizedBox(height: 16),
                    ],
                    _buildSettingsSection(),
                    const SizedBox(height: 16),
                    _buildPriorityLegend(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      color: Colors.white,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showEditDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _userName.isNotEmpty ? _userName : 'Pengguna',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          // Info chips row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (_userNim.isNotEmpty)
                _infoChip(Icons.badge_outlined, _userNim),
              if (_userProdi.isNotEmpty)
                _infoChip(Icons.school_outlined, _userProdi),
              if (_userNim.isEmpty && _userProdi.isEmpty)
                _infoChip(Icons.school_outlined, 'Mahasiswa Aktif'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard('Total Tugas', '${_allTugas.length}',
              Icons.assignment_outlined, const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          _buildStatCard('Selesai', '$_selesai',
              Icons.check_circle_outline, const Color(0xFF22C55E)),
          const SizedBox(width: 10),
          _buildStatCard('Pending', '$_belumSelesai',
              Icons.pending_outlined, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMataKuliahSection() {
    final colors = [
      const Color(0xFF2563EB), const Color(0xFF16A34A),
      const Color(0xFF9333EA), const Color(0xFFF97316),
      const Color(0xFF0891B2),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mata Kuliah',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          ..._perMataKuliah.entries.toList().asMap().entries.map((e) {
            final color = colors[e.key % colors.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.menu_book, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.value.key,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937))),
                  ),
                  Text('${e.value.value} tugas',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _settingsTile(Icons.notifications_outlined, 'Notifikasi',
              trailing: Switch(
                value: _notifEnabled,
                onChanged: (val) => setState(() => _notifEnabled = val),
                activeColor: const Color(0xFF2563EB),
              )),
          const Divider(height: 1, indent: 56),
          _settingsTile(Icons.notifications_active_outlined, 'Test Notifikasi',
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              onTap: () async {
                await NotifServices.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notifikasi test dikirim!'),
                      backgroundColor: const Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }),
          const Divider(height: 1, indent: 56),
          _settingsTile(Icons.info_outline, 'Tentang Aplikasi',
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Tugas Kuliah',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026',
                  )),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label,
      {required Widget trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: const Color(0xFF374151)),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937))),
      trailing: trailing,
    );
  }

  Widget _buildPriorityLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keterangan Prioritas',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 14),
          _legendItem(const Color(0xFFEF4444), 'Tinggi',
              'Tugas dengan deadline dekat atau tingkat kesulitan tinggi'),
          const SizedBox(height: 10),
          _legendItem(const Color(0xFFF59E0B), 'Sedang',
              'Tugas dengan deadline sedang atau tingkat kesulitan sedang'),
          const SizedBox(height: 10),
          _legendItem(const Color(0xFF22C55E), 'Rendah',
              'Tugas dengan deadline jauh atau tingkat kesulitan rendah'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12, height: 12,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Keluar / Ganti Akun'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFEF4444)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}