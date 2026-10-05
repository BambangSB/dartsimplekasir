import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';

class TutorialItem {
  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final List<String> bulletPoints;
  final String proTip;

  const TutorialItem({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.bulletPoints,
    required this.proTip,
  });
}

class TutorialScreen extends StatefulWidget {
  final bool isHelpMode;

  const TutorialScreen({
    super.key,
    this.isHelpMode = false,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialItem> _tutorialList = const [
    TutorialItem(
      stepNumber: 'Langkah 1 dari 5',
      title: 'Atur Profil & Nama Toko',
      description:
          'Sesuaikan identitas UMKM Anda agar tercetak otomatis pada header struk kasir dan kertas printer thermal Bluetooth.',
      icon: Icons.storefront_rounded,
      bulletPoints: [
        'Klik nama toko di pojok atas layar kasir untuk mengubahnya kapan saja.',
        'Isi nama toko dan alamat lengkap atau kontak WhatsApp / Instagram.',
        'Data tersimpan permanen di HP Anda secara offline tanpa kuota internet.',
      ],
      proTip: 'Nama toko Anda akan langsung muncul di baris teratas nota struk pelanggan.',
    ),
    TutorialItem(
      stepNumber: 'Langkah 2 dari 5',
      title: 'Tambah & Kelola Menu Produk',
      description:
          'Daftarkan semua produk, barang, atau makanan/minuman yang Anda jual dengan mudah dan cepat.',
      icon: Icons.add_business_rounded,
      bulletPoints: [
        'Tekan tombol oranye "+ Tambah Menu" di pojok kanan bawah.',
        'Masukkan nama produk, harga jual, foto (opsional), dan pilih kategori.',
        'Gunakan fitur pencarian untuk menemukan menu dengan cepat.',
      ],
      proTip: 'Tekan dan tahan (tahan lama) kartu produk di beranda untuk mengubah harga atau menghapusnya.',
    ),
    TutorialItem(
      stepNumber: 'Langkah 3 dari 5',
      title: 'Pencatatan Pesanan Kasir',
      description:
          'Proses kasir super praktis, cepat, dan tanpa ribet menghitung manual dengan kalkulator.',
      icon: Icons.point_of_sale_rounded,
      bulletPoints: [
        'Cukup sentuh kartu menu untuk langsung memasukkan ke keranjang kasir.',
        'Tekan tanda (+) atau (-) untuk menambah atau mengurangi jumlah porsi.',
        'Total tagihan dihitung otomatis dan akurat secara real-time di bilah bawah.',
      ],
      proTip: 'Bilah ringkasan kasir di bagian bawah akan otomatis muncul saat ada item terpilih.',
    ),
    TutorialItem(
      stepNumber: 'Langkah 4 dari 5',
      title: 'Pembayaran & Cetak Struk',
      description:
          'Dukung metode pembayaran Tunai maupun QRIS Nontunai, serta cetak struk profesional.',
      icon: Icons.receipt_long_rounded,
      bulletPoints: [
        'Tekan tombol "Bayar" lalu pilih metode Tunai atau QRIS.',
        'Pembayaran Tunai dilengkapi hitung kembalian instan dan tombol nominal cepat.',
        'Hubungkan printer thermal Bluetooth 58mm untuk mencetak nota kasir seketika.',
      ],
      proTip: 'Anda juga bisa membagikan nota kasir digital via WhatsApp tanpa perlu dicetak!',
    ),
    TutorialItem(
      stepNumber: 'Langkah 5 dari 5',
      title: 'Pantau Omzet & Rekap Penjualan',
      description:
          'Ketahui pemasukan harian dan performa usaha Anda dengan data laporan yang akurat.',
      icon: Icons.analytics_rounded,
      bulletPoints: [
        'Buka ikon nota di pojok kanan atas untuk melihat riwayat semua transaksi.',
        'Lihat rekapitulasi total omzet bersih, jumlah nota, dan rincian Tunai vs QRIS.',
        'Filter laporan berdasarkan hari ini, 7 hari terakhir, atau rentang tanggal tertentu.',
      ],
      proTip: 'Semua rekaman transaksi disimpan aman di memori lokal HP dan tidak akan hilang.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishTutorial() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.completeTutorial();

    if (!mounted) return;

    if (widget.isHelpMode) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _tutorialList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTutorial();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isHelpMode || _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  if (_currentPage > 0) {
                    _prevPage();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
        title: const Text(
          'Panduan Penggunaan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _finishTutorial,
            child: Text(
              widget.isHelpMode ? 'Tutup' : 'Lewati',
              style: TextStyle(
                color: Colors.deepOrange.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView Slider Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _tutorialList.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentPage = idx;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _tutorialList[index];
                  return _buildPageItem(item);
                },
              ),
            ),

            // Bottom Navigation & Dot Indicators
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem(TutorialItem item) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepOrange.shade200),
            ),
            child: Text(
              item.stepNumber,
              style: TextStyle(
                color: Colors.deepOrange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Illustration Icon Glow Circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.deepOrange.shade100, width: 2),
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 56,
                color: Colors.deepOrange.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Bullet Points Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: item.bulletPoints.map((point) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.deepOrange.shade600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Pro-Tip Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, size: 20, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.proTip,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _tutorialList.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_tutorialList.length, (idx) {
              final isCurrent = idx == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isCurrent ? 24 : 8,
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.deepOrange : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Buttons
          if (isLastPage)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _finishTutorial,
                icon: const Icon(Icons.storefront, color: Colors.white, size: 20),
                label: Text(
                  widget.isHelpMode ? 'Selesai & Kembali' : 'Mulai Berjualan Sekarang!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                if (_currentPage > 0) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _prevPage,
                      child: Text(
                        'Kembali',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _nextPage,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    label: const Text(
                      'Lanjut',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
