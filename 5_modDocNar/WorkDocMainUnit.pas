unit WorkDocMainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  WorkTable, Dialogs, ExtCtrls, StdCtrls, Grids, Buttons, EmployData;

type
  TWorkDocMainForm = class(TForm)
    TopPn: TPanel;
    WorkPn: TPanel;
    Label1: TLabel;
    WorkSG: TStringGrid;
    WorkBtnPn: TPanel;
    WorkEditBtn: TSpeedButton;
    WorkNotePn: TPanel;
    WorkNoteBtn: TSpeedButton;
    ItemPn: TPanel;
    Label2: TLabel;
    ItemSG: TStringGrid;
    ItemBtnPn: TPanel;
    WorkNoteMemo: TMemo;
    ItemDownBtn: TSpeedButton;
    ItemPrintBtn: TSpeedButton;
    ItemUpBtn: TSpeedButton;
    ItemEditBtn: TSpeedButton;
    WorkPrintAllBtn: TSpeedButton;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    DateBtn: TSpeedButton;
    DateLB: TLabel;
    CancelBtn: TSpeedButton;
    SaveBtn: TSpeedButton;
    Bevel1: TBevel;
    Bevel2: TBevel;
    NightBtn: TSpeedButton;
    AutorPn: TPanel;
    AutorEditBtn: TSpeedButton;
    AutorImg: TImage;
    AutorLB: TLabel;
    Panel1: TPanel;
    NumberLB: TLabel;
    CreateLB: TLabel;
    Bevel4: TBevel;
    RecalcBtn: TSpeedButton;
    procedure WorkPrintAllBtnClick(Sender: TObject);
    procedure AutorEditBtnClick(Sender: TObject);
    procedure NightBtnClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure DateBtnClick(Sender: TObject);
    procedure ItemEditBtnClick(Sender: TObject);
    procedure ItemPrintBtnClick(Sender: TObject);
    procedure WorkEditBtnClick(Sender: TObject);
    procedure WorkNoteBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure UpdateWorkTable;
    procedure UpdateItemTable;
    procedure UpDownBtnClick(Sender: TObject);
    //function  ShowWindow(UserEmpl:TEmploy; num : integer; aLevel : integer; var res:TNarDocCreateRes):boolean;
    function  ShowWindow(var TableForm:TWorkTableForm; var Table:TWorkTable;aLevel : integer):boolean;
    procedure UpdateAutorPay;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure RecalcBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WorkDocMainForm: TWorkDocMainForm;

implementation

{$R *.dfm}

uses GlobalUnit, Keyboard, MsgForm, NumKeyboard, WorkData,
  CalendarUnit, AutorEmpData, DateUtils, PrintUnit;

var
  WorkTableForm : TWorkTableForm;
  WorkTab       : TWorkTable;
  NeedSave      : boolean;
  Saved         : boolean;

//расчет начислений автора наряда
procedure TWorkDocMainForm.UpdateAutorPay;
begin
  if (WorkTab.AutorCalck) then
    begin
      AutorLB.Caption:='Начальник смены:'+chr(13)+
        EmployList.ShortName(WorkTab.Autor.Employ.name)+chr(13)+
        FormatFloat('###0.00',WorkTab.Autor.payroll)+' руб';
      if WorkTab.datewrong then AutorLB.Caption:=AutorLB.Caption+chr(13)+
        '(без % надбавки)';
    end else
      AutorLB.Caption:='Автор наряда:'+chr(13)+EmployList.ShortName(WorkTab.Autor.Employ.name);
end;

procedure TWorkDocMainForm.AutorEditBtnClick(Sender: TObject);
begin
  //Заплатка в связи с неправильным расчетом суммы в окне данных о работе автора
  //до 17.03 к почасовой оплате не прибавлялся процент. Поэтому в нарядах до 18.03
  //в окне автора сумма считается завышенной - с прибалением процента
  if WorkTab.MyDate<EncodeDate(2017,03,18) then begin
    ShowMsg(self,'В связи с расчетной ошибкой в нарядах до 18.03.2017 окно информации о работе автора не отображается !',
      [msbOK]);
    Abort;
  end;

  if AutorEmpDataForm.ShowWindow(self,WorkTab,(Acsses>alBrigadier)) then
    begin
      self.UpdateAutorPay;
      NeedSave:=true;
    end;
