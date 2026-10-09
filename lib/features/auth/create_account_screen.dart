import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/widgets/common.dart';
import 'auth_repository.dart';
import 'consent_checks.dart';
import 'validators.dart';

/// S3 — name, email, password, 18+ and terms.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _adult = false;
  bool _terms = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _email, _password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      validateName(_name.text) == null &&
      validateEmail(_email.text) == null &&
      validateNewPassword(_password.text) == null &&
      _confirm.text == _password.text &&
      _adult &&
      _terms;

  Future<void> _create() async {
    setState(() => _error = null);
    final busy = ref.read(authBusyProvider.notifier)..set(true);
    try {
      await ref.read(authRepositoryProvider).createAccount(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (mounted) {
        showSnack(context, 'Verification email sent to ${_email.text.trim()}');
      }
    } catch (e) {
      // Account may exist without a user doc; the consent screen recovers that.
      if (mounted) setState(() => _error = authMessage(e));
    } finally {
      busy.set(false);
    }
  }

  String? _fieldError(TextEditingController c, String? Function(String?) validate) =>
      c.text.isEmpty ? null : validate(c.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: 'Name', errorText: _fieldError(_name, validateName)),
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    maxLength: 40,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _email,
                    decoration: InputDecoration(labelText: 'Email', errorText: _fieldError(_email, validateEmail)),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'At least 8 characters, with a letter and a number',
                      helperMaxLines: 2,
                      errorText: _fieldError(_password, validateNewPassword),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      errorText: _confirm.text.isNotEmpty && _confirm.text != _password.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConsentChecks(
                    adult: _adult,
                    terms: _terms,
                    onAdult: (v) => setState(() => _adult = v),
                    onTerms: (v) => setState(() => _terms = v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  BusyButton(label: 'Create account', onPressed: _valid ? _create : null),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
