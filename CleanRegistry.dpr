program CleanRegistry;

uses
  ExceptionLog,
  Forms,
  ufrmMain in 'ufrmMain.pas' {frmMain},
  ufrmRegFoundList in 'ufrmRegFoundList.pas' {frmRegFoundList};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
