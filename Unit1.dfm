object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'mixiPageStation'
  ClientHeight = 35
  ClientWidth = 311
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = InitializeExecute
  OnDestroy = FinalizeExecute
  PixelsPerInch = 96
  TextHeight = 13
  object ListBox1: TListBox
    Left = 0
    Top = 0
    Width = 311
    Height = 35
    Align = alClient
    BevelEdges = []
    BevelInner = bvNone
    BevelOuter = bvNone
    Color = clInfoBk
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemHeight = 19
    ParentFont = False
    TabOrder = 0
  end
  object TrayIcon1: TTrayIcon
    Animate = True
    PopupMenu = PopupMenu1
    Visible = True
    OnClick = ShowFormExecute
    Left = 320
    Top = 232
  end
  object PopupMenu1: TPopupMenu
    Left = 320
    Top = 192
    object MenuCheckUpdates: TMenuItem
      Action = CheckUpdates
    end
    object MenuClose: TMenuItem
      Action = CloseForm
    end
  end
  object ActionList1: TActionList
    Left = 320
    Top = 152
    object ShowForm: TAction
      Caption = #34920#31034#12377#12427
      OnExecute = ShowFormExecute
    end
    object CloseForm: TAction
      Caption = #38281#12376#12427
      OnExecute = CloseFormExecute
    end
    object Initialize: TAction
      Caption = #21021#26399#21270
      OnExecute = InitializeExecute
    end
    object Finalize: TAction
      Caption = #32066#20102
      OnExecute = FinalizeExecute
    end
    object CheckUpdates: TAction
      Caption = #26356#26032#12398#12481#12455#12483#12463
      OnExecute = CheckUpdatesExecute
    end
  end
  object Timer1: TTimer
    Interval = 60000
    OnTimer = CheckUpdatesExecute
    Left = 280
    Top = 8
  end
end
