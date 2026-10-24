unit NotebookKernel;

{
  NotebookKernel - High-Throughput mORMot 2 WebSocket Kernel Engine
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)
}

{$I mormot.defines.inc}

interface

uses
  SysUtils, Classes, Variants,
  mormot.core.base,
  mormot.core.json,
  mormot.core.variants,
  mormot.core.data,
  mormot.net.ws.core,
  mormot.net.ws.server,
  uCodeRunner;

type
  { TNotebookWebSocketProtocol - Handles Jupyter-compatible WebSocket messages }
  TNotebookWebSocketProtocol = class(TWebSocketProtocolChat)
  private
    FRunner: TCodeRunner;
    FOwnsRunner: Boolean;
    FCurrentSender: TWebSocketProcess;
    procedure HandleStreamOutput(const ACellId, AStreamType, AText: RawUtf8);
    procedure HandleDisplayData(const ACellId, APayloadJson: RawUtf8);
    procedure HandleExecuteReply(const ACellId, AStatus: RawUtf8; AExecCount, ATimeMs: Integer);
  protected
    procedure OnIncoming(Sender: TWebSocketProcess; const Frame: TWebSocketFrame);
  public
    constructor CreateProtocol(const AUri: RawUtf8 = 'ws'; AExistingRunner: TCodeRunner = nil);
    destructor Destroy; override;
    function Clone(const aClientUri: RawUtf8): TWebSocketProtocol; override;

    property Runner: TCodeRunner read FRunner;
  end;

implementation

{ TNotebookWebSocketProtocol }

constructor TNotebookWebSocketProtocol.CreateProtocol(const AUri: RawUtf8; AExistingRunner: TCodeRunner);
begin
  inherited Create('blaise-kernel', AUri);
  if AExistingRunner <> nil then
  begin
    FRunner := AExistingRunner;
    FOwnsRunner := False;
  end
  else
  begin
    FRunner := TCodeRunner.Create('');
    FOwnsRunner := True;
  end;
  FRunner.OnStream := HandleStreamOutput;
  FRunner.OnDisplay := HandleDisplayData;
  FRunner.OnReply := HandleExecuteReply;
  OnIncomingFrame := OnIncoming;
end;

destructor TNotebookWebSocketProtocol.Destroy;
begin
  if FOwnsRunner then
    FRunner.Free;
  inherited Destroy;
end;

function TNotebookWebSocketProtocol.Clone(const aClientUri: RawUtf8): TWebSocketProtocol;
begin
  Result := TNotebookWebSocketProtocol.CreateProtocol(fUri, FRunner);
end;

procedure TNotebookWebSocketProtocol.HandleStreamOutput(const ACellId, AStreamType, AText: RawUtf8);
var
  Doc: TDocVariantData;
  PayloadJson: RawUtf8;
begin
  Doc.InitFast;
  Doc.AddValue('event', 'stream');
  Doc.AddValue('cell_id', ACellId);
  Doc.AddValue('stream_type', AStreamType);
  Doc.AddValue('text', AText);
  PayloadJson := Doc.ToJson;

  if FCurrentSender <> nil then
    SendFrameJson(FCurrentSender, PayloadJson);
end;

procedure TNotebookWebSocketProtocol.HandleDisplayData(const ACellId, APayloadJson: RawUtf8);
var
  Doc: TDocVariantData;
  ParsedPayload: Variant;
  OutJson: RawUtf8;
begin
  Doc.InitFast;
  Doc.AddValue('event', 'display_data');
  Doc.AddValue('cell_id', ACellId);

  ParsedPayload := Null;
  TDocVariantData(ParsedPayload).InitJson(APayloadJson, JSON_FAST);
  Doc.AddValue('payload', ParsedPayload);
  OutJson := Doc.ToJson;

  if FCurrentSender <> nil then
    SendFrameJson(FCurrentSender, OutJson);
end;

procedure TNotebookWebSocketProtocol.HandleExecuteReply(const ACellId, AStatus: RawUtf8; AExecCount, ATimeMs: Integer);
var
  Doc: TDocVariantData;
  OutJson: RawUtf8;
begin
  Doc.InitFast;
  Doc.AddValue('event', 'execute_reply');
  Doc.AddValue('cell_id', ACellId);
  Doc.AddValue('status', AStatus);
  Doc.AddValue('execution_count', AExecCount);
  Doc.AddValue('execution_time_ms', ATimeMs);
  OutJson := Doc.ToJson;

  if FCurrentSender <> nil then
    SendFrameJson(FCurrentSender, OutJson);
end;

procedure TNotebookWebSocketProtocol.OnIncoming(Sender: TWebSocketProcess; const Frame: TWebSocketFrame);
var
  Doc: TDocVariantData;
  Action: RawUtf8;
  CellId: RawUtf8;
  ExecCount: Integer;
  Source: RawUtf8;
begin
  case Frame.opcode of
    focText:
      begin
        Doc.Init;
        try
          if not Doc.InitJson(Frame.payload, JSON_FAST) then Exit;

          Action := Doc.GetValueOrDefault('action', '');
          if Action = 'execute_cell' then
          begin
            CellId := Doc.GetValueOrDefault('cell_id', '');
            ExecCount := Doc.GetValueOrDefault('execution_count', 1);
            Source := Doc.GetValueOrDefault('source', '');

            FCurrentSender := Sender;
            try
              FRunner.ExecuteCell(string(CellId), ExecCount, string(Source));
            finally
              FCurrentSender := nil;
            end;
          end;
        finally
          Doc.Clear;
        end;
      end;
  end;
end;

end.
