unit EmpWorkData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons,
  EmployData;

const
  alBrigadier =  20;
  alForeman   =  10;

type
  TEmpWorkDataForm = class(TForm)
    CanelBtn: TSpeedButton;
    OKBtn: TSpeedButton;
    Img: TImage;
    NameLB: TLabel;
    Label1: TLabel;
    TabNumBtn: TSpeedButton;
    TimeLB: TLabel;
    Shape1: TShape;
    RatingPn: TPanel;
    rt5: TSpeedButton;
    rt4: TSpeedButton;
    rt3: TSpeedButton;
    rt2: TSpeedButton;
    rt1: TSpeedButton;
    Label3: TLabel;
    WorkNameLB: TLabel;
    CountPn: TPanel;
    Label4: TLabel;
    Count2LB: TLabel;
    Count2Btn: TSpeedButton;
    Label2: TLabel;
    Count1LB: TLabel;
    Count1Btn: TSpeedButton;
    NormLB: TLabel;
    procedure Count2BtnClick(Sender: TObject);
    procedure rt1Click(Sender: TObject);
    procedure Count1BtnClick(Sender: TObject);
    procedure TabNumBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    procedure SetRtBtn(num:integer);
    function  ShowWindow(sender:TComponent;TimePay,GroupPay:boolean;name,workname:string;norm,pay:real;var Time:real;var count1,count2,rating:integer;bmp:TbitMap):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EmpWorkDataForm: TEmpWorkDataForm;

implementation

{$R *.dfm}

uses GlobalUnit, NumKeyboard, Keyboard, ListView, ShadowForm, MsgForm;

var
  resrating   : integer;

procedure TEmpWorkDataForm.SetRtBtn(num:integer);
var
  i   : integer;
  bmp : TBitMap;
begin
  bmp:=TBitMap.Create;
  resrating:=num;
  for I := 0 to RatingPn.ControlCount-1 do
    if copy(RatingPn.Controls[i].Name,1,2)='rt' then
      begin
        if StrToInt(copy(RatingPn.Controls[i].Name,3,1))>num then bmp.LoadFromResourceName(hInstance, 'Rat0BtnImg')
          else bmp.LoadFromResourceName(hInstance, 'Rat1BtnImg');
        (RatingPn.Controls[i] as TSpeedButton).Glyph:=bmp;
      end;
end;

//Окно для индивидуальной ставки
function  TEmpWorkDataForm.ShowWindow(sender:TComponent;TimePay,GroupPay:boolean;name,workname:string;norm,pay:real;var Time:real;var count1,count2,rating:integer;bmp:TbitMap):boolean;
begin
  NameLB.Caption:=name;
  WorkNameLB.Caption:=workname;
  RatingPn.Visible:=GroupPay;
  CountPn.Visible:=(not TimePay)and(not GroupPay);
  TimeLB.Caption:=FormatFloat('#0.##',time);
  Count1LB.Caption:=IntToStr(count1);
  Count2LB.Caption:=IntToStr(count2);
  Img.Picture.Bitmap:=bmp;
  self.SetRtBtn(rating);
  NormLB.Caption:='(норма по ставке '+FormatFloat('###0.0#',norm)+' ед,  оплата '+
    FormatFloat('###0.0#',pay)+' руб/ед)';
  ShadowShow(sender);
  result:=(self.ShowModal=mrOK);
  ShadowHide(sender);
  if result then
    begin
        time:=StrToFloat(TimeLB.Caption);
        count1:=StrToInt(Count1LB.Caption);
        count2:=StrToInt(Count2LB.Caption);
        rating:=resrating;
    end;
end;

procedure TEmpWorkDataForm.CanelBtnClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TEmpWorkDataForm.Count1BtnClick(Sender: TObject);
var
  str : string;
begin
  str:=Count1Lb.Caption;
  if NumKeyBoardForm.GetValue(self,str,true) then Count1LB.Caption:=str;
end;

procedure TEmpWorkDataForm.Count2BtnClick(Sender: TObject);
var
  str : string;
begin
  str:=Count2Lb.Caption;
  if NumKeyBoardForm.GetValue(self,str,true) then Count2LB.Caption:=str;
end;

procedure TEmpWorkDataForm.OKBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrOK;
end;

procedure TEmpWorkDataForm.rt1Click(Sender: TObject);
begin
  self.SetRtBtn(strtoint(copy((sender as TSpeedButton).Name,3,maxint)));
end;

procedure TEmpWorkDataForm.TabNumBtnClick(Sender: TObject);
var
  str : string;
begin
  str:=TimeLb.Caption;
  if NumKeyBoardForm.GetValue(self,str,false) then TimeLB.Caption:=str;
end;

end.
