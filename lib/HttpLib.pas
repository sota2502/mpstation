unit HttpLib;

interface

uses
    Classes, IdHttp, IdSSLOpenSSL;

type
    TUserAgent = class
    private
        FTimeout: Integer;
        FHttp: TIdHTTP;
        FSSL: TIdSSLIOHandlerSocketOpenSSL;

        procedure SetTimeout(iTimeout: Integer);
    public
        constructor Create;
        destructor Destroy; override;

        function Get(AURL: String): String; overload;
        procedure Get(AURL: String; AResponseContent: TStream); overload;

        function Post(AURL: String; ASource: TStrings): String; overload;
        procedure Post(AURL: String; ASource: TStrings;
            AResponseContent: TStream); overload;

        property Timeout: Integer read FTimeout write SetTimeout;
        property Http: TIdHTTP read FHttp;
    end;

const
    DEFAULT_TIMEOUT = 10000;

var
    UserAgent: TUserAgent;


implementation


constructor TUserAgent.Create;
begin
    FHttp    := TIdHTTP.Create;
    SetTimeOut(DEFAULT_TIMEOUT);

    FSSL     := TIdSSLIOHandlerSocketOpenSSL.Create;
    with FSSL.SSLOptions do
    begin
        Method      := sslvTLSv1;
        Mode        := sslmUnassigned;
        VerifyMode  := [];
        VerifyDepth := 0;
    end;

    FHttp.IOHandler := FSSL;
end;


destructor TUserAgent.Destroy;
begin
    FSSL.Free;
    FHttp.Free;
end;


function TUserAgent.Get(AURL: String): String;
begin
    Result := FHttp.Get(AURL);
end;


procedure TUserAgent.Get(AURL: String; AResponseContent: TStream);
begin
    FHttp.Get(AURL);
end;


function TUserAgent.Post(AURL: String; ASource: TStrings): String;
begin
    Result := FHttp.Post(AURL, ASource);
end;


procedure TUserAgent.Post(AURL: String; ASource: TStrings;
    AResponseContent: TStream);
begin
    FHttp.Post(AURL, ASource, AResponseContent);
end;


procedure TUserAgent.SetTimeout(iTimeout: Integer);
begin
    FTimeout             := iTimeout;
    FHttp.ReadTimeout    := iTimeout;
    FHttp.ConnectTimeout := iTimeout;
end;


initialization
    UserAgent := TUserAgent.Create;

finalization
    UserAgent.Free;

end.
