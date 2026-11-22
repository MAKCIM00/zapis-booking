import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'service_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<ServiceCategory> _categories = const [];
  List<ServiceItem> _services = const [];
  String? _categoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final api = context.read<ApiClient>();
    try {
      final categories = _categories.isEmpty ? await api.categories() : _categories;
      final page = await api.services(query: _searchController.text, categoryId: _categoryId);
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _services = page.items;
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: kSeed,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeader(user),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Найти услугу',
                  prefixIcon: const Icon(Icons.search_rounded, color: kMuted),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kSeed, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCategories(),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: kSeed)),
              )
            else if (_error != null)
              _buildError()
            else if (_services.isEmpty)
              _buildEmpty()
            else
              ..._services.map(
                (service) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _ServiceCard(
                    service: service,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ServiceScreen(service: service)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppUser? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C4DF6), Color(0xFF8B67FF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${greetingFor(DateTime.now())},',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user == null ? 'гость' : firstName(user.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.content_cut_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Салон красоты «Аура»',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Томск, пр. Ленина, 42 · ежедневно 10:00–20:00',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _ServiceCategoryChip(
            label: 'Все',
            selected: _categoryId == null,
            onTap: () {
              setState(() => _categoryId = null);
              _load();
            },
          ),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _ServiceCategoryChip(
                label: category.title,
                selected: _categoryId == category.id,
                onTap: () {
                  setState(() => _categoryId = category.id);
                  _load();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: kMuted),
          const SizedBox(height: 12),
          Text(_error ?? 'Ошибка', textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('Повторить')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: kMuted),
          SizedBox(height: 12),
          Text('Ничего не нашли. Попробуйте другой запрос.', style: TextStyle(color: kMuted)),
        ],
      ),
    );
  }
}

class _ServiceCategoryChip extends StatelessWidget {
  const _ServiceCategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kSeed : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kSeed : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : kMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kSeed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  service.categoryTitle,
                  style: const TextStyle(color: kSeed, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              const Icon(Icons.schedule_rounded, size: 14, color: kMuted),
              const SizedBox(width: 4),
              Text(
                formatDuration(service.durationMinutes),
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF231F35)),
          ),
          const SizedBox(height: 4),
          Text(
            service.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kMuted, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                formatPrice(service.price),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kSeed),
              ),
              const Spacer(),
              if (service.masters.isNotEmpty) ...[
                SizedBox(
                  height: 26,
                  width: 26.0 * service.masters.take(3).length + 8,
                  child: Stack(
                    children: [
                      for (var i = 0; i < service.masters.take(3).length; i++)
                        Positioned(
                          left: i * 20,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFFEDE7FF),
                              child: Text(
                                service.masters[i].initials,
                                style: const TextStyle(fontSize: 9, color: kSeed, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right_rounded, color: kMuted),
            ],
          ),
        ],
      ),
    );
  }
}
