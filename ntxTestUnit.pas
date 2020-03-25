unit ntxTestUnit;

interface

uses
  System.Classes, System.Variants, System.JSON, Data.DB,
  ntxConst, ntxLog, ntxTestReport;

type
  TntxTest = class;
  TntxTestJSON = class;
  TntxTestList = class(TList)
  private
    m_options: TntxTestOptions;
    function GetItems(i: integer): TntxTest;
    procedure BuildReportI(AReport: TntxReport; ALevel: Integer);
  protected
  public
    constructor Create(AOptions: TntxTestOptions);
    destructor Destroy; override;
    procedure Clear; override;
    property Items[i: integer]: TntxTest read GetItems; default;
    function GetFailureCount: integer;
    function GetCancelledCount: integer;
    function GetTotalCount: integer;
  end;
  TntxThrowsFunction = reference to function(t: TntxTest): Boolean;
  TntxCallFunction = reference to function(t: TntxTest): Boolean;
  TntxTestURL = class(TObject)
  private
    m_owner: TntxTest;
    m_input: string;
    m_protocol, m_host, m_path: string;
    m_port: integer;
    m_params: TStrings;
    constructor Create(AOwner: TntxTest);
    function Parse(const AURL: string): Boolean;
  protected
  public
    destructor Destroy; override;
    function Protocol(const AExpectedProtocol: string): TntxTestURL;
    function Host(const AExpectedHost: string): TntxTestURL;
    function Port(const AExpectedPort: integer): TntxTestURL;
    function HasParam(const AParam: string): TntxTestURL; overload;
    function HasParam(const AParam, AExpectedValue: string): TntxTestURL; overload;
    function HasNoParam(const AParam: string): TntxTestURL;
    function Done: TntxTest;
  end;
  TntxJSONForItemFunction = reference to function(t: TntxTestJSON): Boolean;
  {TntxJSONCallFunction = reference to function(t: TntxTestJSON): Boolean;
  TntxJSONForAllFunction = reference to function(AIndex: integer;
    t: TntxTestJSON): Boolean;}
  TntxTestJSON = class(TObject)
  private
    m_owner: TntxTest;
    m_superj: TntxTestJSON;
    m_name: string;
    m_data: TJSONValue;   // entweder Object oder Array
    m_array: Boolean;     // TRUE: in m_data ist ein Array
    function _jn(const AName: string=''): string;
    constructor Create(AOwner: TntxTest); overload;
    constructor Create(AOwner: TntxTestJSON; const AName: string); overload;
    constructor Create(AOwner: TntxTestJSON; AIndex: integer); overload;
    function Parse(const AJSON: string): Boolean;
    procedure CheckValues_Eq(AJValue: TJSONValue; const AValue: Variant;
      const AName, ACheck: string);
  protected
  public
    destructor Destroy; override;
    // die Property muss vorhanden sein
    function Eq(const AName: string; const AExpectedValue: Variant;
      const ACheck: string = ''): TntxTestJSON;
    // die Property ist optional, der Wert wird geprüft, nur wenn der Name
    // vorhanden ist
    function EqX(const AName: string; const AExpectedValue: Variant;
      const ACheck: string = ''): TntxTestJSON;
    function IsObject(const ACheck: string = ''): TntxTestJSON;
    function IsArray(const ACheck: string = ''): TntxTestJSON;
    function IsEmpty(const ACheck: string = ''): TntxTestJSON; overload;
    function NotEmpty(const ACheck: string = ''): TntxTestJSON;
    function HasValue(const AName: string;
      const ACheck: string = ''): TntxTestJSON;
    function HasNoValue(const AName: string;
      const ACheck: string = ''): TntxTestJSON;
    function HasProperties(const APropList, AOptionalList: array of string;
      AOnly: Boolean; const ACheck: string = ''): TntxTestJSON;
    function Done: TntxTest; overload;
    function Done(const AName: string): TntxTestJSON; overload;
    function CheckArray(const AName: string;
      const ACheck: string = ''): TntxTestJSON;
    function ForItem(AIndex: integer;
      AFunction: TntxJSONForItemFunction): TntxTestJSON;
    function SizeEq(AExpectedSize: integer;
      const ACheck: string = ''): TntxTestJSON;
    function CheckObject(const AName: string;
      const ACheck: string = ''): TntxTestJSON;
    {function Call(AFunction: TntxJSONCallFunction): TntxTestJSON;}
    {function NotEq(const AName: string; const AValue: Variant): TntxTestJSON;}
  end;
  TntxTest = class(TObject)
  private
    m_options: TntxTestOptions;
    m_owner: TntxTest;
    m_name: string;
    m_state: TntxTestState;
    m_text: string;
    m_subtests: TntxTestList;
    procedure SetFailure(const chk, txt: string);
    procedure BuildReportI(AReport: TntxReport; ALevel: Integer);
    function _tnm(const ACheck: string): string;
  protected
    procedure RegisterFailure(const AFmt: string;
      const AArgs: array of const; const ACheck: string = ''); overload;
    procedure RegisterFailure(const AResFmt, AExpFmt: string;
      const AArgs: array of const; const ACheck: string = ''); overload;
  public
    constructor Create(const AName: string; AOptions: TntxTestOptions;
      AOwner: TntxTest = nil);
    destructor Destroy; override;
    function BuildReport(AReportFormat: TTestReportFormat = trfPlainText): string;
    function Subtest(const AName: string): TntxTest;
    function Start: TntxTest;
    function Eq(const AResult, AExpected: Boolean;
      const ACheck: string = ''): TntxTest; overload;
    function Eq(const AResult, AExpected: string;
      const ACheck: string = ''): TntxTest; overload;
    function Eq(const AResult, AExpected: AnsiString;
      const ACheck: string = ''): TntxTest; overload;
    function Eq(const AResult, AExpected: integer;
      const ACheck: string = ''): TntxTest; overload;
    function Eq(AResult: TStrings; const AExpected: array of string;
      const ACheck: string = ''): TntxTest; overload;
    function Eq(ADataSet: TDataSet; const AFieldName, AExpected: string;
      const ACheck: string = ''): TntxTest; overload;
    function Eq(ADataSet: TDataSet; const AFieldName: string;
      AExpected: integer; const ACheck: string = ''): TntxTest; overload;
    function Eq(const AResult, AExpected: TBlobData;
      const ACheck: string = ''): TntxTest; overload;
    function VarEq(const AResult, AExpected: Variant;
      const ACheck: string = ''): TntxTest; overload;
    function LT(const AResult, AExpected: integer;
      const ACheck: string = ''): TntxTest; overload;
    function LT(const AResult, AExpected: TDateTime;
      const ACheck: string = ''): TntxTest; overload;
    function LE(const AResult, AExpected: integer;
      const ACheck: string = ''): TntxTest; overload;
    function GT(const AResult, AExpected: integer;
      const ACheck: string = ''): TntxTest; overload;
    function GE(const AResult, AExpected: integer;
      const ACheck: string = ''): TntxTest; overload;
    function NotEmpty(const AResult: string;
      const ACheck: string = ''): TntxTest; overload;
    function NotEmpty(const AResult: array of string;
      const ACheck: string = ''): TntxTest; overload;
    function IsEmpty(const AResult: string;
      const ACheck: string = ''): TntxTest; overload;
    function IsEmpty(const AResult: array of string;
      const ACheck: string = ''): TntxTest; overload;
    function IsA(AObject: TObject; AClass: TntxObjectClass;
      const ACheck: string = ''): TntxTest; overload;
    function IsA(AObject: TObject; const AClassName: string;
      const ACheck: string = ''): TntxTest; overload;
    function IsNotA(AObject: TObject; const AClassName: string;
      const ACheck: string = ''): TntxTest; overload;
    function IsA(AClass: TntxObjectClass; const AClassName: string;
      const ACheck: string = ''): TntxTest; overload;
    function IsNotA(AClass: TntxObjectClass; const AClassName: string;
      const ACheck: string = ''): TntxTest; overload;
    function IsNil(APtr: Pointer; const ACheck: string = ''): TntxTest;
    function NotNil(APtr: Pointer; const ACheck: string = ''): TntxTest;
    function IsNull(ADataSet: TDataSet; const AFieldName: string;
      const ACheck: string = ''): TntxTest;
    function NotNull(ADataSet: TDataSet; const AFieldName: string;
      const ACheck: string = ''): TntxTest;
    function ContainsAll(AResult: TStrings;       // case sensitive
      const AShouldContain: array of string;
      const ACheck: string = ''): TntxTest;
    function ContainsAny(AResult: TStrings;       // case sensitive
      const AShouldContain: array of string;
      const ACheck: string = ''): TntxTest;
    function ContainsText(const AResult: string;  // case insensitive
      const AShouldContain: array of string;
      const ACheck: string = ''): TntxTest;
    function NotEq(const AResult, AToCompare: string;
      const ACheck: string = ''): TntxTest;
    function CheckURL(const AURL: string;
      const ACheck: string = ''): TntxTestURL;
    function CheckJSON(const AJSON: string;
      const ACheck: string = ''): TntxTestJSON;
    function Call(AFunction: TntxCallFunction): TntxTest;
    function Throws(const AMessageRegex: string;
      AFunction: TntxThrowsFunction): TntxTest;
    function Cancel(const AReason: string): TntxTest;
    function Done: TntxTest;
    function GetFailureCount: integer;
    function GetCancelledCount: integer;
    function GetTotalCount: integer;
    function IsFailed: Boolean;
    function IsCancelled: Boolean;
    function IsRunning: Boolean;
    function IsPassed: Boolean;
    property Name: string read m_name;
    property State: TntxTestState read m_state;
  end;