end;

procedure TWorkDocMainForm.CancelBtnClick(Sender: TObject);
begin
  self.Close;
end;

procedure TWorkDocMainForm.DateBtnClick(Sender: TObject);
var
  dt        : Tdate;
  pay1,pay2 : real;
begin
  dt:=WorkTab.MyDate;
  if CalendarForm.GetDate(self,dt) then
    begin
      if dt>date then
        begin
          ShowMsg(self,'Дата позже сегодняшней!',[msbOk]);
          Abort;
        end;
      if dt<=CloseDate then
        begin
          ShowMsg(self,'База закрыта с '+FormatDateTime('dd mmm yyyy',CloseDate)+chr(13)
            +'Работа с выбранной вами датой невозможна!',[msbOk]);
          Abort;
        end;
      if (WorkTab.AutorCalck)then
        if (dt<IncDay(DateOf(WorkTab.createtime),-1))then
            begin
              if(ShowMsg(self,'Наряд выполняется с опозданием более чем в 1 день. '+
                'Начисление премии начальнику смены производится не будет. Продолжить?',[msbOk,msbCancel])=msbOK)
                  then WorkTab.datewrong:=true else Abort;
            end else WorkTab.datewrong:=false;
      Worktab.CalckAutorPay(pay1,pay2);
      self.UpdateAutorPay;
      WorkTab.MyDate:=dt;
      DateLB.Caption:=FormatDateTime('dd mmm yyyy',WorkTab.MyDate)+chr(13)+
        FormatDateTime('dddd',WorkTab.MyDate);
      NeedSave:=true;
    end;
end;

procedure TWorkDocMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if(Acsses=alViewer)or(not NeedSave)or((NeedSave)and(Acsses<alViewer)and(ShowMsg(self,'Наряд не записан!'+chr(13)
    +'Вы уверенны, что хотите выйти?',[msbOK,msbCancel])=msbOK)) then else Action:=caNone;
end;

procedure TWorkDocMainForm.FormResize(Sender: TObject);
var
  pnt : tpoint;
begin
  WorkPn.Width:=round(self.ClientWidth*0.45);
  WorkPn.Margins.Left:=round(self.ClientWidth*0.045);
  WorkSG.ColWidths[0]:=WorkSG.ClientWidth-WorkSG.ColWidths[1]-WorkSG.ColWidths[2];
  WorkBtnPn.Margins.Left:=round((WorkPn.Width-(WorkPrintAllBtn.Left+WorkPrintAllBtn.Width+30))/2);
  WorkBtnPn.Margins.Right:=WorkBtnPn.Margins.Left;
  ItemPn.Width:=round(self.ClientWidth*0.45);
  ItemSG.ColWidths[0]:=ItemSG.ClientWidth-ItemSG.ColWidths[1]-ItemSG.ColWidths[2]-ItemSG.ColWidths[3]-ItemSG.ColWidths[4];
  ItemBtnPn.Margins.Left:=round((ItemPn.Width-(ItemPrintBtn.Left+ItemPrintBtn.Width+30))/2);
  ItemBtnPn.Margins.Right:=ItemBtnPn.Margins.Left;
  pnt.X:=WorkBtnPn.Left;
  pnt.y:=WorkBtnPn.Top;
  pnt:=WorkPn.ClientToScreen(pnt);
  pnt:=self.ScreenToClient(pnt);
  WorkNotePn.Margins.Left:=pnt.X;
  pnt.X:=ItemBtnPn.Left+ItemBtnPn.Width;
  pnt.y:=ItemBtnPn.Top+ItemBtnPn.Height;
  pnt:=ItemPn.ClientToScreen(pnt);
  pnt:=self.ScreenToClient(pnt);
  WorkNotePn.Margins.Right:=self.ClientWidth-pnt.X;
end;

//Кнопки Вверх и Вниз обоих таблиц
procedure TWorkDocMainForm.UpDownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='ItemDownBtn')and(ItemSG.Selection.Top<ItemSG.RowCount-1) then
    ItemSG.Selection:=TGridRect(rect(0,ItemSg.Selection.Top+1,ItemSG.ColCount-1,ItemSg.Selection.Top+1));
  if ((Sender as TSpeedButton).name='ItemUpBtn')and(ItemSg.Selection.Top>1) then
    ItemSG.Selection:=TGridRect(rect(0,ItemSg.Selection.Top-1,ItemSG.ColCount-1,ItemSg.Selection.Top-1));
