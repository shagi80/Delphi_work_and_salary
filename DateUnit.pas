unit DateUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons;

type
  TDateForm = class(TForm)
    CloseBtn: TSpeedButton;
    SpeedButton1: TSpeedButton;
    Label1: TLabel;
    Date1LB: TLabel;
    Date2LB: TLabel;
    SpeedButton2: TSpeedButton;
    MonthBtn: TSpeedButton;
    Month1Btn: TSpeedButton;
    Month2Btn: TSpeedButton;
    OkBtn: TSpeedButton;
    Shape1: TShape;
    PrevMonthBtn: TSpeedButton;
    procedure PrevMonthBtnClick(Sender: TObject);
    procedure MonthBtnClick(Sender: TObject);
    procedure Month2BtnClick(Sender: TObject);
    procedure Month1BtnClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    function ShowWindow(sender:TComponent;var dt1,dt2:Tdate):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DateForm: TDateForm;

implementation

{$R *.dfm}

uses CalendarUnit, ShadowForm,DateUtils;

var
  date1,date2:TDate;

procedure TDateForm.CloseBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

procedure TDateForm.OkBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrOK;
end;

function TDateForm.ShowWindow(sender:TComponent;var dt1,dt2:Tdate):boolean;
begin
  result:=false;
  Date1:=dt1;
  Date2:=dt2;
  Date1LB.Caption:='c '+FormatDateTime('dd mmm yyy (ddd)',Date1);
  Date2LB.Caption:='по '+FormatDateTime('dd mmm yyy (ddd)',Date2);
  ShadowShow(sender);
  if self.ShowModal=mrOk then
    begin
      dt1:=StartOfTheDay(Date1);
      dt2:=EndOfTheDay(Date2);
      result:=true;
    end;
  ShadowHide(sender);
end;

procedure TDateForm.SpeedButton1Click(Sender: TObject);
begin
  CalendarForm.GetDate(self,date1);
  Date1LB.Caption:='c '+FormatDateTime('dd mmm yyy (ddd)',Date1);
end;

procedure TDateForm.SpeedButton2Click(Sender: TObject);
begin
  CalendarForm.GetDate(self,date2);
  Date2LB.Caption:='по '+FormatDateTime('dd mmm yyy (ddd)',Date2);
end;

procedure TDateForm.MonthBtnClick(Sender: TObject);
begin
  Date1:=TDate(StartOfTheMonth(now));
  Date2:=TDate(EndOfTheMonth(now));
  Date1LB.Caption:='c '+FormatDateTime('dd mmm yyy (ddd)',Date1);
  Date2LB.Caption:='по '+FormatDateTime('dd mmm yyy (ddd)',Date2);
end;

procedure TDateForm.Month1BtnClick(Sender: TObject);
begin
  Date1:=TDate(StartOfTheMonth(now));
  Date2:=IncDay(TDate(StartOfTheMonth(now)),14);
  Date1LB.Caption:='c '+FormatDateTime('dd mmm yyy (ddd)',Date1);
  Date2LB.Caption:='по '+FormatDateTime('dd mmm yyy (ddd)',Date2);
end;

procedure TDateForm.Month2BtnClick(Sender: TObject);
begin
  Date1:=IncDay(TDate(StartOfTheMonth(now)),15);
  Date2:=TDate(EndOfTheMonth(now));
  Date1LB.Caption:='c '+FormatDateTime('dd mmm yyy (ddd)',Date1);
  Date2LB.Caption:='по '+FormatDateTime('dd mmm yyy (ddd)',Date2);
end;

procedure TDateForm.PrevMonthBtnClick(Sender: TObject);
begin
  Date1:=TDate(StartOfTheMonth((StartOfTheMonth(now)-1)));
  Date2:=TDate(EndOfTheMonth((StartOfTheMonth(now)-1)));
  Date1LB.Caption:='c '+FormatDateTime('dd mmm yyy (ddd)',Date1);
  Date2LB.Caption:='по '+FormatDateTime('dd mmm yyy (ddd)',Date2);
end;

end.
