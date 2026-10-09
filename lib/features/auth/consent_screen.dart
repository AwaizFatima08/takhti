import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/common.dart';
import 'auth_repository.dart';
import 'consent_checks.dart';
import 'validators.dart';

/// S5 — shown to a signed-in user who has no `users/{uid}` doc yet
/// (first Google sign-in, or an interrupted email sign-up).
/// Leaving without agreeing signs the user out again.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  late final TextEditingController _name;
  bool _adult = false;
  bool _terms = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    var name = user?.displayName?.trim() ?? '';
    if (name.length > 40) name = name.substring(0, 40);
    _name = TextEditingController(text: name)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _error = null);
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;
    if (user == null) return;
    try {
      await repo.createUserDoc(user, name: _name.text, provider: repo.usesGoogle ? 'google' : 'password');
    } catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = validateName(_name.text) == null && _adult && _terms;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(authRepositoryProvider).signOut();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('One more step'),
          leading: IconButton(
            tooltip: 'Cancel and sign out',
            icon: const Icon(Icons.close),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Takhti Grow is for adults. Please confirm before you continue.',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Your name',
                      errorText: _name.text.isEmpty ? null : validateName(_name.text),
                    ),
                  ),
                  ConsentChecks(
                    adult: _adult,
                    terms: _terms,
                    onAdult: (v) => setState(() => _adult = v),
                    onTerms: (v) => setState(() => _terms = v),
                  ),
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  BusyButton(label: 'Continue', onPressed: valid ? _continue : null),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
