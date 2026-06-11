import 'package:flutter_quill/quill_delta.dart';

/// Converts a subset of Markdown into a Quill [Delta].
///
/// Supported syntax:
/// - `## Heading` → H2
/// - `**bold**` → bold
/// - `*italic*` → italic
/// - `- item` → bullet list item
/// - Plain text → plain paragraph
///
/// Any unsupported syntax is inserted as plain text without throwing.
class MarkdownToDeltaConverter {
  const MarkdownToDeltaConverter();

  Delta convert(String markdown) {
    final delta = Delta();
    final lines = markdown.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;

      if (line.startsWith('### ')) {
        final text = line.substring(4);
        _insertInlineFormatted(delta, text);
        delta.insert('\n', {'header': 3});
      } else if (line.startsWith('## ')) {
        final text = line.substring(3);
        _insertInlineFormatted(delta, text);
        delta.insert('\n', {'header': 2});
      } else if (line.startsWith('# ')) {
        final text = line.substring(2);
        _insertInlineFormatted(delta, text);
        delta.insert('\n', {'header': 1});
      } else if (line.startsWith('- ')) {
        // Bullet list
        final text = line.substring(2);
        _insertInlineFormatted(delta, text);
        delta.insert('\n', {'list': 'bullet'});
      } else {
        // Plain text (with possible inline formatting)
        _insertInlineFormatted(delta, line);
        if (!isLast) {
          delta.insert('\n');
        }
      }
    }

    // Ensure document ends with a newline (Quill requirement)
    if (!markdown.endsWith('\n')) {
      delta.insert('\n');
    }

    return delta;
  }

  void _insertInlineFormatted(Delta delta, String text) {
    // Process bold (**text**) and italic (*text*) inline markers.
    // We use a simple state-machine to avoid regex catastrophic backtracking.
    var remaining = text;

    while (remaining.isNotEmpty) {
      // Bold: **...**
      final boldStart = remaining.indexOf('**');
      // Italic: *...* (single star, but not **)
      final italicStart = _findSingleStar(remaining);

      if (boldStart != -1 && (italicStart == -1 || boldStart <= italicStart)) {
        // Insert text before bold marker
        if (boldStart > 0) {
          delta.insert(remaining.substring(0, boldStart));
        }
        final afterOpen = remaining.substring(boldStart + 2);
        final closeIdx = afterOpen.indexOf('**');
        if (closeIdx != -1) {
          final boldText = afterOpen.substring(0, closeIdx);
          delta.insert(boldText, {'bold': true});
          remaining = afterOpen.substring(closeIdx + 2);
        } else {
          // No closing **: treat as plain text
          delta.insert('**');
          remaining = afterOpen;
        }
      } else if (italicStart != -1) {
        // Insert text before italic marker
        if (italicStart > 0) {
          delta.insert(remaining.substring(0, italicStart));
        }
        final afterOpen = remaining.substring(italicStart + 1);
        final closeIdx = _findSingleStar(afterOpen);
        if (closeIdx != -1) {
          final italicText = afterOpen.substring(0, closeIdx);
          delta.insert(italicText, {'italic': true});
          remaining = afterOpen.substring(closeIdx + 1);
        } else {
          // No closing *: treat as plain text
          delta.insert('*');
          remaining = afterOpen;
        }
      } else {
        // No more formatting markers
        delta.insert(remaining);
        remaining = '';
      }
    }
  }

  /// Finds the index of a single `*` that is NOT part of `**`.
  int _findSingleStar(String text) {
    var i = 0;
    while (i < text.length) {
      if (text[i] == '*') {
        if (i + 1 < text.length && text[i + 1] == '*') {
          i += 2; // skip **
        } else {
          return i;
        }
      } else {
        i++;
      }
    }
    return -1;
  }
}
