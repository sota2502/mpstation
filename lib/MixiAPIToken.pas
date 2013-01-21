unit MixiAPIToken;

interface

uses
    Classes, Contnrs, SysUtils, Crypt, HttpLib, superxmlparser, superobject;

type
    TMixiAPIToken = class
    private
        FAccessToken: String;
        FRefreshToken: String;
        FExpire: TDateTime;
        FTokenType: String;
        FScope: String;

    public
        function isExpired: Boolean;

        procedure SaveToFile(Path: String);
        procedure LoadFromFile(Path: String);

        property AccessToken: String read FAccessToken write FAccessToken;
        property RefreshToken: String read FRefreshToken write FRefreshToken;
        property Expire: TDateTime read FExpire write FExpire;
        property TokenType: String read FTokenType write FTokenType;
        property Scope: String read FScope write FScope;
    end;

    TMixiAPITokenFactory = class
    private
        FConsumerKey: String;
        FConsumerSecret: String;
        FRedirectUrl: String;
        FTokenContainer: TObjectList;
    public
        constructor Create(key, secret: String; redirect: String = '');
        destructor Destroy; override;

        function CreateClientCredentials: TMixiAPIToken;
        function RefreshToken(token: TMixiAPIToken): Boolean;
    end;

    ECreateTokenError = class(Exception);

const
    TOKEN_DESCRIPTION = 'This is the mixi Graph API Project';
    TOKEN_ENDPOINT    = 'https://secure.mixi-platform.com/2/token';
    HTTP_TIMEOUT      = 300;

implementation

function TMixiAPIToken.isExpired;
begin
    Result := FExpire < Now;
end;

procedure TMixiAPIToken.SaveToFile(Path: String);
var SL: TStringList;
begin
    SL := TStringList.Create;

    try
        SL.Add(Encrypt(
            CryptData(FAccessToken, TOKEN_DESCRIPTION)
        ));

        SL.Add(Encrypt(
            CryptData(FRefreshToken, TOKEN_DESCRIPTION)
        ));

        SL.Add(DateTimeToStr(FExpire));

        SL.SaveToFile(Path);
    finally
        SL.Free;
    end;
end;

procedure TMixiAPIToken.LoadFromFile(Path: String);
var SL: TStringList;
    cd: TCryptData;
begin
    SL := TStringList.Create;

    try
        SL.LoadFromFile(Path);

        if SL.Count < 3 then
            raise Exception.Create('Invalid File');

        cd := Decrypt(SL[0]);
        if Not( cd.Description = TOKEN_DESCRIPTION ) then
            raise Exception.Create('Invalid Access Token');
        FAccessToken  := cd.Data;

        cd := Decrypt(SL[1]);
        if Not( cd.Description = TOKEN_DESCRIPTION ) then
            raise Exception.Create('Invalid Refresh Token');
        FRefreshToken := cd.Data;

        FExpire       := StrToDateTime(SL[2]);
    finally
        SL.Free;
    end;
end;


constructor TMixiAPITokenFactory.Create(key, secret, redirect: String);
begin
    FConsumerKey    := key;
    FConsumerSecret := secret;
    FRedirectUrl    := redirect;

    FTokenContainer := TObjectList.Create;
end;

destructor TMixiAPITokenFactory.Destroy;
begin
    FTokenContainer.Free;
end;

function TMixiAPITokenFactory.CreateClientCredentials: TMixiAPIToken;
var req, res: TStringList;
    ms: TMemoryStream;
    json: ISuperObject;

    token: TMixiAPIToken;

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
        req.Values['grant_type']    := 'client_credentials';
        req.Values['client_id']     := FConsumerKey;
        req.Values['client_secret'] := FConsumerSecret;

        try
            //Self.Post(TOKEN_ENDPOINT, req, ms);
            UserAgent.Post(TOKEN_ENDPOINT, req, ms);
        except

        end;
        ms.Position := 0;

        res.LoadFromStream(ms);

        json := SO(res.Text);

        token := TMixiAPIToken.Create;
        token.AccessToken  := json['access_token'].AsString;
        token.RefreshToken := json['refresh_token'].AsString;
        token.Expire       := CalcExpire(json['expires_in'].AsInteger);
        token.TokenType    := json['token_type'].AsString;
        token.Scope        := json['scope'].AsString;

        FTokenContainer.Add(token);
        Result := token;
    finally
        req.Free;
        res.Free;
        ms.Free;
    end;
end;


function TMixiAPITokenFactory.RefreshToken(token: TMixiAPIToken): Boolean;
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
        req.Values['grant_type']    := 'refresh_token';
        req.Values['client_id']     := FConsumerKey;
        req.Values['client_secret'] := FConsumerSecret;
        req.Values['refresh_token'] := token.RefreshToken;

        try
            //Self.Post(TOKEN_ENDPOINT, req, ms);
            UserAgent.Post(TOKEN_ENDPOINT, req, ms);
        except
            on E: Exception do
            begin
                raise ECreateTokenError.Create(E.Message);
            end;
        end;
        ms.Position := 0;

        res.LoadFromStream(ms);

        json := SO(res.Text);

        token.AccessToken  := json['access_token'].AsString;
        token.RefreshToken := json['refresh_token'].AsString;
        token.Expire       := CalcExpire(json['expires_in'].AsInteger);
        token.TokenType    := json['token_type'].AsString;
        token.Scope        := json['scope'].AsString;
    finally
        req.Free;
        res.Free;
        ms.Free;
    end;

    Result := True;
end;


end.