end;

//Обновление таблицы результатов работы персонала
procedure TWorkDocMainForm.UpdateWorkTable;
var
  i : integer;
begin
  WorkSG.Cells[0,0]:=' Слотрудник';
  WorkSG.Cells[1,0]:=' Часы';
  WorkSG.Cells[2,0]:=' Нач-ние';
  WorkSG.Enabled:=(WorkTab.EmployCount>0);
  if WorkTab.EmployCount=0 then
    begin
      WorkSG.RowCount:=2;
      WorkSG.Rows[1].Clear;
    end else
    begin
      WorkSG.RowCount:=WorkTab.EmployCount+1;
      for i := 0 to WorkTab.EmployCount - 1 do
        begin
          WorkSG.Cells[0,i+1]:=WorkTab.Employees[i].Employ.name;
          WorkSG.Cells[1,i+1]:=FormatFloat('#0.#',WorkTab.Employees[i].time)+' час';
          WorkSG.Cells[2,i+1]:=FormatFloat('####0.00',WorkTab.Employees[i].payroll)+' руб';
        end;
    end;
end;

//Обновление таблицы результатов приозводства
procedure TWorkDocMainForm.UpdateItemTable;
var
  i : integer;
begin
  ItemSG.Cells[0,0]:=' Деталь';
  ItemSG.Cells[1,0]:=' Гот прод';
  ItemSG.Cells[2,0]:=' Брак';
  ItemSG.Cells[3,0]:=' Общ вр';
  ItemSG.Cells[4,0]:=' Цикл,с';
  ItemBtnPn.Enabled:=(WorkTab.ItemCount>0);
  if WorkTab.ItemCount>0 then ItemSG.RowCount:=WorkTab.ItemCount+1 else ItemSG.RowCount:=2;
  ItemSG.Rows[1].Clear;
  for i := 0 to WorkTab.ItemCount - 1 do
    begin
      ItemSG.Cells[0,i+1]:=WorkTab.ItemList[i].Item.name;
      ItemSG.Cells[1,i+1]:=IntToStr(WorkTab.ItemList[i].good)+' ед';
      if WorkTab.ItemList[i].good>0 then
        ItemSG.Cells[2,i+1]:=IntToStr(WorkTab.ItemList[i].bad)+' ('+
          FormatFloat('##0.##',WorkTab.ItemList[i].bad/(WorkTab.ItemList[i].good+WorkTab.ItemList[i].bad)*100)+'%)'
        else ItemSG.Cells[2,i+1]:=IntToStr(WorkTab.ItemList[i].bad)+' (100%)';
      ItemSG.Cells[3,i+1]:=FormatFloat('##0.0#',WorkTab.ItemList[i].hour);
      ItemSG.Cells[4,i+1]:=FormatFloat('##0.0#',WorkTab.ItemList[i].cycle);
    end;
end;

//function TWorkDocMainForm.ShowWindow(UserEmpl:TEmploy;num : integer; aLevel : integer; var res:TNarDocCreateRes):boolean;
function TWorkDocMainForm.ShowWindow(var TableForm:TWorkTableForm; var Table:TWorkTable;aLevel : integer):boolean;
var
  bmp   : TBitMap;
  buf   : word;
