import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_format.dart';
import 'add_menu_screen.dart';
import 'checkout_screen.dart';
import 'history_screen.dart';
import 'printer_settings_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenCheckout;

  const HomeScreen({
    super.key,
    this.onOpenHistory,
    this.onOpenCheckout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStoreProfileDialog(BuildContext context, SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.storeName);
    final addressController = TextEditingController(text: settings.storeAddress);

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.storefront, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Profil & Nama UMKM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama UMKM ini akan muncul di header nota / struk kasir digital dan hasil cetak printer thermal.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko / UMKM',
                  hintText: 'Contoh: Kedai Berkah Sejahtera',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat / Catatan Kaki Nota',
                  hintText: 'Contoh: Jl. Mawar No. 10 / IG: @kedaiberkah',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newAddress = addressController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama UMKM tidak boleh kosong')),
                );
                return;
              }
              await settings.updateStoreProfile(
                storeName: newName,
                storeAddress: newAddress,
              );
              if (!dCtx.mounted) return;
              Navigator.of(dCtx).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil UMKM berhasil disimpan!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Filter menu berdasarkan kategori & pencarian teks
    List<MenuItem> displayedMenus = menuProvider.menus;
    if (_searchQuery.isNotEmpty) {
      displayedMenus = displayedMenus
          .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari menu...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              )
            : InkWell(
                onTap: () => _showStoreProfileDialog(context, settingsProvider),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              settingsProvider.storeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14, color: Colors.white70),
                        ],
                      ),
                      const Text(
                        'KasirKu UMKM',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Nama & Profil UMKM',
            onPressed: () => _showStoreProfileDialog(context, settingsProvider),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Tutup Pencarian' : 'Cari Menu',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Pengaturan Printer',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Riwayat Transaksi',
            onPressed: widget.onOpenHistory ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Panduan Aplikasi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TutorialScreen(isHelpMode: true)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Kategori (Horizontal Chips)
          _buildCategoryFilter(menuProvider),

          // Grid Daftar Menu
          Expanded(
            child: menuProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedMenus.isEmpty
                    ? _buildEmptyState()
                    : _buildMenuGrid(displayedMenus, cartProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddMenuScreen()),
          );
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: cartProvider.totalItemCount > 0
          ? _buildCartSummaryBar(context, cartProvider)
          : null,
    );
  }

  Widget _buildCategoryFilter(MenuProvider menuProvider) {
    final categories = menuProvider.categories;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = menuProvider.selectedCategory == cat;

          return FilterChip(
            label: Text(cat),
            selected: isSelected,
            selectedColor: Colors.deepOrange.shade100,
            checkmarkColor: Colors.deepOrange,
            labelStyle: TextStyle(
              color: isSelected ? Colors.deepOrange.shade900 : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
            ),
            onSelected: (_) {
              menuProvider.setCategory(cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid(List<MenuItem> menus, CartProvider cartProvider) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.76,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        final quantity = cartProvider.getItemQuantity(menu.id ?? 0);

        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: quantity > 0
                ? const BorderSide(color: Colors.deepOrange, width: 2)
                : BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () {
              cartProvider.addToCart(menu);
            },
            onLongPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddMenuScreen(menuToEdit: menu)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Menu
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.orange.shade50,
                        child: menu.imagePath != null && File(menu.imagePath!).existsSync()
                            ? Image.file(File(menu.imagePath!), fit: BoxFit.cover)
                            : Icon(
                                menu.category == 'Minuman'
                                    ? Icons.local_cafe_outlined
                                    : Icons.fastfood_outlined,
                                size: 50,
                                color: Colors.deepOrange.shade300,
                              ),
                      ),
                      // Badge Kategori
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            menu.category ?? 'Umum',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                      // Tombol Edit Kecil
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white70,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.edit, color: Colors.black87),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddMenuScreen(menuToEdit: menu),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Detail Menu
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormat.toRupiah(menu.price),
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Kontrol Jumlah Keranjang
                      if (quantity > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => cartProvider.decreaseQuantity(menu),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.remove, size: 16, color: Colors.deepOrange),
                              ),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            InkWell(
                              onTap: () => cartProvider.addToCart(menu),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.add, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 28,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepOrange),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => cartProvider.addToCart(menu),
                            child: const Text(
                              '+ Tambah',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Belum ada menu yang ditemukan',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddMenuScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Menu Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummaryBar(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Jumlah Item & Total
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cartProvider.totalItemCount} Item Terpilih',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  CurrencyFormat.toRupiah(cartProvider.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Tombol Reset Keranjang
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
              tooltip: 'Kosongkan Keranjang',
              onPressed: () {
                cartProvider.clearCart();
              },
            ),

            const SizedBox(width: 8),

            // Tombol Bayar / Checkout
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onOpenCheckout ??
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                  },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text(
                'Bayar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
