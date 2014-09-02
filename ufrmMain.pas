unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, StrUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls, ImgList, ActnList, Registry;

type
  TfrmMain = class(TForm)
    Label1: TLabel;
    edtKeywords: TEdit;
    cbClasses: TCheckBox;
    cbCurrUser: TCheckBox;
    cbLocalMachine: TCheckBox;
    cbAllUsers: TCheckBox;
    cbConfig: TCheckBox;
    btnSearch: TBitBtn;
    btnExit: TBitBtn;
    btnInfo: TBitBtn;
    StatusBar: TStatusBar;
    ActionList: TActionList;
    actSearchRegistry: TAction;
    ImageList: TImageList;
    actInformation: TAction;
    actExit: TAction;
    actCancelSearch: TAction;
    cbCheckNames: TCheckBox;
    cbCheckValues: TCheckBox;
    pbClasses: TProgressBar;
    pbCurrUser: TProgressBar;
    pbLocalMachine: TProgressBar;
    pbAllUsers: TProgressBar;
    pbConfig: TProgressBar;
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure actCancelSearchExecute(Sender: TObject);
    procedure actSearchRegistryExecute(Sender: TObject);
    procedure actInformationExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
  private
    FCurrRoot: string;
    FCurrProgressBar: TProgressBar;
    FKeyWordList: TStringList;
    FCancelSearch: Boolean;
    function NoSectionsChecked: Boolean;
    procedure SearchRegistry;
    procedure SearchRegPath(RootKey: HKEY; Path: string = '');
    procedure SearchRegValues(Reg: TRegistry);
    function KeywordFound(SearchStr: string): Boolean;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  ufrmRegFoundList;


procedure TfrmMain.FormCreate(Sender: TObject);
// create the list of keywords to be used throughout the program
begin
  FKeyWordList := TStringList.Create;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  // why does this keep getting reset?
  StatusBar.Font.Name := 'Arial Narrow';
  StatusBar.Font.Style := [];
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
// free the memory for the keyword list
begin
  FKeyWordList.Free;
end;

procedure TfrmMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.actInformationExecute(Sender: TObject);
// display the only help message in the program
begin
  MessageDlg('This program searches through the Windows registry for the keywords ' +
             'given and displays all entries found in a list.  You can then, with ' +
             'the click of a button, remove these entries from the registry.  This ' +
             'helps to clean things out after a program has been "uninstalled" but ' +
             'leaves left-over settings you no longer need to keep.'#10#13#13 +
             'DISCLAIMER: Modifying the system registry can render your system ' +
             'unusable or may cause other unknown problems.'#10#13 +
             'Use caution and ALWAYS make a backup.', mtInformation, [mbOK], 0);
end;

procedure TfrmMain.actSearchRegistryExecute(Sender: TObject);
// does some checking, then sets up the GUI for the actual registry check/clean process
var
  i: Integer;
  SaveStatusBarText: string;
begin
  if Length(Trim(edtKeywords.Text)) = 0 then
    MessageDlg('Please enter some keywords to search.', mtWarning, [mbOK], 0)
  else if NoSectionsChecked then
    MessageDlg('There is nothing to do because no registry sections have been checked.', mtWarning, [mbOK], 0)
  else if (not cbCheckNames.Checked) and (not cbCheckValues.Checked) then
    MessageDlg('There is nothing to do because neither "Check Key Names" nor "Check Key Values" are checked.', mtWarning, [mbOK], 0)
  else begin
    // the status bar doubles as progessive search display so the user knows how it's doing
    SaveStatusBarText := StatusBar.SimpleText;
    // initialize the cancel function
    FCancelSearch := False;
    // turn on the hourglass--this will take a while
    Screen.Cursor := crHourGlass;
    try
      // disable all text edit fields, checkboxes, and buttons (except the cancel button)
      for i := 0 to ComponentCount - 1 do
        if (Components[i] is TWinControl) and ((Components[i] as TWincontrol).Tag <> 1) then
          (Components[i] as TWinControl).Enabled := False;
      // the Search button doubles as the cancel button
      btnSearch.Glyph := nil;
      btnSearch.Action := actCancelSearch;
      // parse the keywords
      FKeywordList.CommaText := Trim(edtKeywords.Text);

      // all set--here's the meat!
      SearchRegistry;

    finally
      // turn everything back on and restore normalcy
      for i := 0 to ComponentCount - 1 do
        if (Components[i] is TWinControl) and ((Components[i] as TWincontrol).Tag <> 1) then
          (Components[i] as TWinControl).Enabled := True;
      btnSearch.Glyph := nil;
      btnSearch.Action := actSearchRegistry;
      Screen.Cursor := crDefault;
      StatusBar.SimpleText := SaveStatusBarText;
    end;
  end;
end;

procedure TfrmMain.actCancelSearchExecute(Sender: TObject);
// the cancel button was hit!!
begin
  FCancelSearch := True;
end;

function TfrmMain.NoSectionsChecked: Boolean;
// return whether or not at least one of the registry sections is to be checked
begin
  Result := (not cbClasses.Checked) and
            (not cbCurrUser.Checked) and
            (not cbLocalMachine.Checked) and
            (not cbAllUsers.Checked) and
            (not cbConfig.Checked);
