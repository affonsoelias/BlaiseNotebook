unit BlaiseSklearn;

{
  BlaiseSklearn - Strongly-Typed Object Pascal API for Scikit-Learn
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)

  Provides native Object Pascal abstractions for Scikit-Learn:
  - TPyLinearRegression: Linear Regression model
  - TPyRandomForestRegressor: Random Forest Regressor
  - TPyRandomForestClassifier: Random Forest Classifier
  - TPyKMeans: K-Means Clustering
  - TPyLogisticRegression: Logistic Regression classifier
  - TPyDecisionTreeClassifier: Decision Tree classifier
  - PyTrainTestSplit, PyAccuracyScore, PyR2Score, PyConfusionMatrix
}

{ objfpc}{+}
{ advancedrecords}

interface

uses
  SysUtils, Classes, Math, StrUtils,
  BlaiseOutput, BlaisePyKernel, BlaiseMathKernel, BlaisePandas;

type
  { TPyLinearRegression - Scikit-learn LinearRegression model }
  TPyLinearRegression = class
  private
    FVarName: string;
  public
    constructor Create;
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries); overload;
    procedure Fit(const X: TPySeries; const Y: TPySeries); overload;
    function Predict(const X: TPyDataFrame): TPySeries; overload;
    function Predict(const X: TPySeries): TPySeries; overload;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double; overload;
    function Score(const X: TPySeries; const Y: TPySeries): Double; overload;

    function Slope: Double;
    function Coefficients: TDoubleArray;
    function Intercept: Double;
    function Summary: string;

    property VarName: string read FVarName;
  end;

  { TPyRandomForestRegressor - Scikit-learn RandomForestRegressor model }
  TPyRandomForestRegressor = class
  private
    FVarName: string;
  public
    constructor Create(nEstimators: Integer = 100; maxDepth: Integer = -1; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double;
    function FeatureImportances: TDoubleArray;
    procedure PlotFeatureImportances(const AFeatures: array of string; const ATitle: string = 'Feature Importances');

    property VarName: string read FVarName;
  end;

  { TPyRandomForestClassifier - Scikit-learn RandomForestClassifier model }
  TPyRandomForestClassifier = class
  private
    FVarName: string;
  public
    constructor Create(nEstimators: Integer = 100; maxDepth: Integer = -1; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double;

    property VarName: string read FVarName;
  end;

  { TPyKMeans - Scikit-learn KMeans Clustering model }
  TPyKMeans = class
  private
    FVarName: string;
  public
    constructor Create(nClusters: Integer = 3; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Labels: TPySeries;
    function Inertia: Double;

    property VarName: string read FVarName;
  end;

  { TPyLogisticRegression - Scikit-learn Logistic Regression classification model }
  TPyLogisticRegression = class
  private
    FVarName: string;
  public
    constructor Create(maxIter: Integer = 200; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double;
    function PredictProba(const X: TPyDataFrame): TPyDataFrame;

    property VarName: string read FVarName;
  end;

  { TPyDecisionTreeClassifier - Scikit-learn DecisionTreeClassifier model }
  TPyDecisionTreeClassifier = class
  private
    FVarName: string;
  public
    constructor Create(maxDepth: Integer = -1; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double;
    function FeatureImportances: TDoubleArray;
    procedure PlotFeatureImportances(const AFeatures: array of string; const ATitle: string = 'Decision Tree Feature Importances');

    property VarName: string read FVarName;
  end;

procedure EnsurePySklearn;
procedure PyTrainTestSplit(const X: TPyDataFrame; const Y: TPySeries; TestSize: Double;
  out XTrain, XTest: TPyDataFrame; out YTrain, YTest: TPySeries; RandomState: Integer = 42);
function PyAccuracyScore(const YTrue, YPred: TPySeries): Double;
function PyR2Score(const YTrue, YPred: TPySeries): Double;
function PyConfusionMatrix(const YTrue, YPred: TPySeries): TPyDataFrame;


implementation

var
  FormatSettingsUS: TFormatSettings;

procedure EnsurePySklearn;
begin
  EnsurePyPandas;
  TBlaisePy.Exec(
    'import sklearn'#10 +
    'from sklearn.linear_model import LinearRegression, LogisticRegression'#10 +
    'from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier'#10 +
    'from sklearn.tree import DecisionTreeClassifier'#10 +
    'from sklearn.cluster import KMeans'#10 +
    'from sklearn.model_selection import train_test_split'#10 +
    'from sklearn.metrics import accuracy_score, r2_score, confusion_matrix'#10
  );
end;

{ TPyLinearRegression }

constructor TPyLinearRegression.Create;
begin
  inherited Create;
  EnsurePySklearn;
  FVarName := NewPyVar('lr');
  TBlaisePy.Exec(
    'from sklearn.linear_model import LinearRegression'#10 +
    Format('%s = LinearRegression()', [FVarName]));
end;

procedure TPyLinearRegression.Fit(const X: TPyDataFrame; const Y: TPySeries);
begin
  TBlaisePy.Exec(Format('%s.fit(%s, %s)', [FVarName, X.VarName, Y.VarName]));
end;

procedure TPyLinearRegression.Fit(const X: TPySeries; const Y: TPySeries);
begin
  TBlaisePy.Exec(Format('%s.fit(%s.values.reshape(-1, 1), %s)', [FVarName, X.VarName, Y.VarName]));
end;

function TPyLinearRegression.Predict(const X: TPyDataFrame): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_pred');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.predict(%s), name="Prediction")', [NewVar, FVarName, X.VarName]));
  Result := TPySeries.Create(NewVar, 'Prediction');
end;

function TPyLinearRegression.Predict(const X: TPySeries): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_pred');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.predict(%s.values.reshape(-1, 1)), name="Prediction")', [NewVar, FVarName, X.VarName]));
  Result := TPySeries.Create(NewVar, 'Prediction');
end;

function TPyLinearRegression.Score(const X: TPyDataFrame; const Y: TPySeries): Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.score(%s, %s))', [FVarName, X.VarName, Y.VarName])), 0.0, FormatSettingsUS);
end;

