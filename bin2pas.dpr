program Bin2Pas;

uses
  Forms,
  main in 'main.pas' {Form1},
  b2p_core in 'b2p_core.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Binary to Pascal source converter';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
