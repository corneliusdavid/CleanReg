unit ufrmRegFoundList;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, ImgList, StdCtrls, Buttons, ExtCtrls, StrUtils, Registry;

type
  TfrmRegFoundList = class(TForm)
    lbEntriesFound: TListBox;
    pnlBottom: TPanel;
    btnRemove: TBitBtn;
    btnCleanReg: TBitBtn;
    btnClose: TBitBtn;
    ActionList: TActionList;
    ImageList: TImageList;
    actRemove: TAction;
    actCleanReg: TAction;
    actClose: TAction;
    procedure lbEntriesFoundClick(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure actCleanRegExecute(Sender: TObject);
    procedure actRemoveExecute(Sender: TObject);
  private
    procedure RemoveRegistryEntry(s: string);
    procedure Log(s: string);
  end;

var
  frmRegFoundList: TfrmRegFoundList;


implementation

{$R *.dfm}

procedure TfrmRegFoundList.actRemoveExecute(Sender: TObject);
begin
  if lbEntriesFound.ItemIndex > -1 then
    lbEntriesFound.DeleteSelected;
end;

procedure TfrmRegFoundList.actCleanRegExecute(Sender: TObject);
var
  i: Integer;
begin
  if (MessageDlg('Are you ready to remove all listed entries from the Windows registry?',
                 mtConfirmation, [mbYes, mbNo], 0) = mrYes) then begin
    Log(FormatDateTime('dd-mmm-yyyy  tt', Now));
    for i := lbEntriesFound.Count - 1 downto 0 do
      RemoveRegistryEntry(lbEntriesFound.Items[i]);
  end;
end;

procedure TfrmRegFoundList.actCloseExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmRegFoundList.lbEntriesFoundClick(Sender: TObject);
begin
  actRemove.Enabled := lbEntriesFound.ItemIndex > -1;
end;

procedure TfrmRegFoundList.RemoveRegistryEntry(s: string);
var
  p: Integer;
  root: string;
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  try
    root := LeftStr(s, Pos(':', s) - 1);

    if root = 'CLASSES_ROOT' then
      reg.RootKey := HKEY_CLASSES_ROOT
    else if root = 'CURRENT_USER' then
      reg.RootKey := HKEY_CURRENT_USER
    else if root = 'LOCAL_MACHINE' then
      reg.RootKey := HKEY_LOCAL_MACHINE
    else if root = 'USERS' then
      reg.RootKey := HKEY_USERS
    else if root = 'CURRENT_CONFIG' then
      reg.RootKey := HKEY_CURRENT_CONFIG
    else
      Exit; // must not be a registry entry--let's get out of here

    s := RightStr(s, Length(s) - (Length(root) + 2));
    p := Pos('  "', s);

    if p = 0 then begin
      // delete a whole key along with sub keys and values
      if reg.KeyExists(s) then begin
        reg.DeleteKey(s);
        Log(s);
      end;
    end else begin
      // delete a single value...
      s := LeftStr(s, p);
      messagedlg('delete a single value: ' + s, mtInformation, [mbOk], 0);
    end;
  finally
    reg.Free;
  end;
end;

procedure TfrmRegFoundList.Log(s: string);
var
  f: TextFile;
  FileName: string;
begin
  FileName := ChangeFileExt(Application.ExeName, '.LOG');
  AssignFile(f, Filename);
  if FileExists(FileName) then
    Append(f)
  else
    Rewrite(f);

  Writeln(f, s);
  CloseFile(f);
end;

end.
