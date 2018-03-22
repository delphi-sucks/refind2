unit TextSearchAction;

interface

uses
  ActionObjekte;

const
  ParamSearch = 'search';
  ParamIgnoreCase = 'ignore-case';
  ParamRegex = 'regex';

type
  TTextSearchAction = class(TAction)
  strict private
    FSearch: String;
    FIgnoreCase: Boolean;
    FRegEx: Boolean;
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
  System.SysUtils, System.Classes, System.RegularExpressions,
  ParameterObjekte;

{ TTextSearchAction }

constructor TTextSearchAction.Create;
begin
  inherited;
  AddOption('search', 'TEXT', 'Text to search', [apoRequired]);
  AddOption('ignore-case', 'Replace text case insensitive', []);
  AddOption('regex', 'Search the text as a regular expression', []);
end;

class function TTextSearchAction.GetDescription: String;
begin
  Result := 'Search for text';
end;

class function TTextSearchAction.GetName: String;
begin
  Result := 'text::search';
end;

procedure TTextSearchAction.Execute;
var
  i1: Integer;
  SearchText: String;
  Line: Integer;
  Offset: Integer;
  PasFile: TActionFile;
  FileWritten: Boolean;
  Count: Integer;
  RegEx: TRegEx;
  RegExOptions: TRegExOptions;
  Matches: TMatchCollection;
begin
  inherited;
  Count := 0;
  SearchText := Parameters.GetValue(ParamSearch);
  if Parameters.IsOptionSet(ParamRegex) then
  begin
    RegExOptions := [];
    if Parameters.IsOptionSet(ParamIgnoreCase) then
    begin
      RegExOptions := RegExOptions + [roIgnoreCase];
    end;
    RegEx := TRegEx.Create(SearchText, RegExOptions);
    for PasFile in Files do
    begin
      FileWritten := False;
      Offset := PasFile.Content.IndexOf(SearchText);
      Matches := RegEx.Matches(PasFile.Content);
      if Matches.Count > 0 then
      begin
        for i1 := 0 to Matches.Count - 1 do
        begin
          if Matches.Item[i1].Success then
          begin
            if not FileWritten then
            begin
              writeln(PasFile.FileName);
              FileWritten := True;
            end;
            Line := PasFile.Content.Substring(0, Matches.Item[i1].Index).CountChar(#10) + 1;
            writeln('  Line ' + Line.ToString + ': ...' + (PasFile.Content.Substring(Matches.Item[i1].Index - 10, 10 + Matches.Item[i1].Length + 10) + '...').Replace(#13#10, '~', [rfReplaceAll]));
            Inc(Count);
          end;
        end;
      end;

      while Offset <> -1 do
      begin
        if not FileWritten then
        begin
          writeln(PasFile.FileName);
          FileWritten := True;
        end;
        Line := PasFile.Content.Substring(0, Offset).CountChar(#10) + 1;
        writeln('  Line ' + Line.ToString + ': ...' + (PasFile.Content.Substring(Offset - 10, 10 + SearchText.Length + 10) + '...').Replace(#13#10, '~', [rfReplaceAll]));
        Inc(Count);
        Offset := PasFile.Content.IndexOf(SearchText, Offset + 1);
      end;
      if FileWritten then
      begin
        writeln(EmptyStr);
      end;
    end;
  end else
  begin
    for PasFile in Files do
    begin
      FileWritten := False;
      Offset := PasFile.Content.IndexOf(SearchText);
      while Offset <> -1 do
      begin
        if not FileWritten then
        begin
          writeln(PasFile.FileName);
          FileWritten := True;
        end;
        Line := PasFile.Content.Substring(0, Offset).CountChar(#10) + 1;
        writeln('  Line ' + Line.ToString + ': ...' + (PasFile.Content.Substring(Offset - 10, 10 + SearchText.Length + 10) + '...').Replace(#13#10, '~', [rfReplaceAll]));
        Inc(Count);
        Offset := PasFile.Content.IndexOf(SearchText, Offset + 1);
      end;
      if FileWritten then
      begin
        writeln(EmptyStr);
      end;
    end;
  end;
  writeln(Count.ToString + ' Found');
end;

procedure TTextSearchAction.Options;
begin
  inherited;
  FSearch := Parameters.GetValue('search');
  FIgnoreCase := Parameters.IsOptionSet('ignore-case');
  FRegEx := Parameters.IsOptionSet('regex');
end;

initialization
begin
  Actions.Add(TTextSearchAction);
end;

finalization

end.