begin
  buf:=Acsses;
  Acsses:=alevel;
  RecalcBtn.Visible:=(Acsses=alAdmin);
  WorkTableForm:=TableForm;
  WorkTab:=Table;
  WorkTab.change:=false;
  WorkTab.itmchange:=false;
  NeedSave:=false;
  Saved   :=false;
  //Ограничение прав бригадира
  WorkNoteBtn.Enabled:=(aLevel<=alBrigadier);
  DateBtn.Enabled:=(aLevel<=alBrigadier);
  AutorEditBtn.Enabled:=(WorkTab.autorcalck);
  NightBtn.Enabled:=(aLevel<=alBrigadier);
  SaveBtn.Visible:=(aLevel<=alBrigadier);
  ItemEditBtn.Enabled:=(aLevel<=alBrigadier);
  //Обновление визуальных элементов главного окна
  CreateLB.Caption:='(создан '+FormatDateTime('dd.mm.yy hh:mm',WorkTab.createtime)+')';
  WorkNoteMemo.Text:=WorkTab.note;
  self.UpdateWorkTable;
  self.UpdateItemTable;
  DateLB.Caption:=FormatDateTime('dd mmm yyyy',WorkTab.MyDate)+chr(13)+
        FormatDateTime('dddd',WorkTab.MyDate);
  NumberLb.Caption:='Наряд №'+chr(13)+FormatFloat('00000',WorkTab.number);
  bmp:=TBitMap.Create;
  if WorkTab.night then bmp.LoadFromResourceName(hInstance, 'NightBtnImg')
        else bmp.LoadFromResourceName(hInstance, 'SunBtnImg');
  NightBtn.Glyph:=bmp;
  NightBtn.NumGlyphs:=2;
  bmp.Free;
  self.UpdateAutorPay;
  AutorImg.Picture.Bitmap:=WorkTab.Autor.Bitmap;
  //Показ окна
  self.ShowModal;
  result:=Saved;
  Acsses:=buf;
end;

procedure TWorkDocMainForm.ItemEditBtnClick(Sender: TObject);
var
  time:string;
  ind : integer;
begin
  if (ItemSG.Enabled)and(ItemSG.Selection.Top>0) then
    begin
      NeedSave:=true;
      ind:=ItemSG.Selection.Top;
      time:=ItemSG.Cells[4,ind];
      if NumKeyBoardForm.GetValue(self,time,false) then
        begin
          ItemSG.Cells[4,ind]:=time;
          WorkTab.ItemList[ind-1].cycle:=StrToFloat(time);
        end;
    end;
end;

procedure TWorkDocMainForm.ItemPrintBtnClick(Sender: TObject);
begin
  if FileExists(ExePath+DefBaseFolder+WorkTab.fname) then
    printmod.PrintNarItemList(ExePath+DefBaseFolder+WorkTab.fname)
  else ShowMsg(self,'Наряд не записан!',[msbOk])
end;

procedure TWorkDocMainForm.NightBtnClick(Sender: TObject);
var
  bmp : TBitMap;
begin
  NeedSave:=true;
  WorkTab.night:=not WorkTab.night;
  bmp:=TbitMap.Create;
  if WorkTab.night then bmp.LoadFromResourceName(hInstance, 'NightBtnImg')
    else bmp.LoadFromResourceName(hInstance, 'SunBtnImg');
  NightBtn.Glyph:=bmp;
  bmp.Free;
  WorkTab.Night:=WorkTab.night;
  WorkTab.ChangeAndRepaint;
  self.UpdateWorkTable;
  self.UpdateAutorPay;
end;

procedure TWorkDocMainForm.SaveBtnClick(Sender: TObject);
var
  i : integer;
begin
  if Length(WorkTab.fname)=0 then WorkTab.fname:='doc'+IntToStr(WorkTab.number)+'.nrd';
  WorkTab.note:=WorkNoteMemo.Text;
  //проверка макс начисления для рабочих
  i:=0;
  while(i<WorkTab.EmployCount)and(WorkTab.Employees[i].payroll<=EmplMaxPay)do inc(i);
  if(i<WorkTab.EmployCount)then begin
    ShowMSG(self,'Сотрудник '+WorkTab.Employees[i].Employ.name+
        chr(13)+' заработал более '+
        FormatFloat('###0.00',EmplMaxPay)+'рублей !'+chr(13)+
        'Наряд не может быть расчитан !',[msbOK]);
    Abort;
  end;
  //проверка макс начисления для автора
  if(WorkTab.autor.payroll>AutorMaxPay)then begin
    ShowMSG(self,'Автор наряда заработал более '+chr(13)+
        FormatFloat('###0.00',AutorMaxPay)+'рублей !'+chr(13)+
        'Наряд не может быть расчитан !',[msbOK]);
    Abort;
  end;
  //проверка записи времени цикла
  i:=0;
  while(i<WorkTab.ItemCount)and(WorkTab.ItemList[i].cycle>0) do inc(i);
  if(i=WorkTab.ItemCount)or(AskCycleTime=false)then
    begin
      WorkTab.SaveToFile(ExePath+DefBaseFolder+WorkTab.fname);
      NeedSave:=false;
      Saved   :=true;
    end else
      ShowMSG(self,'Для '+WorkTab.ItemList[i].Item.name+chr(13)+' не уканно время цикла!',[msbOK]);
