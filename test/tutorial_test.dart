import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_kasir/providers/settings_provider.dart';
import 'package:simple_kasir/screens/tutorial_screen.dart';

void main() {
  testWidgets('TutorialScreen renders and navigates through pages correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const MaterialApp(
          home: TutorialScreen(isHelpMode: true),
        ),
      ),
    );

    // Initial step check
    expect(find.text('Panduan Penggunaan'), findsOneWidget);
    expect(find.text('Langkah 1 dari 5'), findsOneWidget);
    expect(find.text('Atur Profil & Nama Toko'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    // Tap Lanjut to go to Step 2
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Langkah 2 dari 5'), findsOneWidget);
    expect(find.text('Tambah & Kelola Menu Produk'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);

    // Tap Kembali to go back to Step 1
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Langkah 1 dari 5'), findsOneWidget);

    // Fast-forward to the last step (Langkah 5)
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Langkah 5 dari 5'), findsOneWidget);
    expect(find.text('Pantau Omzet & Rekap Penjualan'), findsOneWidget);
    expect(find.text('Selesai & Kembali'), findsOneWidget);
  });
}
