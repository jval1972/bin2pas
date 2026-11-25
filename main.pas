unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Menus, StdCtrls, SynEdit, SynHighlighterPas, Buttons;

type
  TPascalSynEdit = class(TSynEdit);

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
    ClearButton1: TSpeedButton;
    OpenButton1: TSpeedButton;
    SaveAsButton1: TSpeedButton;
    AboutButton1: TSpeedButton;
    ExitButton1: TSpeedButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Timer1: TTimer;
    Panel3: TPanel;
    GroupBox1: TGroupBox;
    CompressionCheckBox: TCheckBox;
    PackedCheckBox: TCheckBox;
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
    procedure SaveAsButton1Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure File1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure CompressionCheckBoxClick(Sender: TObject);
    procedure PackedCheckBoxClick(Sender: TObject);
  private
    { Private declarations }
    SynPasSyn1: TSynPasSyn;
    SynEdit1: TPascalSynEdit;
    Files: TStringList;
    procedure ActionAbout;
    procedure ActionOpen;
    procedure ActionClose;
    procedure ActionClear;
    procedure ActionSaveAs;
    procedure ActionUpdateControls;
    procedure ActionBuildFiles;
    procedure ActionChangeFile(const id: Integer);
    procedure DefaultsToControls;
    procedure ControlsToDefaults;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  b2p_core, b2p_utils, b2p_options, frm_message;

const
  rsTitle = 'Binary to Pascal';

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

  SynPasSyn1 := TSynPasSyn.Create(Self);

  SynEdit1.Highlighter := SynPasSyn1;
  SynEdit1.ReadOnly := True;

  Files := TStringList.Create;

  LoadDefaults(ChangeFileExt(ParamStr(0), '.ini'));
  DefaultsToControls;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  ControlsToDefaults;
  SaveDefaults(ChangeFileExt(ParamStr(0), '.ini'));
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
      for i := 0 to OpenDialog1.Files.Count - 1 do
        Files.Add(OpenDialog1.Files.Strings[i]);

      SynEdit1.Clear;
      ListBox1.Clear;

      ActionBuildFiles;

      for i := 0 to Files.Count - 1 do
        ListBox1.Items.Add(ExtractFileName(Files.Strings[i]));
        
    finally
      Screen.Cursor := crDefault;
    end;

    ActionChangeFile(0);
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

procedure TForm1.ActionSaveAs;
const
  MAX_CHECK = 10;
var
  uname, line: string;
  i, j, p: Integer;
  lst: TStringList;
  lunit: Integer;
begin
  if SynEdit1.Lines.Count = 0 then
    Exit;

  uname := '';
  lunit := -1;

  for i := 0 to MAX_CHECK - 1 do
  begin
    if i = SynEdit1.Lines.Count then
      Break;

    line := AnsiString(SynEdit1.Lines.Strings[i]);
    if Pos('UNIT ', UpperCase(line)) = 1 then
    begin
      for j := 5 to Length(line) do
      begin
        if (line[j] in ABC_CHARS) or (line[j] in NUM_CHARS) or (line[j] = '_') then
          uname := uname + line[j]
        else if (line[j] = ' ') and (uname = '') then
        else
          Break;
      end;
      if uname <> '' then
        if uname[1] in NUM_CHARS then
          uname := '_' + uname;

      lunit := i;
      Break;
    end;
  end;

  if uname <> '' then
    uname := uname + '.pas';

  SaveDialog1.FileName := uname;

  if SaveDialog1.Execute then
  begin
    lst := TStringList.Create;
    try
      lst.Text := AnsiString(SynEdit1.Text);

      if (lunit >= 0) and (lunit < lst.Count) then
        if UpperCase(ExtractFileName(SaveDialog1.FileName)) <> UpperCase(uname) then
          if Pos('UNIT ', UpperCase(lst.Strings[lunit])) = 1 then
          begin
            uname := ExtractFileName(SaveDialog1.FileName);
            p := Pos('.', uname);
            if p > 0 then
              SetLength(uname, p - 1);
            if uname <> '' then
              lst.Strings[lunit] := Format('unit %s;', [b2p_pascalname(uname)]);
          end;

      backupfile(SaveDialog1.FileName);
      lst.SaveToFile(SaveDialog1.FileName);
    finally
      lst.Free;
    end;
  end;
end;

procedure TForm1.ActionUpdateControls;
begin
  SaveAs1.Enabled := SynEdit1.Lines.Count > 0;
  SaveAsButton1.Enabled := SynEdit1.Lines.Count > 0;
end;

procedure TForm1.ActionBuildFiles;
var
  i: Integer;
  flags: LongWord;
begin
  flags := 0;
  if CompressionCheckBox.Checked then
    flags := flags or B2PF_ZIP;
  if PackedCheckBox.Checked then
    flags := flags or B2PF_PACKED;

  for i := 0 to Files.Count - 1 do
    b2p_create_unit(Files.Strings[i], '', flags);
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
  if UpperCase(srcfilename) = UpperCase(Files.Strings[id]) then
    srcfilename := IncludeTrailingPathDelimiter(ExtractFilePath(Files.Strings[id])) + b2p_pascalname(ChangeFileExt(ListBox1.Items.Strings[id], '')) + '_unit.pas';

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
      lst.Add(Format('// File truncated - Showning %d of %d lines', [MAXLINES, cnt]));
    end;

    SynEdit1.Text := lst.Text;
  finally
    lst.Free;
  end;

  Screen.Cursor := crDefault;
end;

procedure TForm1.DefaultsToControls;
begin
  CompressionCheckBox.Checked := optUseCompression;
  PackedCheckBox.Checked := optUsePackedArrays;
end;

procedure TForm1.ControlsToDefaults;
begin
  optUseCompression := CompressionCheckBox.Checked;
  optUsePackedArrays := PackedCheckBox.Checked;
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
  ActionOpen;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
begin
  ActionChangeFile(ListBox1.ItemIndex);
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

procedure TForm1.SaveAsButton1Click(Sender: TObject);
begin
  ActionSaveAs;
end;

procedure TForm1.SaveAs1Click(Sender: TObject);
begin
  ActionSaveAs;
end;

procedure TForm1.File1Click(Sender: TObject);
begin
  ActionUpdateControls;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  ActionUpdateControls;
end;

procedure TForm1.CompressionCheckBoxClick(Sender: TObject);
begin
  ControlsToDefaults;

  Screen.Cursor := crHourGlass;
  try
    ActionBuildFiles;
  finally
    Screen.Cursor := crDefault;
  end;

  ActionChangeFile(ListBox1.ItemIndex);
end;

procedure TForm1.PackedCheckBoxClick(Sender: TObject);
begin
  ControlsToDefaults;

  Screen.Cursor := crHourGlass;
  try
    ActionBuildFiles;
  finally
    Screen.Cursor := crDefault;
  end;

  ActionChangeFile(ListBox1.ItemIndex);
end;

end.
