unit BlaiseNotebook;

{
  BlaiseNotebook - High-Performance Interactive Scientific Notebook for BlaiseVue
  -------------------------------------------------------------------------------
  Part of BlaiseNotebook Suite (Universal Pascal Platform)
  Encapsulates data models, cell operations, scroll-preserving manipulations,
  and reactive event bridging so components remain clean Object Pascal.
}

{$mode objfpc}

interface

uses
  JS, Web, SysUtils;

const
  BLAISE_NOTEBOOK_VERSION = '1.0.0';
  CELL_CODE               = 'code';
  CELL_MARKDOWN           = 'markdown';
  STATUS_IDLE             = 'idle';
  STATUS_RUNNING          = 'running';
  STATUS_SUCCESS          = 'success';
  STATUS_ERROR            = 'error';
  STATUS_ABORTED          = 'aborted';

type
  { TBVNotebookBridge - Centralized Object Pascal bridge for notebook interactions }
  TBVNotebookBridge = class
  public
    { Type and status inspection }
    class function IsCellCode(ACell: JSValue): Boolean;
    class function IsCellMarkdown(ACell: JSValue): Boolean;
    class function BuildCellClasses(ACell: JSValue): JSValue;
    class procedure UpdateCellSource(ACell: JSValue; const ANewVal: string);

    { Vue / BlaiseVue event dispatching }
    class procedure Emit(AComponent: JSValue; const AEventName: string); overload;
    class procedure Emit(AComponent: JSValue; const AEventName: string; const AParam1: JSValue); overload;
    class procedure Emit(AComponent: JSValue; const AEventName: string; const AParam1: JSValue; const AParam2: JSValue); overload;

    { Viewport Scroll Management }
    class function GetScrollY: Double;
    class procedure RestoreScrollY(const AY: Double);

    { Cell Array Manipulations with automatic scroll preservation }
    class function FindCellIndex(ACells: JSValue; ACellOrIdx: JSValue): Integer;
    class function CreateCellObject(const AType: string; const ASource: string): JSValue;
    class procedure InsertCellBelow(ACells: JSValue; ACellOrIdx: JSValue; const AType, ADefaultSource: string; AForceUpdate: JSValue = nil);
    class procedure InsertCellAt(ACells: JSValue; const AIdx: Integer; const AType, ADefaultSource: string; AForceUpdate: JSValue = nil);
    class procedure MoveCell(ACells: JSValue; const AFromIdx, AToIdx: Integer; AForceUpdate: JSValue = nil);
    class procedure DeleteCellAt(ACells: JSValue; const AIdx: Integer; AForceUpdate: JSValue = nil);
  end;

implementation

{ TBVNotebookBridge }

class function TBVNotebookBridge.IsCellCode(ACell: JSValue): Boolean;
begin
  asm
    const c = ACell;
    return (c && c.type === 'code');
  end;
end;

class function TBVNotebookBridge.IsCellMarkdown(ACell: JSValue): Boolean;
begin
  asm
    const c = ACell;
    return (c && c.type === 'markdown');
  end;
end;

class function TBVNotebookBridge.BuildCellClasses(ACell: JSValue): JSValue;
begin
  asm
    const c = ACell || {};
    return {
      'cell-is-code': c.type === 'code',
      'cell-is-md': c.type === 'markdown',
      'cell-status-running': c.status === 'running',
      'cell-status-error': c.status === 'error',
      'cell-status-success': c.status === 'success',
      'cell-status-aborted': c.status === 'aborted'
    };
  end;
end;

class procedure TBVNotebookBridge.UpdateCellSource(ACell: JSValue; const ANewVal: string);
begin
  asm
    if (ACell) {
      ACell.source = ANewVal;
    }
  end;
end;

class procedure TBVNotebookBridge.Emit(AComponent: JSValue; const AEventName: string);
begin
  asm
    if (AComponent && typeof AComponent.$emit === 'function') {
      AComponent.$emit(AEventName);
    }
  end;
end;

class procedure TBVNotebookBridge.Emit(AComponent: JSValue; const AEventName: string; const AParam1: JSValue);
begin
  asm
    if (AComponent && typeof AComponent.$emit === 'function') {
      AComponent.$emit(AEventName, AParam1);
    }
  end;
