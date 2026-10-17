import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import 'add_page.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Tugas> _allTugas = [];
  List<Tugas> _filteredTugas = [];
  String _filterPrioritas = 'Semua';
  bool _isLoading = true;
  String _userName = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _loadTugas();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pengguna';
    });
  }

  Future<void> _loadTugas() async {
    setState(() => _isLoading = true);
    final tugas = await DBHelper.instance.getAllTugas();
    setState(() {
      _allTugas = tugas;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_filterPrioritas == 'Semua') {
      _filteredTugas = List.from(_allTugas);
    } else {
      _filteredTugas =
          _allTugas.where((t) => t.prioritas == _filterPrioritas).toList();
    }
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

  Color _getMataKuliahColor(String mataKuliah) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF16A34A),
      const Color(0xFF9333EA),
      const Color(0xFFF97316),
      const Color(0xFF0891B2),
    ];
    return colors[mataKuliah.length % colors.length];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: RefreshIndicator(
        onRefresh: _loadTugas,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildMotivationCard()),
            SliverToBoxAdapter(child: _buildFilterRow()),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              )
            else if (_filteredTugas.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _filteredTugas.length) {
                      return const SizedBox(height: 100);
                    }
                    return _buildTugasCard(_filteredTugas[index]);
                  },
                  childCount: _filteredTugas.length + 1,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPage()),
          );
          _loadTugas();
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tugas Kuliah',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Halo, $_userName ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 22)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Text(
                        'Semangat! ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text('💪', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jangan lupa selesaikan tugasmu',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Image.network(
              'https://cdn-icons-png.flaticon.com/512/4128/4128349.png',
              width: 64,
              height: 64,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.school,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['Semua', 'Tinggi', 'Sedang', 'Rendah'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          const Text(
            'Daftar Tugas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            initialValue: _filterPrioritas,
            onSelected: (value) {
              setState(() {
                _filterPrioritas = value;
                _applyFilter();
              });
            },
            itemBuilder: (_) => filters
                .map(
                  (f) => PopupMenuItem(
                    value: f,
                    child: Text(f),
                  ),
                )
                .toList(),
            child: Row(
              children: [
                Text(
                  _filterPrioritas,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTugasCard(Tugas tugas) {
    final color = _getMataKuliahColor(tugas.mataKuliah);
    final icon = _getMataKuliahIcon(tugas.mataKuliah);
    final priColor = _getPrioritasColor(tugas.prioritas);
    final isSelesai = tugas.status == 'Selesai';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailPage(tugas: tugas)),
        );
        _loadTugas();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tugas.namaTugas,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                      decoration: isSelesai
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tugas.mataKuliah,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDeadline(tugas.deadline),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: priColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tugas.prioritas,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: priColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.task_alt, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tambahkan tugas baru dengan tombol +',
            style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }
}