function TPyLinearRegression.Score(const X: TPySeries; const Y: TPySeries): Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.score(%s.values.reshape(-1, 1), %s))', [FVarName, X.VarName, Y.VarName])), 0.0, FormatSettingsUS);
end;

function TPyLinearRegression.Slope: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.coef_[0])', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPyLinearRegression.Coefficients: TDoubleArray;
var
  JsonStr, ItemStr: string;
  Len, P1, P2: Integer;
begin
  SetLength(Result, 0);
  JsonStr := TBlaisePy.EvalStr(Format('json.dumps([float(x) for x in %s.coef_])', [FVarName]));
  if (Length(JsonStr) >= 2) and (JsonStr[1] = '[') and (JsonStr[Length(JsonStr)] = ']') then
  begin
    JsonStr := Copy(JsonStr, 2, Length(JsonStr) - 2);
    if Trim(JsonStr) = '' then Exit;
    P1 := 1;
    while P1 <= Length(JsonStr) do
    begin
      P2 := PosEx(',', JsonStr, P1);
      if P2 = 0 then P2 := Length(JsonStr) + 1;
      ItemStr := Trim(Copy(JsonStr, P1, P2 - P1));
      Len := Length(Result);
      SetLength(Result, Len + 1);
      Result[Len] := StrToFloatDef(ItemStr, 0.0, FormatSettingsUS);
      P1 := P2 + 1;
    end;
  end;
end;

function TPyLinearRegression.Intercept: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.intercept_)', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPyLinearRegression.Summary: string;
begin
  Result := Format('LinearRegression(Slope=%.4f, Intercept=%.4f)', [Slope, Intercept], FormatSettingsUS);
end;

{ TPyRandomForestRegressor }

constructor TPyRandomForestRegressor.Create(nEstimators, maxDepth, randomState: Integer);
var
  DepthParam: string;
begin
  inherited Create;
  EnsurePySklearn;
  FVarName := NewPyVar('rf_reg');
  if maxDepth <= 0 then DepthParam := 'None' else DepthParam := IntToStr(maxDepth);
  TBlaisePy.Exec(
    'from sklearn.ensemble import RandomForestRegressor'#10 +
    Format('%s = RandomForestRegressor(n_estimators=%d, max_depth=%s, random_state=%d)',
      [FVarName, nEstimators, DepthParam, randomState]));
end;

procedure TPyRandomForestRegressor.Fit(const X: TPyDataFrame; const Y: TPySeries);
begin
  TBlaisePy.Exec(Format('%s.fit(%s, %s)', [FVarName, X.VarName, Y.VarName]));
end;

function TPyRandomForestRegressor.Predict(const X: TPyDataFrame): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_pred');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.predict(%s), name="RF_Prediction")', [NewVar, FVarName, X.VarName]));
  Result := TPySeries.Create(NewVar, 'RF_Prediction');
end;

