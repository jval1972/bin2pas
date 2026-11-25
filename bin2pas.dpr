program Bin2Pas;

uses
  Forms,
  main in 'main.pas' {Form1},
  b2p_core in 'b2p_core.pas',
  frm_PageSetup in 'SynEdit\frm_PageSetup.pas' {PageSetupDlg},
  frm_PrintPreview in 'SynEdit\frm_PrintPreview.pas' {ScriptPrintPreviewDlg},
  SynCompletionProposal in 'SynEdit\SynCompletionProposal.pas',
  SynEdit in 'SynEdit\SynEdit.pas',
  SynEditHighlighter in 'SynEdit\SynEditHighlighter.pas',
  SynEditHighlighterOptions in 'SynEdit\SynEditHighlighterOptions.pas',
  SynEditKbdHandler in 'SynEdit\SynEditKbdHandler.pas',
  SynEditKeyCmds in 'SynEdit\SynEditKeyCmds.pas',
  SynEditKeyConst in 'SynEdit\SynEditKeyConst.pas',
  SynEditMiscClasses in 'SynEdit\SynEditMiscClasses.pas',
  SynEditMiscProcs in 'SynEdit\SynEditMiscProcs.pas',
  SynEditPrint in 'SynEdit\SynEditPrint.pas',
  SynEditPrinterInfo in 'SynEdit\SynEditPrinterInfo.pas',
  SynEditPrintHeaderFooter in 'SynEdit\SynEditPrintHeaderFooter.pas',
  SynEditPrintMargins in 'SynEdit\SynEditPrintMargins.pas',
  SynEditPrintPreview in 'SynEdit\SynEditPrintPreview.pas',
  SynEditPrintTypes in 'SynEdit\SynEditPrintTypes.pas',
  SynEditRegexSearch in 'SynEdit\SynEditRegexSearch.pas',
  SynEditSearch in 'SynEdit\SynEditSearch.pas',
  SynEditStrConst in 'SynEdit\SynEditStrConst.pas',
  SynEditTextBuffer in 'SynEdit\SynEditTextBuffer.pas',
  SynEditTypes in 'SynEdit\SynEditTypes.pas',
  SynEditWordWrap in 'SynEdit\SynEditWordWrap.pas',
  SynHighlighterMulti in 'SynEdit\SynHighlighterMulti.pas',
  SynHighlighterPas in 'SynEdit\SynHighlighterPas.pas',
  SynRegExpr in 'SynEdit\SynRegExpr.pas',
  SynTextDrawer in 'SynEdit\SynTextDrawer.pas',
  SynUnicode in 'SynEdit\SynUnicode.pas',
  frm_message in 'frm_message.pas' {frmMessage},
  b2p_utils in 'b2p_utils.pas',
  b2p_options in 'b2p_options.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Binary to Pascal source converter';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPageSetupDlg, PageSetupDlg);
  Application.CreateForm(TScriptPrintPreviewDlg, ScriptPrintPreviewDlg);
  Application.Run;
end.