implementation

uses
  System.SysUtils, System.RegularExpressions, System.StrUtils;

{ TntxTest }

constructor TntxTest.Create(const AName: string; AOptions: TntxTestOptions;
  AOwner: TntxTest);
begin
  inherited Create;
  m_owner:=AOwner;
  m_options:=AOptions;
  m_name:=AName;
  m_subtests:=TntxTestList.Create(AOptions);
  m_state:=ntsCreated;
  m_text:='';
end;

destructor TntxTest.Destroy;
begin
  m_subtests.Free;
  inherited Destroy;
end;

function TntxTest._tnm(const ACheck: string): string;
begin
  if ACheck='' then
    Result:=m_name
  else
    Result:=m_name+'('+ACheck+')';
end;

function TntxTest.IsFailed: Boolean;
begin
  Result:=(m_state = ntsFailed);
end;

procedure TntxTest.SetFailure(const chk, txt: string);
begin
  if chk='' then
    m_text:=txt
  else
    m_text:=chk+': '+txt;
  m_state:=ntsFailed;
  Log('Test "%s" failed: %s', [_tnm(chk), m_text]);
end;

function TntxTest.IsCancelled: Boolean;
begin
  Result:=(m_state = ntsCancelled);
end;

function TntxTest.IsRunning: Boolean;
begin
  Result:=m_state in [ntsCreated, ntsRunning];
end;

function TntxTest.IsPassed: Boolean;
begin
  Result:=(GetFailureCount=0) and (GetCancelledCount=0);
end;

function TntxTest.GetCancelledCount: integer;
begin
  if m_subtests.Count>0 then
    Result:=m_subtests.GetCancelledCount
  else if IsCancelled then
    Result:=1
  else
    Result:=0;
end;

function TntxTest.GetFailureCount: integer;
begin
  if m_subtests.Count>0 then
    Result:=m_subtests.GetFailureCount
  else if IsFailed then
    Result:=1
  else
    Result:=0;
end;

function TntxTest.GetTotalCount: integer;
begin
  Result:=m_subtests.GetTotalCount;
  if Result=0 then  // wenn keine Subtests vorhanden
    Result:=1;      // sich selbst melden
end;

function TntxTest.Subtest(const AName: string): TntxTest;
begin
  Result:=TntxTest.Create(AName, m_options, Self);
  m_subtests.Add(Result);
end;

function TntxTest.Start: TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Start', [m_name]);
  m_state:=ntsRunning;
  Result:=Self;
end;

procedure TntxTest.RegisterFailure(const AFmt: string;
  const AArgs: array of const; const ACheck: string);
begin
  Assert(Assigned(Self), 'TTest.RegisterFailure.4: Self=nil!');
  SetFailure(ACheck, Format(AFmt, AArgs));
end;

procedure TntxTest.RegisterFailure(const AResFmt, AExpFmt: string;
  const AArgs: array of const; const ACheck: string);
begin
  Assert(Assigned(Self), 'TTest.RegisterFailure.5: Self=nil!');
  SetFailure(ACheck, Format('got '+AResFmt+', expected '+AExpFmt, AArgs));
end;

function TntxTest.Eq(const AResult, AExpected: Boolean;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Eq(boolean): ''%s'', ''%s''',
      [_tnm(ACheck), BoolVal(AResult), BoolVal(AExpected)]);
  if IsRunning then
    if AResult<>AExpected then
      RegisterFailure(
        '%s', '%s', [BoolVal(AResult), BoolVal(AExpected)], ACheck);
  Result:=Self;
end;

function TntxTest.Eq(const AResult, AExpected, ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Eq(string): ''%s'', ''%s''', [_tnm(ACheck), AResult, AExpected]);
  if IsRunning then
    if AResult<>AExpected then
      RegisterFailure('''%s''', '''%s''', [AResult, AExpected], ACheck);
  Result:=Self;
end;

