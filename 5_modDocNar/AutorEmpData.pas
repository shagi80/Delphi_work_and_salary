unit AutorEmpData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons,
  WorkTable;

const
  alBrigadier =  20;
  alForeman   =  10;

type
  TAutorEmpDataForm = class(TForm)
    CanelBtn: TSpeedButton;
    OKBtn: TSpeedButton;
    Img: TImage;
    NameLB: TLabel;
    Label1: TLabel;
    TimeBtn: TSpeedButton;
    Label3: TLabel;
    rt1: TSpeedButton;
    TimeLB: TLabel;
    Label4: TLabel;
    NoteLB: TLabel;
    NoteBtn: TSpeedButton;
    Shape1: TShape;
    rt2: TSpeedButton;
    rt3: TSpeedButton;
    rt4: TSpeedButton;
    rt5: TSpeedButton;
    Pay1CapLB: TLabel;
    Pay2CapLB: TLabel;
    PayCapLB: TLabel;
    Label7: TLabel;
    TotPayLB: TLabel;
    Pay2LB: TLabel;
    Pay1LB: TLabel;
    TimePayLB: TLabel;
    Label2: TLabel;
    DTWCB: TCheckBox;
    Label5: TLabel;
    StavPay: TLabel;
    procedure DTWCBClick(Sender: TObject);
    procedure NoteBtnClick(Sender: TObject);
    procedure rt1Click(Sender: TObject);
    procedure TimeBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    procedure SetRtBtn(num:integer);
    function  ShowWindow(sender:TComponent;var WTab : TWorkTable; ReadOnly:boolean):boolean;
    procedure  Calck;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AutorEmpDataForm: TAutorEmpDataForm;

implementation

{$R *.dfm}

uses GlobalUnit, NumKeyboard, Keyboard, ListView, ShadowForm, MsgForm;

var
  rating,dtw                 : integer;
  night,read,timepay         : boolean;
  TabNightPay, pay1,pay2, sum : real;

procedure TAutorEmpDataForm.Calck;
var
  tpay : real;
begin
  Label2.Caption:=FloatToStr(sum);

  //вычисляем сумму по часам (с учетом надбавки за ночь)
  if timepay then
   //if not (Night) then tpay:=sum*StrToFloat(TimeLB.Caption)*(1+AutorRatingVal[rating]/100) else tpay:=sum*StrToFloat(TimeLB.Caption)*TabNightPay*(1+AutorRatingVal[rating]/100)
   if not (Night) then tpay:=sum*StrToFloat(TimeLB.Caption) else tpay:=sum*StrToFloat(TimeLB.Caption)*TabNightPay
   else tpay:=0;
  //отображаем суммы по часам и по проценту
  Pay1LB.Caption:=FormatFloat('####0.00',tpay);
  StavPay.Caption:=FormatFloat('####0.00',pay1);
  if dtw=1 then Pay2LB.Caption:=FormatFloat('####0.00',pay2*AutorRatingVal[rating]/100)
    else Pay2LB.Caption:='лишен';
  //определяем какая сумма больше
  {if (pay1+(pay2*dtw*AutorRatingVal[rating]/100))<tpay then
    begin
      TotPayLB.Caption:=FormatFloat('####0.00',tpay);
      TimePayLB.Caption:='(оплата по часам)';
    end else
    begin
      if (AutorMaxPay>0)and((pay1+(pay2*dtw*AutorRatingVal[rating]/100))>AutorMaxPay) then begin
        TotPayLB.Caption:=FormatFloat('####0.00',AutorMaxPay);
        TimePayLB.Caption:='(ограничено)';
      end else begin
        TotPayLB.Caption:=FormatFloat('####0.00',(pay1+(pay2*dtw*AutorRatingVal[rating]/100)));
        TimePayLB.Caption:='(% от наряда)';
      end;
    end;    }
  //с 1 спентября 2020 г
  if (AutorMaxPay>0)and((tpay+pay1+(pay2*dtw*AutorRatingVal[rating]/100))>AutorMaxPay) then begin
        TotPayLB.Caption:=FormatFloat('####0.00',AutorMaxPay);
        TimePayLB.Caption:='(ограничено)';
  end else begin
        TotPayLB.Caption:=FormatFloat('####0.00',(tpay+pay1+(pay2*dtw*AutorRatingVal[rating]/100)));
        TimePayLB.Caption:='(по часам + %)';
  end;
end;

