import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Tugas> _allTugas = [];
  List<Tugas> _selectedDayTugas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTugas();
  }

  Future<void> _loadTugas() async {
    setState(() => _isLoading = true);
    final tugas = await DBHelper.instance.getAllTugas();
    setState(() {
      _allTugas = tugas;
      _updateSelectedDayTugas();
      _isLoading = false;
    });
  }

  void _updateSelectedDayTugas() {
    final dateStr =
        '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';
    _selectedDayTugas =
        _allTugas.where((t) => t.deadline.startsWith(dateStr)).toList();
  }

  Set<String> get _datesWithTugas {
    return _allTugas.map((t) => t.deadline.substring(0, 10)).toSet();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  String _monthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }

  String _formatDeadline(String deadline) {
    try {
      final dt = DateTime.parse(deadline.replaceAll(' ', 'T'));
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return deadline;
    }
  }

  String _formatSelectedDay() {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${_selectedDay.day} ${months[_selectedDay.month]} ${_selectedDay.year}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kalender',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : RefreshIndicator(
              onRefresh: _loadTugas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    _buildSelectedDayTugas(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun, 1=Mon...

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF2563EB),
                ),
              ),
              Text(
                '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Day cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (ctx, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final dateStr =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final hasTugas = _datesWithTugas.contains(dateStr);
              final isSelected = _selectedDay.year == date.year &&
                  _selectedDay.month == date.month &&
                  _selectedDay.day == date.day;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = date;
                    _updateSelectedDayTugas();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : isToday
                            ? const Color(0xFFDBEAFE)
                            : null,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF374151),
                        ),
                      ),
                      if (hasTugas && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayTugas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tugas pada ${_formatSelectedDay()}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedDayTugas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 40,
                    color: Color(0xFFD1D5DB),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada tugas pada tanggal ini',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_selectedDayTugas.map((tugas) {
              final priColor = _getPrioritasColor(tugas.prioritas);
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(tugas: tugas),
                    ),
                  );
                  _loadTugas();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: priColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tugas.namaTugas,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
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
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: priColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tugas.prioritas,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: priColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),
          if (_selectedDayTugas.isNotEmpty)
            GestureDetector(
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Lihat semua tugas di tanggal ini',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Color(0xFF2563EB),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}