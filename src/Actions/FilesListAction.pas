unit FilesListAction;

interface

uses
  ActionObjekte;

type
  TFilesListAction = class(TAction)
  public
    class function GetName: String; override;
    class function GetDescription: String; override;
  public
    procedure Execute; override;
  end;

implementation

uses
  System.SysUtils;

{ TFilesListAction }

class function TFilesListAction.GetDescription: String;
begin
  Result := 'List the matching files';
end;

class function TFilesListAction.GetName: String;
begin
  Result := 'files::list';
end;

procedure TFilesListAction.Execute;
var
  ActionFile: TActionFile;
begin
  inherited;
  for ActionFile in Files do
  begin
    writeln(ActionFile.FileName);
  end;
  writeln(EmptyStr);
  writeln(Files.Count.ToString + ' Found');
end;

initialization
begin
  Actions.Add(TFilesListAction);
end;

finalization

end.
