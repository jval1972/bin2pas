unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Menus, StdCtrls, SynEdit, SynHighlighterPas, Buttons;

type
  TPascalSynEdit = class(TSynEdit)
  private
    funitname: string;
    function GetSaveFileName(const fn: string): string;
    procedure SetUnitName(const fn: string);
  public
    property unitname: string read funitname write funitname;
    procedure DoSave;
  end;

type
  TForm1 = class(TForm)
    ToolbarPanel: TPanel;
    BackPanel: TPanel;
    LeftPanel: TPanel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Open1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    SaveAs1: TMenuItem;
    N2: TMenuItem;
    Clear1: TMenuItem;
    Panel1: TPanel;
    ListBox1: TListBox;
    PreviewPanel: TPanel;
    Panel2: TPanel;
    Help1: TMenuItem;
    About1: TMenuItem;
    EditorPanel: TPanel;
    OpenDialog1: TOpenDialog;
    ClearButton1: TSpeedButton;
    OpenButton1: TSpeedButton;
    SaveAsButton1: TSpeedButton;
    AboutButton1: TSpeedButton;
    ExitButton1: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure OpenButton1Click(Sender: TObject);
    procedure AboutButton1Click(Sender: TObject);
    procedure ExitButton1Click(Sender: TObject);
    procedure Clear1Click(Sender: TObject);
    procedure ClearButton1Click(Sender: TObject);
  private
    { Private declarations }
    SynPasSyn1: TSynPasSyn;
    SynEdit1: TPascalSynEdit;
    Files: TStringList;
    procedure ActionAbout;
    procedure ActionOpen;
    procedure ActionClose;
    procedure ActionClear;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  b2p_core, b2p_utils, frm_message;

const
  rsTitle = 'Binary to Pascal';
    
function TPascalSynEdit.GetSaveFileName(const fn: string): string;
begin
  Result := fn + '.pas';
end;

procedure TPascalSynEdit.SetUnitName(const fn: string);
var
  lst: TStringList;
begin
  if funitname <> fn then
  begin
    if not ReadOnly then
    begin
      if funitname <> '' then
      begin
        lst := TStringList.Create;
        lst.Text := Text;
        lst.SaveToFile(GetSaveFileName(funitname));
        lst.Free;
      end;
    end;
    lst := TStringList.Create;
    if FileExists(GetSaveFileName(fn)) then
      lst.LoadFromFile(GetSaveFileName(fn));
    Text := lst.Text;
    lst.Free;
    funitname := fn;
  end;
end;

procedure TPascalSynEdit.DoSave;
var
  lst: TStringList;
begin
  if not ReadOnly then
    if funitname <> '' then
    begin
      lst := TStringList.Create;
      lst.Text := Text;
      lst.SaveToFile(GetSaveFileName(funitname));
      lst.Free;
    end;
end;

//==============================================================================

procedure TForm1.FormCreate(Sender: TObject);
begin
  SynEdit1 := TPascalSynEdit.Create(Self);
  SynEdit1.Parent := EditorPanel;
  SynEdit1.Align := alClient;
  SynEdit1.Highlighter := nil;
  SynEdit1.Gutter.ShowLineNumbers := True;
  SynEdit1.Gutter.AutoSize := True;
  SynEdit1.MaxScrollWidth := 255;
  SynEdit1.WantTabs := True;
  SynEdit1.unitname := '';

  SynPasSyn1 := TSynPasSyn.Create(Self);

  SynEdit1.Highlighter := SynPasSyn1;
  SynEdit1.ReadOnly := True;

  Files := TStringList.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Files.Free;
end;

procedure TForm1.ActionAbout;
begin
  FRMMessage(
    Format(
      '%s'#13#10'Version ' + I_VersionBuilt +
      #13#10#13#10'A tool for converting binary files to Pascal code.'#13#10'© 2026, jvalavanis@gmail.com',
      [rsTitle]));
end;

procedure TForm1.ActionOpen;
var
  i: Integer;
begin
  if OpenDialog1.Execute then
  begin
    Screen.Cursor := crHourGlass;

    try
      Files.Clear;
      SynEdit1.Clear;
      ListBox1.Clear;

      for i := 0 to OpenDialog1.Files.Count - 1 do
      begin
        b2p_create_unit(OpenDialog1.Files.Strings[i], '', B2PF_ZIP);
        Files.Add(OpenDialog1.Files.Strings[i]);
      end;

      for i := 0 to Files.Count - 1 do
        ListBox1.Items.Add(ExtractFileName(Files.Strings[i]));
        
    finally
      Screen.Cursor := crDefault;
    end;

    DoChangeFile(0);
  end;
end;

procedure TForm1.ActionClose;
begin
  Close;
end;

procedure TForm1.ActionClear;
begin
  SynEdit1.Clear;
  Files.Clear;
  ListBox1.ItemIndex := -1;
  ListBox1.Items.Clear;
end;

procedure TForm1.ActionChangeFile(const id: Integer);
const
  MAXLINES = 100000;
var
  lst: TStringList;
  cnt: Integer;
  srcfilename: string;
begin
  if (id < 0) or (id >= ListBox1.Items.Count) then
  begin
    SynEdit1.Clear;
    Exit;
  end;

  ListBox1.ItemIndex := id;

  srcfilename := IncludeTrailingPathDelimiter(ExtractFilePath(Files.Strings[id])) + b2p_pascalname(ChangeFileExt(ListBox1.Items.Strings[id], '.pas'));
  if not FileExists(srcfilename) then
  begin
    SynEdit1.Text := 'File "' + srcfilename + '" not found!';
    Exit;
  end;

  Screen.Cursor := crHourGlass;

  lst := TStringList.Create;
  try
    lst.LoadFromFile(srcfilename);

    cnt := lst.Count;
    if lst.Count > MAXLINES then
    begin
      while lst.Count > MAXLINES do
        lst.Delete(lst.Count - 1);
      lst.Add('');
      lst.Add(Format('// File trunccated - Showning %d of %d lines', [MAXLINES, cnt]));
    end;

    SynEdit1.Text := lst.Text;
  finally
    lst.Free;
  end;

  Screen.Cursor := crDefault;
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
  ActionOpen;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
begin
    DoChangeFile(ListBox1.ItemIndex);
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  ActionClose;
end;

procedure TForm1.About1Click(Sender: TObject);
begin
  ActionAbout;
end;

procedure TForm1.OpenButton1Click(Sender: TObject);
begin
  ActionOpen;
end;

procedure TForm1.AboutButton1Click(Sender: TObject);
begin
  ActionAbout;
end;

procedure TForm1.ExitButton1Click(Sender: TObject);
begin
  ActionClose;
end;

procedure TForm1.Clear1Click(Sender: TObject);
begin
  ActionClear;
end;

procedure TForm1.ClearButton1Click(Sender: TObject);
begin
  ActionClear;
end;

end.