function TPyRandomForestRegressor.Score(const X: TPyDataFrame; const Y: TPySeries): Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.score(%s, %s))', [FVarName, X.VarName, Y.VarName])), 0.0, FormatSettingsUS);
end;

function TPyRandomForestRegressor.FeatureImportances: TDoubleArray;
var
  JsonStr, ItemStr: string;
  Len, P1, P2: Integer;
begin
  SetLength(Result, 0);
  JsonStr := TBlaisePy.EvalStr(Format('json.dumps([float(x) for x in %s.feature_importances_])', [FVarName]));
  if (Length(JsonStr) >= 2) and (JsonStr[1] = '[') and (JsonStr[Length(JsonStr)] = ']') then
  begin
    JsonStr := Copy(JsonStr, 2, Length(JsonStr) - 2);
    if Trim(JsonStr) = '' then Exit;
    P1 := 1;
    while P1 <= Length(JsonStr) do
    begin
      P2 := PosEx(',', JsonStr, P1);
      if P2 = 0 then P2 := Length(JsonStr) + 1;
      ItemStr := Trim(Copy(JsonStr, P1, P2 - P1));
      Len := Length(Result);
      SetLength(Result, Len + 1);
      Result[Len] := StrToFloatDef(ItemStr, 0.0, FormatSettingsUS);
      P1 := P2 + 1;
    end;
  end;
end;

procedure TPyRandomForestRegressor.PlotFeatureImportances(const AFeatures: array of string; const ATitle: string);
var
  LabelsJson, DataJson, ChartJson: string;
  i: Integer;
  Imp: TDoubleArray;
begin
  Imp := FeatureImportances;
  LabelsJson := '[';
  DataJson := '[';
  for i := 0 to High(AFeatures) do
  begin
    if i > 0 then
    begin
      LabelsJson := LabelsJson + ', ';
      DataJson := DataJson + ', ';
    end;
    LabelsJson := LabelsJson + '"' + AFeatures[i] + '"';
    if i <= High(Imp) then
      DataJson := DataJson + PyFloat(Imp[i])
    else
      DataJson := DataJson + '0.0';
  end;
  LabelsJson := LabelsJson + ']';
  DataJson := DataJson + ']';

  ChartJson := Format('{"labels": %s, "datasets": [{"label": "Importance", "data": %s, "backgroundColor": "#10b981"}]}',
    [LabelsJson, DataJson]);
  TBlaiseOutput.ShowChart(ATitle, 'bar', ChartJson);
end;

{ TPyRandomForestClassifier }

constructor TPyRandomForestClassifier.Create(nEstimators, maxDepth, randomState: Integer);
var
  DepthParam: string;
begin
  inherited Create;
  EnsurePySklearn;
  FVarName := NewPyVar('rf_clf');
  if maxDepth <= 0 then DepthParam := 'None' else DepthParam := IntToStr(maxDepth);
  TBlaisePy.Exec(
    'from sklearn.ensemble import RandomForestClassifier'#10 +
    Format('%s = RandomForestClassifier(n_estimators=%d, max_depth=%s, random_state=%d)',
      [FVarName, nEstimators, DepthParam, randomState]));
end;

procedure TPyRandomForestClassifier.Fit(const X: TPyDataFrame; const Y: TPySeries);
begin
  TBlaisePy.Exec(Format('%s.fit(%s, %s)', [FVarName, X.VarName, Y.VarName]));
end;

function TPyRandomForestClassifier.Predict(const X: TPyDataFrame): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_pred');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.predict(%s), name="Classification")', [NewVar, FVarName, X.VarName]));
  Result := TPySeries.Create(NewVar, 'Classification');
end;

function TPyRandomForestClassifier.Score(const X: TPyDataFrame; const Y: TPySeries): Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.score(%s, %s))', [FVarName, X.VarName, Y.VarName])), 0.0, FormatSettingsUS);
end;

{ TPyKMeans }

constructor TPyKMeans.Create(nClusters, randomState: Integer);
begin
  inherited Create;
  EnsurePySklearn;
  FVarName := NewPyVar('kmeans');
  TBlaisePy.Exec(
    'from sklearn.cluster import KMeans'#10 +
    Format('%s = KMeans(n_clusters=%d, random_state=%d, n_init="auto")',
      [FVarName, nClusters, randomState]));
end;

procedure TPyKMeans.Fit(const X: TPyDataFrame);
begin
  TBlaisePy.Exec(Format('%s.fit(%s)', [FVarName, X.VarName]));
end;

function TPyKMeans.Predict(const X: TPyDataFrame): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_cluster');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.predict(%s), name="Cluster")', [NewVar, FVarName, X.VarName]));
  Result := TPySeries.Create(NewVar, 'Cluster');
