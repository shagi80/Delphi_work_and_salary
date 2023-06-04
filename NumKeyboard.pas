unit NumKeyboard;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, ExtCtrls, StdCtrls;

type
  TNumKeyboardForm = class(TForm)
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
    BSBtn: TSpeedButton;
    RightBtn: TSpeedButton;
    LeftBtn: TSpeedButton;
    Edit: TEdit;
    OKBtn: TSpeedButton;
    CanelBtn: TSpeedButton;
    PointBtn: TSpeedButton;
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CanelBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    function  GetValue(sender:TComponent;var str:string; onlyint : boolean):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  NumKeyboardForm: TNumKeyboardForm;

implementation

{$R *.dfm}

uses ShadowForm;

procedure TNumKeyboardForm.EditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key=13 then self.OKBtnClick(sender);
end;

function  TNumKeyboardForm.GetValue(sender:TComponent; var str:string; onlyint : boolean):boolean;
const
  newstr='000';
begin
  result:=false;
  PointBtn.Enabled:=not onlyint;
  if Length(str)=0 then Edit.Text:=newstr else Edit.Text:=str;
  Edit.SelectAll;
  ShadowShow(sender);
  if (self.ShowModal=mrOK)and(Length(Edit.Text)>0)and(Edit.Text<>newstr) then
    begin
      str:=Edit.Text;
      result:=true;
    end;
  ShadowHide(sender);
end;

procedure TNumKeyboardForm.CanelBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

procedure TNumKeyboardForm.OKBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrOK;
end;

procedure TNumKeyboardForm.SpeedButton1Click(Sender: TObject);
var
  btnname : string;
begin
  btnname:=(sender as TSpeedButton).name;
  if btnname='LeftBtn' then SendMessage(Edit.Handle, WM_KEYDOWN, VK_LEFT, 0)
    else if btnname='RightBtn' then SendMessage(Edit.Handle, WM_KEYDOWN, VK_RIGHT, 0)
      else if btnname='BSBtn' then SendMessage(Edit.Handle, WM_CHAR, VK_BACK, 0)
          else SendMessage(Edit.Handle, WM_CHAR, Word((sender as TSpeedButton).Caption[1]), 0);
end;

end.
