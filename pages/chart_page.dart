import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../database/db_helper.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<Tugas> _allTugas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tugas = await DBHelper.instance.getAllTugas();
    setState(() {
      _allTugas = tugas;
      _isLoading = false;
    });
  }

  int get _total => _allTugas.length;
  int get _selesai => _allTugas.where((t) => t.status == 'Selesai').length;
  int get _belumSelesai =>
      _allTugas.where((t) => t.status == 'Belum Selesai').length;
  int get _tinggi =>
      _allTugas.where((t) => t.prioritas == 'Tinggi').length;
  int get _sedang =>
      _allTugas.where((t) => t.prioritas == 'Sedang').length;
  int get _rendah =>
      _allTugas.where((t) => t.prioritas == 'Rendah').length;

  Map<String, int> get _perMataKuliah {
    final map = <String, int>{};
    for (final t in _allTugas) {
      map[t.mataKuliah] = (map[t.mataKuliah] ?? 0) + 1;
    }
    return map;
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
          'Statistik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummarySection(),
                    const SizedBox(height: 20),
                    _buildPrioritasSection(),
                    const SizedBox(height: 20),
                    _buildMataKuliahSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard(
              label: 'Total Tugas',
              value: _total,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
            ),
            const SizedBox(width: 10),
            _buildSummaryCard(
              label: 'Selesai',
              value: _selesai,
              color: const Color(0xFF22C55E),
              bgColor: const Color(0xFFF0FDF4),
            ),
            const SizedBox(width: 10),
            _buildSummaryCard(
              label: 'Belum Selesai',
              value: _belumSelesai,
              color: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEF2F2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritasSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tugas per Prioritas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 130,
                height: 130,
                child: _total == 0
                    ? const Center(
                        child: Text(
                          'Tidak ada\ndata',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      )
                    : CustomPaint(
                        painter: _DonutChartPainter(
                          tinggi: _tinggi,
                          sedang: _sedang,
                          rendah: _rendah,
                          total: _total,
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow(
                      color: const Color(0xFFEF4444),
                      label: 'Tinggi',
                      count: _tinggi,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendRow(
                      color: const Color(0xFFF59E0B),
                      label: 'Sedang',
                      count: _sedang,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendRow(
                      color: const Color(0xFF22C55E),
                      label: 'Rendah',
                      count: _rendah,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMataKuliahSection() {
    final perMK = _perMataKuliah;
    if (perMK.isEmpty) return const SizedBox();

    final maxVal = perMK.values.isEmpty
        ? 1
        : perMK.values.reduce((a, b) => a > b ? a : b);

    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF16A34A),
      const Color(0xFF9333EA),
      const Color(0xFFF97316),
      const Color(0xFF0891B2),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tugas per Mata Kuliah',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...perMK.entries.toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final mk = entry.value.key;
            final count = entry.value.value;
            final color = colors[idx % colors.length];
            final barFraction = maxVal == 0 ? 0.0 : count / maxVal;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mk,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$count tugas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: 8,
                            width: constraints.maxWidth * barFraction,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int tinggi;
  final int sedang;
  final int rendah;
  final int total;

  _DonutChartPainter({
    required this.tinggi,
    required this.sedang,
    required this.rendah,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 22.0;

    final data = [
      (tinggi / total, const Color(0xFFEF4444)),
      (sedang / total, const Color(0xFFF59E0B)),
      (rendah / total, const Color(0xFF22C55E)),
    ];

    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final (fraction, color) in data) {
      if (fraction <= 0) continue;
      final sweepAngle = fraction * 2 * math.pi - gap;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      old.tinggi != tinggi || old.sedang != sedang || old.rendah != rendah;
}