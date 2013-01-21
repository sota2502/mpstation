unit MixiPageObserver;

interface

uses
    SysUtils, Classes, Contnrs, MixiPage, MixiAPIToken, HttpLib,
    superxmlparser, superobject;

const
    API_ENDPOINT    = 'http://api.mixi-platform.com/2';

type
    TObserveUpdates = class
    private
        FMessage: String;
        FIsRead: Boolean;
    public
        constructor Create(sMessage: String);

        property Message: String read FMessage;
        property IsRead: Boolean read FIsRead write FIsRead;
    end;

    TObserveEntry = class
    private
        FPageId: Cardinal;
        FPage: TMixiPage;
        FFeeds: TObjectList;
        FUpdates: TObjectList;

        function CallPageAPI(token: TMixiAPIToken): ISuperObject;
        function CallFeedsAPI(token: TMixiAPIToken): ISuperObject;
        procedure AddUpdate(message: String);
        function GetFeedByContentUri(Uri: String): TMixiPageFeed;
    public
        constructor Create(pageId: Cardinal);
        destructor Destroy; override;

        procedure Initialize(token: TMixiAPIToken);
        procedure Synchronize(token: TMixiAPIToken);

        property PageId: Cardinal read FPageId;
        property Page: TMixiPage read FPage;
        property Feeds: TObjectList read FFeeds;
        property Updates: TObjectList read FUpdates;
    end;

    TMixiPageObserver = class
    private
        FObserveList: TObjectList;
        FUpdates: TObjectList;
        FTokenFactory: TMixiAPITokenFactory;
        FToken: TMixiAPIToken;

        function GetToken: TMixiAPIToken;
    public
        constructor Create(key, secret: String; redirect: String = '');
        destructor Destroy; override;

        procedure Synchronize;

        procedure AddObserve(pageId: Cardinal);
        procedure RemoveObserve(pageId: Cardinal);

        property ObserveList: TObjectList read FObserveList;
        property Updates: TObjectList read FUpdates;
    end;

implementation

{
    TObserveUpdates
}

constructor TObserveUpdates.Create(sMessage: String);
begin
    FMessage := sMessage;
    IsRead   := False;
end;

{
    TObserveEntry
}

constructor TObserveEntry.Create(pageId: Cardinal);
begin
    FPageId  := pageId;
    FFeeds   := TObjectList.Create;
    FUpdates := TObjectList.Create;
end;

destructor TObserveEntry.Destroy;
begin
    FPage.Free;
    FFeeds.Free;
    FUpdates.Free;
end;

procedure TObserveEntry.Initialize(token: TMixiAPIToken);
var i, mx: Integer;
    feedJson: ISuperObject;
begin
    FPage := TMixiPage.Create(Self.CallPageAPI(token));

    feedJson := CallFeedsAPI(token);
    mx := feedJson['entry'].AsArray.Length - 1;
    for i := 0 to mx do
    begin
        FFeeds.Add(
            TMixiPageFeed.Create(feedJson['entry'].AsArray.O[i])
        );
    end;
end;

procedure TObserveEntry.Synchronize(token: TMixiAPIToken);
var i, mx: Integer;
    json, feedJson: ISuperObject;
    feed: TMixiPageFeed;
begin
    FUpdates.Clear;

    //page
    json := CallPageAPI(token);
    if ( FPage.HasUpdates(json) ) then
    begin
        AddUpdate(FPage.GetUpdateMessage(json));
        FPage.Update(json);
    end;

    //feeds
    json := CallFeedsAPI(token);
    mx := json['entry'].AsArray.Length - 1;
    for i := 0 to mx do
    begin
        feedJson := json['entry'].AsArray.O[i];
        feed := GetFeedByContentUri(feedJson['contentUri'].AsString);
        if ( feed = nil ) then Continue;

        if feed.HasUpdates(feedJson) then
            AddUpdate(feed.GetUpdateMessage(feedJson));
    end;

    FFeeds.Clear;
    for i := 0 to mx do
    begin
        feedJson := json['entry'].AsArray.O[i];
        Feeds.Add(
            TMixiPageFeed.Create(feedJson)
        );
    end;
