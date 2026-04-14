class NumberToWords {
  NumberToWords._();

  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String _below100(int n) {
    if (n < 20) return _ones[n];
    return '${_tens[n ~/ 10]}${n % 10 != 0 ? ' ${_ones[n % 10]}' : ''}';
  }

  static String _below1000(int n) {
    if (n < 100) return _below100(n);
    return '${_ones[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${_below100(n % 100)}' : ''}';
  }

  static String _convert(int n) {
    if (n == 0) return 'Zero';
    if (n < 0) return 'Minus ${_convert(-n)}';

    String result = '';

    if (n >= 10000000) {
      result += '${_convert(n ~/ 10000000)} Crore ';
      n %= 10000000;
    }
    if (n >= 100000) {
      result += '${_convert(n ~/ 100000)} Lakh ';
      n %= 100000;
    }
    if (n >= 1000) {
      result += '${_convert(n ~/ 1000)} Thousand ';
      n %= 1000;
    }
    if (n > 0) {
      result += _below1000(n);
    }
    return result.trim();
  }

  static String toWords(double amount) {
    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String words = 'Indian Rupee ${_convert(rupees)}';
    if (paise > 0) {
      words += ' and ${_convert(paise)} Paise';
    }
    words += ' Only';
    return words;
  }
}