end;

function TPyKMeans.Labels: TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_labels');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.labels_, name="Cluster")', [NewVar, FVarName]));
  Result := TPySeries.Create(NewVar, 'Cluster');
end;

function TPyKMeans.Inertia: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.inertia_)', [FVarName])), 0.0, FormatSettingsUS);
end;

{ PyTrainTestSplit }

procedure PyTrainTestSplit(const X: TPyDataFrame; const Y: TPySeries; TestSize: Double;
  out XTrain, XTest: TPyDataFrame; out YTrain, YTest: TPySeries; RandomState: Integer);
var
  XTrVar, XTeVar, YTrVar, YTeVar, Code: string;
begin
  EnsurePySklearn;
  XTrVar := NewPyVar('xtr');
  XTeVar := NewPyVar('xte');
  YTrVar := NewPyVar('ytr');
  YTeVar := NewPyVar('yte');

  Code :=
    'from sklearn.model_selection import train_test_split'#10 +
    Format('%s, %s, %s, %s = train_test_split(%s, %s, test_size=%s, random_state=%d)',
      [XTrVar, XTeVar, YTrVar, YTeVar, X.VarName, Y.VarName, PyFloat(TestSize), RandomState]);
  TBlaisePy.Exec(Code);

  XTrain := TPyDataFrame.Create(XTrVar);
  XTest  := TPyDataFrame.Create(XTeVar);
  YTrain := TPySeries.Create(YTrVar, 'y_train');
  YTest  := TPySeries.Create(YTeVar, 'y_test');
end;

{ TPyLogisticRegression }

constructor TPyLogisticRegression.Create(maxIter: Integer; randomState: Integer);
begin
  inherited Create;
  EnsurePySklearn;
  FVarName := NewPyVar('log_reg');
  TBlaisePy.Exec(
    'from sklearn.linear_model import LogisticRegression'#10 +
    Format('%s = LogisticRegression(max_iter=%d, random_state=%d)',
      [FVarName, maxIter, randomState]));
end;

procedure TPyLogisticRegression.Fit(const X: TPyDataFrame; const Y: TPySeries);
begin
  TBlaisePy.Exec(Format('%s.fit(%s, %s)', [FVarName, X.VarName, Y.VarName]));
end;

function TPyLogisticRegression.Predict(const X: TPyDataFrame): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_pred');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.predict(%s), name="LogisticRegression_Pred")',
    [NewVar, FVarName, X.VarName]));
  Result := TPySeries.Create(NewVar, 'LogisticRegression_Pred');
end;

function TPyLogisticRegression.Score(const X: TPyDataFrame; const Y: TPySeries): Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.score(%s, %s))', [FVarName, X.VarName, Y.VarName])), 0.0, FormatSettingsUS);
end;

function TPyLogisticRegression.PredictProba(const X: TPyDataFrame): TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df_proba');
  TBlaisePy.Exec(
    Format('__probs = %s.predict_proba(%s)'#10 +
           '%s = pd.DataFrame(__probs, columns=[f"Class_{c}" for c in %s.classes_])',
           [FVarName, X.VarName, NewVar, FVarName]));
  Result := TPyDataFrame.Create(NewVar);
end;

{ TPyDecisionTreeClassifier }

constructor TPyDecisionTreeClassifier.Create(maxDepth: Integer; randomState: Integer);
var
  DepthParam: string;
begin
  inherited Create;
  EnsurePySklearn;
  FVarName := NewPyVar('dt_clf');
  if maxDepth <= 0 then DepthParam := 'None' else DepthParam := IntToStr(maxDepth);
  TBlaisePy.Exec(
    'from sklearn.tree import DecisionTreeClassifier'#10 +
    Format('%s = DecisionTreeClassifier(max_depth=%s, random_state=%d)',
      [FVarName, DepthParam, randomState]));
end;

procedure TPyDecisionTreeClassifier.Fit(const X: TPyDataFrame; const Y: TPySeries);
begin
  TBlaisePy.Exec(Format('%s.fit(%s, %s)', [FVarName, X.VarName, Y.VarName]));
end;

function TPyDecisionTreeClassifier.Predict(const X: TPyDataFrame): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s_pred');
  TBlaisePy.Exec(Format('%s = pd.Series(%s.predict(%s), name="DecisionTree_Pred")',
    [NewVar, FVarName, X.VarName]));
  Result := TPySeries.Create(NewVar, 'DecisionTree_Pred');
end;

