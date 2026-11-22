import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'demo@zapis.ru');
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'demo1234');

  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final auth = context.read<AuthState>();
    try {
      if (_isRegister) {
        await auth.register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.login(_emailController.text.trim(), _passwordController.text);
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
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C4DF6), Color(0xFF9B72FF), Color(0xFFE8DEFF)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 24),
                  _buildForm(scheme),
                  const SizedBox(height: 16),
                  Text(
                    'Демо-доступ: demo@zapis.ru / demo1234',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: const Icon(Icons.content_cut_rounded, color: kSeed, size: 34),
        ),
        const SizedBox(height: 16),
        const Text(
          'Аура',
          style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Запись в салон красоты онлайн',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 14)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ModeButton(
                  label: 'Вход',
                  selected: !_isRegister,
                  onTap: () => setState(() => _isRegister = false),
                ),
                const SizedBox(width: 8),
                _ModeButton(
                  label: 'Регистрация',
                  selected: _isRegister,
                  onTap: () => setState(() => _isRegister = true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isRegister) ...[
              _field(
                controller: _nameController,
                label: 'Имя и фамилия',
                icon: Icons.person_outline_rounded,
                validator: (value) => (value == null || value.trim().length < 2) ? 'Укажите имя' : null,
              ),
              const SizedBox(height: 12),
            ],
            _field(
              controller: _emailController,
              label: 'Email',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                return email.contains('@') && email.contains('.') ? null : 'Введите email';
              },
            ),
            if (_isRegister) ...[
              const SizedBox(height: 12),
              _field(
                controller: _phoneController,
                label: 'Телефон',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().length < 6) ? 'Укажите телефон' : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: _decoration('Пароль', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
              validator: (value) => (value == null || value.length < 6) ? 'Минимум 6 символов' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(_isRegister ? 'Создать аккаунт' : 'Войти'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _decoration(label, icon),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F5FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kSeed, width: 1.6),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kSeed : const Color(0xFFF1EEFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : kMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
