unit Mixi;

interface

uses
    IdHttp, MD5, SysUtils, Classes, superxmlparser, superobject, IdSSLOpenSSL,
    HttpLib, Crypt;
const
    AUTH_ENDPOINT   = 'https://mixi.jp/connect_authorize.pl';
    TOKEN_ENDPOINT  = 'https://secure.mixi-platform.com/2/token';

    API_DESC = 'This is the test project for mixi Graph API';

    HTTP_TIMEOUT = 10000;
type
    TAPIToken = class;

    TAPIToken = class
    private
        FConsumerKey: String;
        FConsumerSecret: String;
        FRedirectUrl: String;

        FCode: String;
        FAccessToken: String;
        FRefreshToken: String;
        FExpire: TDateTime;

    public
        constructor Create(key, secret, redirect: String);
        procedure Authorize(code: String);
        function Refresh: Boolean;

        function isExpired: Boolean;

        procedure SaveToFile(Path: String);
        procedure LoadFromFile(Path: String);

        property Code: String read FCode write FCode;
        property AccessToken: String read FAccessToken write FAccessToken;
        property RefreshToken: String read FRefreshToken write FRefreshToken;
        property Expire: TDateTime read FExpire write FExpire;
    end;


    function AuthorizeUUID: String;
    function AuthorizeUrl(key: String; scopes: array of String): String;


implementation


function AuthorizeUUID: String;
var buf: String;
begin
    Randomize;
    buf := DateTimeToStr(Now) + IntToStr(Random($7FFFFFFF));
    Result := CalcMD5(PByte(buf), Length(buf));
end;


function AuthorizeUrl(key: String; scopes: array of String): String;
var i, mx: Integer;
    scope: String;
begin
    mx := High(scopes);
    scope := '';
    for i := 0 to mx do
    begin
        scope := scope + scopes[i];
        if i < mx then
            scope := scope + ' ';
    end;

    Result := AUTH_ENDPOINT
        + '?client_id=' + key
        + '&response_type=code'
        + '&scope=' + scope
        + '&display=pc';
end;


constructor TAPIToken.Create(key: string; secret: string; redirect: string);
begin
    FConsumerKey    := key;
    FConsumerSecret := secret;
    FRedirectUrl    := redirect;
end;



procedure TAPIToken.Authorize(code: string);
var req, res: TStringList;
    ms: TMemoryStream;
    json: ISuperObject;

    function CalcExpire(exp: Integer): TDateTime;
    var hh, mm, ss: Integer;
    begin
        ss := exp mod 60;
        mm := (exp div 60) mod 60;
        hh := (exp div 3600) mod 24;
        Result := Now + EncodeTime(hh, mm, ss, 0)
    end;
begin
    req := TStringList.Create;
    res := TStringList.Create;
    ms  := TMemoryStream.Create;

    try
        req.Values['grant_type']    := 'authorization_code';
        req.Values['client_id']     := FConsumerKey;
        req.Values['client_secret'] := FConsumerSecret;
        req.Values['code']          := code;
        req.Values['redirect_uri']  := FRedirectUrl;

        try
            //Self.Post(TOKEN_ENDPOINT, req, ms);
            UserAgent.Post(TOKEN_ENDPOINT, req, ms);
        except

        end;
        ms.Position := 0;

        res.LoadFromStream(ms);

        json := SO(res.Text);
        res.SaveToFile('json.txt');

        FCode         := code;
        FAccessToken  := json['access_token'].AsString;
        FRefreshToken := json['refresh_token'].AsString;
        FExpire       := CalcExpire(json['expires_in'].AsInteger);
    finally
        req.Free;
        res.Free;
        ms.Free;
    end;
end;



function TAPIToken.Refresh: Boolean;
var req, res: TStringList;
    ms: TMemoryStream;
    json: ISuperObject;
begin
    req := TStringList.Create;
    res := TStringList.Create;
    ms := TMemoryStream.Create;

    try
        req.Values['grant_type']    := 'refresh_token';
        req.Values['client_id']     := FConsumerKey;
        req.Values['client_secret'] := FConsumerSecret;
        req.Values['refresh_token'] := FRefreshToken;

        //Self.Post(TOKEN_ENDPOINT, req, ms);
        UserAgent.Post(TOKEN_ENDPOINT, req, ms);

        ms.Position := 0;
        res.LoadFromStream(ms);
        json := SO(res.Text);

        FCode         := code;
        FAccessToken  := json['access_token'].AsString;
        FRefreshToken := json['refresh_token'].AsString;
        FExpire       := Now + EncodeTime(0, 0, 0, json['expires_in'].AsInteger);
    finally
        req.Free;
        res.Free;
        ms.Free;
    end;

    Result := True;
end;



function TAPIToken.isExpired: Boolean;
begin
    Result := FExpire < Now;
end;


procedure TAPIToken.SaveToFile(Path: String);
var SL: TStringList;
begin
    SL := TStringList.Create;

    try
        SL.Add(Encrypt(
            CryptData(FAccessToken, API_DESC)
        ));

        SL.Add(Encrypt(
            CryptData(FRefreshToken, API_DESC)
        ));

        SL.Add(DateTimeToStr(FExpire));

        SL.SaveToFile(Path);
    finally
        SL.Free;
    end;
end;


procedure TAPIToken.LoadFromFile(Path: String);
var SL: TStringList;
    cd: TCryptData;
begin
    SL := TStringList.Create;

    try
        SL.LoadFromFile(Path);

        if SL.Count < 3 then
            raise Exception.Create('Invalid File');

        cd := Decrypt(SL[0]);
        if Not( cd.Description = API_DESC ) then
            raise Exception.Create('Invalid Access Token');
        FAccessToken  := cd.Data;

        cd := Decrypt(SL[1]);
        if Not( cd.Description = API_DESC ) then
            raise Exception.Create('Invalid Refresh Token');
        FRefreshToken := cd.Data;

        FExpire       := StrToDateTime(SL[2]);
    finally
        SL.Free;
    end;
end;


end.
