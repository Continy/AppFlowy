import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/board/board.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

import '../../util.dart';
import '../grid_test/util.dart';

class AppFlowyBoardTest {
  final AppFlowyUnitTest unitTest;

  AppFlowyBoardTest({required this.unitTest});

  static Future<AppFlowyBoardTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    return AppFlowyBoardTest(unitTest: inner);
  }

  Future<BoardTestContext> createTestBoard() async {
    final app = await unitTest.createWorkspace();
    final builder = BoardPluginBuilder();
    return ViewBackendService.createView(
      parentViewId: app.id,
      name: "Test Board",
      layoutType: builder.layoutType!,
      openAfterCreate: true,
    ).then((result) {
      return result.fold(
        (view) async {
          final context = BoardTestContext(
            view,
            DatabaseController(view: view),
          );
          final result = await context._boardDataController.open();
          result.fold((l) => null, (r) => throw Exception(r));
          return context;
        },
        (error) {
          throw Exception();
        },
      );
    });
  }
}

Future<void> boardResponseFuture() {
  return Future.delayed(boardResponseDuration(milliseconds: 200));
}

Duration boardResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}

class BoardTestContext {
  final ViewPB gridView;
  final DatabaseController _boardDataController;

  BoardTestContext(this.gridView, this._boardDataController);

  List<RowInfo> get rowInfos {
    return _boardDataController.rowCache.rowInfos;
  }

  List<FieldInfo> get fieldContexts => fieldController.fieldInfos;

  FieldController get fieldController {
    return _boardDataController.fieldController;
  }

  DatabaseController get databaseController => _boardDataController;

  FieldEditorBloc makeFieldEditor({
    required FieldInfo fieldInfo,
  }) {
    final editorBloc = FieldEditorBloc(
      viewId: databaseController.viewId,
      fieldController: fieldController,
      field: fieldInfo.field,
    );
    return editorBloc;
  }

  Future<CellController> makeCellController(String fieldId) async {
    final builder = await makeCellControllerBuilder(fieldId);
    return builder.build();
  }

  Future<CellControllerBuilder> makeCellControllerBuilder(
    String fieldId,
  ) async {
    final RowInfo rowInfo = rowInfos.last;
    final rowCache = _boardDataController.rowCache;

    final rowDataController = RowController(
      viewId: rowInfo.viewId,
      rowMeta: rowInfo.rowMeta,
      rowCache: rowCache,
    );

    final rowBloc = RowBloc(
      viewId: rowInfo.viewId,
      dataController: rowDataController,
      rowId: rowInfo.rowMeta.id,
    )..add(const RowEvent.initial());
    await gridResponseFuture();

    return CellControllerBuilder(
      cellContext: rowBloc.state.cellByFieldId[fieldId]!,
      cellCache: rowCache.cellCache,
    );
  }

  Future<FieldEditorBloc> createField(FieldType fieldType) async {
    final editorBloc =
        await createFieldEditor(databaseController: _boardDataController)
          ..add(const FieldEditorEvent.initial());
    await gridResponseFuture();
    editorBloc.add(FieldEditorEvent.switchFieldType(fieldType));
    await gridResponseFuture();
    return Future(() => editorBloc);
  }

  FieldInfo singleSelectFieldContext() {
    final fieldInfo = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.SingleSelect);
    return fieldInfo;
  }

  FieldInfo textFieldContext() {
    final fieldInfo = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.RichText);
    return fieldInfo;
  }

  FieldInfo checkboxFieldContext() {
    final fieldInfo = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.Checkbox);
    return fieldInfo;
  }
}
