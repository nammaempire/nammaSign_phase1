extension StringX on String {
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool get isValidEmail =>
      RegExp(r'^[\w\.-]+@[\w-]+\.[\w\.-]+$').hasMatch(trim());

  bool get isNumeric => RegExp(r'^-?[0-9]+$').hasMatch(this);
}
