/// WhatsApp number as SmartLab stores it (`numberformat_excel`): digits only,
/// `08...` becomes `628...`, and the result must start with `628` and have 10
/// to 15 digits. Returns null when the number cannot be normalized.
String? normalizeWaPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('08')) digits = '628${digits.substring(2)}';
  if (!digits.startsWith('628')) return null;
  if (digits.length < 10 || digits.length > 15) return null;
  return digits;
}
