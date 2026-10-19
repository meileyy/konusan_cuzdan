import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/money_formatter.dart';
import '../state/app_state.dart';

/// Eğitmen / ebeveyn paneli (PIN korumalı).
/// Seviye, ses ayarları, ürünler, ilerleme raporu ve veri temizleme.
class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late Future<({int total, int correct})> _stats;

  @override
  void initState() {
    super.initState();
    _stats = context.read<AppState>().db.getProgressStats();
  }

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addProduct() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const _ProductDialog(),
    );
    if (product == null || !mounted) return;
    await context.read<AppState>().addProduct(product);
    _toast('${product.name} eklendi');
  }

  Future<void> _changePin() async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: '4 haneli sayı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (pin == null || !mounted) return;
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _toast('PIN 4 haneli bir sayı olmalı');
      return;
    }
    await context.read<AppState>().setSetting('pin', pin);
    _toast('PIN değiştirildi');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Eğitmen Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Section('Zorluk seviyesi'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
            ],
            selected: {app.level},
            onSelectionChanged: (s) =>
                app.setSetting('level', s.first.toString()),
          ),
          const SizedBox(height: 6),
          Text(switch (app.level) {
            1 => 'Seviye 1: Sadece 5, 10 ve 20 TL banknotlar.',
            2 => 'Seviye 2: Bütün banknotlar ve 1 TL.',
            _ => 'Seviye 3: Kuruşlar dahil bütün paralar.',
          }),
          const _Section('Ses'),
          if (!app.speech.turkishVoiceFound)
            const Card(
              color: Color(0xFFFFF3CD),
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded),
                title: Text('Türkçe ses yüklü değil'),
                subtitle: Text(
                  'Telefon Türkçe yönergeleri İngilizce sesle okuyabilir. '
                  'Ayarlar → Sistem → Diller → Metin okuma → Google Konuşma '
                  'Hizmetleri → ⚙ → Ses verilerini yükle → Türkçe.',
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('Ses efektleri'),
            value: app.soundOn,
            onChanged: (v) => app.setSetting('sound', v ? '1' : '0'),
          ),
          const _Section('Konuşan kişi'),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.record_voice_over),
                label: Text('Kayıtlı ses'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.computer),
                label: Text('Bilgisayar sesi'),
              ),
            ],
            selected: {app.useRecordedVoice},
            onSelectionChanged: (s) async {
              await app.setSetting(
                'voice_source',
                s.first ? 'recorded' : 'tts',
              );
              app.say(
                'Merhaba! Ben Konuşan Cüzdan. Hadi birlikte alışveriş yapalım!',
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            app.voice.recordingCount == 0
                ? 'Henüz kayıtlı ses yok; bilgisayar sesi kullanılıyor. '
                      'Kayıtlar assets/voice klasörüne eklenince kendiliğinden '
                      'kullanılır (liste: tasarim/ses_kayit_listesi.md).'
                : '${app.voice.recordingCount} / ${app.voice.phraseCount} kayıt '
                      'bulundu. Kaydı eksik olan cümleler bilgisayar sesiyle '
                      'okunur. Aşağıdaki hız ve ton ayarları bilgisayar sesi '
                      'içindir.',
          ),
          ListTile(
            title: const Text('Konuşma hızı'),
            subtitle: Slider(
              value: app.speechRate.clamp(0.2, 0.7),
              min: 0.2,
              max: 0.7,
              divisions: 10,
              label: app.speechRate.toStringAsFixed(2),
              onChanged: (v) =>
                  app.setSetting('speech_rate', v.toStringAsFixed(2)),
              onChangeEnd: (_) => app.sayWithComputer('Konuşma hızı böyle.'),
            ),
          ),
          ListTile(
            title: const Text('Ses tonu'),
            subtitle: Slider(
              value: app.speechPitch.clamp(0.8, 1.4),
              min: 0.8,
              max: 1.4,
              divisions: 12,
              label: app.speechPitch.toStringAsFixed(2),
              onChanged: (v) => app.setSetting('pitch', v.toStringAsFixed(2)),
              onChangeEnd: (_) => app.sayWithComputer('Merhaba! Sesim böyle.'),
            ),
          ),
          const _Section('İlerleme (Oyun)'),
          FutureBuilder(
            future: _stats,
            builder: (context, snapshot) {
              final s = snapshot.data;
              if (s == null) return const LinearProgressIndicator();
              final pct = s.total == 0
                  ? 0
                  : (s.correct * 100 / s.total).round();
              return Card(
                child: ListTile(
                  leading: const Text('⭐', style: TextStyle(fontSize: 32)),
                  title: Text(
                    '${s.total} soru, ${s.correct} ilk denemede doğru',
                  ),
                  subtitle: Text('Başarı: %$pct'),
                  trailing: IconButton(
                    tooltip: 'İlerlemeyi sıfırla',
                    icon: const Icon(Icons.restart_alt),
                    onPressed: () async {
                      if (!await _confirm('Oyun ilerlemesi silinecek.')) return;
                      await app.db.clearProgress();
                      setState(() => _stats = app.db.getProgressStats());
                    },
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              const Expanded(child: _Section('Ürünler')),
              FilledButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Ekle'),
              ),
            ],
          ),
          for (final p in app.products)
            Card(
              child: ListTile(
                leading: Text(p.emoji, style: const TextStyle(fontSize: 32)),
                title: Text(p.name),
                subtitle: Text(
                  '${formatMoney(p.priceKurus)} · Seviye ${p.level}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (!await _confirm('${p.name} silinecek.')) return;
                    await app.deleteProduct(p.id!);
                  },
                ),
              ),
            ),
          const _Section('Veriler'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Cüzdanı boşalt'),
            onTap: () async {
              final ok = await _confirm('Cüzdandaki bütün paralar silinecek.');
              if (!ok) return;
              await app.clearWallet();
              _toast('Cüzdan boşaltıldı');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Alışveriş geçmişini temizle'),
            onTap: () async {
              if (!await _confirm('Bütün alışveriş geçmişi silinecek.')) return;
              await app.db.clearTransactions();
              _toast('Geçmiş temizlendi');
            },
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('PIN değiştir'),
            subtitle: const Text('Varsayılan PIN: 1234'),
            onTap: _changePin,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Yeni ürün ekleme formu.
class _ProductDialog extends StatefulWidget {
  const _ProductDialog();

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _name = TextEditingController();
  final _emoji = TextEditingController(text: '🛍️');
  final _price = TextEditingController();
  int _level = 1;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final price = parseMoneyInput(_price.text);
    if (name.isEmpty) {
      setState(() => _error = 'Ürün adı yazın');
      return;
    }
    if (price == null || price <= 0 || price % 5 != 0) {
      setState(() => _error = 'Geçerli bir fiyat yazın (ör. 15 veya 17,50)');
      return;
    }
    Navigator.of(context).pop(
      Product(
        name: name,
        emoji: _emoji.text.trim().isEmpty ? '🛍️' : _emoji.text.trim(),
        priceKurus: price,
        level: price % 100 != 0 ? 3 : _level,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni ürün'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Ürün adı'),
            ),
            TextField(
              controller: _emoji,
              decoration: const InputDecoration(labelText: 'Resim (emoji)'),
            ),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Fiyat (TL)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Seviye'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
              ],
              onChanged: (v) => setState(() => _level = v ?? 1),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}
