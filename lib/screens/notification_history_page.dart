import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_history.dart';
import '../widgets/form_fields.dart';

/// 通知历史页：时间倒序，精简列表（无截图），点击查看详情（含截图）。
class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});
  @override
  State<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<NotificationRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationHistory.instance.getAll();
    if (mounted) setState(() { _records = list; _loading = false; });
  }

  Future<void> _clearAll() async {
    await NotificationHistory.instance.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('通知历史', style: TextStyle(color: onSurface)),
        leading: BackButton(color: onSurface),
        actions: [
          if (_records.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('清空', style: TextStyle(color: Color(0xFFFF3366))),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _records.isEmpty
              ? Center(child: Text('暂无通知记录', style: TextStyle(color: onSurface.withOpacity(0.4))))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _tile(_records[i]),
                ),
    );
  }

  // 精简列表项：时间 + 标题 + 内容（无截图），有截图显示小图标
  Widget _tile(NotificationRecord r) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final timeStr = DateFormat('MM-dd HH:mm:ss').format(r.dateTime);
    final hasImage = r.imagePath != null && File(r.imagePath!).existsSync();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openDetail(r),
      child: GlassPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(r.title, style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(timeStr, style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(r.body, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13)),
                ],
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 10),
              Icon(Icons.image_outlined, color: kPrimary.withOpacity(0.7), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  // 详情：完整内容 + 截图
  void _openDetail(NotificationRecord r) {
    final hasImage = r.imagePath != null && File(r.imagePath!).existsSync();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(r.dateTime);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Text(r.title, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(timeStr, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 12),
              Text(r.body, style: TextStyle(color: onSurface.withOpacity(0.85), fontSize: 14)),
              const SizedBox(height: 16),
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(r.imagePath!), fit: BoxFit.contain),
                )
              else
                Text('（无截图）', style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}
