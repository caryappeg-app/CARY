// Core: أدوات تنسيق مشتركة (من غير أي اعتماد على Flutter)

/// 12345678 -> 12,345,678
String formatNumber(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
