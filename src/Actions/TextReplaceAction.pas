unit TextReplaceAction;

interface

uses
  ActionObjekte;

const
  ParamSearch = 'search';
  ParamReplace = 'replace';
  ParamIgnoreCase = 'ignore-case';
  ParamRegEx = 'regex';

type
  TTextReplaceAction = class(TAction)
  strict private
    FSearch:      String;
    FReplace:     String;
    FIgnoreCase:  Boolean;
  protected
    procedure Options; override;
  public
    class function GetName: String; override;
    class function GetDescription: String; override;
  public
    constructor Create; override;
    procedure Execute; override;
  end;

implementation

uses
  System.SysUtils, System.RegularExpressions,
  ParameterObjekte;

{ TTextReplaceAction }

constructor TTextReplaceAction.Create;
begin
  inherited;
  AddOption(ParamSearch, 'TEXT', 'Text to search', [apoRequired]);
  AddOption(ParamReplace, 'TEXT', 'Text to replace', [apoRequired]);
  AddOption(ParamIgnoreCase, 'Replace text case insensitive', []);
  AddOption(ParamRegEx, 'Use regular expressions', []);
end;

class function TTextReplaceAction.GetDescription: String;
begin
  Result := 'Replace text';
end;

class function TTextReplaceAction.GetName: String;
begin
  Result := 'text::replace';
end;

procedure TTextReplaceAction.Execute;
var
  PasFile: TActionFile;
  SearchText: String;
  ReplaceText: String;
  ReplaceFlags: TReplaceFlags;
  RegExOptions: TRegExOptions;
  IsRegEx: Boolean;
begin
  inherited;
  SearchText := Parameters.GetValue(ParamSearch);
  ReplaceText := Parameters.GetValue(ParamReplace);
  IsRegEx := Parameters.IsOptionSet(ParamRegEx);

  ReplaceFlags := [rfReplaceAll];
  RegExOptions := [];
  if Parameters.IsOptionSet(ParamIgnoreCase) then
  begin
    ReplaceFlags := ReplaceFlags + [rfIgnoreCase];
    RegExOptions := RegExOptions + [roIgnoreCase];
  end;
  for PasFile in Files do
  begin
    if IsRegEx then
    begin
      PasFile.Content := TRegEx.Replace(PasFile.Content, SearchText, ReplaceText, RegExOptions);
    end else
    begin
      PasFile.Content := PasFile.Content.Replace(SearchText, ReplaceText, ReplaceFlags);
    end;
    if PasFile.HasChanged then
    begin
      writeln(PasFile.FileName);
      PasFile.Save;
    end;
  end;
end;

procedure TTextReplaceAction.Options;
begin
  inherited;
  FSearch := Parameters.GetValue('search');
  FReplace := Parameters.GetValue('replace');
  FIgnoreCase := Parameters.IsOptionSet('ignore-case');
end;

initialization
begin
  Actions.Add(TTextReplaceAction);
end;

finalization

end.
