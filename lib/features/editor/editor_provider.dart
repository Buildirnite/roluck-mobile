import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EditorTool { crop, removeBg, rotate, flip, filters, adjust, effects, frame, resize, watermark, blur, annotate, compress }

/// Un paso del historial de edición: el nombre que se muestra en el chip y el
/// snapshot de la imagen resultante tras aplicar ese paso. [opKey] identifica la
/// operación (p. ej. `rotate:90`) para poder detectar cancelaciones con su
/// inversa inmediata.
class EditStep {
  final String name;
  final Uint8List bytes;
  final String? opKey;
  const EditStep(this.name, this.bytes, {this.opKey});
}

class EditorState {
  final File? inputFile;
  final Uint8List? originalBytes;
  // Historial completo de pasos. Pueden quedar pasos por delante del [cursor]
  // cuando se ha deshecho algo (disponibles para rehacer).
  final List<EditStep> steps;
  // Cuántos pasos están aplicados (0 = imagen original, steps.length = todos).
  final int cursor;
  final EditorTool? activeTool;
  final bool isProcessing;
  // Vista previa temporal (p. ej. mientras se arrastra un slider de ajuste).
  // No forma parte del historial hasta que se confirma con commitEdit.
  final Uint8List? previewBytes;
  // True mientras se mantiene pulsado para comparar con el original.
  final bool comparing;

  const EditorState({
    this.inputFile,
    this.originalBytes,
    this.steps = const [],
    this.cursor = 0,
    this.activeTool,
    this.isProcessing = false,
    this.previewBytes,
    this.comparing = false,
  });

  /// Imagen en el estado actual del historial.
  Uint8List? get currentBytes =>
      cursor == 0 ? originalBytes : steps[cursor - 1].bytes;

  /// Imagen que se debe mostrar en pantalla: el original si se está comparando,
  /// la vista previa temporal si la hay, o el estado actual del historial.
  Uint8List? get displayBytes =>
      comparing ? originalBytes : (previewBytes ?? currentBytes);

  /// ¿Hay algo editado para poder comparar con el original?
  bool get canCompare => cursor > 0 || previewBytes != null;

  /// Nombres de los pasos aplicados (hasta el cursor).
  List<String> get appliedEdits =>
      steps.take(cursor).map((s) => s.name).toList();

  /// Clave de operación del último paso aplicado (o null si no hay).
  String? get lastOpKey => cursor > 0 ? steps[cursor - 1].opKey : null;

  bool get canUndo => cursor > 0;
  bool get canRedo => cursor < steps.length;

  EditorState copyWith({
    File? inputFile,
    Uint8List? originalBytes,
    List<EditStep>? steps,
    int? cursor,
    EditorTool? activeTool,
    bool clearActiveTool = false,
    bool? isProcessing,
    Uint8List? previewBytes,
    bool clearPreview = false,
    bool? comparing,
  }) {
    return EditorState(
      inputFile: inputFile ?? this.inputFile,
      originalBytes: originalBytes ?? this.originalBytes,
      steps: steps ?? this.steps,
      cursor: cursor ?? this.cursor,
      activeTool: clearActiveTool ? null : (activeTool ?? this.activeTool),
      isProcessing: isProcessing ?? this.isProcessing,
      previewBytes: clearPreview ? null : (previewBytes ?? this.previewBytes),
      comparing: comparing ?? this.comparing,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  Future<void> setInput(File file) async {
    final bytes = await file.readAsBytes();
    state = EditorState(
      inputFile: file,
      originalBytes: bytes,
      steps: const [],
      cursor: 0,
    );
  }

  void setActiveTool(EditorTool? tool) {
    // Al cambiar (o cerrar) de herramienta se descarta cualquier vista previa
    // sin confirmar.
    if (tool == state.activeTool) {
      state = state.copyWith(clearActiveTool: true, clearPreview: true);
    } else {
      state = state.copyWith(activeTool: tool, clearPreview: true);
    }
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  /// Muestra una vista previa temporal (no toca el historial).
  void setPreview(Uint8List bytes) =>
      state = state.copyWith(previewBytes: bytes);

  /// Descarta la vista previa temporal.
  void clearPreview() => state = state.copyWith(clearPreview: true);

  /// Activa/desactiva la comparación con el original (mantener pulsado).
  void setComparing(bool value) =>
      state = state.copyWith(comparing: value);

  void applyEdit(String name, Uint8List result, {String? opKey}) {
    // Si había pasos deshechos por delante del cursor, se descartan al aplicar
    // una nueva edición (rama nueva del historial).
    final kept = state.steps.take(state.cursor).toList();
    final next = [...kept, EditStep(name, result, opKey: opKey)];
    state = state.copyWith(steps: next, cursor: next.length, clearPreview: true);
  }

  /// ¿Una operación cuya inversa es [inverseKey] deshace exactamente el último
  /// paso aplicado? (p. ej. rotar 90° der. justo después de 90° izq.). Permite
  /// a las herramientas cancelar SIN procesar la imagen para nada.
  bool cancelsLastStep(String? inverseKey) =>
      inverseKey != null &&
      state.cursor > 0 &&
      state.steps[state.cursor - 1].opKey == inverseKey;

  /// Quita el último paso aplicado. Se usa cuando una acción cancela la
  /// anterior; vuelve al snapshot previo sin reprocesar la imagen.
  void discardLastStep() {
    if (state.cursor > 0) removeStep(state.cursor - 1);
  }

  /// Retrocede un paso (deshacer). El paso queda disponible para rehacer.
  void undo() {
    if (state.cursor > 0) {
      state = state.copyWith(cursor: state.cursor - 1, clearPreview: true);
    }
  }

  /// Avanza un paso (rehacer).
  void redo() {
    if (state.cursor < state.steps.length) {
      state = state.copyWith(cursor: state.cursor + 1, clearPreview: true);
    }
  }

  /// Salta a un punto del historial: deja aplicados [count] pasos.
  void jumpTo(int count) {
    final c = count.clamp(0, state.steps.length);
    state = state.copyWith(cursor: c, clearPreview: true);
  }

  /// Quita un paso del historial. Como cada paso se calcula sobre el anterior,
  /// no es posible recalcular los posteriores: se elimina ese paso y todos los
  /// que vinieron después, dejando el estado justo antes de ese paso.
  void removeStep(int index) {
    if (index < 0 || index >= state.steps.length) return;
    final next = state.steps.take(index).toList();
    state = state.copyWith(steps: next, cursor: next.length, clearPreview: true);
  }

  void resetToOriginal() {
    state = state.copyWith(
      steps: const [],
      cursor: 0,
      clearActiveTool: true,
      clearPreview: true,
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(),
);