function TntxTest.Eq(const AResult, AExpected: AnsiString;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Eq(AnsiString): ''%s'', ''%s''', [_tnm(ACheck),
      string(AResult), string(AExpected)]);
  if IsRunning then
    if AResult<>AExpected then
      RegisterFailure('''%s''', '''%s''', [string(AResult), string(AExpected)],
        ACheck);
  Result:=Self;
end;

function TntxTest.Eq(const AResult, AExpected: integer;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Eq(integer): %d, %d', [_tnm(ACheck), AResult, AExpected]);
  if IsRunning then
    if AResult<>AExpected then
      RegisterFailure('%d', '%d', [AResult, AExpected], ACheck);
  Result:=Self;
end;

function TntxTest.Eq(AResult: TStrings; const AExpected: array of string;
  const ACheck: string): TntxTest;
var
  i: integer;
begin
  if ntoLog in m_options then
    Log('Test %s: Eq(TStrings): %s, %s',
      [_tnm(ACheck), PrtStringList(AResult), PrtStringArray(AExpected)]);
  if IsRunning then
  begin
    if AResult.Count<>Length(AExpected) then
      RegisterFailure(
        '%d item(s)', '%d', [AResult.Count, Length(AExpected)], ACheck)
    else
      for i:=0 to AResult.Count-1 do
      begin
        if AResult.Strings[i]<>AExpected[Low(AExpected)+i] then
        begin
          RegisterFailure('got %s, expected %s, first mismatch at %d',
            [PrtStringList(AResult), PrtStringArray(AExpected), i], ACheck);
          Break;
        end;
      end;
  end;
  Result:=Self;
end;

function TntxTest.Eq(ADataSet: TDataSet;
  const AFieldName, AExpected, ACheck: string): TntxTest;
var
  sCheck: string;
  fld: TField;
begin
  if ACheck<>'' then
    sCheck:=ACheck
  else
    sCheck:=AFieldName;
  fld:=ADataSet.Fields.FindField(AFieldName);
  if ntoLog in m_options then
    Log('Test %s: Eq(TField, string): %s, ''%s''',
      [_tnm(sCheck), PrtField(fld), AExpected]);
  if IsRunning then
  begin
    if fld=nil then
      RegisterFailure('field ''%s'' not found', [AFieldName], sCheck)
    else if fld.IsNull then
      RegisterFailure('NULL', '''%s''', [AExpected], sCheck)
    else if fld.AsString<>AExpected then
      RegisterFailure('%s', '''%s''', [PrtVariant(fld.AsVariant), AExpected],
        sCheck);
  end;
  Result:=Self;
end;

function TntxTest.Eq(ADataSet: TDataSet; const AFieldName: string;
  AExpected: integer; const ACheck: string): TntxTest;
var
  sCheck: string;
  iResult: integer;
  fld: TField;
begin
  if ACheck<>'' then
    sCheck:=ACheck
  else
    sCheck:=AFieldName;
  fld:=ADataSet.Fields.FindField(AFieldName);
  if ntoLog in m_options then
    Log('Test %s: Eq(TField, integer): %s, %d',
      [_tnm(sCheck), PrtField(fld), AExpected]);
  if IsRunning then
  begin
    if fld=nil then
      RegisterFailure('field ''%s'' not found', [AFieldName], sCheck)
    else if fld.IsNull then
      RegisterFailure('NULL', '%d', [AExpected], sCheck)
    else begin
      try
        iResult:=fld.AsInteger;
        if iResult<>AExpected then
          RegisterFailure('%d', '%d', [iResult, AExpected], sCheck);
      except
        RegisterFailure('can''t convert to integer: %s', [PrtVariant(fld.Value)],
          sCheck);
      end;
    end;
  end;
  Result:=Self;
end;

{ Für Blobdaten }
function TntxTest.Eq(const AResult, AExpected: TBlobData;
  const ACheck: string): TntxTest;
var
  i: integer;
begin
  if ntoLog in m_options then
    Log('Test %s: Eq(TBlobData): %s, %s',
      [_tnm(ACheck), PrtBlobData(AResult), PrtBlobData(AExpected)]);
  if IsRunning then
  begin
    if Length(AResult)<>Length(AExpected) then
      RegisterFailure(
        '%d bytes(s)', '%d', [Length(AResult), Length(AExpected)], ACheck)
    else
      for i:=0 to Length(AResult)-1 do
      begin
        if AResult[i]<>AExpected[i] then
        begin
          RegisterFailure('mismatch at position %d: got byte %s, expected %s',
            [i, PrtByte(AResult[i]), PrtByte(AExpected[i])], ACheck);
          Break;
        end;
      end;
  end;
  Result:=Self;
end;

function TntxTest.VarEq(const AResult, AExpected: Variant;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: VarEq: %s, %s',
      [_tnm(ACheck), PrtVariant(AResult), PrtVariant(AExpected)]);
  if IsRunning then
  begin
    if VarIsEmpty(AExpected) then
    begin
      if not VarIsEmpty(AResult) then
        RegisterFailure('%s', 'Unassigned', [PrtVariant(AResult)], ACheck);
    end
    else if VarIsNull(AExpected) then
    begin
      if not VarIsNull(AResult) then
        RegisterFailure('%s', 'Null', [PrtVariant(AResult)], ACheck);
    end
    else if VarToStr(AResult)<>VarToStr(AExpected) then
      RegisterFailure('%s', '%s', [PrtVariant(AResult), PrtVariant(AExpected)],
        ACheck);
  end;
  Result:=Self;
end;