function TPyDecisionTreeClassifier.Score(const X: TPyDataFrame; const Y: TPySeries): Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.score(%s, %s))', [FVarName, X.VarName, Y.VarName])), 0.0, FormatSettingsUS);
end;

function TPyDecisionTreeClassifier.FeatureImportances: TDoubleArray;
var
  JsonStr, ItemStr: string;
  P1, P2, Len: Integer;
begin
  SetLength(Result, 0);
  JsonStr := TBlaisePy.EvalStr(Format('json.dumps(list(%s.feature_importances_))', [FVarName]));
  if (Length(JsonStr) >= 2) and (JsonStr[1] = '[') and (JsonStr[Length(JsonStr)] = ']') then
  begin
    JsonStr := Copy(JsonStr, 2, Length(JsonStr) - 2);
    if Trim(JsonStr) = '' then Exit;
    P1 := 1;
    while P1 <= Length(JsonStr) do
    begin
      P2 := PosEx(',', JsonStr, P1);
      if P2 = 0 then P2 := Length(JsonStr) + 1;
      ItemStr := Trim(Copy(JsonStr, P1, P2 - P1));
      Len := Length(Result);
      SetLength(Result, Len + 1);
      Result[Len] := StrToFloatDef(ItemStr, 0.0, FormatSettingsUS);
      P1 := P2 + 1;
    end;
  end;
end;

procedure TPyDecisionTreeClassifier.PlotFeatureImportances(const AFeatures: array of string; const ATitle: string);
var
  LabelsJson, DataJson, ChartJson: string;
  i: Integer;
  Imp: TDoubleArray;
begin
  Imp := FeatureImportances;
  LabelsJson := '[';
  DataJson := '[';
  for i := 0 to High(AFeatures) do
  begin
    if i > 0 then
    begin
      LabelsJson := LabelsJson + ', ';
      DataJson := DataJson + ', ';
    end;
    LabelsJson := LabelsJson + '"' + AFeatures[i] + '"';
    if i <= High(Imp) then
      DataJson := DataJson + PyFloat(Imp[i])
    else
      DataJson := DataJson + '0.0';
  end;
  LabelsJson := LabelsJson + ']';
  DataJson := DataJson + ']';

  ChartJson := Format('{"labels": %s, "datasets": [{"label": "Importance", "data": %s, "backgroundColor": "#8b5cf6"}]}',
    [LabelsJson, DataJson]);
  TBlaiseOutput.ShowChart(ATitle, 'bar', ChartJson);
end;

{ Evaluation Metrics }

function PyAccuracyScore(const YTrue, YPred: TPySeries): Double;
begin
  EnsurePySklearn;
  TBlaisePy.Exec('from sklearn.metrics import accuracy_score');
  Result := StrToFloatDef(
    TBlaisePy.EvalStr(
      Format('float(accuracy_score(%s, %s))',
        [YTrue.VarName, YPred.VarName])),
    0.0, FormatSettingsUS);
end;

function PyR2Score(const YTrue, YPred: TPySeries): Double;
begin
  EnsurePySklearn;
  TBlaisePy.Exec('from sklearn.metrics import r2_score');
  Result := StrToFloatDef(
    TBlaisePy.EvalStr(
      Format('float(r2_score(%s, %s))',
        [YTrue.VarName, YPred.VarName])),
    0.0, FormatSettingsUS);
end;

function PyConfusionMatrix(const YTrue, YPred: TPySeries): TPyDataFrame;
var
  NewVar, Code: string;
begin
  EnsurePySklearn;
  NewVar := NewPyVar('df_cm');
  Code :=
    'from sklearn.metrics import confusion_matrix'#10 +
    Format(
      '__classes = sorted(list(set(list(%s) + list(%s))))'#10 +
      '__cm = confusion_matrix(%s, %s, labels=__classes)'#10 +
      '__labels = [f"Pred_{c}" for c in __classes]'#10 +
      '__idx = [f"True_{c}" for c in __classes]'#10 +
      '__df_cm = pd.DataFrame(__cm, columns=__labels)'#10 +
      '__df_cm.insert(0, "Actual / True", __idx)'#10 +
      '%s = __df_cm',
      [YTrue.VarName, YPred.VarName, YTrue.VarName, YPred.VarName, NewVar]);
  TBlaisePy.Exec(Code);
  Result := TPyDataFrame.Create(NewVar);
end;



initialization
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  FormatSettingsUS := DefaultFormatSettings;
  FormatSettingsUS.DecimalSeparator := '.';
  FormatSettingsUS.ThousandSeparator := ',';

end.
