unit Unit1;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, ExtCtrls, ActnList, Menus, StdCtrls, MixiPageObserver, Settings;

const
    SAVE_FILE = 'pages.txt';

type
    TForm1 = class(TForm)
        TrayIcon1: TTrayIcon;
        PopupMenu1: TPopupMenu;
        MenuClose: TMenuItem;
        ActionList1: TActionList;
        CloseForm: TAction;
        ShowForm: TAction;
        ListBox1: TListBox;
        Initialize: TAction;
        Finalize: TAction;
        CheckUpdates: TAction;
    MenuCheckUpdates: TMenuItem;
        Timer1: TTimer;
        procedure CloseFormExecute(Sender: TObject);
        procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
        procedure ShowFormExecute(Sender: TObject);
        procedure InitializeExecute(Sender: TObject);
        procedure FinalizeExecute(Sender: TObject);
    procedure CheckUpdatesExecute(Sender: TObject);
    private
        FObserver: TMixiPageObserver;
  end;

var
    Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.CheckUpdatesExecute(Sender: TObject);
var i: Integer;
    updates: TObserveUpdates;
begin
    FObserver.Synchronize;

    ListBox1.Clear;
    if FObserver.Updates.Count = 0 then
    begin
        ListBox1.Items.Add('çXêVÇÕÇ†ÇËÇ‹ÇπÇÒ');
    end
    else
    begin
        for i := 0 to FObserver.Updates.Count - 1 do
        begin
            updates := TObserveUpdates(FObserver.Updates[i]);
            ListBox1.Items.Add(updates.Message);
        end;
    end;

    Self.ClientWidth := ListBox1.Width;
    Self.ClientHeight := Listbox1.Height;

    ShowForm.Execute;
end;

procedure TForm1.CloseFormExecute(Sender: TObject);
begin
    Application.Terminate;
end;

procedure TForm1.FinalizeExecute(Sender: TObject);
begin
    FObserver.Free;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    if Sender = Self then
    begin
        CanClose := False;
        Self.Hide;
        Exit;
    end;
end;

procedure TForm1.InitializeExecute(Sender: TObject);
var i, pageId: Integer;
    SL: TStringList;
begin
    FObserver := TMixiPageObserver.Create(CONSUMER_KEY, CONSUMER_SECRET);

    SL := TStringList.Create;
    try
        SL.LoadFromFile(SAVE_FILE);
        for i := 0 to SL.Count - 1 do
        begin
            pageId := StrToIntDef(SL[i], 0);
            if pageId = 0 then Continue;

            FObserver.AddObserve(pageId);
        end;
    finally
        SL.Free;
    end;

    FObserver.Synchronize;
end;

procedure TForm1.ShowFormExecute(Sender: TObject);
var rect: TRect;
begin
    SystemParametersInfo(SPI_GETWORKAREA, 0, @rect, 0);

    Self.Show;
    Self.Left := rect.Right - Self.Width;
    Self.Top  := rect.Bottom - Self.Height;
end;

end.
