import 'package:flutter/material.dart';

import '../services/money_formatter.dart';
import '../utils/theme.dart';

/// Büyük tuşlu fiyat girme ekranı. Kuruşlu tutarlar sadece 3. seviyede açılır.
/// Fiyatı kuruş olarak döndürür, vazgeçilirse null.
Future<int?> showPriceKeypad(BuildContext context, {required bool allowKurus}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _PriceKeypadDialog(allowKurus: allowKurus),
  );
}

class _PriceKeypadDialog extends StatefulWidget {
  const _PriceKeypadDialog({required this.allowKurus});

  final bool allowKurus;

  @override
  State<_PriceKeypadDialog> createState() => _PriceKeypadDialogState();
}

class _PriceKeypadDialogState extends State<_PriceKeypadDialog> {
  String _text = '';
  String? _error;

  void _press(String key) {
    setState(() {
      _error = null;
      if (key == '⌫') {
        if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
        return;
      }
      if (key == ',') {
        if (_text.isEmpty || _text.contains(',')) return;
        _text += ',';
        return;
      }
      final parts = _text.split(',');
      if (parts.length == 2 && parts[1].length >= 2) return;
      if (parts.length == 1 && parts[0].length >= 4) return;
      if (_text == '0') _text = '';
      _text += key;
    });
  }

  void _submit() {
    final kurus = parseMoneyInput(_text);
    if (kurus == null || kurus <= 0) {
      setState(() => _error = 'Bir fiyat yaz');
      return;
    }
    if (kurus % 5 != 0) {
      setState(() => _error = 'Kuruş 5\'in katı olmalı');
      return;
    }
    Navigator.of(context).pop(kurus);
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      widget.allowKurus ? ',' : '',
      '0',
      '⌫',
    ];
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Fiyat kaç lira?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _text.isEmpty ? '0 TL' : '$_text TL',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final k in keys)
                  k.isEmpty
                      ? const SizedBox()
                      : FilledButton.tonal(
                          onPressed: () => _press(k),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            k,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
