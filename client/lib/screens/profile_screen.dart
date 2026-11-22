import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';
import 'home_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(BuildContext context, AuthState auth) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditProfileDialog(auth: auth),
    );

    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
    }
  }

  Future<void> _logout(BuildContext context, AuthState auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Выйти')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await auth.logout();
    if (context.mounted) {
      context.read<AppShellController>().select(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final api = context.read<ApiClient>();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _initials(user?.fullName),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Гость',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Телефон',
                    value: user?.phone ?? '—',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: user?.email ?? '—',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: kSeed),
                    title: const Text('Редактировать профиль'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: kMuted),
                    onTap: () => _editProfile(context, auth),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Выйти', style: TextStyle(color: Colors.redAccent)),
                    onTap: () => _logout(context, auth),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Подключение к API', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(api.baseUrl, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  const SizedBox(height: 10),
                  const Text(
                    'Flutter-клиент + C# REST API. Демо-проект: каталог услуг, '
                    'выбор мастера и времени, запись и отмена.',
                    style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _initials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return '?';
    }
    final parts = fullName.trim().split(' ').where((part) => part.isNotEmpty).toList();
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kMuted),
      title: Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF231F35))),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.auth});

  final AuthState auth;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.auth.user?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.auth.user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.auth.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Профиль'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Имя и фамилия'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Телефон'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
