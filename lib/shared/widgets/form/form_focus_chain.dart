import 'package:flutter/widgets.dart';

//TODO USAR ESTO EN LOS DEMÁS FORMULARIOS
/// Ordered focus traversal for form fields keyed by logical names (e.g. form field IDs).
class FormFocusChain {
  FormFocusChain(this.fields)
    : assert(fields.isNotEmpty, 'fields must not be empty');

  final List<String> fields;
  final Map<String, FocusNode> _nodes = <String, FocusNode>{};

  FocusNode nodeFor(String field) => _nodes.putIfAbsent(field, FocusNode.new);

  FocusNode operator [](String field) => nodeFor(field);

  void requestNextAfter(String field) {
    final index = fields.indexOf(field);
    if (index == -1) {
      return;
    }
    if (index < fields.length - 1) {
      nodeFor(fields[index + 1]).requestFocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _scheduleScrollFocusedIntoView();
  }

  void unfocusAll(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  void dispose() {
    final nodes = List<FocusNode>.of(_nodes.values);
    _nodes.clear();
    for (final FocusNode node in nodes) {
      node.dispose();
    }
  }

  void _scheduleScrollFocusedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final FocusNode? focused = FocusManager.instance.primaryFocus;
      final BuildContext? nodeContext = focused?.context;
      if (nodeContext != null && nodeContext.mounted) {
        Scrollable.ensureVisible(
          nodeContext,
          alignment: 0.18,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}
