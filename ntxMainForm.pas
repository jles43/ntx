unit ntxMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

const
  WM_RUNTESTS = WM_USER+1;

type
  TntxMainForm = class(TForm)
    pnlControls: TPanel;
    Splitter1: TSplitter;
    memLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private-Deklarationen }
    m_exitcode: integer;
    function AutoClose: Boolean;
    procedure OnRunTests(var Msg: TMessage); message WM_RUNTESTS;
  protected
    function PerformTests: integer; virtual;
  public
    { Public-Deklarationen }
    property ExitCode: integer read m_exitcode;
  end;

var
  _ntxMainForm: TntxMainForm;

implementation

{$R *.dfm}

function TntxMainForm.AutoClose: Boolean;
var
  i: integer;
  s: string;
begin
  Result:=true;
  for i:=1 to ParamCount do
  begin
    s:=ParamStr(i);
    if (s[1]='/') or (s[1]='-') then
    begin
      Delete(s, 1, 1);
      if SameText(s, 'NOCLOSE') then
        Result:=false;
    end;
  end;
end;

procedure TntxMainForm.FormCreate(Sender: TObject);
begin
  m_exitcode:=0;
  memLog.Clear;
  pnlControls.Caption:='';
end;

procedure TntxMainForm.FormDestroy(Sender: TObject);
begin
  {}
end;

procedure TntxMainForm.FormShow(Sender: TObject);
begin
  {}
end;

procedure TntxMainForm.FormActivate(Sender: TObject);
begin
  PostMessage(Handle, WM_RUNTESTS, 1, LParam(Self));
end;

procedure TntxMainForm.OnRunTests(var Msg: TMessage);
begin
  m_exitcode:=PerformTests;
  if AutoClose then
    Close;
end;

function TntxMainForm.PerformTests: integer;
begin
  Result:=0;
end;

end.