{ Assert(AResult<AExpected) }
function TntxTest.LT(const AResult, AExpected: integer;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: LT(integer): %d, %d', [_tnm(ACheck), AResult, AExpected]);
  if IsRunning then
    if AResult>=AExpected then
      RegisterFailure('%d', 'less than %d', [AResult, AExpected], ACheck);
  Result:=Self;
end;

{ Assert(AResult<AExpected) }
function TntxTest.LT(const AResult, AExpected: TDateTime;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: LT(datetime): ''%s'', ''%s''',
      [_tnm(ACheck), PrtDateTime(AResult), PrtDateTime(AExpected)]);
  if IsRunning then
    if AResult>=AExpected then
      RegisterFailure('''%s''', 'less than ''%s''',
        [DateTimeToStr(AResult), DateTimeToStr(AExpected)], ACheck);
  Result:=Self;
end;

{ Assert(AResult<=AExpected) }
function TntxTest.LE(const AResult, AExpected: integer;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: LE(integer): %d, %d', [_tnm(ACheck), AResult, AExpected]);
  if IsRunning then
    if AResult>AExpected then
      RegisterFailure(
        '%d', 'less than or equal %d', [AResult, AExpected], ACheck);
  Result:=Self;
end;

{ Assert(AResult>AExpected) }
function TntxTest.GT(const AResult, AExpected: integer;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: GT(integer): %d, %d', [_tnm(ACheck), AResult, AExpected]);
  if IsRunning then
    if AResult<=AExpected then
      RegisterFailure('%d', 'greater than %d', [AResult, AExpected], ACheck);
  Result:=Self;
end;

{ Assert(AResult>=AExpected) }
function TntxTest.GE(const AResult, AExpected: integer;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: GE(integer): %d, %d', [_tnm(ACheck), AResult, AExpected]);
  if IsRunning then
    if AResult<AExpected then
      RegisterFailure(
        '%d', 'greater than or equal %d', [AResult, AExpected], ACheck);
  Result:=Self;
end;

function TntxTest.NotEmpty(const AResult, ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: NotEmpty(string): ''%s''', [_tnm(ACheck), AResult]);
  if IsRunning then
    if Length(AResult)=0 then
      RegisterFailure('''%s''', 'not empty', [AResult], ACheck);
  Result:=Self;
end;

function TntxTest.NotEmpty(const AResult: array of string;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: NotEmpty(array of string): %s',
      [_tnm(ACheck), PrtStringArray(AResult)]);
  if IsRunning then
    if Length(AResult)=0 then
      RegisterFailure('%s', 'not empty', [PrtStringArray(AResult)], ACheck);
  Result:=Self;
end;

function TntxTest.IsEmpty(const AResult, ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsEmpty(string): ''%s''', [_tnm(ACheck), AResult]);
  if IsRunning then
    if Length(AResult)<>0 then
      RegisterFailure('''%s''', 'empty string', [AResult], ACheck);
  Result:=Self;
end;

function TntxTest.IsEmpty(const AResult: array of string;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsEmpty(array of string): %s',
      [_tnm(ACheck), PrtStringArray(AResult)]);
  if IsRunning then
    if Length(AResult)<>0 then
      RegisterFailure('%s', 'empty array', [PrtStringArray(AResult)], ACheck);
  Result:=Self;
end;

function TntxTest.IsA(AObject: TObject; AClass: TntxObjectClass;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsA(object, class): %s, %s',
      [_tnm(ACheck), PrtObject(AObject), PrtClass(AClass)]);
  if Assigned(AClass) then
  begin
    if Assigned(AObject) then
    begin
      if not (AObject is AClass) then
        RegisterFailure('instance of %s', 'instance of %s',
          [AObject.ClassName, AClass.ClassName], ACheck);
    end
    else
      RegisterFailure('nil', '%s', [PrtClass(AClass)], ACheck)
  end
  else
    if Assigned(AObject) then
      RegisterFailure('%p(%s)', 'nil',
        [Pointer(AObject), AObject.ClassName], ACheck);
  Result:=Self;
end;

function TntxTest.IsA(AObject: TObject;
  const AClassName, ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsA(object, classname): %s, ''%s''',
      [_tnm(ACheck), PrtObject(AObject), AClassName]);
  if Assigned(AObject) then
  begin
    if AObject.ClassName<>AClassName then
      RegisterFailure('instance of %s', 'instance of %s',
        [AObject.ClassName, AClassName], ACheck);
  end
  else if AClassName<>'nil' then
    RegisterFailure('nil', 'instance of %s', [AClassName], ACheck);
  Result:=Self;
end;

function TntxTest.IsNotA(AObject: TObject;
  const AClassName, ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsNotA(object, classname): %s, ''%s''',
      [_tnm(ACheck), PrtObject(AObject), AClassName]);
  if Assigned(AObject) then
  begin
    if AObject.ClassName=AClassName then
      RegisterFailure('should not be an instance of %s', [AClassName], ACheck);
  end
  else if AClassName='nil' then
    RegisterFailure('nil', 'not to be nil', [AClassName], ACheck);
  Result:=Self;
end;

function TntxTest.IsA(AClass: TntxObjectClass; const AClassName: string;
  const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsA(class, name): %s, ''%s''',
      [_tnm(ACheck), PrtClass(AClass), AClassName]);
  if Assigned(AClass) then
  begin
    if AClass.ClassName<>AClassName then
      RegisterFailure('class %s', '%s', [AClass.ClassName, AClassName], ACheck);
  end
  else if AClassName<>'nil' then
    RegisterFailure('%s', '%s', ['nil', AClassName], ACheck);
  Result:=Self;
end;

function TntxTest.IsNotA(AClass: TntxObjectClass;
  const AClassName, ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsNotA(class, name): %s, ''%s''',
      [_tnm(ACheck), PrtClass(AClass), AClassName]);
  if Assigned(AClass) then
  begin
    if AClass.ClassName=AClassName then
      RegisterFailure('should not be a class %s', [AClassName], ACheck);
  end
  else
    if AClassName='nil' then
      RegisterFailure('nil', 'not to be nil', [], ACheck);
  Result:=Self;
end;

function TntxTest.IsNil(APtr: Pointer; const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: IsNil(ptr): %p', [_tnm(ACheck), APtr]);
  if Assigned(APtr) then
    RegisterFailure('$%p', 'nil', [APtr], ACheck);
  Result:=Self;
end;

function TntxTest.NotNil(APtr: Pointer; const ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: NotNil(ptr): %p', [_tnm(ACheck), APtr]);
  if not Assigned(APtr) then
    RegisterFailure('nil', 'not nil', [], ACheck);
  Result:=Self;
end;

function TntxTest.IsNull(ADataSet: TDataSet;
  const AFieldName, ACheck: string): TntxTest;
var
  sCheck: string;
  fld: TField;
begin
  if ACheck<>'' then
    sCheck:=ACheck
  else
    sCheck:=AFieldName;
  fld:=ADataSet.Fields.FindField(AFieldName);
  if ntoLog in m_options then
    Log('Test %s: IsNull(TField): %s', [_tnm(sCheck), PrtField(fld)]);
  if IsRunning then
  begin
    if fld=nil then
      RegisterFailure('field ''%s'' not found', [AFieldName], sCheck)
    else if not fld.IsNull then
      RegisterFailure('%s', 'to be NULL', [PrtVariant(fld.AsVariant)], sCheck);
  end;
  Result:=Self;
end;

function TntxTest.NotNull(ADataSet: TDataSet;
  const AFieldName, ACheck: string): TntxTest;
var
  sCheck: string;
  fld: TField;
begin
  if ACheck<>'' then
    sCheck:=ACheck
  else
    sCheck:=AFieldName;
  fld:=ADataSet.Fields.FindField(AFieldName);
  if ntoLog in m_options then
    Log('Test %s: Eq(TField): %s', [_tnm(sCheck), PrtField(fld)]);
  if IsRunning then
  begin
    if fld=nil then
      RegisterFailure('field ''%s'' not found', [AFieldName], sCheck)
    else if fld.IsNull then
      RegisterFailure('should not be NULL', [], sCheck);
  end;
  Result:=Self;
end;

function TntxTest.ContainsAll(AResult: TStrings;
  const AShouldContain: array of string; const ACheck: string): TntxTest;
var
  i, idx: integer;
begin
  if ntoLog in m_options then
    Log('Test %s: ContainsAll(%s, %s)',
      [_tnm(ACheck), PrtStringList(AResult), PrtStringArray(AShouldContain)]);
  for i:=Low(AShouldContain) to High(AShouldContain) do
  begin
    idx:=AResult.IndexOf(AShouldContain[i]);
    if (idx=-1) or (AResult[idx]<>AShouldContain[i]) then
    begin
      RegisterFailure('%s should contain all of %s, but does not '+
        'contain ''%s''', [PrtStringList(AResult),
        PrtStringArray(AShouldContain), AShouldContain[i]], ACheck);
      Break;
    end;
  end;
  Result:=Self;
end;

function TntxTest.ContainsAny(AResult: TStrings;
  const AShouldContain: array of string; const ACheck: string): TntxTest;
var
  i, idx: integer;
  bFound: Boolean;
begin
  if ntoLog in m_options then
    Log('Test %s: ContainsAll(%s, %s)',
      [_tnm(ACheck), PrtStringList(AResult), PrtStringArray(AShouldContain)]);
  bFound:=false;
  for i:=Low(AShouldContain) to High(AShouldContain) do
  begin
    idx:=AResult.IndexOf(AShouldContain[i]);
    if (idx<>-1) and (AResult[idx]=AShouldContain[i]) then
    begin
      bFound:=true;
      Break;
    end;
  end;
  if not bFound then
    RegisterFailure('(%s) should contain any of [%s]', [PrtStringList(AResult),
      PrtStringArray(AShouldContain)], ACheck);
  Result:=Self;
end;

function TntxTest.ContainsText(const AResult: string;
  const AShouldContain: array of string; const ACheck: string): TntxTest;
var
  bFound: Boolean;
  sNotFound: string;
  i: integer;
begin
  if ntoLog in m_options then
    Log('Test %s: ContainsText(''%s'', %s)',
      [_tnm(ACheck), AResult, PrtStringArray(AShouldContain)]);
  bFound:=true;
  sNotFound:='';
  for i:=Low(AShouldContain) to High(AShouldContain) do
    if not AnsiContainsText(AResult, AShouldContain[i]) then
    begin
      sNotFound:=AShouldContain[i];
      bFound:=false;
      Break;
    end;
  if not bFound then
    RegisterFailure('''%s'' should contain ''%s''', [AResult, sNotFound], ACheck);
  Result:=Self;
end;

function TntxTest.NotEq(const AResult, AToCompare, ACheck: string): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: NotEq(''%s'', ''%s'')', [_tnm(ACheck), AResult, AToCompare]);
  if IsRunning then
    if AResult=AToCompare then
      RegisterFailure('''%s'' expected not to be equal', [AResult, AToCompare],
        ACheck);
  Result:=Self;
end;

function TntxTest.CheckURL(const AURL, ACheck: string): TntxTestURL;
begin
  if ntoLog in m_options then
    Log('Test %s: Check URL %s', [_tnm(ACheck), AURL]);
  Result:=TntxTestURL.Create(Self);
  if IsRunning then
    Result.Parse(AURL);
end;

function TntxTest.CheckJSON(const AJSON, ACheck: string): TntxTestJSON;
begin
  if ntoLog in m_options then
    Log('Test %s: Check JSON %s', [_tnm(ACheck), AJSON]);
    Result:=TntxTestJSON.Create(Self);
    if IsRunning then
      Result.Parse(AJSON);
end;

function TntxTest.Call(AFunction: TntxCallFunction): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Call(%p)', [m_name, @AFunction]);
  if IsRunning then
  try
    AFunction(Self);
  except
    on e: Exception do
    begin
      if ntoLog in m_options then
        Log('Test %s: unexpected exception %s: "%s"',
          [m_name, e.ClassName, e.Message]);
      RegisterFailure('exception %s, but no exception expected',
        [e.ClassName]);
    end;
  end;
  Result:=Self;
end;

function TntxTest.Throws(const AMessageRegex: string;
  AFunction: TntxThrowsFunction): TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Throws(''%s'', %p)', [m_name, AMessageRegex, @AFunction]);
  if IsRunning then
  try
    AFunction(Self);
    // Wenn eine Exception geworfen wurde, kommt die Steuerung hierher nicht
    RegisterFailure('Exception with message like ''%s'' expected',
      [AMessageRegex]);
  except
    on e: Exception do
    begin
      if ntoLog in m_options then
        Log('Test %s: Throws() caught an exception: ''%s''', [m_name, e.Message]);
      if not TRegEx.IsMatch(e.Message, AMessageRegex) then
        RegisterFailure('exception message ''%s''', '''%s''',
          [e.Message, AMessageRegex]);
    end;
  end;
  Result:=Self;
end;

function TntxTest.Cancel(const AReason: string): TntxTest;
begin
  m_state:=ntsCancelled;
  m_text:=AReason;
  Result:=m_owner;
end;

function TntxTest.Done: TntxTest;
begin
  if ntoLog in m_options then
    Log('Test %s: Done', [m_name]);
  if IsRunning then
    m_state:=ntsCompleted;
  Result:=m_owner;
end;

procedure TntxTest.BuildReportI(AReport: TntxReport; ALevel: Integer);
var
  bReportSuccess: Boolean;
begin
  if ntoLog in m_options then
    Log('> TntxTest.BuildReportI(AReport=%p, ALevel=%d), State=%s',
      [Pointer(AReport), ALevel, PrtNtxTestState(m_state)]);
  bReportSuccess:=not (ntoFailureOnly in m_options);
  if m_subtests.Count=0 then
  begin
    AReport.TestResult(Name, m_state, m_text, bReportSuccess);
  end
  else begin
    if bReportSuccess
        or (m_subtests.GetFailureCount+m_subtests.GetCancelledCount>0) then
      AReport.Open(Name);
    m_subtests.BuildReportI(AReport, ALevel);
  end;
  if ntoLog in m_options then
    Log('< TntxTest.BuildReportI', []);
end;

function TntxTest.BuildReport(AReportFormat: TTestReportFormat): string;
var
  trep: TntxReport;
begin
  if ntoLog in m_options then
    Log('> TntxTest.BuildReport(AReportFormat=%s)',
      [PrtTestReportFormat(AReportFormat)]);
  trep:=nil;
  try
    trep:=TntxReport.CreateReport(AReportFormat);
    if Assigned(trep) then
    begin
      trep.Open(Name);
      if m_subtests.Count=0 then
        BuildReportI(trep, 0)
      else
        m_subtests.BuildReportI(trep, 0);
      trep.Close(GetFailureCount, GetCancelledCount, GetTotalCount);
      Result:=trep.Text;
    end
    else
      Result:=TntxReport.NoReport(AReportFormat);
  finally
    trep.Free;
  end;
  if ntoLog in m_options then
    Log('< TntxTest.BuildReport result=''%s''', [PrtString(Result, 64)]);
end;

{ TntxTestList }

constructor TntxTestList.Create(AOptions: TntxTestOptions);
begin
  inherited Create;
  m_options:=AOptions;
end;

destructor TntxTestList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TntxTestList.Clear;
var
  i: integer;
begin
  for i:=0 to Count-1 do
    TObject(inherited Items[i]).Free;
  inherited Clear;
end;

function TntxTestList.GetCancelledCount: integer;
var
  i: integer;
begin
  Result:=0;
  for i:=0 to Count-1 do
    Result:=Result+Items[i].GetCancelledCount;
end;

function TntxTestList.GetFailureCount: integer;
var
  i: integer;
begin
  Result:=0;
  for i:=0 to Count-1 do
    Result:=Result+Items[i].GetFailureCount;
end;

function TntxTestList.GetItems(i: integer): TntxTest;
begin
  Result:=TntxTest(inherited Items[i]);
end;

function TntxTestList.GetTotalCount: integer;
var
  i: integer;
begin
  Result:=0;
  for i:=0 to Count-1 do
    Result:=Result+Items[i].GetTotalCount;
end;

procedure TntxTestList.BuildReportI(AReport: TntxReport; ALevel: Integer);
var
  i: integer;
begin
  if ntoLog in m_options then
    Log('> TntxTestList.BuildReportI(AReport=%p, ALevel=%d)',
      [Pointer(AReport), ALevel]);
  AReport.OpenLevel;
  for i:=0 to Count-1 do
    Items[i].BuildReportI(AReport, ALevel+1);
  AReport.CloseLevel;
  if ntoLog in m_options then
    Log('< TntxTestList.BuildReportI', []);
end;

{ TntxTestURL }

constructor TntxTestURL.Create(AOwner: TntxTest);
begin
  inherited Create;
  m_owner:=AOwner;
  m_input:='';
  m_protocol:='';
  m_host:='';
  m_path:='';
  m_port:=-1;
  m_params:=TStringList.Create;
end;

destructor TntxTestURL.Destroy;
begin
  FreeAndNil(m_params);
  inherited Destroy;
end;

{*******************************************************************************
  TntxTestURL.Parse - 25.06.19 14:45
  by:  JL

<protocol> '://' <host> [':' <port>] ['/' <path> ] ['?' <parameters>]
********************************************************************************}
function TntxTestURL.Parse(const AURL: string): Boolean;
var
  ipos: integer;
  tmpurl: string;
  params, s: string;
begin
  Assert(m_owner<>nil, 'TntxTestURL.Parse: owner not set!');
  if ntoLog in m_owner.m_options then
    Log('> TntxTestURL.Parse(AURL=''%s'')', [AURL]);
  m_input:=AURL;
  tmpurl:=AURL;
  ipos:=Pos('://', tmpurl);
  if ipos=0 then
    m_owner.RegisterFailure('invalid URL: %s', [AURL])
  else begin
    m_protocol:=Copy(tmpurl, 1, ipos-1);
    Delete(tmpurl, 1, ipos+2);
    ipos:=Pos('?', tmpurl);
    if ipos>0 then
    begin
      params:=Copy(tmpurl, ipos+1, Length(tmpurl));
      Delete(tmpurl, ipos, Length(tmpurl)-ipos+1);
    end
    else
      params:='';
    // tmpurl enthält jetzt die URL ohne Protokoll und Parameter:
    // host [':'] port '/' path
    ipos:=Pos('/', tmpurl);
    if ipos=0 then
      m_path:=''
    else begin
      m_path:=Copy(tmpurl, ipos, Length(tmpurl));
      Delete(tmpurl, ipos, Length(tmpurl)-ipos+1);
    end;
    // tmpurl enthält jetzt den Hostnamen und (optional) den Port
    ipos:=Pos(':', tmpurl);
    if ipos=0 then
      m_host:=tmpurl
    else begin
      m_host:=Copy(tmpurl, 1, ipos-1);
      m_port:=StrToIntDef(Copy(tmpurl, ipos+1, Length(tmpurl)), -1);
      if m_port=-1 then
        m_owner.RegisterFailure('invalid port in URL %s', [AURL]);
    end;
    if not m_owner.IsFailed then
    begin
      // parse parameters
      ipos:=Pos('&', params);
      while ipos>0 do
      begin
        s:=Trim(Copy(params, 1, ipos-1));
        if s<>'' then
          m_params.Add(s);
        Delete(params, 1, ipos);
        ipos:=Pos('&', params);
      end;
      if params<>'' then
        m_params.Add(params);
    end;
  end;
  Result:=not m_owner.IsFailed;
  if ntoLog in m_owner.m_options then
    Log('< TntxTestURL.Parse result=%s', [BoolVal(Result)]);
end; {TntxTestURL.Parse}

function TntxTestURL.Protocol(const AExpectedProtocol: string): TntxTestURL;
begin
  Assert(m_owner<>nil, 'TntxTestURL.Protocol: owner not set!');
  if m_owner.IsRunning then
    if m_protocol<>AExpectedProtocol then
      m_owner.RegisterFailure('%s: protocol ''%s'' set, ''%s'' expected',
        [m_input, m_protocol, AExpectedProtocol]);
  Result:=Self;
end;

function TntxTestURL.Host(const AExpectedHost: string): TntxTestURL;
begin
  Assert(m_owner<>nil, 'TntxTestURL.Host: owner not set!');
  if m_owner.IsRunning then
    if m_host<>AExpectedHost then
      m_owner.RegisterFailure('%s: host ''%s'' set, ''%s'' expected',
        [m_input, m_host, AExpectedHost]);
  Result:=Self;
end;

function TntxTestURL.Port(const AExpectedPort: integer): TntxTestURL;
var
  p, xp: string;
begin
  Assert(m_owner<>nil, 'TntxTestURL.Port: owner not set!');
  if m_owner.IsRunning then
    if m_port<>AExpectedPort then
    begin
      if m_port=-1 then
        p:='no port'
      else
        p:=IntToStr(m_port);
      if AExpectedPort=-1 then
        xp:='no port'
      else
        xp:=IntToStr(AExpectedPort);
      m_owner.RegisterFailure('%s: port %s set, %s expected',
        [m_input, p, xp]);
    end;
  Result:=Self;
end;

function TntxTestURL.HasParam(const AParam: string): TntxTestURL;
begin
  Assert(m_owner<>nil, 'TntxTestURL.HasParam: owner not set!');
  if m_owner.IsRunning then
    if (m_params.IndexOfName(AParam)=-1) and (m_params.IndexOf(AParam)=-1) then
      m_owner.RegisterFailure('%s does not contain parameter ''%s''',
        [m_input, AParam]);
  Result:=Self;
end;

function TntxTestURL.HasParam(const AParam, AExpectedValue: string): TntxTestURL;
var
  idx: integer;
  v: string;
begin
  Assert(m_owner<>nil, 'TntxTestURL.HasParam: owner not set!');
  if m_owner.IsRunning then
  begin
    idx:=m_params.IndexOfName(AParam);
    if idx<>-1 then
      v:=m_params.Values[AParam]
    else begin
      idx:=m_params.IndexOf(AParam);
      v:='';
    end;
    if idx=-1 then
      m_owner.RegisterFailure('%s does not contain parameter ''%s''',
        [m_input, AParam])
    else if v<>AExpectedValue then
      m_owner.RegisterFailure('%s: parameter ''%s'' has value ''%s'', '+
        'expected ''%s''', [m_input, AParam, v, AExpectedValue]);
  end;
  Result:=Self;
end;

function TntxTestURL.HasNoParam(const AParam: string): TntxTestURL;
begin
  Assert(m_owner<>nil, 'TntxTestURL.HasParam: owner not set!');
  if m_owner.IsRunning then
    if (m_params.IndexOfName(AParam)<>-1) or (m_params.IndexOf(AParam)<>-1) then
      m_owner.RegisterFailure('%s should not contain parameter ''%s''',
        [m_input, AParam]);
  Result:=Self;
end;

function TntxTestURL.Done: TntxTest;
begin
  Result:=m_owner;
  Free;
end;

{TntxTestJSON}

constructor TntxTestJSON.Create(AOwner: TntxTest);
begin
  inherited Create;
  m_owner:=AOwner;
  m_superj:=nil;
  m_data:=nil;
  m_array:=false;
  m_name:='';
end;

constructor TntxTestJSON.Create(AOwner: TntxTestJSON; const AName: string);
begin
  inherited Create;
  m_owner:=AOwner.m_owner;
  m_superj:=AOwner;
  m_data:=nil;
  m_array:=false;
  m_name:=AName;
end;

constructor TntxTestJSON.Create(AOwner: TntxTestJSON; AIndex: integer);
begin
  inherited Create;
  m_owner:=AOwner.m_owner;
  m_superj:=AOwner;
  m_data:=nil;
  m_array:=false;
  m_name:='['+IntToStr(AIndex)+']';
end;

destructor TntxTestJSON.Destroy;
begin
  if not Assigned(m_superj) then  // top level
    FreeAndNil(m_data);
  inherited Destroy;
end;

function TntxTestJSON._jn(const AName: string): string;
begin
  if Assigned(m_superj) then
  begin
    Result:=m_superj._jn;
    if m_name<>'' then
    begin
      if (m_name[1]='[') or (Result='') then
        Result:=Result+m_name
      else
        Result:=Result+'.'+m_name;
    end;
    if Result='' then
    begin
      if AName<>'' then
        Result:=AName
      else
        Result:='JSON';
    end
    else if AName<>'' then
      Result:=Result+'.'+AName;
  end
  else begin
    Result:=m_name;
  end;
end;

procedure TntxTestJSON.CheckValues_Eq(AJValue: TJSONValue;
  const AValue: Variant; const AName, ACheck: string);
const
  _boolval: array[Boolean] of string = ('false', 'true');
var
  b, bEqual: Boolean;
  sReceived, sExpected: string;
begin
  bEqual:=true;
  case VarType(AValue) of
  varBoolean:
    if AJValue is TJSONBool then
    begin
      sReceived:=_boolval[TJSONBool(AJValue).AsBoolean];
      b:=AValue;
      sExpected:=_boolval[b];
      bEqual:=sReceived=sExpected;
    end
    else
      m_owner.RegisterFailure('%s: wrong type, boolean expected',
        [AName], ACheck);
  varByte,
  varSmallInt,
  varShortInt,
  varWord,
  varLongWord,
  varInteger,
  varInt64:
    if AJValue is TJSONNumber then
    begin
      sReceived:=TJSONNumber(AJValue).Value;
      sExpected:=VarToStr(AValue);
      bEqual:=sReceived=sExpected;
    end
    else
      m_owner.RegisterFailure('%s: wrong type, number expected',
        [AName], ACheck);
  varSingle,
  varDouble:
    if AJValue is TJSONNumber then
    begin
      sReceived:=TJSONNumber(AJValue).Value;
      sExpected:=VarToStr(AValue);
      bEqual:=TJSONNumber(AJValue).AsDouble=AValue;
    end
    else
      m_owner.RegisterFailure('%s: wrong type, number expected',
        [AName], ACheck);
  varString,
  varStrArg,
  varUStrArg,
  varUString:
    if AJValue is TJSONString then
    begin
      bEqual:=TJSONString(AJValue).Value=VarToStr(AValue);
      sReceived:='"'+TJSONString(AJValue).Value+'"';
      sExpected:='"'+VarToStr(AValue)+'"';
    end;
  else
    begin
      if ntoLog in m_owner.m_options then
        Log('  TntxTestJSON.CheckValues_Eq: VarType %s(%d) not supported, compare '+
          'as strings', [VarTypeAsText(VarType(AValue)), VarType(AValue)]);
      sReceived:=AJValue.Value;
      sExpected:=VarToStr(AValue);
      bEqual:=sReceived=sExpected;
    end;
  end;
  if m_owner.IsRunning and (not bEqual) then
    m_owner.RegisterFailure('%s', '%s', [sReceived, sExpected],
      Trim(AName+' '+ACheck));
end;

function TntxTestJSON.Eq(const AName: string; const AExpectedValue: Variant;
  const ACheck: string): TntxTestJSON;
var
  jv: TJSONValue;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.Eq: owner not set!');
  if m_owner.IsRunning then
    Assert(m_data<>nil, 'TntxTestJSON.Eq: data not set! Call Parse() first');
  if m_owner.IsRunning then
  begin
    if not (m_data is TJSONObject) then
      m_owner.RegisterFailure('a JSON object expected', [], ACheck)
    else begin
      jv:=TJSONObject(m_data).Values[AName];
      if jv=nil then
        m_owner.RegisterFailure('JSON has no value named ''%s''', [AName], ACheck)
      else
        CheckValues_Eq(jv, AExpectedValue, _jn(AName), ACheck);
    end;
  end;
  Result:=Self;
end;

function TntxTestJSON.EqX(const AName: string; const AExpectedValue: Variant;
  const ACheck: string): TntxTestJSON;
var
  jv: TJSONValue;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.EqX: owner not set!');
  if m_owner.IsRunning then
    Assert(m_data<>nil, 'TntxTestJSON.EqX: data not set! Call Parse() first');
  if m_owner.IsRunning then
  begin
    if not (m_data is TJSONObject) then
      m_owner.RegisterFailure('a JSON object expected', [], ACheck)
    else begin
      jv:=TJSONObject(m_data).Values[AName];
      if jv<>nil then
        CheckValues_Eq(jv, AExpectedValue, _jn(AName), ACheck);
    end;
  end;
  Result:=Self;
end;

function TntxTestJSON.IsObject(const ACheck: string): TntxTestJSON;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.IsObject: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.IsObject: data not set! Call Parse() first');
    if not (m_data is TJSONObject) then
      m_owner.RegisterFailure('%s expected to be an object', [_jn], ACheck);
  end;
  Result:=Self;
end;

function TntxTestJSON.IsArray(const ACheck: string): TntxTestJSON;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.IsObject: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.IsObject: data not set! Call Parse() first');
    if not (m_data is TJSONArray) then
      m_owner.RegisterFailure('%s expected to be an array', [_jn], ACheck);
  end;
  Result:=Self;
end; {TntxTestJSON.IsArray}

const
  _what: array[Boolean] of string = ('object', 'array');

function TntxTestJSON.IsEmpty(const ACheck: string): TntxTestJSON;
var
  cnt: integer;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.IsEmpty: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.IsEmpty: data not set! Call Parse() first');
    if m_array then
      cnt:=(m_data as TJSONArray).Count
    else
      cnt:=(m_data as TJSONObject).Count;
    if cnt<>0 then
      m_owner.RegisterFailure('%s%s expected to be empty', [_what[m_array], _jn],
        ACheck);
  end;
  Result:=Self;
end;

function TntxTestJSON.NotEmpty(const ACheck: string): TntxTestJSON;
var
  cnt: integer;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.NotEmpty: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.NotEmpty: data not set! Call Parse() first');
    if m_array then
      cnt:=(m_data as TJSONArray).Count
    else
      cnt:=(m_data as TJSONObject).Count;
    if cnt=0 then
      m_owner.RegisterFailure('%s%s expected not to be empty',
        [_what[m_array], _jn], ACheck);
  end;
  Result:=Self;
end;

function TntxTestJSON.HasValue(const AName, ACheck: string): TntxTestJSON;
var
  jv: TJSONValue;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.HasValue: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.HasValue: data not set! Call Parse() first');
    if not (m_data is TJSONObject) then
      m_owner.RegisterFailure('a JSON object expected', [], ACheck)
    else begin
      jv:=TJSONObject(m_data).Values[AName];
      if jv=nil then
        m_owner.RegisterFailure('a value named ''%s'' expected in %s',
          [AName, _jn], ACheck);
    end;
  end;
  Result:=Self;
end;

function TntxTestJSON.HasNoValue(const AName, ACheck: string): TntxTestJSON;
var
  jv: TJSONValue;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.HasValue: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.HasValue: data not set! Call Parse() first');
    if not (m_data is TJSONObject) then
      m_owner.RegisterFailure('a JSON object expected', [], ACheck)
    else begin
      jv:=TJSONObject(m_data).Values[AName];
      if jv<>nil then
        m_owner.RegisterFailure('a value named ''%s'' not expected in %s',
          [AName, _jn], ACheck);
    end;
  end;
  Result:=Self;
end;

function TntxTestJSON.HasProperties(const APropList, AOptionalList: array of string;
  AOnly: Boolean; const ACheck: string): TntxTestJSON;
var
  i: integer;
  jo: TJSONObject;
  jv: TJSONValue;
  jp: TJSONPair;
  s, sProp: string;
  bContinue: Boolean;

  function CheckPropList(s: string; const text: string): Boolean;
  var
    s1: string;
  begin
    Result:=true;
    if s<>'' then
    begin
      SetLength(s, Length(s)-2);
      if Pos(',', s)>0 then
        s1:='properties'
      else
        s1:='property';
      m_owner.RegisterFailure('%s %s %s', [s1, s, text], ACheck);
      Result:=false;
    end;
  end;

begin
  Assert(m_owner<>nil, 'TntxTestJSON.HasValue: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.HasValue: data not set! Call Parse() first');
    if not (m_data is TJSONObject) then
      m_owner.RegisterFailure('a JSON object expected', [], ACheck)
    else begin
      jo:=TJSONObject(m_data);
      s:='';
      // positive Prüfung: alle Properties aus APropList sollen da sein
      for i:=Low(APropList) to High(APropList) do
      begin
        sProp:=APropList[i];
        jv:=jo.Values[sProp];
        if jv=nil then
          s:=s+sProp+', ';
      end;
      bContinue:=CheckPropList(s, 'not found');
      // negative Prüfung: keine Properties außer APropList sollen da sein
      if bContinue and AOnly then
      begin
        s:='';
        for i:=0 to jo.Count-1 do
        begin
          jp:=jo.Pairs[i];
          sProp:=jp.JsonString.Value;
          if      (IndexStr(sProp, APropList)=-1)
              and (IndexStr(sProp, AOptionalList)=-1) then
            s:=s+sProp+', ';
        end;
        CheckPropList(s, 'not expected');
      end;
    end;
  end;
  Result:=Self;
end;

function TntxTestJSON.CheckArray(const AName, ACheck: string): TntxTestJSON;
var
  jv: TJSONValue;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.CheckArray: owner not set!');
  Assert(m_data<>nil, 'TntxTestJSON.CheckArray: data not set! Call Parse() first');
  Result:=TntxTestJSON.Create(Self, AName);
  if m_owner.IsRunning then // wenn der Test noch nicht beendet
  begin
    // den Wert unter dem Namen AName finden...
    jv:=(m_data as TJSONObject).Values[AName];
    if jv=nil then
      m_owner.RegisterFailure('JSON has no value named ''%s''', [AName], ACheck)
    // und prüfen, ob es ein Array ist
    else if not (jv is TJSONArray) then
      m_owner.RegisterFailure('''%s'' is not an array', [AName], ACheck)
    else begin
      Result.m_data:=jv;
      Result.m_array:=true;
    end;
  end;
end;

function TntxTestJSON.SizeEq(AExpectedSize: integer;
  const ACheck: string): TntxTestJSON;
var
  ja: TJSONArray;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.SizeEq: owner not set!');
  if m_owner.IsRunning then
  begin
    Assert(m_data<>nil, 'TntxTestJSON.SizeEq: data not set! Call Parse() first');
    Assert(m_array, 'TntxTestJSON.SizeEq: JSON is not array!');
    ja:=m_data as TJSONArray;
    if ja.Count<>AExpectedSize then
      m_owner.RegisterFailure('wrong size of array%s: got %d, expected %d',
        [_jn, ja.Count, AExpectedSize], ACheck);
  end;
  Result:=Self;
end;

function TntxTestJSON.ForItem(AIndex: integer;
  AFunction: TntxJSONForItemFunction): TntxTestJSON;
var
  tje: TntxTestJSON;
  ja: TJSONArray;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.ForItem: owner not set!');
  if m_owner.IsRunning and Assigned(AFunction) then
  begin
    Assert(m_array, 'TntxTestJSON.ForItem: array expected!');
    tje:=nil;
    try
      tje:=TntxTestJSON.Create(Self, AIndex);
      ja:=TJSONArray(m_data);
      Assert(AIndex<ja.Count, 'TntxTestJSON.ForItem: AIndex='+IntToStr(AIndex)+
        'is out of range (0..'+IntToStr(ja.Count)+')');
      tje.m_data:=TJSONArray(m_data).Items[AIndex];
      tje.m_array:=tje.m_data is TJSONArray;
      AFunction(tje);
    finally
      tje.Free;
    end;
  end;
  Result:=Self;
end;

function TntxTestJSON.CheckObject(const AName, ACheck: string): TntxTestJSON;
var
  jv: TJSONValue;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.CheckObject: owner not set!');
  Result:=TntxTestJSON.Create(Self, AName);
  if m_owner.IsRunning then // wenn der Test noch nicht beendet
  begin
    Assert(m_data<>nil, 'TntxTestJSON.CheckObject: data not set! Call Parse() first');
    // den Wert unter dem Namen AName finden...
    jv:=(m_data as TJSONObject).Values[AName];
    if jv=nil then
      m_owner.RegisterFailure('JSON has no ''%s'' value', [AName], ACheck)
    // und prüfen, ob es ein Array ist
    else if not (jv is TJSONObject) then
      m_owner.RegisterFailure('''%s'' is not an object', [AName], ACheck)
    else begin
      m_data:=jv;
      m_array:=false;
    end;
  end;
end;

function TntxTestJSON.Parse(const AJSON: string): Boolean;
begin
  Assert(m_owner<>nil, 'TntxTestJSON.Parse: owner not set!');
  Assert(m_data=nil, 'TntxTestJSON.Parse: already parsed!');
  m_data:=TJSONObject.ParseJSONValue(BytesOf(AJSON), 0);
  Result:=false;
  if m_data<>nil then
  begin
    Result:=true;
    if m_data is TJSONArray then
      m_array:=true
    else if m_data is TJSONObject then
      m_array:=false
    else
      Result:=false;
  end;
end;

function TntxTestJSON.Done: TntxTest;
begin
  Result:=m_owner;
  Free;
end;

function TntxTestJSON.Done(const AName: string): TntxTestJSON;
begin
  Assert(AName=m_name, 'TntxTestJSON.Done('''+AName+'''): '+
    'unbalanced Check/Done! Done('''+m_name+''') expected');
  Result:=m_superj;
  Free;
end;

end.