end;

procedure TfrmMain.SearchRegistry;
// for each registry section to be checked, calls SearchRegPath
begin
  pbClasses.Position := 0;
  pbCurrUser.Position := 0;
  pbLocalMachine.Position := 0;
  pbAllUsers.Position := 0;
  pbConfig.Position := 0;

  frmRegFoundList := TfrmRegFoundList.Create(self);
  try
    if cbClasses.Checked and (not FCancelSearch) then begin
      FCurrRoot := 'CLASSES_ROOT:';
      FCurrProgressBar := pbClasses;
      SearchRegPath(HKEY_CLASSES_ROOT);
    end;
    if cbCurrUser.Checked and (not FCancelSearch) then begin
      FCurrRoot := 'CURRENT_USER:';
      FCurrProgressBar := pbCurrUser;
      SearchRegPath(HKEY_CURRENT_USER);
    end;
    if cbLocalMachine.Checked and (not FCancelSearch) then begin
      FCurrRoot := 'LOCAL_MACHINE:';
      FCurrProgressBar := pbLocalMachine;
      SearchRegPath(HKEY_LOCAL_MACHINE);
    end;
    if cbAllUsers.Checked and (not FCancelSearch) then begin
      FCurrRoot := 'USERS:';
      FCurrProgressBar := pbAllUsers;
      SearchRegPath(HKEY_USERS);
    end;
    if cbConfig.Checked and (not FCancelSearch) then begin
      FCurrRoot := 'CURRENT_CONFIG:';
      FCurrProgressBar := pbConfig;
      SearchRegPath(HKEY_CURRENT_CONFIG);
    end;

    // found them all, now show them and let the user decide what to do
    if FCancelSearch then
      frmRegFoundList.lbEntriesFound.Items.Add('SEARCH CANCELED!');
    frmRegFoundList.ShowModal;
  finally
    frmRegFoundList.Free;
  end;
end;

procedure TfrmMain.SearchRegPath(RootKey: HKEY; Path: string = '');
// recursively searches all registry keys in the given path
var
  s: string;
  reg: TRegistry;
  RegKeyList: TStringList;
  i: Integer;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := RootKey;

    RegKeyList := TStringList.Create;
    try
      // open the registry key for the path given
      reg.OpenKeyReadOnly(Path);
      // get a list of all sub-keys
      reg.GetKeyNames(RegKeyList);
      // if path is blank, we're on the root path, so setup the progressbar
      if Path = EmptyStr then
        FCurrProgressBar.Max := RegKeyList.Count;

      // here's where we traverse all keys in the current path
      for i := 0 to RegKeyList.Count - 1 do begin
        // display work in progress
        if Path = EmptyStr then
          FCurrProgressBar.StepIt;
        s := FCurrRoot + Reg.CurrentPath + '\' + RegKeyList.Strings[i];
        StatusBar.SimpleText := s;
        // watch for cancel press and also update controls
        Application.ProcessMessages;

        // was cancel pressed?
        if FCancelSearch then
          Break;

        // check registry keys
        if cbCheckNames.Checked and KeywordFound(RegKeyList.Strings[i]) then
          frmRegFoundList.lbEntriesFound.Items.Add(FCurrRoot + '\' + reg.CurrentPath + '\' + RegKeyList.Strings[i]);
        // check registry string values
        if cbCheckValues.Checked then
          SearchRegValues(reg);

        // traverse sub-keys
        if Length(Trim(RegKeyList.Strings[i])) > 0 then
          SearchRegPath(RootKey, Reg.CurrentPath + '\' + RegKeyList.Strings[i]);
      end;
    finally
      reg.CloseKey;
      RegKeyList.Free;
    end;
  finally
    reg.Free;
  end;
end;

function TfrmMain.KeywordFound(SearchStr: string): Boolean;
// searches the given string for an occurance of any of our keywords
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FKeywordList.Count - 1 do
    if AnsiContainsText(SearchStr, FKeywordList.Strings[i]) then begin
      Result := True;
      Break;
    end;
end;

procedure TfrmMain.SearchRegValues(Reg: TRegistry);
// searches through all values in the given registry key
var
  i: Integer;
  RegValueInfo: TRegDataInfo;
  RegValueNames: TStringList;
  s: string;
begin
  RegValueNames := TStringList.Create;
  try
    reg.GetValueNames(RegValueNames);
    for i := 0 to RegValueNames.Count - 1 do
      if reg.GetDataInfo(RegValueNames.Strings[i], RegValueInfo) then
        if (RegValueInfo.RegData = rdString) or (RegValueInfo.RegData = rdExpandString) then begin
          s := reg.ReadString(RegValueNames.Strings[i]);
          if KeywordFound(s) then
            frmRegFoundList.lbEntriesFound.Items.Add(FCurrRoot + '\' + reg.CurrentPath + '\' +
                         RegValueNames.Strings[i] + '  "' + s + '"');
        end;
  finally
    RegValueNames.Free;
  end;
end;

end.
