unit MixiPage;

interface

uses
    Classes, SysUtils, Crypt, superxmlparser, superobject;

type
    TMixiContent = class
    public
        constructor Create(json: ISuperObject);

        function HasUpdates(json: ISuperObject): Boolean; virtual;
        function GetUpdateMessage(json: ISuperObject): String; virtual;
        procedure Update(json: ISuperObject); virtual;
    end;

    TMixiPage = class(TMixiContent)
    private
        FId: Cardinal;
        FName: String;
        FDetails: String;
        FFollowerCount: Cardinal;
    public
        function HasUpdates(json: ISuperObject): Boolean; override;
        function GetUpdateMessage(json: ISuperObject): String; override;
        procedure Update(json: ISuperObject); override;

        property Id: Cardinal read FId;
        property Name: String read FName;
        property Details: String read FDetails;
        property FollowerCount: Cardinal read FFollowerCount;
    end;

    TMixiPageFeed = class(TMixiContent)
    private
        FContentUri: String;
        FTitle: String;
        FBody: String;
        FPCUrl: String;
        FMobileUrl: String;
        FSmartphoneUrl: String;
        FFavoriteCount: Cardinal;
        FCommentCount: Cardinal;
    public
        function HasUpdates(json: ISuperObject): Boolean; override;
        function GetUpdateMessage(json: ISuperObject): String; override;
        procedure Update(json: ISuperObject); override;

        property ContentUri: String read FContentUri;
        property Title: String read FTitle;
        property Body: String read FBody;
        property PCUrl: String read FPCUrl;
        property MobileUrl: String read FMobileUrl;
        property SmartphoneUrl: String read FSmartphoneUrl;
        property FavoriteCoiunt: Cardinal read FFavoriteCount;
        property CommentCount: Cardinal read FCommentCount;
    end;

implementation

{
    TMixiContent
}

// 継承先でoverrideしない限りはfalse
constructor TMixiContent.Create(json: ISuperObject);
begin
    Self.Update(json);
end;

function TMixiContent.HasUpdates(json: ISuperObject): Boolean;
begin
    Result := False;
end;

function TMixiContent.GetUpdateMessage(json: ISuperObject): String;
begin
    Result := '';
end;

procedure TMixiContent.Update(json: ISuperObject);
begin

end;

{
    TMixiPage
}

function TMixiPage.HasUpdates(json: ISuperObject): Boolean;
begin
    Result := json['entry.followerCount'].AsInteger > FFollowerCount;
end;

function TMixiPage.GetUpdateMessage(json: ISuperObject): String;
begin
    Result := Format(
        'フォロワーが%d人 増えました',
        [json['entry.followerCount'].AsInteger - FFollowerCount]
    );
end;

procedure TMixiPage.Update(json: ISuperObject);
begin
    Fid            := json['entry.id'].AsInteger;
    FName          := json['entry.displayName'].AsString;
    FDetails       := json['entry.details'].AsString;
    FFollowerCount := json['entry.followerCount'].AsInteger;
end;


{
    TMixiPageFeed
}

function TMixiPageFeed.HasUpdates(json: ISuperObject): Boolean;
begin
    Result := False;
    if ( json['favoriteCount'].AsInteger > FFavoriteCount ) then
        Result := True;
    if ( json['commentCount'].AsInteger > FCommentCount ) then
        Result := True;
end;

function TMixiPageFeed.GetUpdateMessage(json: ISuperObject): String;
var favoriteDiff, commentDiff: Integer;
begin
    favoriteDiff := json['favoriteCount'].AsInteger - FFavoriteCount;
    commentDiff  := json['commentCount'].AsInteger - FCommentCount;

    Result := '';
    if ( (favoriteDiff = 0) and (commentDiff = 0) ) then Exit;

    if ( favoriteDiff > 0 ) then
        Result := Result + Format('イイネ%d件 ', [favoriteDiff]);
    if ( commentDiff > 0 ) then
        Result := Result + Format('コメント%d件 ', [commentDiff]);

    Result := Result + 'がつきました';
end;

procedure TMixiPageFeed.Update(json: ISuperObject);
begin
    FContentUri    := json['contentUri'].AsString;
    FTitle         := json['title'].AsString;
    FBody          := json['body'].AsString;
    FPCUrl         := json['urls.pcUrl'].AsString;
    FMobileUrl     := json['urls.mobileUrl'].AsString;
    FSmartphoneUrl := json['urls.smartphoneUrl'].AsString;
    FFavoriteCount := json['favoriteCount'].AsInteger;
    FCommentCount  := json['commentCount'].AsInteger;
end;


end.
