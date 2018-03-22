unit UsesAddAction;

interface

uses
  System.Classes,
  ActionObjekte;

const
  ParamUnit = 'unit';
  ParamSection = 'section';

type
  TUsesAddAction = class(TAction)
  strict private
    FUses: TStringList;
    FSection: String;
    FSectionCondition: String;
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

{ TUsesAddAction }

constructor TUsesAddAction.Create;
begin
  inherited;
  FUses := TStringList.Create;

  AddOption('unit', 'UNIT_NAME', 'Name of the unit to add', [apoRequired, apoList]);
  AddOption('section', 'implementation|interface|auto', 'Section where the unit should be added to the uses', [apoRequired]);
  AddOption('section-condition', 'TEXT', 'Used in combination with section=auto. Defines the section where the given text is found', []);
end;

destructor TUsesAddAction.Destroy;
begin
  FreeAndNil(FUses);
  inherited;
end;

class function TUsesAddAction.GetDescription: String;
begin
  Result := 'Add a unit to the uses';
end;

class function TUsesAddAction.GetName: String;
begin
  Result := 'uses::add';
end;

procedure TUsesAddAction.Execute;

  function fctParseUses(const AContent: String): String;
  type
    TCommentType = (ctNone, ctSingleLine, ctMultiLine);
  var
    sUses: String;
    Pos: Integer;
    CurrentChar: Char;
    NextChar: Char;
    CommentType: TCommentType;
  begin
    sUses := EmptyStr;
    CommentType := ctNone;
    for Pos := 0 to AContent.Length - 1 do
    begin
      CurrentChar := AContent.Chars[Pos];
      if AContent.Length > Pos + 1 then
      begin
        NextChar := AContent.Chars[Pos + 1];
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

  procedure prcAddUses(var AUses: String; const AUnit: String);
  begin
    AUses := AUses + ', ' + AUnit;
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
  SectionSelected: String;
begin
  inherited;
  Units := TList<String>.Create;
  try
    for Parameter in Parameters do
    begin
      if Parameter.IsOption
      and (Parameter.Name = ParamUnit) then
      begin
        Units.Add(Parameter.Value);
      end;
    end;
    for PasFile in Files do
    begin
      InterfacePos := PasFile.Content.IndexOf(#13#10'interface'#13#10);
      ImplementationPos := PasFile.Content.IndexOf(#13#10'implementation'#13#10);

      if FSection = 'auto' then
      begin
        if PasFile.Content.IndexOf(FSectionCondition) < ImplementationPos then
        begin
          SectionSelected := 'interface';
        end else
        begin
          SectionSelected := 'implementation';
        end;
      end else
      begin
        SectionSelected := FSection;
      end;

      if (InterfacePos <> -1)
      and (SectionSelected = 'interface') then
      begin
        UsesPos := PasFile.Content.IndexOf(#13#10'uses', InterfacePos, ImplementationPos - InterfacePos);
        if UsesPos <> -1 then
        begin
          sUses := fctParseUses(PasFile.Content.Substring(UsesPos + 6));
          UsesSave := sUses;
          for sUnit in Units do
          begin
            prcAddUses(sUses, sUnit);
            if sUses <> UsesSave then
            begin
              PasFile.Content := PasFile.Content.Replace(UsesSave, sUses, []);
            end;
          end;
        end;
      end;

      if (ImplementationPos <> -1)
      and (SectionSelected = 'implementation') then
      begin
        UsesPos := PasFile.Content.IndexOf(#13#10'uses', ImplementationPos);
        if UsesPos <> -1 then
        begin
          sUses := fctParseUses(PasFile.Content.Substring(UsesPos + 6));
          UsesSave := sUses;
          for sUnit in Units do
          begin
            prcAddUses(sUses, sUnit);
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

procedure TUsesAddAction.Options;
begin
  inherited;
  Parameters.GetValues('unit', FUses);
  FSection := Parameters.GetValue('section');
  FSectionCondition := Parameters.GetValue('section-condition');
end;

initialization
begin
  Actions.Add(TUsesAddAction);
end;

finalization

end.
