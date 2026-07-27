class PhoneValidator {
  // E.164 format validation
  static bool isValid(String phone) {
    if (phone.isEmpty) return false;

    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Check E.164 format: +[country code][number]
    // Must start with +, followed by 1-3 digit country code, then 4-14 digits
    final e164Pattern = RegExp(r'^\+[1-9]\d{1,14}$');
    return e164Pattern.hasMatch(cleaned);
  }

  // Format phone to E.164 for storage
  static String toE164(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Ensure it starts with +
    if (!cleaned.startsWith('+')) {
      // Assume Ethiopia country code if no + prefix
      cleaned = '+251$cleaned';
    }

    return cleaned;
  }

  // Format phone for display (e.g., +251 91 234 5678)
  static String formatForDisplay(String phone) {
    if (!isValid(phone)) return phone;

    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Ethiopia format: +251 XX XXX XXXX
    if (cleaned.startsWith('+251') && cleaned.length == 13) {
      return '+251 ${cleaned.substring(4, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    }

    // Generic format: +XXX XXX XXX XXXX
    if (cleaned.length > 4) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
    }

    return cleaned;
  }

  // Convert phone to email format for Supabase Auth
  static String phoneToEmail(String phone) {
    final e164 = toE164(phone);
    // Remove + sign and append domain
    final phoneDigits = e164.replaceAll('+', '');
    return '$phoneDigits@faarfanna.app';
  }

  // Extract phone from email (reverse of phoneToEmail)
  static String? emailToPhone(String email) {
    if (!email.endsWith('@faarfanna.app')) return null;

    final phoneDigits = email.split('@')[0];
    if (!RegExp(r'^\d+$').hasMatch(phoneDigits)) return null;

    return '+$phoneDigits';
  }

  // Validate password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Validate full name
  static String? validateFullName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Full name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Validate phone number
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    if (!cleaned.startsWith('+')) {
      return 'Phone must start with + and country code (e.g., +251)';
    }

    if (!isValid(cleaned)) {
      return 'Invalid phone number format';
    }

    return null;
  }
}
