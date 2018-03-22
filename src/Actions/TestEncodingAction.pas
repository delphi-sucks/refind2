unit TestEncodingAction;

interface

uses
  ActionObjekte;

type
  TTestEncodingAction = class(TAction)
  public
    class function GetName: String; override;
    class function GetDescription: String; override;
  public
    procedure Execute; override;
  end;

implementation

uses
  System.SysUtils;

{ TTestEncodingAction }

class function TTestEncodingAction.GetDescription: String;
begin
  Result := 'Test the encoding of refind2 by loading and saving the matching files';
end;

class function TTestEncodingAction.GetName: String;
begin
  Result := 'test::encoding';
end;

procedure TTestEncodingAction.Execute;
var
  PasFile: TActionFile;
begin
  inherited;
  for PasFile in Files do
  begin
    writeln(PasFile.FileName);
    PasFile.Save;
  end;
end;

initialization
begin
  Actions.Add(TTestEncodingAction);
end;

finalization

end.
