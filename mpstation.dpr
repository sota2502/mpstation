program mpstation;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Crypt in 'lib\Crypt.pas',
  HttpLib in 'lib\HttpLib.pas',
  IdSSLOpenSSLHeaders in 'lib\IdSSLOpenSSLHeaders.pas',
  MD5 in 'lib\MD5.PAS',
  Mixi in 'lib\Mixi.pas',
  superobject in 'lib\superobject.pas',
  superxmlparser in 'lib\superxmlparser.pas',
  MixiAPIToken in 'lib\MixiAPIToken.pas',
  MixiPage in 'lib\MixiPage.pas',
  MixiPageObserver in 'lib\MixiPageObserver.pas',
  Settings in 'Settings.pas';

{$R *.res}

begin
    Application.Initialize;
    Application.ShowMainForm := False;
    Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
