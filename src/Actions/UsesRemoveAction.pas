unit UsesRemoveAction;

interface

uses
  System.Classes,
  ActionObjekte;

type
  TUsesRemoveAction = class(TAction)
  strict private
    UsesList: TStringList;
  protected
    procedure Options; override;
  public
    class function GetName: String; override;
    class function GetDescription: String; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Execute; override;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  ParameterObjekte;

{ TUsesRemoveAction }

constructor TUsesRemoveAction.Create;
begin
  inherited;
  UsesList := TStringList.Create;

  AddOption('unit', 'UNIT_NAME', 'Name of the unit to remove', [apoRequired, apoList]);
end;

destructor TUsesRemoveAction.Destroy;
begin
  FreeAndNil(UsesList);
  inherited;
end;

class function TUsesRemoveAction.GetDescription: String;
begin
  Result := 'Remove a unit from the uses';
end;

class function TUsesRemoveAction.GetName: String;
begin
  Result := 'uses::remove';
end;

procedure TUsesRemoveAction.Execute;

  function fctParseUses(const _sContent: String): String;
  type
    TCommentType = (ctNone, ctSingleLine, ctMultiLine);
  var
    sUses:        String;
    Pos:         Integer;
    CurrentChar:     Char;
    NextChar:        Char;
    CommentType:  TCommentType;
  begin
    sUses := EmptyStr;
    CommentType := ctNone;
    for Pos := 0 to _sContent.Length - 1 do
    begin
      CurrentChar := _sContent.Chars[Pos];
      if _sContent.Length > Pos + 1 then
      begin
        NextChar := _sContent.Chars[Pos + 1];
      end else
      begin
        NextChar := #0;
      end;
      if (CommentType = ctSingleLine)
      and (CurrentChar = #10) then
      begin
        CommentType := ctNone;
        Continue;
      end;
      if (CommentType = ctMultiLine)
      and (CurrentChar = '}') then
      begin
        CommentType := ctNone;
        Continue;
      end;

      if CommentType <> ctNone then
      begin
        Continue;
      end;
      if (CurrentChar = '/')
      and (NextChar = '/') then
      begin
        CommentType := ctSingleLine;
        Continue;
      end;
      if CurrentChar = '{' then
      begin
        CommentType := ctMultiLine;
        Continue;
      end;
      if CurrentChar = ';' then
      begin
        Break;
      end;
      sUses := sUses + CurrentChar;
    end;
    Result := sUses;
  end;

  procedure prcRemoveUses(var AUses: String; const AUnit: String);
  begin
    AUses := AUses.Replace(' ' + AUnit + ' ', EmptyStr, [rfReplaceAll, rfIgnoreCase]);
    AUses := AUses.Replace(' ' + AUnit + ',', EmptyStr, [rfReplaceAll, rfIgnoreCase]);
    AUses := AUses.Replace(',' + AUnit + ' ', EmptyStr, [rfReplaceAll, rfIgnoreCase]);
    AUses := AUses.Replace(' ' + AUnit + #13#10, #13#10, [rfReplaceAll, rfIgnoreCase]);
    if AUses.EndsWith(', ' + AUnit) then
    begin
      AUses := AUses.Substring(0, AUses.Length - (AUnit.Length + 2));
    end;
    if AUses.EndsWith(',' + AUnit) then
    begin
      AUses := AUses.Substring(0, AUses.Length - (AUnit.Length + 1));
    end;
  end;

var
  Parameter: TParameter;
  PasFile: TActionFile;
  InterfacePos: Integer;
  ImplementationPos: Integer;
  UsesPos: Integer;
  UsesSave: String;
  sUses: String;
  sUnit: String;
  Units: TList<String>;
begin
  inherited;
  Units := TList<String>.Create;
  try
    for Parameter in Parameters do
    begin
      if Parameter.IsOption
      and (Parameter.Name = 'unit') then
      begin
        Units.Add(Parameter.Value);
      end;
    end;
    for PasFile in Files do
    begin
      InterfacePos := PasFile.Content.IndexOf(#13#10'interface'#13#10);
      ImplementationPos := PasFile.Content.IndexOf(#13#10'implementation'#13#10);
      if InterfacePos <> -1 then
      begin
        UsesPos := PasFile.Content.IndexOf(#13#10'uses', InterfacePos, ImplementationPos - InterfacePos);
        if UsesPos <> -1 then
        begin
          sUses := fctParseUses(PasFile.Content.Substring(UsesPos + 6));
          UsesSave := sUses;
          for sUnit in Units do
          begin
            prcRemoveUses(sUses, sUnit);
            if sUses <> UsesSave then
            begin
              PasFile.Content := PasFile.Content.Replace(UsesSave, sUses, []);
            end;
          end;
        end;
      end;

      if ImplementationPos <> -1 then
      begin
        UsesPos := PasFile.Content.IndexOf(#13#10'uses', ImplementationPos);
        if UsesPos <> -1 then
        begin
          sUses := fctParseUses(PasFile.Content.Substring(UsesPos + 6));
          UsesSave := sUses;
          for sUnit in Units do
          begin
            prcRemoveUses(sUses, sUnit);
            if sUses <> UsesSave then
            begin
              PasFile.Content := PasFile.Content.Replace(UsesSave, sUses, []);
            end;
          end;
        end;
      end;
      if PasFile.HasChanged then
      begin
        PasFile.Save;
        writeln(PasFile.FileName);
      end;
    end;
  finally
    FreeAndNil(Units);
  end;
end;

procedure TUsesRemoveAction.Options;
begin
  inherited;
  Parameters.GetValues('unit', UsesList);
end;

initialization
begin
  Actions.Add(TUsesRemoveAction);
end;

finalization

end.
