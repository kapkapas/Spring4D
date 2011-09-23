unit frmObserverPattern;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, uObserverDemo;

type
  TForm28 = class(TForm)
    Timer1: TTimer;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FEditorMonitor: TEditorMonitor;
  end;

var
  Form28: TForm28;

implementation

{$R *.dfm}

procedure TForm28.FormCreate(Sender: TObject);
begin
  FEditorMonitor := TEditorMonitor.Create;

  FEditorMonitor.AddListener(TCurrentTimeEditUpdater.Create(Edit1));
  FEditorMonitor.AddListener(TTickTimeEditUpdater.Create(Edit2));
end;

procedure TForm28.FormDestroy(Sender: TObject);
begin
  FEditorMonitor.Free;
end;

procedure TForm28.Timer1Timer(Sender: TObject);
var
  UpdateProc: TProc<TEditUpdater>;
begin
  UpdateProc := procedure(aEditUpdater: TEditUpdater)
                begin
                  aEditUpdater.Update;
                end;

  FEditorMonitor.NotifyListeners(UpdateProc);
end;

end.
