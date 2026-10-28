import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_record.dart';
import '../services/money_formatter.dart';
import '../state/app_state.dart';
import '../utils/theme.dart';
import '../widgets/kid_scaffold.dart';
import '../widgets/mascot.dart';
import '../widgets/product_image.dart';

/// Geçmiş: veritabanındaki alışverişler. Bir karta dokununca sesli özetlenir.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _instruction =
      'Burada aldığın şeyler var. Dinlemek için birine dokun.';
  late final Future<List<TransactionRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().db.getTransactions();
    speakAfterFirstFrame(this, _instruction);
  }

  String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  void _speak(TransactionRecord t) {
    final app = context.read<AppState>();
    final change = t.changeKurus == 0
        ? 'Para üstü yoktu.'
        : 'Para üstü ${speakMoney(t.changeKurus)} aldın.';
    app.say(
      '${t.productName} aldın. ${speakMoney(t.priceKurus)}. '
      '${speakMoney(t.paidKurus)} verdin. $change',
    );
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      title: 'Geçmiş',
      instruction: _instruction,
      body: FutureBuilder<List<TransactionRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: MascotBubble(
                  pose: MascotPose.shop,
                  size: 110,
                  text: 'Henüz alışveriş\nyapmadın!',
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const MascotBubble(
                  pose: MascotPose.cheer,
                  size: 90,
                  text: 'Aldıkların burada!\nDinlemek için dokun.',
                  speech: _instruction,
                );
              }
              final t = items[index - 1];
              return Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _speak(t),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ProductImage(emoji: t.productEmoji, size: 64),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.productName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _date(t.createdAt),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _Tag(
                                    'Fiyat ${formatMoney(t.priceKurus)}',
                                    AppColors.warning,
                                  ),
                                  _Tag(
                                    'Verdin ${formatMoney(t.paidKurus)}',
                                    AppColors.primary,
                                  ),
                                  _Tag(
                                    'Üstü ${formatMoney(t.changeKurus)}',
                                    AppColors.success,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.volume_up_rounded,
                          size: 32,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
