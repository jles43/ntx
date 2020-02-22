unit ntxConst;

interface

type
  TntxTestOption = (ntoFailureOnly, ntoLog);
  TntxTestOptions = set of TntxTestOption;
  TntxTestState = (ntsCreated, ntsRunning, ntsCompleted, ntsCancelled, ntsFailed);

function PrtNtxTestOption(val: TntxTestOption): string;
function PrtNtxTestOptions(val: TntxTestOptions): string;
function PrtNtxTestState(val: TntxTestState): string;

implementation

uses
  // DELPHI VCL
  System.SysUtils;

function PrtNtxTestOption(val: TntxTestOption): string;
const
  _names: array[TntxTestOption] of PChar = (
    'ntoFailureOnly', 'ntoLog'
  );
begin
  Result:=StrPas(_names[val]);
end;

function PrtNtxTestOptions(val: TntxTestOptions): string;
var
  i: TntxTestOption;
begin
  Result:='';
  for i:=Low(TntxTestOption) to High(TntxTestOption) do
    if i in val then
      Result:=Result+PrtNtxTestOption(i)+', ';
  if Result<>'' then
    SetLength(Result, Length(Result)-2);
  Result:='['+Result+']';
end;

function PrtNtxTestState(val: TntxTestState): string;
const
  _names: array[TntxTestState] of PChar = (
    'ntsCreated', 'ntsRunning', 'ntsCompleted', 'ntsCancelled', 'ntsFailed'
  );
begin
  Result:=StrPas(_names[val]);
end;

end.
