unit ntxTestData;

interface

uses
  System.Classes;

type
  TntxTestData = class(TObject)
  private
    m_tempdir: string;
    m_tempdata: TStringList;  // has
    function GetTempDir: string;
    function GetTempData(const AName: string): string;
    procedure SetTempData(const AName, AValue: string);
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearTempData;
    procedure SetTempDir(const APath: string);
    property TempData[const AName: string]: string
      read GetTempData write SetTempData;
    property TempDir: string read GetTempDir;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, WinApi.Windows,
  // NTX
  ntxLog;

{*******************************************************************************
  CutTrailingChars - 29.11.13 09:33
  by:  JL

Die Funktion schneidet alle Substrings <chars> am Ende des Strings <str> ab und
gibt das Ergebnis zurück. Die Funktion ist Case Insensitive.

Beispiele:

CutTrailingChars('ababb', 'b') -> 'aba' (Zwei 'b' am Ende)
CutTrailingChars('abc', 'b') -> 'abc' ('b' ist nicht am Ende)
CutTrailingChars('abcabab', 'ab') -> 'abc' (Zwei 'ab' am Ende)
CutTrailingChars('AbaB', 'ab') -> '' (case insensitive)
CutTrailingChars('w1; w2; w3; ', '; ') -> 'w1; w2; w3'
CutTrailingChars('w1; w2; w3; ', ';') -> 'w1; w2; w3; ' (';' nicht am Ende)
CutTrailingChars('abc     ', ' ') -> 'abc' (genau wie TrimRight)
********************************************************************************}
function CutTrailingChars(const str, chars: string): string;
var
  lenc, lens: integer;
begin
  lenc:=Length(chars);
  lens:=Length(str);
  if lenc>0 then  // sonst endlose Schleife
    while (lens>=lenc) and SameText(Copy(str, lens-lenc+1, lenc), chars) do
      Dec(lens, lenc);
  Result:=Copy(str, 1, lens);
end; {CutTrailingChars}

{ Prüft den String <s>, ob dieser am Ende ein Backslash hat. Wenn <bAdd> = true
  ist, wird <s> mit dem Backslash zurückgegeben; <bAdd> = false - das Backslash
  am Ende wird entfernt. }
function CheckTrailingBackSlash(const s: string; bAdd: Boolean = true): string;
var
  l: integer;
