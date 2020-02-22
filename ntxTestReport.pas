unit ntxTestReport;

interface

uses
  System.Classes,
  ntxConst;

type
  TTestReportFormat = (trfPlainText);
  TntxReport = class(TObject)
  private
    function GetText: string;
  protected
    m_output: TStringList;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    class function CreateReport(AFormat: TTestReportFormat = trfPlainText): TntxReport;
    class function NoReport(AFormat: TTestReportFormat = trfPlainText): string;
    procedure Open(const ATestName: string); virtual; abstract;
    procedure OpenLevel; virtual; abstract;
    procedure TestResult(const ATestName: string; AState: TntxTestState;
      const AReason: string; AReportSuccess: Boolean); virtual; abstract;
    procedure CloseLevel; virtual; abstract;
    procedure Close(AFailed, ACancelled, ATotal: integer); virtual; abstract;
    property Text: string read GetText;
  end;
  TntxReportPlainText = class(TntxReport)
  private
    m_indent: string;
  protected
  public
    constructor Create; override;
    procedure Open(const ATestName: string); override;
    procedure OpenLevel; override;
    procedure TestResult(const ATestName: string; AState: TntxTestState;
      const AFailureReason: string; AReportSuccess: Boolean); override;
    procedure CloseLevel; override;
    procedure Close(AFailed, ACancelled, ATotal: integer); override;
  end;

function PrtTestReportFormat(val: TTestReportFormat): string;

implementation

uses
  System.SysUtils;

function PrtTestReportFormat(val: TTestReportFormat): string;
const
  _names: array[TTestReportFormat] of PChar = (
    'trfPlainText'
  );
begin
  Result:=StrPas(_names[val]);
end;

{ TntxReport }

constructor TntxReport.Create;
begin
  inherited Create;
  m_output:=TStringList.Create;
end;

destructor TntxReport.Destroy;
begin
  m_output.Free;
  inherited Destroy;
end;

function TntxReport.GetText: string;
begin
  Result:=m_output.Text;
end;

class function TntxReport.CreateReport(AFormat: TTestReportFormat): TntxReport;
begin
  case AFormat of
  trfPlainText:
    Result:=TntxReportPlainText.Create;
  else
    Result:=nil;
  end;
end;

class function TntxReport.NoReport(AFormat: TTestReportFormat): string;
begin
  case AFormat of
  trfPlainText:
    Result:=TntxReportPlainText.NoReport;
  else
    Result:='no report created';
  end;
end;

{ TntxReportPlainText }

constructor TntxReportPlainText.Create;
begin
  inherited;

end;

procedure TntxReportPlainText.Open(const ATestName: string);
begin
  m_output.Add(m_indent+Format('Test "%s"', [ATestName]));
end;

procedure TntxReportPlainText.OpenLevel;
begin
  m_indent:=m_indent+'  ';
end;

procedure TntxReportPlainText.TestResult(const ATestName: string;
  AState: TntxTestState; const AFailureReason: string; AReportSuccess: Boolean);
begin
  if AState=ntsFailed then
    m_output.Add(m_indent+
      Format('Test "%s" failed: %s', [ATestName, AFailureReason]))
  else if AState=ntsCancelled then
    m_output.Add(m_indent+
      Format('Test "%s" cancelled: %s', [ATestName, AFailureReason]))
  else if AReportSuccess then
    m_output.Add(m_indent+
      Format('Test "%s" succeeded', [ATestName]));
end;

procedure TntxReportPlainText.CloseLevel;
begin
  Delete(m_indent, 1, 2);
end;

procedure TntxReportPlainText.Close(AFailed, ACancelled, ATotal: integer);
begin
  m_output.Add(m_indent+Format('Failed %d, cancelled %d (of %d)',
    [AFailed, ACancelled, ATotal]));
end;

end.
