program BmpHViewer;

uses
  Forms,
  Unit1 in 'Unit1.pas' {frmBmpHView};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmBmpHView, frmBmpHView);
  Application.Run;
end.
