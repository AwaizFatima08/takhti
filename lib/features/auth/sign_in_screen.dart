import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/common.dart';
import 'auth_repository.dart';
import 'validators.dart';

/// S2 — Google or email + password.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthCancelled {
      // User closed the picker.
    } catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    }
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(_email.text, _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Sign in to keep your streak and reflections safe.', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 28),
                    BusyButton(
                      label: 'Continue with Google',
                      icon: const _GoogleMark(),
                      onPressed: _google,
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: theme.textTheme.bodyMedium),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/sign-in/forgot'),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    BusyButton(label: 'Sign in', onPressed: _signIn),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('New here?', style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => context.push('/sign-in/create'),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/preview'),
                      child: const Text('Peek at Lesson 1'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple "G" mark; avoids bundling Google's logo artwork.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
      );
}
