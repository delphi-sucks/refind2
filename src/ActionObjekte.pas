unit ActionObjekte;

interface

uses
  System.Classes, System.Generics.Collections;

type
  TActionParameterOption = (apoRequired, apoList);
  TActionParameterOptions = set of TActionParameterOption;

  TActionFile = class(TObject)
  strict private
    FFileName: String;
    FContent: String;
    FHasChanged: Boolean;
    procedure SetContent(const AContent: String);
  public
    constructor Create(const AFileName: String);
    procedure Save;
    property FileName: String read FFileName;
    property HasChanged: Boolean read FHasChanged;
    property Content: String read FContent write SetContent;
  end;

  TlstActionFiles = class(TObjectList<TActionFile>)
  strict private
    procedure AddFile(const APath: String);
  public
    procedure Refresh;
  end;

  TAction = class(TObject)
  strict private type

    TOption = class(TObject)
    public
      FName: String;
      FExampleValue: String;
      FDescription: String;
      FOptions: TActionParameterOptions;
    end;
    TOptions = class(TObjectList<TOption>);

  strict private
    FOptions: TOptions;
    FFiles: TlstActionFiles;
  protected
    procedure AddOption(const AName: String; const ADescription: String;
      const AOptions: TActionParameterOptions = []); overload;
    procedure AddOption(const AName: String; const AExampleValue: String; const ADescription: String;
      const AOptions: TActionParameterOptions = []); overload;

    procedure Options; virtual;
    property Files: TlstActionFiles read FFiles;
  public
    class function GetName: String; virtual;
    class function GetDescription: String; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetHelp: String; virtual;
    procedure Execute; virtual;
  end;

  TActionClass = class of TAction;

  TActions = class(TDictionary<String, TActionClass>)
  public
    procedure Add(const AClass: TActionClass);
  end;

var
  Actions: TActions;

implementation

uses
  System.SysUtils, System.IOUtils, System.RegularExpressions, System.Types,
  ParameterObjekte;

{ TAction }

constructor TAction.Create;
begin
  inherited;
  FOptions := TOptions.Create(True);
  FFiles := TlstActionFiles.Create(True);
end;

destructor TAction.Destroy;
begin
  FreeAndNil(FFiles);
  FreeAndNil(FOptions);
  inherited;
end;

class function TAction.GetDescription: String;
begin
  Result := EmptyStr;
end;

function TAction.GetHelp: String;

  function fctActions: String;
  var
    Action: String;
    ActionsHelp: String;
    lstActionsHelp: TStringList;
    Length: Integer;
    MaxLength: Integer;
  begin
    ActionsHelp := EmptyStr;
    MaxLength := 0;
    lstActionsHelp := TStringList.Create;
    try
      for Action in Actions.Keys do
      begin
        Length := Action.Length;
        if Length > MaxLength then
        begin
          MaxLength := Length;
        end;
        lstActionsHelp.Add(Action);
      end;
      lstActionsHelp.Sort;
      for Action in lstActionsHelp do
      begin
        ActionsHelp := ActionsHelp +
          '  ' + Action.PadRight(MaxLength) + '  ' + Actions.Items[Action].GetDescription + #13#10;
      end;
    finally
      FreeAndNil(lstActionsHelp);
    end;
    Result := ActionsHelp;
  end;

  function fctOptions: String;
  var
    Options: String;
    Option: TOption;
  begin
    if FOptions.Count = 0 then
    begin
      Result := EmptyStr;
      Exit;
    end;
    Options := 'Action options:'#13#10;
    for Option in FOptions do
    begin
      Options := Options +
        '  ';
      if Option.FName.Length = 1 then
      begin
        Options := Options + '-';
      end else
      begin
        Options := Options + '--';
      end;
      Options := Options + Option.FName;
      if Option.FExampleValue <> EmptyStr then
      begin
        Options := Options + '=[' + Option.FExampleValue + ']';
      end;
      if Option.FDescription <> EmptyStr then
      begin
        Options := Options +
          '   ' + Option.FDescription;
      end;
      Options := Options + #13#10;
    end;
    Result := Options;
  end;

begin
  Result :=
    'Usage: refind2 [ACTION] [OPTIONS] [FILES]...'#13#10 +
    'Better version of refind to refactor delphi source code.'#13#10 +
    #13#10 +
    'Actions:'#13#10 +
    fctActions +
    #13#10 +
    'Global options:'#13#10 +
    '  --files-recursive             Search in all subfolders if the FILES-Argument is an expression'#13#10 +
    '  --ignore-config               Ignore the configuration file'#13#10 +
    '  --test                        Don''t change any file'#13#10 +
    #13#10 +
    '  --contains=[TEXT]             File must contain the given text'#13#10 +
    '  --contains-not=[TEXT]         File must not contain the given text'#13#10 +
    '  --contains-regex=[REGEX]      File must not contain the given regular expression'#13#10 +
    '  --contains-not-regex=[REGEX]  File must not contain the given regular expression'#13#10 +
    #13#10 +
    fctOptions +
    #13#10 +
    'FILES may be a relative or absolute path'#13#10 +
    #13#10 +
    #13#10 +
    'SPECIALS CHARACTERS'#13#10 +
    '\r      Carriage return.'#13#10 +
    '\n      Line feed.'#13#10 +
    #13#10 +
    #13#10 +
    'CONFIGURATION'#13#10 +
    'It is possible to define default configurations like paths.'#13#10 +
    'The configuration path is:'#13#10 +
    '  %APPDATA%\refind2.cfg'#13#10 +
    #13#10 +
    'The configuration is defined by the arguments that can be set.'#13#10 +
    'Each line represents an argument.';
