unit CalendarUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, ExtCtrls, Buttons, DateUtils, StdCtrls;

type
  TCalendarForm = class(TForm)
    MonthPn: TPanel;
    SG: TStringGrid;
    IncMonthBtn: TSpeedButton;
    DecmonthBtn: TSpeedButton;
    CancelBtn: TSpeedButton;
    MonthLb: TLabel;
    procedure SGDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure CancelBtnClick(Sender: TObject);
    procedure SGSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure DecmonthBtnClick(Sender: TObject);
    procedure IncMonthBtnClick(Sender: TObject);
    function GetDate(sender: TComponent;var Dt:TDate):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CalendarForm: TCalendarForm;

implementation

{$R *.dfm}

uses ShadowForm;

var
  CurDate : TDate;
  StDay : byte;


procedure TCalendarForm.CancelBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

function TCalendarForm.GetDate(sender: TComponent;var Dt:TDate):boolean;
begin
  CurDate:=Dt;
  MonthLb.Caption:=FormatDateTime('mmmm yyyy',CurDate);
  stday:=DayOfTheWeek(EncodeDate(YearOf(CurDate),MonthOf(CurDate),1));
  ShadowForm.ShadowShow(sender);
  if self.ShowModal=mrOk then
    begin
      Dt:=CurDate;
      result:=true;
    end else result:=false;
  ShadowForm.ShadowHide(sender);
end;

procedure TCalendarForm.SGDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  str  : WideString;
  Flag : Cardinal;
  Rct  : TRect;
  d    : byte;
begin
  SG.Canvas.FillRect(Rect);
  Flag := DT_CENTER or DT_SINGLELINE or DT_VCENTER;
  SG.Canvas.Font.Color:=clBlack;
  if (Arow=0)then
    begin
      case ACol of
        0:str:='ПНД';
        1:str:='ВТ';
        2:str:='СР';
        3:str:='ЧТ';
        4:str:='ПТН';
        5:str:='СБ';
        6:str:='ВС';
      end;
      if aCol>4 then SG.Canvas.Font.Color:=clRed;
    end else
      begin
        //Оопределение номера дня для соотв ячейки
        d:=(aRow-1)*7+(aCol+1)-StDay+1;
        //Оопределение вхождения номера дня для соотв ячейки в диапазон месяца
        if ((aRow=1)and((ACol+1)<stday))or(d>DaysInAMonth(YearOf(CurDate),MonthOf(CurDate)))
          then str:='' else
            begin
              str:=IntToStr(d);
              if EncodeDate(YearOf(CurDate),MonthOf(CurDate),d)=Date then SG.Canvas.Font.Color:=clRed;
            end;
      end;
  Rct:=Rect;
  Inc(Rct.Left,2);
  Inc(Rct.Top,2);
  DrawTextW((Sender as TDrawGrid).Canvas.Handle,PWideChar(str),length(str),Rct,Flag);
end;

procedure TCalendarForm.SGSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var
  d : byte;  
begin
  //Оопределение номера дня для соотв ячейки
  d:=(aRow-1)*7+(aCol+1)-StDay+1;
  //Оопределение вхождения номера дня для соотв ячейки в диапазон месяца
  if ((aRow=1)and((ACol+1)<stday))or(d>DaysInAMonth(YearOf(CurDate),MonthOf(CurDate)))
    then CanSelect:=false else CanSelect:=true;
  if CanSelect then
    begin
      CurDate:=EncodeDate(YearOf(CurDate),MonthOf(CurDate),d);
      self.ModalResult:=mrOk;
    end;
end;

procedure TCalendarForm.DecmonthBtnClick(Sender: TObject);
begin
  CurDate:=IncMonth(CurDate,-1);
  MonthLb.Caption:=FormatDateTime('mmmm yyyy',CurDate);
  stday:=DayOfTheWeek(EncodeDate(YearOf(CurDate),MonthOf(CurDate),1));
  SG.Repaint;
end;

procedure TCalendarForm.IncMonthBtnClick(Sender: TObject);
begin
  CurDate:=IncMonth(CurDate,1);
  MonthLb.Caption:=FormatDateTime('mmmm yyyy',CurDate);
  stday:=DayOfTheWeek(EncodeDate(YearOf(CurDate),MonthOf(CurDate),1));
  SG.Repaint;
end;

end.
