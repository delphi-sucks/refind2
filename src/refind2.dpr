program refind2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Generics.Collections,
  ParameterObjekte in 'ParameterObjekte.pas',
  ActionObjekte in 'ActionObjekte.pas',
  FilesListAction in 'Actions\FilesListAction.pas',
  TestEncodingAction in 'Actions\TestEncodingAction.pas',
  TextReplaceAction in 'Actions\TextReplaceAction.pas',
  TextSearchAction in 'Actions\TextSearchAction.pas',
  UsesAddAction in 'Actions\UsesAddAction.pas',
  UsesRemoveAction in 'Actions\UsesRemoveAction.pas';

{$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED}
{$IFOPT D-}{$WEAKLINKRTTI ON}{$ENDIF}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

var
  sAction: String;
  objParameter: TParameter;
  classAction: TActionClass;
  Action: TAction;
  sHelp: String;
begin
  Action := TAction.Create;
  sAction := EmptyStr;
  try
    if Parameters.Count = 0 then
    begin
      Writeln(Action.GetHelp);
    end else
    begin
      objParameter := Parameters.Items[0];
      if objParameter.IsOption then
      begin
        raise Exception.Create('First argument must be the action!');
      end;
      if Actions.TryGetValue(objParameter.Value, classAction) then
      begin
        sAction := objParameter.Value;

        FreeAndNil(Action);
        Action := classAction.Create;
        sHelp := Action.GetHelp;
        Action.Execute;
      end else
      begin
        raise Exception.Create('unknown action "' + objParameter.Value + '"!');
      end;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message + #13#10);
      Writeln(Action.GetHelp);
    end;
  end;
end.