end;

class function TAction.GetName: String;
begin
  Result := EmptyStr;
end;

procedure TAction.AddOption(const AName, AExampleValue, ADescription: String; const AOptions: TActionParameterOptions);
var
  Option: TOption;
begin
  Option := TOption.Create;
  Option.FName := AName;
  Option.FExampleValue := AExampleValue;
  Option.FDescription := ADescription;
  Option.FOptions := AOptions;
  FOptions.Add(Option);
end;

procedure TAction.AddOption(const AName, ADescription: String; const AOptions: TActionParameterOptions);
var
  Option: TOption;
begin
  Option := TOption.Create;
  Option.FName := AName;
  Option.FDescription := ADescription;
  Option.FOptions := AOptions;
  FOptions.Add(Option);
end;

procedure TAction.Execute;
var
  Option: TOption;
  Parameter: TParameter;
  Count: Integer;
begin
  for Option in FOptions do
  begin
    Count := 0;
    for Parameter in Parameters do
    begin
      if Parameter.Name = Option.FName then
      begin
        Inc(Count);
        if not (apoList in Option.FOptions) then
        begin
          if Count > 1 then
          begin
            raise Exception.Create('Option "' + Option.FName + '" can only be set one time!');
          end;
        end;
      end;
    end;
    if (Count = 0)
    and (apoRequired in Option.FOptions) then
    begin
      raise Exception.Create('Option "' + Option.FName + '" must be set!');
    end;
  end;
  Options;
  FFiles.Refresh;
  if FFiles.Count = 0 then
  begin
    raise Exception.Create('No matching files found!');
  end;
end;

procedure TAction.Options;
begin

end;

{ TlstActions }

procedure TActions.Add(const AClass: TActionClass);
begin
  inherited Add(AClass.GetName, AClass);
end;

{ TActionFile }

constructor TActionFile.Create(const AFileName: String);
begin
  inherited Create;
  FFileName := AFileName;
  FContent := TFile.ReadAllText(FFileName, TEncoding.ANSI);
end;

procedure TActionFile.Save;
begin
  if not Parameters.IsOptionSet('test') then
  begin
    TFile.WriteAllText(FFileName, FContent, TEncoding.ANSI);
  end;
  FHasChanged := False;
end;

procedure TActionFile.SetContent(const AContent: String);
begin
  if FContent <> AContent then
  begin
    FContent := AContent;
    FHasChanged := True;
  end;
end;

{ TlstActionFiles }

procedure TlstActionFiles.AddFile(const APath: String);
var
  Parameter: TParameter;
  ActionFile: TActionFile;
begin
  ActionFile := TActionFile.Create(APath);
  try
    for Parameter in Parameters do
    begin
      if not Parameter.IsOption then
      begin
        Continue;
      end;

      if Parameter.Name = 'contains' then
      begin
        if not ActionFile.Content.Contains(Parameter.Value) then
        begin
          Exit;
        end;
      end;
      if Parameter.Name = 'contains-not' then
      begin
        if ActionFile.Content.Contains(Parameter.Value) then
        begin
          Exit;
        end;
      end;
      if Parameter.Name = 'contains-regex' then
      begin
        if not TRegEx.IsMatch(ActionFile.Content, Parameter.Value) then
        begin
          Exit;
        end;
      end;
      if Parameter.Name = 'contains-not-regex' then
      begin
        if TRegEx.IsMatch(ActionFile.Content, Parameter.Value) then
        begin
          Exit;
        end;
      end;
    end;
    Add(ActionFile);
    ActionFile := nil;
  finally
    FreeAndNil(ActionFile);
  end;
end;

procedure TlstActionFiles.Refresh;

  procedure prcSearchDefault(const _sPath: String);
  var
    SearchOption: TSearchOption;
    Files: TStringDynArray;
    i1: Integer;
    Dir: String;
    Name: String;
  begin
    SearchOption := TSearchOption.soTopDirectoryOnly;
    if Parameters.IsOptionSet('files-recursive') then
    begin
      SearchOption := TSearchOption.soAllDirectories;
    end;

    if FileExists(_sPath) then
    begin
      AddFile(_sPath);
    end else
    if DirectoryExists(_sPath) then
    begin
      Files := TDirectory.GetFiles(_sPath, '*.pas', SearchOption);
      for i1 := Low(Files) to High(Files) do
      begin
        AddFile(Files[i1]);
      end;
      Files := TDirectory.GetFiles(_sPath, '*.dpr', SearchOption);
      for i1 := Low(Files) to High(Files) do
      begin
        AddFile(Files[i1]);
      end;
    end else
    begin
      Dir := ExtractFilePath(_sPath);
      if DirectoryExists(Dir) then
      begin
        Name := ExtractFileName(_sPath);
        Files := TDirectory.GetFiles(Dir, Name, SearchOption);
        for i1 := Low(Files) to High(Files) do
        begin
          AddFile(Files[i1]);
        end;
      end;
    end;
  end;

var
  Parameter: TParameter;
begin
  Clear;
  for Parameter in Parameters do
  begin
    if Parameter.IsOption then
    begin
      Continue;
    end;
    prcSearchDefault(Parameter.Value);
  end;
end;

initialization
begin
  Actions := TActions.Create;
end;

finalization
begin
  FreeAndNil(Actions);
end;

end.
