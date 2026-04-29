String? requiredValidator(String? value, {String label = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$label is required';
  }

  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }

  final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!regex.hasMatch(value.trim())) {
    return 'Enter a valid email';
  }

  return null;
}

String? phoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Phone number is required';
  }

  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 15) {
    return 'Enter a valid phone number';
  }

  return null;
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  final regex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
  );
  if (!regex.hasMatch(value)) {
    return 'Use 8+ chars with upper, lower, number and special';
  }

  return null;
}

String? aadhaarValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Aadhaar number is required';
  }

  final regex = RegExp(r'^[2-9][0-9]{11}$');
  if (!regex.hasMatch(value.trim())) {
    return 'Enter a valid Aadhaar number';
  }

  return null;
}
