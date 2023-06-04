unit Keyboard;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, ExtCtrls, StdCtrls;

type
  TKeyboardForm = class(TForm)
    Panel1: TPanel;
    BtnPanel: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    SpeedButton11: TSpeedButton;
    SpeedButton12: TSpeedButton;
    SpeedButton13: TSpeedButton;
    SpeedButton14: TSpeedButton;
    SpeedButton15: TSpeedButton;
    SpeedButton16: TSpeedButton;
    SpeedButton17: TSpeedButton;
    SpeedButton18: TSpeedButton;
    SpeedButton19: TSpeedButton;
    SpeedButton20: TSpeedButton;
    SpeedButton21: TSpeedButton;
    SpeedButton22: TSpeedButton;
    SpeedButton23: TSpeedButton;
    SpeedButton24: TSpeedButton;
    SpeedButton25: TSpeedButton;
    SpeedButton26: TSpeedButton;
    SpeedButton27: TSpeedButton;
    SpeedButton28: TSpeedButton;
    SpeedButton29: TSpeedButton;
    SpeedButton30: TSpeedButton;
    SpeedButton31: TSpeedButton;
    SpeedButton32: TSpeedButton;
    SpeedButton33: TSpeedButton;
    SpeedButton34: TSpeedButton;
    SpeedButton35: TSpeedButton;
    SpeedButton36: TSpeedButton;
    SpeedButton37: TSpeedButton;
    SpeedButton38: TSpeedButton;
    SpeedButton39: TSpeedButton;
    SpeedButton40: TSpeedButton;
    SpeedButton41: TSpeedButton;
    SpeedButton42: TSpeedButton;
    SpeedButton43: TSpeedButton;
    BSBtn: TSpeedButton;
    ShiftBtn: TSpeedButton;
    RightBtn: TSpeedButton;
    LeftBtn: TSpeedButton;
    SpaceBtn: TSpeedButton;
    Edit: TEdit;
    OKBtn: TSpeedButton;
    CanelBtn: TSpeedButton;
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CanelBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure ShiftBtnClick(Sender: TObject);
    procedure CapsLock(capslock : word);
    function  GetString(sender:TComponent;var str:string; CapsSpace:boolean):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KeyboardForm: TKeyboardForm;

implementation

{$R *.dfm}

uses ShadowForm;

var
  autocaps : boolean;

function  TKeyboardForm.GetString(sender:TComponent;var str:string; CapsSpace:boolean):boolean;
begin
  autocaps:=CapsSpace;
  result:=false;
  Edit.Text:=str;
  Edit.SelectAll;
  if CapsSpace then self.CapsLock(1) else self.CapsLock(2);
  ShadowShow(sender);
  if (self.ShowModal=mrOK)and(Length(Edit.Text)>0) then
    begin
      str:=Edit.Text;
      result:=true;
    end;
  ShadowHide(sender);
end;

procedure TKeyboardForm.CanelBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

procedure TKeyboardForm.CapsLock(capslock : word);
var
  i   : integer;
  str : string;
begin
  for I := 0 to self.BtnPanel.ControlCount - 1 do
    if (self.BtnPanel.Controls[i] is TSpeedButton)
      and(Length((self.BtnPanel.Controls[i] as TSpeedButton).Caption)=1)
      then begin
        str:=(self.BtnPanel.Controls[i] as TSpeedButton).Caption;
        if (capslock=1)and(str[1] in ['à'..'ÿ']) then
          (self.BtnPanel.Controls[i] as TSpeedButton).Caption:=
            AnsiUpperCase((self.BtnPanel.Controls[i] as TSpeedButton).Caption);
        if (capslock=2)and(str[1] in ['À'..'ß']) then
          (self.BtnPanel.Controls[i] as TSpeedButton).Caption:=
            AnsiLowerCase((self.BtnPanel.Controls[i] as TSpeedButton).Caption);
        if (capslock=0) then
          if (str[1] in ['à'..'ÿ']) then
          (self.BtnPanel.Controls[i] as TSpeedButton).Caption:=
            AnsiUpperCase((self.BtnPanel.Controls[i] as TSpeedButton).Caption)
            else
          (self.BtnPanel.Controls[i] as TSpeedButton).Caption:=
            AnsiLowerCase((self.BtnPanel.Controls[i] as TSpeedButton).Caption);
      end;
end;


procedure TKeyboardForm.EditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key=13 then self.OKBtnClick(sender);
end;

procedure TKeyboardForm.OKBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrOK;
end;

procedure TKeyboardForm.ShiftBtnClick(Sender: TObject);
begin
  self.CapsLock(0);
end;

procedure TKeyboardForm.SpeedButton1Click(Sender: TObject);
var
  btnname : string;
begin
  btnname:=(sender as TSpeedButton).name;
  if btnname='LeftBtn' then SendMessage(Edit.Handle, WM_KEYDOWN, VK_LEFT, 0)
    else if btnname='RightBtn' then SendMessage(Edit.Handle, WM_KEYDOWN, VK_RIGHT, 0)
      else if btnname='BSBtn' then SendMessage(Edit.Handle, WM_CHAR, VK_BACK, 0)
          else SendMessage(Edit.Handle, WM_CHAR, Word((sender as TSpeedButton).Caption[1]), 0);
  if (btnname='SpaceBtn')and(autocaps) then self.CapsLock(1) else self.CapsLock(2);
end;

end.
