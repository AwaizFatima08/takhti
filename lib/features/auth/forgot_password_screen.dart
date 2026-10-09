import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/common.dart';
import 'auth_repository.dart';
import 'validators.dart';

/// S4 — always the same message, so the screen does not reveal which emails exist.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Enter your email and we will send you a link to choose a new password.',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 20),
                  if (_sent)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'If an account exists for this email, a reset link is on its way.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  BusyButton(label: _sent ? 'Send again' : 'Send reset link', onPressed: _send),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
