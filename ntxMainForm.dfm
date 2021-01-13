object _ntxMainForm: TntxMainForm
  Left = 0
  Top = 0
  Caption = 'ntxMainForm'
  ClientHeight = 558
  ClientWidth = 889
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 409
    Width = 889
    Height = 3
    Cursor = crVSplit
    Align = alTop
    ExplicitWidth = 149
  end
  object pnlControls: TPanel
    Left = 0
    Top = 0
    Width = 889
    Height = 409
    Align = alTop
    Caption = 'pnlControls'
    TabOrder = 0
  end
  object memLog: TMemo
    Left = 0
    Top = 412
    Width = 889
    Height = 146
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'memLog')
    ParentFont = False
    TabOrder = 1
    ExplicitLeft = 280
    ExplicitTop = 418
    ExplicitWidth = 185
    ExplicitHeight = 89
  end
end
