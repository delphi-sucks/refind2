unit ParameterObjekte;

interface

uses
  System.Generics.Collections, System.Classes;

const
  cParam_Test = 'test';
  cParam_FilesRecursive = 'files-recursive';
  cParam_IgnoreConfig = 'ignore-config';
  cParam_Contains = 'contains';
  cParam_ContainsNot = 'contains-not';
  cParam_ContainsRegex = 'contains-regex';
  cParam_ContainsNotRegex = 'contains-not-regex';

type
  TParameter = class(TObject)
  strict private
    FName: String;
    FValue: String;
    FIsOption: Boolean;
    procedure ReplaceSpecialCharacters(var AInput: String);
  public
    constructor Create(const AParameter: String);
    property Name: String read FName;
    property Value: String read FValue;
    property IsOption: Boolean read FIsOption;
  end;

  TlstParameters = class(TObjectList<TParameter>)
  strict private
    procedure LoadConfig;
  public
    constructor Create;
    function IsOptionSet(const AName: String): Boolean;
    function GetCount(const AName: String): Integer;
    function GetValue(const AName: String): String;
    procedure GetValues(const AName: String; const AValues: TStringList);
  end;

var
  Parameters: TlstParameters;

implementation

uses
  Winapi.ShlObj,
  System.SysUtils,
  Vcl.Forms;

{ TParameter }

constructor TParameter.Create(const AParameter: String);
begin
  if AParameter.StartsWith('--') then
  begin
    FIsOption := True;
    if AParameter.Contains('=') then
    begin
      FName := AParameter.Substring(2, AParameter.IndexOf('=') - 2);
      FValue := AParameter.Substring(AParameter.IndexOf('=') + 1);
    end else
    begin
      FName := AParameter.Substring(2);
      FValue := EmptyStr;
    end;
  end else
  if AParameter.StartsWith('-') then
  begin
    FIsOption := True;
    if AParameter.Length <= 1 then
    begin
      raise Exception.Create('Could not parse argument "' + AParameter + '"!');
    end;
    FName := AParameter.Substring(1, 1);
    if AParameter.Length > 2 then
    begin
      FValue := AParameter.Substring(2);
    end else
    begin
      FValue := EmptyStr;
    end;
  end else
  begin
    FIsOption := False;
    FName := EmptyStr;
    FValue := AParameter;
  end;
  ReplaceSpecialCharacters(FValue);
end;

procedure TParameter.ReplaceSpecialCharacters(var AInput: String);
begin
  AInput := AInput.Replace('\r', #13, [rfReplaceAll]);
  AInput := AInput.Replace('\n', #10, [rfReplaceAll]);
end;

{ TlstParameters }

constructor TlstParameters.Create;
var
  i1: Integer;
  Parameter: TParameter;
begin
  inherited Create(True);

  for i1 := 1 to ParamCount do
  begin
    Parameter := TParameter.Create(ParamStr(i1));
    Add(Parameter);
  end;

  LoadConfig;
end;

function TlstParameters.GetCount(const AName: String): Integer;
var
  Parameter: TParameter;
begin
  Result := 0;
  for Parameter in Self do
  begin
    if Parameter.IsOption
    and (Parameter.Name = AName) then
    begin
      Inc(Result);
    end;
  end;
end;

function TlstParameters.GetValue(const AName: String): String;
var
  Parameter: TParameter;
begin
  for Parameter in Self do
  begin
    if Parameter.IsOption
    and (Parameter.Name = AName) then
    begin
      Result := Parameter.Value;
      Exit;
    end;
  end;
  Result := EmptyStr;
end;

procedure TlstParameters.GetValues(const AName: String; const AValues: TStringList);
var
  Parameter: TParameter;
begin
  AValues.Clear;
  for Parameter in Self do
  begin
    if Parameter.IsOption
    and (Parameter.Name = AName) then
    begin
      AValues.Add(Parameter.Value);
      Exit;
    end;
  end;
end;

function TlstParameters.IsOptionSet(const AName: String): Boolean;
var
  Parameter: TParameter;
begin
  for Parameter in Self do
  begin
    if Parameter.IsOption
    and (Parameter.Name = AName) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

procedure TlstParameters.LoadConfig;

  function fctGetAppDataFolder: String;
  var
    ItemIDList: PItemIDList;
    Path: array[0..200] of Char;
  begin
    SHGetSpecialFolderLocation(Application.Handle, CSIDL_APPDATA, ItemIDList);
    SHGetPathFromIDList(ItemIDList, Path);
    Result := Path;
  end;

var
  HomeFolder: String;
  ConfigFile: String;
  Lines: TStringList;
  i1: Integer;
  Param: String;
begin
  if IsOptionSet('ignore-config') then
  begin
    Exit;
  end;

  HomeFolder := fctGetAppDataFolder;
  if HomeFolder <> EmptyStr then
  begin
    ConfigFile := HomeFolder + '\refind2.cfg';
    if FileExists(ConfigFile) then
    begin
      Lines := TStringList.Create;
      try
        Lines.Delimiter := #10;
        Lines.StrictDelimiter := True;
        Lines.LoadFromFile(ConfigFile);
        for i1 := 0 to Lines.Count - 1 do
        begin
          Param := Lines.Strings[i1].Trim;
          if Param <> EmptyStr then
          begin
            Add(TParameter.Create(Param));
          end;
        end;
      finally
        FreeAndNil(Lines);
      end;
    end;
  end;
end;

initialization
begin
  Parameters := TlstParameters.Create;
end;

finalization
begin
  FreeAndNil(Parameters);
end;

end.