begin
  l:=Length(s);
  if l=0 then // Leerverzeichnis bleibt leer
    Result:=s
  else if s[1]='\' then // Rootverzeichnis, möglicherweise mit Pfad
  begin
    Result:=CutTrailingChars(s, '\');
    if (Result='') or bAdd then
      Result:=Result+'\';
  end
  else begin
    Result:=CutTrailingChars(s, '\');
    if bAdd then
      Result:=Result+'\';
  end;
end;

function FullySpecified(const dir: string): Boolean;
const
  DRIVES = ['A'..'Z','a'..'z'];
begin
  if Length(dir)<3 then
    Result:=false
  else if CharInSet(dir[1], DRIVES) and (dir[2]=':') and (dir[3]='\') then
    Result:=true { drive specified }
  else if (dir[1]='\') and (dir[2]='\') then
    Result:=true { specified as UNC }
  else
    Result:=false;
end;

function ConstructFilespec(dirs: array of string; const fn: string = ''): string;
var
  i: integer;
begin
  Result:=fn;
  for i:=High(dirs) downto Low(dirs) do
  begin
    if FullySpecified(Result) then
      Break;
    Result:=CheckTrailingBackSlash(dirs[i])+Result;
  end;
end;

function ExpandEnv(const sWithEnvVars: string; size: longint): string;
var
  buf: PChar;
begin
  buf:=nil;
  try
    Inc(size); // add terminating zero char
    buf:=AllocMem(size);
    ExpandEnvironmentStrings(PChar(sWithEnvVars), buf, size);
    Result:=StrPas(buf);
  finally
    if buf<>nil then
      FreeMem(buf);
  end;
end;

{*******************************************************************************
  ResolvePath - 30.11.18 11:59
  by:  JL
********************************************************************************}
function ResolvePath(const APath: string): string;
var
  sPath: string;
begin
  sPath:=ExpandEnv(APath, 1024);
  sPath:=ConstructFileSpec([ExtractFileDir(ParamStr(0)), sPath], '');
  Result:=CheckTrailingBackSlash(TPath.GetFullPath(sPath), false);
  ForceDirectories(Result);
  Result:=Result+'\';
end; {ResolvePath}

{ TntxTestData }

constructor TntxTestData.Create;
begin
  inherited Create;
  m_tempdata:=TStringList.Create;
end;

destructor TntxTestData.Destroy;
begin
  m_tempdata.Free;
  inherited Destroy;
end;

function TntxTestData.GetTempData(const AName: string): string;
begin
  Result:=m_tempdata.Values[AName];
end;

procedure TntxTestData.SetTempData(const AName, AValue: string);
begin
  m_tempdata.Values[AName]:=AValue;
end;

procedure TntxTestData.ClearTempData;
begin
  m_tempdata.Clear;
end;

function TntxTestData.GetTempDir: string;
begin
  if m_tempdir='' then
    m_tempdir:=ResolvePath('%TEMP%');
  Result:=m_tempdir;
end;

{*******************************************************************************
  TntxTestData.SetTempDir - 30.11.18 11:37
  by:  JL

Prozedur setzt das Verzeichnis zu temporären Dateien, die für den Tests
verwendet werden. Der Pfad wird in APath übergeben, er kann die
Umgebungsvariablen in Form %var% enthalten, sie werden aufgelöst. Falls das
Verzeichnis noch nicht existiert, wird es angelegt.

Es gibt folgende Varianten:

1) APath enthält einen absoluten Pfad.

Das Verzeichnis für temporäre Dateien ist also eindeutig spezifiziert.

2) APath enthält einen relativen Pfad.

Das Verzeichnis wird relativ zum Verzeichnis aufgelöst, wo das Testprogramm
steht. Zum Beispiel, ein Testprogramm liegt im Verzeichnis 'C:\DEV\TESTS\BIN',
und SetTempDir wird mit APath='..\TEMP' aufgerufen. Dann wird das Verzeichnis
auf C:\DEV\TESTS\TEMP gesetzt.

ACHTUNG!!! Wenn das Testprogramm in einem Programmverzeichnis liegt (also unten
'C:\Program Files\...' oder 'C:\Program Files (x86)\...', kann es
Zugriffsprobleme beim Anlegen des Verzeichnisses bzw. beim Schreiben der
temporären Dateien geben. Das Testprogramm muss unter Admin-Rechten ausgeführt
werden. Aber weil Testprogramme hauptsächlich für die Entwicklung verwendet
und also in den Entwicklungsverzeichnissen erzeugt werden, soll es keine
Probleme geben.

3) Die Prozedur wird nie aufgerufen.

In diesem Fall werden die temporären Dateien im Verzeichnis %TEMP% abgelegt,
also wie es in der System-Umgebung gesetzt ist.

ACHTUNG!!! Standardmäßig verweist dieses Verzeichnis auf
C:\Users\<uid>\AppData\Local\Temp, aber %TEMP% kann in der Konsole anders
definiert sein, wie zum Beispiel in der AMIS-Buildkonsole.

Und generell werden die Umgebungsvariablen genutzt, die in der System-Umgebung
definiert sind, aus welcher das Testprogramm aufgerufen wurde.

********************************************************************************}
procedure TntxTestData.SetTempDir(const APath: string);
begin
  m_tempdir:=ResolvePath(APath);
  Log('ntxTestData: m_tempdir=''%s''', [m_tempdir]);
end; {TntxTestData.SetTempDir}

end.
