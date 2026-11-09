unit uToolTemplate;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

function GetToolName: string;
function GetToolVersion: string;

implementation

function GetToolName: string;
begin
  Result := 'Official Auxiliary Tool Template';
end;

function GetToolVersion: string;
begin
  Result := '1.0.0';
end;

end.