end;

procedure TWorkDocMainForm.WorkEditBtnClick(Sender: TObject);
begin
  WorkTableForm.ShowModal;
  NeedSave:=WorkTab.change;
  self.UpdateWorkTable;
  self.UpdateItemTable;
  self.UpdateAutorPay;
end;

procedure TWorkDocMainForm.WorkNoteBtnClick(Sender: TObject);
var
  note:string;
begin
  note:=WorkNoteMemo.Text;
  NeedSave:=true;
  if  KeyboardForm.GetString(self,note,false) then WorkNoteMemo.Text:=note;
end;

procedure TWorkDocMainForm.WorkPrintAllBtnClick(Sender: TObject);
begin
 if ((Acsses=alViewer)or(not NeedSave))and(FileExists(ExePath+DefBaseFolder+WorkTab.fname)) then
    printmod.PrintNarEmplList(ExePath+DefBaseFolder+WorkTab.fname)
  else ShowMsg(self,'Наряд не записан!',[msbOk])
end;


// пересчет по новым ставкам


procedure TWorkDocMainForm.RecalcBtnClick(Sender: TObject);
var
  e,w,id : integer;
begin


  WorkTab.autor.ratval:=AutorRatingVal[WorkTab.autor.rating];
  for e := 0 to workTab.EmployCount - 1 do begin
    id:=FunctionList.IndFromCode(WorkTab.Employees[e].funct.code);
    if id>=0 then WorkTab.Employees[e].funct:=FunctionList.Item[id];
    id:=EmployList.IndFromCode(WorkTab.Employees[e].Employ.code);

    {showmessage(WorkTab.Employees[e].Employ.name+'  '+
       WorkTab.Employees[e].Employ.code+'  '+inttostr(id)); }

    if id>=0 then id:=FunctionList.IndFromCode(EmployList.Item[id].funct.code);
    if id>=0 then WorkTab.Employees[e].Employ.funct:=FunctionList.Item[id];

    WorkTab.Employees[e].ratval:=RatingVal[WorkTab.Employees[e].rating];

    for w := 0 to high(WorkTab.Employees[e].Works) do begin
      WorkTab.Employees[e].Works[w].Work.PayRoll:=
        WorkList.GetItemByCode(WorkTab.Employees[e].Works[w].Work.code).PayRoll;
    { showmessage( WorkTab.Employees[e].Works[w].Work.name+chr(13)+
      FloatToStr(WorkTab.Employees[e].Works[w].Work.PayRoll)+chr(13)+
      'Raiting='+IntToStr(WorkTab.autor.rating)+chr(13)+
      ''+Floattostr(WorkTab.autor.ratval));  }
    end;
  end;

  id:=EmployList.IndFromCode(WorkTab.autor.Employ.code);
  if id>=0 then id:=FunctionList.IndFromCode(EmployList.Item[id].funct.code);
  if id>=0 then WorkTab.autor.Employ.funct:=FunctionList.Item[id];
  WorkTab.autor.ratval:=AutorRatingVal[WorkTab.autor.rating];
      {ShowMessage(WorkTab.autor.Employ.name+chr(13)+WorkTab.autor.Employ.funct.name+chr(13)+
        FloatTostr(WorkTab.autor.Employ.funct.sum)+chr(13)+
      'Raiting='+IntToStr(WorkTab.autor.rating)+chr(13)+
      ''+Floattostr(WorkTab.autor.ratval));  }


  for e := 0 to high(WorkTab.GroupWork) do
    WorkTab.GroupWork[e].Work.PayRoll:=WorkList.GetItemByCode(WorkTab.GroupWork[e].Work.code).PayRoll;
  WorkTab.ChangeAndRepaint;
  self.UpdateWorkTable;
  self.UpdateItemTable;
  self.UpdateAutorPay;
end;


end.
