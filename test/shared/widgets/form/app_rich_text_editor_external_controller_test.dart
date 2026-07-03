// Widget tests for AppRichTextEditor externalController feature
// AC5: backward compat when externalController is null
// AC6: widget does NOT dispose an externally-provided controller (_ownsController=false)
// AC3: document reflects the converted Delta after AiInsertButton insert
// AC4: onChanged is called with non-empty JSON after insert
// AC7: ConfirmationDialog shown when document.length > 1; insert only on confirm
// AC8: direct insert (no dialog) when document.length <= 1

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_insert_button.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ─── Spy ─────────────────────────────────────────────────────────────────────

class _ControllerSpy extends QuillController {
  _ControllerSpy()
    : super(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );

  int disposeCallCount = 0;

  @override
  void dispose() {
    disposeCallCount++;
    super.dispose();
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: SingleChildScrollView(child: FormBuilder(child: child)),
    ),
  );
}

Widget _editorWithInsertButton({
  required QuillController controller,
  ValueChanged<String>? onChanged,
  String markdown = '## Título de prueba\nContenido insertado',
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppRichTextEditor(
        name: 'description',
        externalController: controller,
        onChanged: onChanged,
      ),
      AiInsertButton(markdown: markdown, quillController: controller),
    ],
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppRichTextEditor — externalController', () {
    // AC5 ─────────────────────────────────────────────────────────────────────
    testWidgets(
      'AC5: externalController=null compiles and renders without error (backward compat)',
      (tester) async {
        await tester.pumpWidget(_wrap(const AppRichTextEditor(name: 'desc')));
        await tester.pumpAndSettle();

        // Widget renders without throwing
        expect(find.byType(AppRichTextEditor), findsOneWidget);
      },
    );

    // AC6 ─────────────────────────────────────────────────────────────────────
    testWidgets(
      'AC6: widget does NOT call dispose() on externalController when removed',
      (tester) async {
        final spy = _ControllerSpy();
        addTearDown(spy.dispose);

        await tester.pumpWidget(
          _wrap(AppRichTextEditor(name: 'desc', externalController: spy)),
        );
        await tester.pumpAndSettle();

        // Remove widget from the tree by replacing with an empty scaffold
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
        await tester.pumpAndSettle();

        // Widget state dispose was called, but _ownsController==false
        // so _controller.dispose() must NOT have been forwarded to the spy.
        expect(
          spy.disposeCallCount,
          0,
          reason:
              '_ownsController=false: widget must NOT call dispose() on external controller',
        );
      },
    );

    // AC3 ─────────────────────────────────────────────────────────────────────
    testWidgets(
      'AC3: quillController.document reflects the Delta converted after insert',
      (tester) async {
        final controller = QuillController.basic();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _wrap(_editorWithInsertButton(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Document is empty — direct insert, no dialog
        expect(controller.document.length, 1); // just the trailing newline

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        // After insert the document has more content than just the newline
        expect(controller.document.length, greaterThan(1));
        expect(
          controller.document.toPlainText(),
          contains('Título de prueba'),
          reason: 'Delta converted from markdown must appear in the document',
        );
      },
    );

    // AC4 ─────────────────────────────────────────────────────────────────────
    testWidgets(
      'AC4: onChanged is invoked with non-empty JSON after document= + updateSelection',
      (tester) async {
        final controller = QuillController.basic();
        addTearDown(controller.dispose);

        final onChangedValues = <String>[];

        await tester.pumpWidget(
          _wrap(
            _editorWithInsertButton(
              controller: controller,
              onChanged: onChangedValues.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(
          onChangedValues,
          isNotEmpty,
          reason: 'onChanged must be called after document update',
        );
        expect(
          onChangedValues.last,
          isNotEmpty,
          reason: 'onChanged must emit non-empty JSON',
        );
        // Quill Delta JSON is a list starting with '['
        expect(
          onChangedValues.last.startsWith('['),
          isTrue,
          reason: 'JSON must be a Quill Delta JSON array',
        );
      },
    );

    // AC7 ─────────────────────────────────────────────────────────────────────
    testWidgets(
      'AC7: shows ConfirmationDialog when document.length > 1; inserts only on confirm',
      (tester) async {
        final doc = Document()..insert(0, 'Contenido existente en el editor');
        final controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
        addTearDown(controller.dispose);

        const newMarkdown = '## Nuevo título\nContenido nuevo';

        await tester.pumpWidget(
          _wrap(
            _editorWithInsertButton(
              controller: controller,
              markdown: newMarkdown,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          controller.document.length,
          greaterThan(1),
          reason: 'Pre-condition: document must have content',
        );

        // Tap insert — should show confirmation dialog
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(
          find.text('Reemplazar descripción'),
          findsOneWidget,
          reason: 'ConfirmationDialog with ai_confirmReplaceTitle must appear',
        );

        // Cancel — content should remain unchanged
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(
          controller.document.toPlainText(),
          contains('Contenido existente en el editor'),
          reason: 'Cancel must NOT replace the content',
        );

        // Tap insert again and confirm
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        expect(
          controller.document.toPlainText(),
          contains('Nuevo título'),
          reason:
              'Confirm must replace the document content with the new delta',
        );
      },
    );

    // AC8 ─────────────────────────────────────────────────────────────────────
    testWidgets(
      'AC8: inserts directly without ConfirmationDialog when document is empty',
      (tester) async {
        final controller = QuillController.basic();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _wrap(_editorWithInsertButton(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(controller.document.length, 1); // empty document

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        // No confirmation dialog
        expect(
          find.text('Reemplazar descripción'),
          findsNothing,
          reason: 'Empty document: no ConfirmationDialog must be shown',
        );

        // Content inserted directly
        expect(
          controller.document.length,
          greaterThan(1),
          reason: 'Content must be inserted without dialog',
        );
      },
    );
  });
}