end;

class procedure TBVNotebookBridge.Emit(AComponent: JSValue; const AEventName: string; const AParam1: JSValue; const AParam2: JSValue);
begin
  asm
    if (AComponent && typeof AComponent.$emit === 'function') {
      AComponent.$emit(AEventName, AParam1, AParam2);
    }
  end;
end;

class function TBVNotebookBridge.GetScrollY: Double;
begin
  asm
    return window.scrollY || window.pageYOffset || (document.documentElement ? document.documentElement.scrollTop : 0);
  end;
end;

class procedure TBVNotebookBridge.RestoreScrollY(const AY: Double);
begin
  asm
    requestAnimationFrame(function() {
      window.scrollTo({ top: AY, behavior: 'instant' });
    });
  end;
end;

class function TBVNotebookBridge.FindCellIndex(ACells: JSValue; ACellOrIdx: JSValue): Integer;
begin
  asm
    const cells = ACells || [];
    if (ACellOrIdx && typeof ACellOrIdx === 'object' && ACellOrIdx.id) {
      return cells.findIndex(function(x) { return x && x.id === ACellOrIdx.id; });
    }
    if (typeof ACellOrIdx === 'number') {
      return ACellOrIdx;
    }
    return -1;
  end;
end;

class function TBVNotebookBridge.CreateCellObject(const AType: string; const ASource: string): JSValue;
begin
  asm
    const factory = window.bvCreateCell;
    if (typeof factory === 'function') {
      return factory(AType, ASource);
    }
    return {
      id: 'cell_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6),
      type: AType,
      source: ASource,
      output: '',
      status: 'idle',
      execCount: null,
      hasError: false,
      renderMath: true,
      lastRunTime: null
    };
  end;
end;

class procedure TBVNotebookBridge.InsertCellBelow(ACells: JSValue; ACellOrIdx: JSValue; const AType, ADefaultSource: string; AForceUpdate: JSValue = nil);
var
  SavedY: Double;
begin
  SavedY := GetScrollY;
  asm
    const cells = ACells || [];
    let targetIdx = TBVNotebookBridge.FindCellIndex(cells, ACellOrIdx);
    if (targetIdx < 0 || targetIdx >= cells.length) {
      targetIdx = cells.length - 1;
    }
    const newCell = TBVNotebookBridge.CreateCellObject(AType, ADefaultSource);
    cells.splice(targetIdx + 1, 0, newCell);
  end;
  RestoreScrollY(SavedY);
end;

class procedure TBVNotebookBridge.InsertCellAt(ACells: JSValue; const AIdx: Integer; const AType, ADefaultSource: string; AForceUpdate: JSValue = nil);
var
  SavedY: Double;
begin
  SavedY := GetScrollY;
  asm
    const cells = ACells || [];
    const newCell = TBVNotebookBridge.CreateCellObject(AType, ADefaultSource);
    cells.splice(AIdx, 0, newCell);
  end;
  RestoreScrollY(SavedY);
end;

class procedure TBVNotebookBridge.MoveCell(ACells: JSValue; const AFromIdx, AToIdx: Integer; AForceUpdate: JSValue = nil);
var
  SavedY: Double;
begin
  SavedY := GetScrollY;
  asm
    const cells = ACells || [];
    if (AFromIdx >= 0 && AFromIdx < cells.length && AToIdx >= 0 && AToIdx < cells.length) {
      const item = cells.splice(AFromIdx, 1)[0];
      cells.splice(AToIdx, 0, item);
    }
  end;
  RestoreScrollY(SavedY);
end;

class procedure TBVNotebookBridge.DeleteCellAt(ACells: JSValue; const AIdx: Integer; AForceUpdate: JSValue = nil);
var
  SavedY: Double;
begin
  asm
    const cells = ACells || [];
    if (cells.length <= 1) {
      alert('The notebook must contain at least one cell.');
      return;
    }
  end;
  SavedY := GetScrollY;
  asm
    const cells = ACells || [];
    cells.splice(AIdx, 1);
  end;
  RestoreScrollY(SavedY);
end;

end.
