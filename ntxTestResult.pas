unit ntxTestResult;

interface

uses
  // DELPHI VCL
  System.Classes,
  // NTX
  ntxConst, ntxTestUnit;

type
  // forward declarations
  TntxTestResults = class;
  // class declarations
  TntxTestResult = class(TObject)
  private
    m_list: TntxTestResults;  // ref
    m_report: string;
    m_test: TntxTest;         // has
    function GetReport: string;
  protected
  public
    constructor Create(AList: TntxTestResults; const ATitle: string);
    destructor Destroy; override;
    property Test: TntxTest read m_test;
    property Report: string read GetReport;
  end;
  TntxTestResults = class(TList) // enthält TntxTestResult
  private
    m_class: TntxTestClass;
    m_options: TntxTestOptions;
    procedure FreeItems;
    function GetResults(idx: integer): TntxTestResult;
    function GetTests(idx: integer): TntxTest;
    function GetFailedCount: integer;
  protected
    property TestOptions: TntxTestOptions read m_options;
  public
    constructor Create(AOptions: TntxTestOptions; ATestClass: TntxTestClass=nil);
    destructor Destroy; override;
    function NewTest(const ATitle: string): TntxTest;
    function AllPassed: Boolean;
    function GetReport: string;
    property FailedCount: integer read GetFailedCount;
    property Results[idx: integer]: TntxTestResult read GetResults; default;
    property Tests[idx: integer]: TntxTest read GetTests;
  end;

implementation

uses
  // DELPHI VCL
  System.SysUtils,
  // NTX
  ntxLog;

{ TntxTestResult }

constructor TntxTestResult.Create(AList: TntxTestResults; const ATitle: string);
begin
  inherited Create;
  m_list:=AList;
  m_report:='';
  m_test:=m_list.m_class.Create(ATitle, m_list.TestOptions);
end;

destructor TntxTestResult.Destroy;
begin
  FreeAndNil(m_test);
  inherited Destroy;
end;

function TntxTestResult.GetReport: string;
const
  NO_REPORT = '<no report>';
begin
  if ntoLog in m_list.TestOptions then
    Log('> TntxTestResult.GetReport, m_report=''%s'', m_test.m_state=%s',
      [PrtString(m_report, 64), PrtNtxTestState(m_test.State)]);
  if m_report=NO_REPORT then // BuildReport hat '' zurückgegeben
    Result:=''
  else if m_test.IsRunning then // Test läuft noch
    Result:=''
  else if m_report<>'' then  // Bericht wurde in m_report gespeichert
    Result:=m_report
  else begin // Test läuft nicht mehr, aber Bericht wurde nicht abgerufen
    Result:=m_test.BuildReport;
    if Result='' then
      m_report:=NO_REPORT
    else
      m_report:=Result;
  end;
  if ntoLog in m_list.TestOptions then
    Log('< TntxTestResult.GetReport result=''%s''', [PrtString(Result, 64)]);
end;

{ TntxTestResults }

constructor TntxTestResults.Create(AOptions: TntxTestOptions;
  ATestClass: TntxTestClass);
begin
  inherited Create;
  m_options:=AOptions;
  if Assigned(ATestClass) then
    m_class:=ATestClass
  else
    m_class:=TntxTest;
  Log('Create TntxTestResults(%s, %s)', [PrtNtxTestOptions(AOptions),
    PrtClass(m_class)]);
end;

destructor TntxTestResults.Destroy;
begin
  FreeItems;
  inherited Destroy;
end;

procedure TntxTestResults.FreeItems;
var
  i: integer;
  item: TObject;
begin
  if ntoLog in TestOptions then
    Log('> TntxTestResults.FreeItems', []);
  for i:=0 to Count-1 do
  begin
    item:=Items[i];
    item.Free;
    Items[i]:=nil;
  end;
  if ntoLog in TestOptions then
    Log('< TntxTestResults.FreeItems', []);
end;

function TntxTestResults.GetResults(idx: integer): TntxTestResult;
begin
  Result:=TntxTestResult(Items[idx]);
end;

function TntxTestResults.GetTests(idx: integer): TntxTest;
var
  tr: TntxTestResult;
begin
  tr:=GetResults(idx);
  if tr=nil then
    Result:=nil
  else
    Result:=tr.Test;
end;

function TntxTestResults.GetFailedCount: integer;
var
  i: integer;
begin
  if ntoLog in TestOptions then
    Log('> TntxTestResults.GetFailedCount', []);
  Result:=0;
  for i:=0 to Count-1 do
  begin
    if Tests[i].GetFailureCount<>0 then
      Inc(Result);
  end;
  if ntoLog in TestOptions then
    Log('< TntxTestResults.GetFailedCount result=%d', [Result]);
end;

function TntxTestResults.AllPassed: Boolean;
var
  i: integer;
begin
  if ntoLog in TestOptions then
    Log('> TntxTestResults.AllPassed', []);
  Result:=true;
  for i:=0 to Count-1 do
    if not Tests[i].IsPassed then
    begin
      Result:=false;
      Break;
    end;
  if ntoLog in TestOptions then
    Log('< TntxTestResults.AllPassed result=%s', [BoolVal(Result)]);
end;

function TntxTestResults.NewTest(const ATitle: string): TntxTest;
var
  tr: TntxTestResult;
begin
  if ntoLog in TestOptions then
    Log('> TntxTestResults.NewTest(ATitle=''%s'')', [ATitle]);
  tr:=TntxTestResult.Create(Self, ATitle);
  Add(tr);
  Result:=tr.Test;
  if ntoLog in TestOptions then
    Log('< TntxTestResults.NewTest result=%p(%s)',
      [Pointer(Result), PrtObject(Result)]);
end;

function TntxTestResults.GetReport: string;
var
  tr: TntxTestResult;
  i: integer;
  sl: TStringList;
  s: string;
begin
  if ntoLog in TestOptions then
    Log('> TntxTestResults.GetReport, FailureOnly=%s, Count=%d',
      [BoolVal(ntoFailureOnly in TestOptions), Count]);
  sl:=nil;
  try
    sl:=TStringList.Create;
    for i:=0 to Count-1 do
    begin
      tr:=Results[i];
      if ntoLog in TestOptions then
        Log('  TntxTestResults.GetReport: Results[%d]=%p, IsPassed=%s',
          [i, Pointer(tr), BoolVal(tr.Test.IsPassed)]);
      if (ntoFailureOnly in TestOptions) and tr.Test.IsPassed then
        Continue;
      s:=tr.Report;
      if ntoLog in TestOptions then
        Log('  TntxTestResults.GetReport: Results[%d].Report=[%s]',
          [i, s]);
      if s<>'' then
        sl.Add(s);
    end;
    Result:=sl.Text;
  finally
    sl.Free;
  end;
  if ntoLog in TestOptions then
    Log('< TntxTestResults.GetReport result=''%s''', [PrtString(Result, 64)]);
end;

end.