end;

function TObserveEntry.CallPageAPI(token: TMixiAPIToken): ISuperObject;
var endpoint, response: String;
begin
    endpoint := Format(
        '%s/pages/%d?access_token=%s',
        [API_ENDPOINT, FPageId, token.AccessToken]
    );

    response := UserAgent.Get(endpoint);
    Result := SO(Utf8ToAnsi(response));
end;

function TObserveEntry.CallFeedsAPI(token: TMixiAPIToken): ISuperObject;
var endpoint, response: String;
    json: ISuperObject;
    ua: TUserAgent;
begin
    ua := TUserAgent.Create;
    try
        endpoint := Format(
            '%s/pages/%d/feeds?access_token=%s',
            [API_ENDPOINT, FPageId, token.AccessToken]
        );

        response := ua.Get(endpoint);
    finally
        ua.Free;
    end;
    json := SO(Utf8ToAnsi(response));
    Result := json;
end;

function TObserveEntry.GetFeedByContentUri(Uri: String): TMixiPageFeed;
var i, mx: Integer;
    feed: TMixiPageFeed;
begin
    Result := nil;
    mx := FFeeds.Count - 1;
    for i := 0 to mx do
    begin
        feed := TMixiPageFeed(FFeeds[i]);
        if ( feed.ContentUri = Uri ) then
        begin
            Result := feed;
            Exit;
        end;
    end;
end;

procedure TObserveEntry.AddUpdate(message: String);
begin
    FUpdates.Add(
        TObserveUpdates.Create(message)
    );
end;

{
    TMixiPageObserver
}

constructor TMixiPageObserver.Create(key, secret, redirect: String);
begin
    FObserveList  := TObjectList.Create;
    FTokenFactory := TMixiAPITokenFactory.Create(key, secret, redirect);
    FToken        := nil;
    FUpdates      := TObjectList.Create(False);
end;

destructor TMixiPageObserver.Destroy;
begin
    FObserveList.Free;
    FTokenFactory.Free;
    FUpdates.Free;
end;

procedure TMixiPageObserver.Synchronize;
var token: TMixiAPIToken;
    entry: TObserveEntry;
    i, mx: Integer;

    procedure CopyUpdates;
    var i, mx: Integer;
    begin
        mx := entry.Updates.Count - 1;
        for i := 0 to mx do
            FUpdates.Add(entry.Updates[i]);
    end;
begin
    mx := FObserveList.Count - 1;
    FUpdates.Clear;
    for i := 0 to mx do
    begin
        token := GetToken;

        entry := TObserveEntry(FObserveList[i]);
        try
            entry.Synchronize(token);

            if entry.Updates.Count > 0 then
                CopyUpdates;
        except

        end;
    end;

end;


procedure TMixiPageObserver.AddObserve(pageId: Cardinal);
var entry: TObserveEntry;
begin
    entry := TObserveEntry.Create(pageId);
    entry.Initialize(GetToken);
    FObserveList.Add(entry);
end;

procedure TMixiPageObserver.RemoveObserve(pageId: Cardinal);
var i, mx: Integer;
begin
    mx := FObserveList.Count - 1;
    for i := 0 to mx do
    begin
        if TObserveEntry(FObserveList[i]).PageId = pageId then
        begin
            FObserveList.Delete(i);
        end;
    end;
end;

function TMixiPageObserver.GetToken: TMixiAPIToken;
begin
    if FToken = nil then
    begin
        FToken := FTokenFactory.CreateClientCredentials;
        Result := FToken;
        Exit;
    end;

    if FToken.isExpired then
    begin
        if Not(FTokenFactory.RefreshToken(FToken)) then
        begin
            FToken := FTokenFactory.CreateClientCredentials;
        end;
    end;

    Result := FToken;
end;


end.
