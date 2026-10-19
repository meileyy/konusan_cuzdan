import 'package:flutter/material.dart';

/// Eğitmen/ebeveyn paneline girişte istenen 4 haneli PIN.
/// Çocuğun ayarları yanlışlıkla değiştirmesini önler.
Future<bool> showPinDialog(BuildContext context, String correctPin) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _PinDialog(correctPin: correctPin),
  );
  return result ?? false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.correctPin});

  final String correctPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _entered = '';
  bool _error = false;

  void _press(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = false;
    });
    if (_entered.length == 4) {
      if (_entered == widget.correctPin) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _entered = '';
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eğitmen Girişi', textAlign: TextAlign.center),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ? 'PIN yanlış, tekrar deneyin' : 'PIN kodunu girin',
              style: TextStyle(color: _error ? Colors.red : null),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    i < _entered.length ? Icons.circle : Icons.circle_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final k in [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  '',
                  '0',
                  '⌫',
                ])
                  k.isEmpty
                      ? const SizedBox()
                      : TextButton(
                          onPressed: () => k == '⌫'
                              ? setState(
                                  () => _entered = _entered.isEmpty
                                      ? ''
                                      : _entered.substring(
                                          0,
                                          _entered.length - 1,
                                        ),
                                )
                              : _press(k),
                          child: Text(k, style: const TextStyle(fontSize: 24)),
                        ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
      ],
    );
  }
}
