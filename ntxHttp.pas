// UNDER CONSTRUCTION!!!
unit ntxHttp;

interface

{$DEFINE USE_LOG}

uses
  // DELPHI VCL
  Classes, SysUtils,
  // Indy
  IdContext, IdCustomHTTPServer, IdHTTPServer;

type
  TntxHttpServer = class(TIdHttpServer)
  private type
    TntxHttpMockDataItem = class(TCollectionItem)
    private
      m_cmd,
      m_url,
      m_reqdata: string;
      m_headers: TStringList;
      m_code: longint;
      m_resptype,
      m_respdata: string;
      procedure SetData(code: longint;
        const resptype, respdata: string); overload;
      procedure SetData(const cmd, url, reqdata, headers: string;
        code: longint; const resptype, respdata: string); overload;
      procedure SetHeaders(const headers: string);
      function CompareHeaders(const headers: string): Boolean;
      procedure MockResponse(AResponseInfo: TIdHTTPResponseInfo);
    protected
    public
      constructor Create(Collection: TCollection); override;
      destructor Destroy; override;
      function IsEqual(const cmd, url, reqdata, headers: string): Boolean;
      function Match(const cmd, url, reqdata: string; headers: TStrings): Boolean;
    end;
    TntxHttpMockData = class(TCollection)
    private
      function GetItems(idx: integer): TntxHttpMockDataItem;
    protected
    public
      constructor Create;
      destructor Destroy; override;
      function FindItem(const cmd, url, reqdata, headers: string): TntxHttpMockDataItem; overload;
      function FindItem(const cmd, url, reqdata: string; headers: TStrings): TntxHttpMockDataItem; overload;
      function Add: TntxHttpMockDataItem;
      property Items[idx: integer]: TntxHttpMockDataItem read GetItems; default;
    end;

  private
    m_mocks: TntxHttpMockData;
  protected
    //function GetActive: Boolean;
    //procedure SetActive(val: Boolean); override;
    function GetRequestData(req: TIdHTTPRequestInfo): string;
    function ParseRequest(req: TIdHTTPRequestInfo; out cmd, url, reqdata: string;
      headers: TStrings): Boolean;
    procedure ProcessGetCommand(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    // Die Mockdaten werden ersetzt, wenn cmd+url+reqdata+headers gleich sind
    // sonst werden sie hinzugefügt
    procedure SetMockData(
      // request
      const cmd, url, reqdata, headers: string;
      // response
      code: longint; const resptype, respdata: string);
    //property Active: Boolean read GetActive write SetActive;
  end;

implementation

uses
  // DELPHI VCL
  StrUtils
  // NTX
  {$IFDEF USE_LOG}, ntxLog{$ENDIF}
  ;

{ TntxHttpMockDataItem }

constructor TntxHttpServer.TntxHttpMockDataItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  m_cmd:='';
  m_url:='';
  m_reqdata:='';
  m_headers:=TStringList.Create;
  m_code:=-1;
  m_resptype:='';
  m_respdata:='';
end;

destructor TntxHttpServer.TntxHttpMockDataItem.Destroy;
begin
  m_headers.Free;
  inherited Destroy;
end;

{*******************************************************************************
  TntxHttpMockDataItem.SetData - 25.03.24 16:44
  by:  JL
********************************************************************************}
procedure TntxHttpServer.TntxHttpMockDataItem.SetData(code: longint;
  const resptype, respdata: string);
begin
  m_code:=code;
  m_resptype:=resptype;
  m_respdata:=respdata;
end; {TntxHttpMockDataItem.SetData}

{*******************************************************************************
  TntxHttpMockDataItem.SetHeaders - 09.07.24 14:09
  by:  JL
********************************************************************************}
procedure TntxHttpServer.TntxHttpMockDataItem.SetHeaders(const headers: string);
begin
  m_headers.CommaText:=headers;
end; {TntxHttpMockDataItem.SetHeaders}

{*******************************************************************************
  TntxHttpMockDataItem.SetData - 25.03.24 16:42
  by:  JL
********************************************************************************}
procedure TntxHttpServer.TntxHttpMockDataItem.SetData(
  const cmd, url, reqdata, headers: string;
  code: longint; const resptype, respdata: string);
begin
  m_cmd:=cmd;
  m_url:=url;
  m_reqdata:=reqdata;
  SetHeaders(headers);
  SetData(code, resptype, respdata);
end; {TntxHttpMockDataItem.SetData}

{*******************************************************************************
  TntxHttpMockDataItem.MockResponse - 25.03.24 17:06
  by:  JL
********************************************************************************}
procedure TntxHttpServer.TntxHttpMockDataItem.MockResponse(
  AResponseInfo: TIdHTTPResponseInfo);
begin
  AResponseInfo.ResponseNo:=m_code;
  AResponseInfo.ContentType:=m_resptype;
  AResponseInfo.ContentText:=m_respdata;
end; {TntxHttpMockDataItem.MockResponse}

{*******************************************************************************
  TntxHttpMockDataItem.CompareHeaders - 09.07.24 14:12
  by:  JL

Wenn alle Elemente in <headers> haben gleiche Abbildung in m_headers, dann
sind die Headers gleich. Die Reihenfolge darf abweichen. Also

m_headers = ['a=b', 'c=d'], headers = 'c=d,a=b' => TRUE
m_headers = ['a=b', 'c=d'], headers = 'a=b' => FALSE, weil 'c=d' fehlt
********************************************************************************}
function TntxHttpServer.TntxHttpMockDataItem.CompareHeaders(
  const headers: string): Boolean;
var
  sl: TStringList;
  i: integer;
begin
  sl:=TStringList.Create;
  try
    sl.CommaText:=headers;
    Result:=sl.Count=m_headers.Count;
    if Result then
      for i:=0 to sl.Count-1 do
        if m_headers.IndexOf(sl[i])=-1 then
        begin
          Result:=false;
          Break;
        end;
  finally
    sl.Free;
  end;
end; {TntxHttpMockDataItem.CompareHeaders}

{*******************************************************************************
  TntxHttpMockDataItem.IsEqual - 25.03.24 16:45
  by:  JL
********************************************************************************}
function TntxHttpServer.TntxHttpMockDataItem.IsEqual(
  const cmd, url, reqdata, headers: string): Boolean;
begin
  Result:=(cmd=m_cmd) and (url=m_url);
  if Result then
    //          ignorieren oder vergleichen
    Result:=(m_reqdata='*') or (m_reqdata=reqdata);
  if Result and (m_headers.Count>0) then
    Result:=CompareHeaders(headers);
end; {TntxHttpMockDataItem.IsEqual}

{*******************************************************************************
  TntxHttpMockDataItem.Match - 09.07.24 14:25
  by:  JL
********************************************************************************}
function TntxHttpServer.TntxHttpMockDataItem.Match(
  const cmd, url, reqdata: string; headers: TStrings): Boolean;
var
  i: integer;
begin
  Result:=(cmd=m_cmd) and (url=m_url);
  if Result then
    //          ignorieren oder vergleichen
    Result:=(m_reqdata='*') or (m_reqdata=reqdata);
  if Result and (m_headers.Count>0) then
  begin
    for i:=0 to m_headers.Count-1 do  // alle aus m_headers sollen in headers vorliegen
      if headers.IndexOf(m_headers[i])=-1 then
      begin
        Result:=false;
        Break;
      end;
  end;
end; {TntxHttpMockDataItem.Match}

{ TntxHttpMockData }

constructor TntxHttpServer.TntxHttpMockData.Create;
begin
  inherited Create(TntxHttpMockDataItem);
end;

destructor TntxHttpServer.TntxHttpMockData.Destroy;
begin
  inherited Destroy;
end;

function TntxHttpServer.TntxHttpMockData.GetItems(idx: integer): TntxHttpMockDataItem;
begin
  Result:=TntxHttpMockDataItem(inherited Items[idx]);
end;

function TntxHttpServer.TntxHttpMockData.Add: TntxHttpMockDataItem;
begin
  Result:=TntxHttpMockDataItem(inherited Add);
end;

{*******************************************************************************
  TntxHttpMockData.FindItem - 25.03.24 16:51
  by:  JL
********************************************************************************}
function TntxHttpServer.TntxHttpMockData.FindItem(
  const cmd, url, reqdata, headers: string): TntxHttpMockDataItem;
var
  i: integer;
begin
  Result:=nil;
  for i:=0 to Count-1 do
    if Items[i].IsEqual(cmd, url, reqdata, headers) then
    begin
      Result:=Items[i];
      Break;
    end;
end; {TntxHttpMockData.FindItem}

{*******************************************************************************
  TntxHttpMockData.FindItem - 09.07.24 14:22
  by:  JL
********************************************************************************}
function TntxHttpServer.TntxHttpMockData.FindItem(const cmd, url, reqdata: string;
  headers: TStrings): TntxHttpMockDataItem;
var
  i: integer;
begin
  Result:=nil;
  for i:=0 to Count-1 do
  begin
    if Items[i].Match(cmd, url, reqdata, headers) then
    begin
      Result:=Items[i];
      Break;
    end;
  end;
end; {TntxHttpMockData.FindItem}

{ TntxHttpServer }

constructor TntxHttpServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  m_mocks:=TntxHttpMockData.Create;
  OnCommandGet:=ProcessGetCommand;
end;

destructor TntxHttpServer.Destroy;
begin
  FreeAndNil(m_mocks);
  inherited Destroy;
end;

{*******************************************************************************
  TntxHttpServer.GetRequestData - 26.03.24 11:29
  by:  JL
********************************************************************************}
function TntxHttpServer.GetRequestData(req: TIdHTTPRequestInfo): string;
const
  ALLOWED_CONTENT_TYPES: array[0..2] of string = (
    'application/json',
    'application/xml',
    'multipart/form-data'
  );
var
  buf: TBytes;
  enc: TEncoding;
begin
  {$IFDEF USE_LOG}
  Log('> TntxHttpServer.GetRequestData(req=%p), ContentLength=%d, '+
    'ContentType=''%s''',
    [Pointer(req), req.ContentLength, req.ContentType]);
  {$ENDIF}
  if req.ContentLength<=0 then
    Result:=''
  else begin
    if SameText(LeftStr(req.ContentType, 5), 'text/')
       or (IndexText(req.ContentType, ALLOWED_CONTENT_TYPES)>=0) then
    begin
      {$IFDEF USE_LOG}
      Log('  TntxHttpServer.GetRequestData: Size=%d, ContentEncoding=''%s''',
        [req.PostStream.Size, req.ContentEncoding]);
      {$ENDIF}
      // get string from the stream according to encoding
      SetLength(buf, req.PostStream.Size);
      req.PostStream.Seek(0, soBeginning);
      req.PostStream.Read(buf[0], Length(buf));
      if SameText(req.ContentEncoding, 'utf-8') then
        enc:=TEncoding.UTF8
      else
        enc:=TEncoding.ANSI;
      Result:=enc.GetString(buf);
    end
    else
      Result:='';
  end;
  {$IFDEF USE_LOG}
  Log('< TntxHttpServer.GetRequestData result=''%s''', [Result])
  {$ENDIF}
end; {TntxHttpServer.GetRequestData}

{*******************************************************************************
  TntxHttpServer.ParseRequest - 26.03.24 11:24
  by:  JL
********************************************************************************}
function TntxHttpServer.ParseRequest(req: TIdHTTPRequestInfo;
  out cmd, url, reqdata: string; headers: TStrings): Boolean;
var
  i, p: integer;
  s, sName, sValue: string;
begin
  {$IFDEF USE_LOG}
  Log('> TntxHttpServer.ParseRequest(req=%p, cmd=?, url=?, reqdata=?)',
    [Pointer(req)]);
  Log('+ TntxHttpServer.ParseRequest: RawHTTPCommand=''%s'', Command=''%s'', '+
    'Document=''%s'', QueryParams=''%s'', RawHeaders=''%s''',
    [req.RawHTTPCommand, req.Command, req.Document, req.QueryParams,
     req.RawHeaders.CommaText]);
  {$ENDIF}
  if req.Command<>'' then
  begin
    cmd:=req.Command;
    url:=req.Document;
    if req.QueryParams<>'' then
      url:=url+'?'+req.QueryParams;
    reqdata:=GetRequestData(req);
    headers.Clear;
    for i:=0 to req.RawHeaders.Count-1 do
    begin
      s:=req.RawHeaders.Strings[i];
      p:=Pos(':', s);
      if p=0 then Continue;
      sName:=Trim(Copy(s, 1, p-1));
      if sName='' then Continue;
      sValue:=Trim(Copy(s, p+1, Length(s)));
      headers.Values[sName]:=sValue;
    end;
    Result:=true;
  end
  else begin
    cmd:='';
    url:='';
    reqdata:='';
    headers.Clear;
    Result:=false;
  end;
  {$IFDEF USE_LOG}
  Log('< TntxHttpServer.ParseRequest result=%s, cmd=''%s'', url=''%s'', '+
    'reqdata=''%s'', headers=[%s]',
    [BoolVal(Result), cmd, url, reqdata, headers.CommaText]);
  {$ENDIF}
end; {TntxHttpServer.ParseRequest}

{*******************************************************************************
  TntxHttpServer.ProcessGetCommand - 25.03.24 16:57
  by:  JL
********************************************************************************}
procedure TntxHttpServer.ProcessGetCommand(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  item: TntxHttpMockDataItem;
  cmd, url, reqdata: string;
  headers: TStringList;
begin
  {$IFDEF USE_LOG}
  Log('> TntxHttpServer.ProcessGetCommand(AContext=%p, ARequestInfo=%p, '+
    'AResponseInfo=%p)',
    [Pointer(AContext), Pointer(ARequestInfo), Pointer(AResponseInfo)]);
  {$ENDIF}
  headers:=TStringList.Create;
  try
    if ParseRequest(ARequestInfo, cmd, url, reqdata, headers) then
    begin
      item:=m_mocks.FindItem(cmd, url, reqdata, headers);
      if item=nil then
        AResponseInfo.ResponseNo:=404
      else
        item.MockResponse(AResponseInfo);
    end
    else
      AResponseInfo.ResponseNo:=500;
  finally
    headers.Free;
  end;
  {$IFDEF USE_LOG}
  Log('< TntxHttpServer.ProcessGetCommand, ResponseNo=%d',
    [AResponseInfo.ResponseNo]);
  {$ENDIF}
end; {TntxHttpServer.ProcessGetCommand}

{*******************************************************************************
  TntxHttpServer.SetMockData - 25.03.24 16:53
  by:  JL
********************************************************************************}
procedure TntxHttpServer.SetMockData(const cmd, url, reqdata, headers: string;
  code: longint; const resptype, respdata: string);
var
  item: TntxHttpMockDataItem;
begin
  item:=m_mocks.FindItem(cmd, url, reqdata, headers);
  if item=nil then  // not found
    m_mocks.Add.SetData(cmd, url, reqdata, headers, code, resptype, respdata)
  else              // found
    item.SetData(code, resptype, respdata);
end; {TntxHttpServer.SetMockData}

end.
