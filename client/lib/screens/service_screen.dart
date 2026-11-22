import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'home_shell.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key, required this.service});

  final ServiceItem service;

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final TextEditingController _commentController = TextEditingController();

  late final List<DateTime> _dates;
  late DateTime _selectedDate;

  ServiceDetails? _details;
  ServiceSlots? _slots;
  String? _masterId;
  Slot? _selectedSlot;

  bool _loading = true;
  bool _loadingSlots = false;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(10, (index) => DateTime(now.year, now.month, now.day).add(Duration(days: index)));
    _selectedDate = _dates.first;
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final api = context.read<ApiClient>();
    try {
      final details = await api.serviceDetails(widget.service.id);
      final slots = await api.slots(widget.service.id, _selectedDate, masterId: _masterId);
      if (!mounted) {
        return;
      }
      setState(() {
        _details = details;
        _slots = slots;
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

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });

    try {
      final slots = await context.read<ApiClient>().slots(
            widget.service.id,
            _selectedDate,
            masterId: _masterId,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingSlots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _book() async {
    final slot = _selectedSlot;
    if (slot == null) {
      return;
    }

    setState(() => _booking = true);
    final messenger = ScaffoldMessenger.of(context);
    final shell = context.read<AppShellController>();

    try {
      final booking = await context.read<ApiClient>().createBooking(
            serviceId: widget.service.id,
            masterId: slot.masterId,
            startAt: slot.startAt,
            comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      shell.openBookings();
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Вы записаны: ${formatDateLong(booking.startAt)}, ${formatTime(booking.startAt)}'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _booking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kSeed))
          : _error != null
              ? _buildError()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _buildHeader(details),
                    const SizedBox(height: 24),
                    if (details != null) _buildMasters(details),
                    const SizedBox(height: 24),
                    const Text('Дата', style: _sectionTitleStyle),
                    const SizedBox(height: 12),
                    _buildDates(),
                    const SizedBox(height: 24),
                    const Text('Свободное время', style: _sectionTitleStyle),
                    const SizedBox(height: 12),
                    _buildSlots(),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Комментарий (необязательно)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  static const TextStyle _sectionTitleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Color(0xFF231F35),
  );

  Widget _buildHeader(ServiceDetails? details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kSeed.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.service.categoryTitle,
                style: const TextStyle(color: kSeed, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.service.title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF231F35)),
        ),
        const SizedBox(height: 10),
        Text(
          details?.description ?? widget.service.description,
          style: const TextStyle(fontSize: 14, height: 1.45, color: kMuted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _InfoPill(icon: Icons.schedule_rounded, text: formatDuration(widget.service.durationMinutes)),
            const SizedBox(width: 8),
            _InfoPill(icon: Icons.payments_outlined, text: formatPrice(widget.service.price)),
          ],
        ),
      ],
    );
  }

  Widget _buildMasters(ServiceDetails details) {
    if (details.masters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Мастер', style: _sectionTitleStyle),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _MasterTile(
                title: 'Любой',
                subtitle: 'свободный',
                initials: '★',
                selected: _masterId == null,
                onTap: () {
                  setState(() => _masterId = null);
                  _loadSlots();
                },
              ),
              ...details.masters.map(
                (master) => _MasterTile(
                  title: master.fullName.split(' ').first,
                  subtitle: '★ ${master.rating}',
                  initials: master.initials,
                  selected: _masterId == master.id,
                  onTap: () {
                    setState(() => _masterId = master.id);
                    _loadSlots();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDates() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final selected = DateUtils.isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadSlots();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? kSeed : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? kSeed : kBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    index == 0 ? 'сегодня' : formatWeekday(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white70 : kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF231F35),
                    ),
                  ),
                  Text(
                    formatDateShort(date).split(' ').last,
                    style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : kMuted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlots() {
    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: kSeed)),
      );
    }

    final slots = _slots?.slots ?? const <Slot>[];
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_busy_rounded, color: kMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text('На этот день свободных окон нет. Выберите другую дату.', style: TextStyle(color: kMuted)),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final selected = _selectedSlot?.masterId == slot.masterId && _selectedSlot?.startAt == slot.startAt;
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? kSeed : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? kSeed : kBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatTime(slot.startAt),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF231F35),
                  ),
                ),
                if (_masterId == null)
                  Text(
                    slot.masterName.split(' ').first,
                    style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : kMuted),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -6)),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatPrice(widget.service.price),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kSeed),
                ),
                Text(
                  _selectedSlot == null
                      ? 'выберите время'
                      : '${formatDateShort(_selectedSlot!.startAt)}, ${formatTime(_selectedSlot!.startAt)}',
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _selectedSlot == null || _booking ? null : _book,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: _booking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Записаться'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: kMuted),
            const SizedBox(height: 12),
            Text(_error ?? 'Ошибка', textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: kMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF3C3552), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MasterTile extends StatelessWidget {
  const _MasterTile({
    required this.title,
    required this.subtitle,
    required this.initials,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String initials;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kSeed.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? kSeed : kBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: selected ? kSeed : const Color(0xFFEDE7FF),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : kSeed,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? kSeed : const Color(0xFF231F35),
              ),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: kMuted)),
          ],
        ),
      ),
    );
  }
}
