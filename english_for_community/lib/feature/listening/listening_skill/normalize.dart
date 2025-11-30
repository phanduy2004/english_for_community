// Nếu muốn dùng package: diacritic ^0.1.4
// import 'package:diacritic/diacritic.dart';

/// Bỏ dấu tiếng Việt (không dùng package)
String _removeVietnameseDiacritics(String s) {
  const src = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩ'
      'òóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨ'
      'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  const dst = 'aaaaaaaaaaaaaaaaaeeeeeeeeeee'
      'iiiiiooooooooooooooooouuuuuuuuuu'
      'yyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIII'
      'OOOOOOOOOOOOOOOOOUUUUUUUUUUYYYYYD';
  final map = <String, String>{};
  for (var i = 0; i < src.length; i++) {
    map[src[i]] = dst[i];
  }
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    sb.write(map[ch] ?? ch);
  }
  return sb.toString();
}

/// Chuẩn hoá để so khớp: lowercase + bỏ dấu TV + hợp nhất nháy + bỏ dấu câu + gộp space
String normalizeText(String s) {
  final lower = s.toLowerCase();
  // final noDia = removeDiacritics(lower); // nếu dùng package diacritic
  final noDia = _removeVietnameseDiacritics(lower);
  final fixedQuote = noDia.replaceAll(RegExp(r"[’`´]"), "'");
  final stripped = fixedQuote.replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ');
  return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Tokenize an toàn
List<String> _tok(String s) => normalizeText(s).split(' ').where((e) => e.isNotEmpty).toList();

/// Pass khi & chỉ khi khớp toàn bộ từ sau normalize (bỏ qua dấu câu, hoa/thường, dấu TV)
bool isSentenceCompleteFE(String refRaw, String userText) {
  final a = _tok(refRaw), b = _tok(userText);
  if (a.isEmpty || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Sinh hint: hiện đúng tới từ sai (bao gồm từ sai ở dạng ĐÚNG),
/// phần sau che bằng "*****". KHÔNG trộn input người dùng vào chuỗi hint.
String buildMaskedHintFE(String refRaw, String userText) {
  final refT = _tok(refRaw);
  final hypT = _tok(userText);

  int firstErr = -1;
  for (var i = 0; i < refT.length; i++) {
    final rt = refT[i];
    final ht = (i < hypT.length) ? hypT[i] : '';
    final wrong = rt != ht && !rt.startsWith(ht);
    if (wrong) { firstErr = i; break; }
  }
  if (firstErr == -1 && hypT.length < refT.length) {
    // đang gõ dở -> coi vị trí tiếp theo là điểm sai
    firstErr = hypT.length;
  }
  if (firstErr < 0) {
    // không sai nhưng có thể chưa đủ → cho dẫn đến ngay sau số từ đã gõ (nếu còn)
    firstErr = (hypT.isEmpty ? 0 : hypT.length).clamp(0, (refT.length - 1).clamp(0, refT.length));
  }

  // Dùng refRaw để giữ nguyên hoa/thường & dấu câu ở phần được show
  final rawTokens = refRaw.split(RegExp(r'\s+'));
  final upto = (firstErr + 1).clamp(0, rawTokens.length);
  final shown = rawTokens.take(upto).join(' ');
  return (upto < rawTokens.length) ? '$shown *****' : shown;
}