procedure TAutorEmpDataForm.SetRtBtn(num:integer);
var
  i   : integer;
begin
  rating:=num;
  for I := 0 to self.ControlCount-1 do
    if copy(self.Controls[i].Name,1,2)='rt' then
      begin
        (self.Controls[i] as TSpeedButton).Caption:=IntToStr(AutorRatingVal[StrToInt(copy(self.Controls[i].Name,3,1))])+'%';
        (self.Controls[i] as TSpeedButton).Font.Color:=clSilver;
        (self.Controls[i] as TSpeedButton).Font.Style:=[];
        if StrToInt(copy(self.Controls[i].Name,3,1))=num then
          begin
            (self.Controls[i] as TSpeedButton).Font.Style:=[fsBold];
            (self.Controls[i] as TSpeedButton).Font.Color:=clNavy;
          end;
      end;
end;

function  TAutorEmpDataForm.ShowWindow(sender:TComponent;var WTab : TWorkTable; ReadOnly:boolean):boolean;
begin
  read:=ReadOnly;
  TimeBtn.Enabled:=(not read);
  NoteBtn.Enabled:=(not read);
  TabNightPay:=WTab.NightPay;
  timepay:=WTab.AutorTimePay;
  WTab.CalckAutorPay(pay1,pay2);
  if WTab.datewrong then dtw:=0 else dtw:=1;
  DTWCB.Visible:=(Acsses=alAdmin);
  DTWCB.Checked:=WTAB.datewrong;
  DTWCB.Enabled:=(not Read);
  night:=WTab.Night;
  sum:=WTab.autor.Employ.funct.sum;
  NameLB.Caption:=WTab.autor.Employ.name;
  TimeLB.Caption:=FormatFloat('#0.##',WTab.autor.time);
  NoteLb.Caption:=WTab.autor.note;
  Img.Picture.Bitmap:=WTab.autor.Bitmap;
  self.SetRtBtn(WTab.autor.rating);
  self.Calck;
  PayCapLB.Caption:='(условия оплаты: ';
  if WTab.Night then PayCapLB.Caption:=PayCapLB.Caption+'доплата за работу в ночь '+
    FormatFloat('#0.0#',(WTab.NightPay-1)*100)+'%, ';
  if WTab.datewrong then PayCapLB.Caption:=PayCapLB.Caption+'процент от ставок не начисляется, ' else
    PayCapLB.Caption:=PayCapLB.Caption+'начисляется установленный оценкой процент от ставок, ';
  if WTab.AutorTimePay then PayCapLB.Caption:=PayCapLB.Caption+'разрешена оплата по часам)' else
    PayCapLB.Caption:=PayCapLB.Caption+'оплата по часам запрещена)';
  ShadowShow(sender);
  result:=(self.ShowModal=mrOK)and(not read);
  ShadowHide(sender);
  if (result)and(not read) then
    begin
        WTab.autor.time:=StrToFloat(TimeLB.Caption);
        WTab.autor.note:=NoteLB.Caption;
        WTab.autor.rating:=rating;
        WTab.datewrong:=(dtw=0);
        WTab.autor.ratval:=AutorRatingVal[rating];
        WTab.CalckAutorPay(pay1,pay2);
    end;
end;

procedure TAutorEmpDataForm.CanelBtnClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TAutorEmpDataForm.DTWCBClick(Sender: TObject);
begin
  if DTWCB.Checked then dtw:=0 else dtw:=1;
  self.Calck;
end;

procedure TAutorEmpDataForm.NoteBtnClick(Sender: TObject);
var
  str : string;
begin
  if read then Abort;
  str:=NoteLb.Caption;
  if KeyBoardForm.GetString(self,str,false) then NoteLB.Caption:=str;
end;

procedure TAutorEmpDataForm.OKBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrOK;
end;

procedure TAutorEmpDataForm.rt1Click(Sender: TObject);
begin
  if read then Abort;
  if (Acsses>alForeman) then
    begin
      ShowMSG(self,'Недостаточно прав доступа !',[msbOK]);
      Abort;
    end;
  self.SetRtBtn(strtoint(copy((sender as TSpeedButton).Name,3,maxint)));
  self.Calck;
end;

procedure TAutorEmpDataForm.TimeBtnClick(Sender: TObject);
var
  str : string;
begin
  if read then Abort;
  str:=TimeLb.Caption;
  if NumKeyBoardForm.GetValue(self,str,false) then TimeLB.Caption:=str;
  self.Calck;
end;

end.
