unit MyLibrary;

{
  MyLibrary - Template for BlaiseNotebook External Packages
  
  Instructions:
  1. Copy this entire folder and rename it to your library name (e.g., 'finance').
  2. Rename this unit and file to your desired Unit name (e.g., 'BlaiseFinance.pas').
  3. Update package.json with your name and details.
  4. (Optional) If you wrap Python libraries, list them in requirements.txt.
  5. In any notebook cell, simply type:
       uses MyLibrary;
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, Math, BlaiseOutput;

type
  { TMyCustomService }
  TMyCustomService = class
  public
    class function Add(A, B: Double): Double;
    class function Greet(const AName: string): string;
    class procedure ShowDashboardBanner(const ATitle: string);
  end;

// Global convenience procedures
function CustomAdd(A, B: Double): Double;

implementation

{ TMyCustomService }

class function TMyCustomService.Add(A, B: Double): Double;
begin
  Result := A + B;
end;

class function TMyCustomService.Greet(const AName: string): string;
begin
  Result := 'Welcome to ' + AName + '! Powered by BlaiseNotebook modular package system.';
end;

class procedure TMyCustomService.ShowDashboardBanner(const ATitle: string);
begin
  ShowText('========================================');
  ShowText('  ' + ATitle);
  ShowText('========================================');
end;

function CustomAdd(A, B: Double): Double;
begin
  Result := TMyCustomService.Add(A, B);
end;

end.
