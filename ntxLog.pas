unit ntxLog;

interface

uses
  System.Classes, System.Variants, Data.DB;

type
  TntxObjectClass = class of TObject;

function BoolVal(const val: Boolean): string;
function PrtObject(val: TObject): string;
function PrtClass(val: TntxObjectClass): string;
function PrtStringArray(const val: array of string): string;
function PrtStringList(val: TStrings): string;
function PrtString(const s: string; maxlen: integer): string;
function PrtDate(val: TDateTime): string;
function PrtDateTime(val: TDateTime; const bCompact: Boolean = true): string;
function PrtFieldType(val: TFieldType): string;
function PrtField(fld: TField): string;
function PrtVarType(val: TVarType): string;
function PrtVariant(v: variant; strmax: integer = -1): string;
function PrtByte(val: Byte): string;
function PrtBlobData(const val: variant; maxlen: integer = 8): string;

function ByteToHex(b: byte): string;
function CharToHex(c: AnsiChar): string;


procedure Log(const fmt: string; const args: array of const);

implementation

uses
  System.SysUtils, WinApi.Windows, Data.SqlTimSt;

const
  x: array[0..15] of char = (
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

function ByteToHex(b: byte): string;
begin
  Result:=x[(b shr 4) and $f]+x[b and $f];
end;

function CharToHex(c: AnsiChar): string;
begin
  Result:=ByteToHex(Ord(c));
end;

function PrtByte(val: Byte): string;
begin
  Result:='$'+ByteToHex(val);
end;

function pch(c: char): string;
begin
  if c<' ' then
    Result:='^'+chr(ord(c)+$40)
  else if CharInSet(c, ['^', '''']) then
    Result:=c+c
  else
    Result:=c;
end;

function PrtString(const s: string; maxlen: integer): string;
var
  i, j, len: integer;
  sp: string;
begin
  Result:='';
  len:=Length(s);
  i:=1; j:=1;
  while ( j<=maxlen ) and ( i<=len ) do
  begin
    sp:=pch(s[i]);
    Result:=Result+sp;
    Inc(j, Length(sp));
    Inc(i);
  end;
  if i<=len then
    Result:=Result+'...';
end;

function BoolVal(const val: Boolean): string;
begin
  if val then
    Result:='True'
  else
    Result:='False';
end;

function PrtObject(val: TObject): string;
begin
  if Assigned(val) then
    Result:='instance of '+val.ClassName
  else
    Result:='nil';
end;

function PrtClass(val: TntxObjectClass): string;
begin
  if Assigned(val) then
    Result:='class '+val.ClassName
  else
    Result:='nil';
end;

function PrtStringArray(const val: array of string): string;
var
  i: integer;
begin
  Result:='';
  if Length(val)>0 then
    for i:=Low(val) to High(val) do
      Result:=Result+''''+val[i]+''', ';
  if Length(Result)>0 then
    SetLength(Result, Length(Result)-2);
  Result:='['+Result+']';
end;

function PrtStringList(val: TStrings): string;
var
  i: integer;
begin
  Result:='';
  if val.Count>0 then
    for i:=0 to val.Count-1 do
      Result:=Result+''''+val.Strings[i]+''', ';
  if Length(Result)>0 then
    SetLength(Result, Length(Result)-2);
  Result:='['+Result+']';
end;

const
  DATUM_FORMAT='dd.mm.yyyy';
  ZEIT_FORMAT='hh:nn:ss.zzz';
  FULL_FORMAT=DATUM_FORMAT+' '+ZEIT_FORMAT;
  ONE_SECOND=1.0/(24.0*60.0*60.0);

function PrtDate(val: TDateTime): string;
var
  sFmt: string;
begin
  sFmt:=DATUM_FORMAT;
  Result:=FormatDateTime(sFmt, val);
end; {PrtDate}

{ Wenn bCompact gleich FALSE ist, wird <val> im vollen Format ausgedruckt;
  wenn bCompact gleich TRUE ist,  werden die Zeit bzw. das Datum nicht
  ausgedruckt, wenn sie gleich 0 sind.
}
function PrtDateTime(val: TDateTime; const bCompact: Boolean): string;
var
  sFmt: string;
begin
  if bCompact then
  begin
    if (val>=0.0) and (val<1.0) then { nur Zeit }
      sFmt:=ZEIT_FORMAT
    else if Frac(val)<ONE_SECOND then { nur Datum }
      sFmt:=DATUM_FORMAT
    else
      sFmt:=FULL_FORMAT;
  end
  else
    sFmt:=FULL_FORMAT;
  Result:=FormatDateTime(sFmt, val);
end; {PrtDateTime}

function PrtVarType(val: TVarType): string;
var
  vt0: TVarType;
begin
  vt0:=val and varTypeMask;
  case vt0 of
  varEmpty: Result:='empty';
  varNull: Result:='null';
  varSmallint: Result:='smallint';
  varInteger: Result:='integer';
  varSingle: Result:='single';
  varDouble: Result:='double';
  varCurrency: Result:='currency';
  varDate: Result:='date';
  varOleStr: Result:='olestr';
  varDispatch: Result:='dispatch';
  varError: Result:='error';
  varBoolean: Result:='boolean';
  varVariant: Result:='variant';
  varUnknown: Result:='unknown';
  varShortInt: Result:='shortint';
  varByte: Result:='byte';
  varWord: Result:='word';
  varLongWord: Result:='longword';
  varInt64: Result:='int64';
  varStrArg: Result:='strarg';
  varString: Result:='string';
  varAny: Result:='any';
  varUInt64: Result:='uint64';
  varUString: Result:='unicode string';
  else
    Result:='!'+VarTypeAsText(vt0)+'!';
  end;
  if (val and varArray)<>0 then
    Result:='array of '+Result;
  if (val and varByRef)<>0 then
    Result:=Result+' by ref';
end;

{*******************************************************************************
  PrtVariant - 26.03.03 15:29
  by:  JL

JL, 26.03.2010 08:38 - Die Strings werden durch PrtString vorbereitet, wenn
deren maximale Länge durch <strmax> eingeschränk ist.
********************************************************************************}
function PrtVariant(v: variant; strmax: integer): string;
var
  svt, s: string;
  vt, vt0: TVarType;
begin
  vt:=VarType(v);
  Result:='';
  if (vt and varArray)<>0 then
    Result:='array of ';
  vt0:=vt and varTypeMask;
  svt:=PrtVarType(vt0);
  if (Result='') and (vt0<>varEmpty) and (vt0<>varNull)
    and (vt0<>varDispatch) and (vt0<>varAny) then
  begin
    if vt0=varDate then
      s:=PrtDateTime(v)
    else if VarIsSQLTimeStamp(v) then
      s:=PrtDateTime(v)
    else begin
      s:=v;
      if (vt0=varOleStr) or (vt0=varString) or (vt0=varUString) then
      begin
        if strmax<=0 then
          strmax:=Length(s)*2;
        s:=PrtString(s, strmax);
        s:=''''+s+'''';
      end;
    end;
    svt:=svt+'('+s+')';
  end;
  Result:=Result+svt;
  if (vt and varByRef)<>0 then
    Result:=Result+' by ref';
end; {PrtVariant}

function PrtFieldType(val: TFieldType): string;
const
  names: array[TFieldType] of PChar = (
    'ftUnknown', 'ftString', 'ftSmallint', 'ftInteger', 'ftWord', 'ftBoolean',
    'ftFloat', 'ftCurrency', 'ftBCD', 'ftDate', 'ftTime', 'ftDateTime',
    'ftBytes', 'ftVarBytes', 'ftAutoInc', 'ftBlob', 'ftMemo', 'ftGraphic',
    'ftFmtMemo', 'ftParadoxOle', 'ftDBaseOle', 'ftTypedBinary', 'ftCursor',
    'ftFixedChar', 'ftWideString', 'ftLargeint', 'ftADT', 'ftArray',
    'ftReference', 'ftDataSet', 'ftOraBlob', 'ftOraClob', 'ftVariant',
    'ftInterface', 'ftIDispatch', 'ftGuid', 'ftTimeStamp', 'ftFMTBcd',
    'ftFixedWideChar', 'ftWideMemo', 'ftOraTimeStamp', 'ftOraInterval',
    'ftLongWord', 'ftShortint', 'ftByte', 'ftExtended', 'ftConnection',
    'ftParams', 'ftStream', 'ftTimeStampOffset', 'ftObject', 'ftSingle'
    );
begin
  Result:=StrPas(names[val]);
end;

function PrtField(fld: TField): string;
begin
  if fld=nil then
    Result:='nil'
  else with fld do
    Result:=Format('%s=%s', [FieldName, PrtVariant(Value)]);
end;

function DumpBytes(const bytes: array of byte; maxlen: integer): string;
var
  i, j, ofs, len: integer;
  sb: string;
begin
  len:=Length(bytes);
  if maxlen<len then
  begin
    len:=maxlen-2;
    SetLength(Result, len*2+3);
    j:=len*2+1;
    Result[j]:='.';
    Result[j+1]:='.';
    Result[j+2]:='.';
  end
  else
    SetLength(Result, len*2);
  { An dieser Stelle ist der Platz für <len> hexadezimale Bytes vorbereitet,
    gesamte Länge = len*2, Beginnindex = 1, Endindex = len*2. Falls <bytes>
    länger als <maxlen> ist, liegen im Result drei Punktzeichen ab Index len*2+1
  }
  ofs:=Low(bytes);
  j:=1; { Zielindex (in Result) für die Hex-Ziffern }
  for i:=0 to len-1 do { len Bytes umwandeln und in Result schreiben }
  begin
    sb:=ByteToHex(bytes[i+ofs]);
    Result[j]:=sb[1]; Inc(j);
    Result[j]:=sb[2]; Inc(j);
  end;
end;



{ TBlobData ist 'array of byte', 'string', 'Unassigned' or 'null'
  Andere Typen sind ungültig.
}
function PrtBlobData(const val: variant; maxlen: integer): string;
var
  s, s1: string;
  ab: array of byte;
  len: longint;
begin
  if VarIsNull(val) then
    Result:='null'
  else if VarIsEmpty(val) then
    Result:='empty' { Unassigned }
  else begin
    s:=PrtVarType(VarType(val));
    if s='array of byte' then
    begin
      // Zuerst Länge ermitteln, dann zuweisen, sonst tritt bei der Zuweisung
      // ein Fehler auf, wenn val ein leeres Array ist. Also, so ist falsch
      // ab:=val; len:=Length(ab);
      len:=Length(val);
      if len=0 then
        Result:='array[0 items]'
      else begin
        ab:=val;
        Result:=Format('array[%d..%d]=(%s)', [Low(ab), High(ab),
          DumpBytes(ab, maxlen)]);
      end;
    end
    else if s='string' then
    begin
      s1:=val;
      Result:=Format('string[%d]=''%s''', [Length(s1), PrtString(s1, maxlen)]);
    end
    else
      Result:='invalid type: '+s;
  end;
end;

procedure Log(const fmt: string; const args: array of const);
var
  s: string;
begin
  s:='[ntx] '+Format(fmt, args);
  OutputDebugString(PChar(s));
end;

end.
