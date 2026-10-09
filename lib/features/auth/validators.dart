final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return 'Enter your email';
  if (!_emailPattern.hasMatch(s)) return 'That email address does not look right';
  return null;
}

/// Design 5.2: at least 8 characters, one letter and one number.
String? validateNewPassword(String? v) {
  final s = v ?? '';
  if (s.length < 8) return 'At least 8 characters';
  if (!RegExp(r'[A-Za-z]').hasMatch(s)) return 'Add at least one letter';
  if (!RegExp(r'\d').hasMatch(s)) return 'Add at least one number';
  return null;
}

/// Design S3: 2–40 characters.
String? validateName(String? v) {
  final s = v?.trim() ?? '';
  if (s.length < 2) return 'At least 2 characters';
  if (s.length > 40) return 'At most 40 characters';
  return null;
}
