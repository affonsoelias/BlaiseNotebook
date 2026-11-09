unit BlaiseDataScience;

{
  BlaiseDataScience - Backward-Compatibility Aggregate Unit
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)

  Re-exports BlaisePandas and BlaiseSklearn for existing notebooks and courses.
}

{ objfpc}{+}
{ advancedrecords}

interface

uses
  SysUtils, Classes, Math, StrUtils,
  BlaiseOutput, BlaisePyKernel, BlaiseMathKernel,
  BlaisePandas, BlaiseSklearn;

type
  TPySeries = BlaisePandas.TPySeries;
  TPyDataFrame = BlaisePandas.TPyDataFrame;
  TPyGroupBy = BlaisePandas.TPyGroupBy;

  TPyLinearRegression = BlaiseSklearn.TPyLinearRegression;
  TPyRandomForestRegressor = BlaiseSklearn.TPyRandomForestRegressor;
  TPyRandomForestClassifier = BlaiseSklearn.TPyRandomForestClassifier;
  TPyKMeans = BlaiseSklearn.TPyKMeans;
  TPyLogisticRegression = BlaiseSklearn.TPyLogisticRegression;
  TPyDecisionTreeClassifier = BlaiseSklearn.TPyDecisionTreeClassifier;

// Re-export utility functions
function PyFloat(const V: Double): string; inline;
procedure PyRun(const ACode: string); inline;
function PyEval(const AExpr: string): string; inline;
procedure PyReset; inline;
procedure PyTrainTestSplit(const X: TPyDataFrame; const Y: TPySeries; TestSize: Double;
  out XTrain, XTest: TPyDataFrame; out YTrain, YTest: TPySeries; RandomState: Integer = 42); inline;
function PyAccuracyScore(const YTrue, YPred: TPySeries): Double; inline;
function PyR2Score(const YTrue, YPred: TPySeries): Double; inline;
function PyConfusionMatrix(const YTrue, YPred: TPySeries): TPyDataFrame; inline;

implementation

function PyFloat(const V: Double): string; inline;
begin
  Result := BlaisePandas.PyFloat(V);
end;

procedure PyRun(const ACode: string); inline;
begin
  BlaisePyKernel.PyRun(ACode);
end;

function PyEval(const AExpr: string): string; inline;
begin
  Result := BlaisePyKernel.PyEval(AExpr);
end;

procedure PyReset; inline;
begin
  BlaisePyKernel.PyReset;
end;

procedure PyTrainTestSplit(const X: TPyDataFrame; const Y: TPySeries; TestSize: Double;
  out XTrain, XTest: TPyDataFrame; out YTrain, YTest: TPySeries; RandomState: Integer); inline;
begin
  BlaiseSklearn.PyTrainTestSplit(X, Y, TestSize, XTrain, XTest, YTrain, YTest, RandomState);
end;

function PyAccuracyScore(const YTrue, YPred: TPySeries): Double; inline;
begin
  Result := BlaiseSklearn.PyAccuracyScore(YTrue, YPred);
end;

function PyR2Score(const YTrue, YPred: TPySeries): Double; inline;
begin
  Result := BlaiseSklearn.PyR2Score(YTrue, YPred);
end;

function PyConfusionMatrix(const YTrue, YPred: TPySeries): TPyDataFrame; inline;
begin
  Result := BlaiseSklearn.PyConfusionMatrix(YTrue, YPred);
end;

end.
