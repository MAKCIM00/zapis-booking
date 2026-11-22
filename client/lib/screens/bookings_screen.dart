import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'home_shell.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Booking> _bookings = const [];
  bool _loading = true;
  bool _showPast = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final bookings = await context.read<ApiClient>().bookings();
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  List<Booking> get _upcoming {
    final items = _bookings.where((booking) => booking.isUpcoming).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return items;
  }

  List<Booking> get _past {
    final items = _bookings.where((booking) => !booking.isUpcoming).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return items;
  }

  Future<void> _cancel(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Отменить запись?'),
        content: Text(
          '${booking.serviceTitle}\n${formatDateLong(booking.startAt)}, ${formatTime(booking.startAt)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Оставить')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ApiClient>().cancelBooking(booking.id);
      await _load();
      messenger.showSnackBar(const SnackBar(content: Text('Запись отменена')));
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _showPast ? _past : _upcoming;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Мои записи',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF231F35)),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitcher(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          _SwitchButton(
            label: 'Предстоящие',
            selected: !_showPast,
            onTap: () => setState(() => _showPast = false),
          ),
          _SwitchButton(
            label: 'История',
            selected: _showPast,
            onTap: () => setState(() => _showPast = true),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Booking> items) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kSeed));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: kMuted),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: kSeed,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.event_available_rounded, size: 56, color: kMuted),
            const SizedBox(height: 12),
            Text(
              _showPast ? 'Здесь появятся прошедшие записи' : 'Пока нет предстоящих записей',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.tonal(
                onPressed: () => context.read<AppShellController>().select(0),
                child: const Text('Выбрать услугу'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: kSeed,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _BookingCard(
          booking: items[index],
          onCancel: items[index].isUpcoming ? () => _cancel(items[index]) : null,
        ),
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? kSeed : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : kMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.onCancel});

  final Booking booking;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.isCancelled;
    final past = booking.startAt.isBefore(DateTime.now());

    final statusLabel = cancelled ? 'Отменена' : (past ? 'Завершена' : 'Подтверждена');
    final statusColor = cancelled
        ? kMuted
        : past
            ? const Color(0xFF7A7590)
            : const Color(0xFF2E7D32);

    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cancelled ? const Color(0xFFF1EFF8) : kSeed.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(kRadius)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${booking.startAt.day}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: cancelled ? kMuted : kSeed,
                    ),
                  ),
                  Text(
                    formatDateShort(booking.startAt).split(' ').last,
                    style: TextStyle(fontSize: 12, color: cancelled ? kMuted : kSeed),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.serviceTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF231F35)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatTimeRange(booking.startAt, booking.endAt)} · ${booking.masterName}',
                      style: const TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                    if (booking.comment != null && booking.comment!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '«${booking.comment}»',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: kMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatPrice(booking.price),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF231F35)),
                        ),
                        const Spacer(),
                        if (onCancel != null)
                          TextButton(
                            onPressed: onCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text('Отменить', style: TextStyle(fontSize: 12.5)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
