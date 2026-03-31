String repairTurkishText(String input) {
  if (input.isEmpty) return input;

  var text = input;
  const replacements = {
    'Ã§': 'ç',
    'Ã‡': 'Ç',
    'ÄŸ': 'ğ',
    'Äž': 'Ğ',
    'Ä°': 'İ',
    'Ä±': 'ı',
    'Ã¶': 'ö',
    'Ã–': 'Ö',
    'ÅŸ': 'ş',
    'Åž': 'Ş',
    'Ã¼': 'ü',
    'Ãœ': 'Ü',
    'â€¢': '•',
    'â†“': '↓',
    'â†‘': '↑',
    'â€œ': '“',
    'â€': '”',
    'â€™': '’',
  };

  replacements.forEach((broken, fixed) {
    text = text.replaceAll(broken, fixed);
  });

  return text;
}
