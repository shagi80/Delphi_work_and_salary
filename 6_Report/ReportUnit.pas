
unit ReportUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, ExtCtrls, Grids, StdCtrls, ComCtrls;

type
  TSimplNarPayRec = record
    code,name : string;
    hour, pay, fld1 : real;
  end;

  TSimpleNarPayLst = array of TSimplNarPayRec;

  TReportForm = class(TForm)
    NameLB: TLabel;
    Name2LB: TLabel;
    BtnPn: TPanel;
    CloseBtn: TSpeedButton;
    SB: TScrollBox;
    DownBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    PrintBtn: TSpeedButton;
    Bevel1: TBevel;
    Bevel2: TBevel;
    SaveDlg: TSaveDialog;
    SaveBtn: TSpeedButton;
    procedure PrintBtnClick(Sender: TObject);
    procedure DownBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure OpenDoc(Sender: TObject);
    procedure LabelClick(Sender: TObject);
    procedure OpenEmpPayRep(Sender: TObject);
    procedure OpenEmpBadRep(Sender: TObject);
    procedure OpenOneItemRep(Sender: TObject);
    function  AddRow(capt,text,res,data:string):TPanel;
    procedure SaveBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


procedure LstPayReport(Dt1,Dt2:TDate;Codes:TStringList);
procedure LstItemReport(Dt1,Dt2:TDate;Codes:TStringList);
procedure EmpPayReport(Dt1,Dt2:TDate;Code:string);
procedure OneItemReport(Dt1,Dt2:TDate;Code:string);
procedure EmpBadItemReport(Dt1,Dt2:TDate;Code:string);
procedure LstEmpBadItemReport(Dt1,Dt2:TDate;Codes:TStringList);


implementation

{$R *.dfm}

uses PrintUnit, DateUtils, WorkData, MsgForm, DocListUnit, WorkDocMainUnit,
      WorkTable, GlobalUnit, EmployData;


var
  //переменные для передачи данных в процедуры печати
  date1,date2 : TDate;
  codelst     : TStringList;
  onecode     : string;

  //для создание выгрузки для 1С
  strs        : TStringList;



procedure TReportForm.LabelClick(Sender: TObject);
begin
  ((sender as TLabel).Parent as TPanel).OnClick((sender as TLabel).Parent);
end;

procedure TReportForm.OpenDoc(Sender: TObject);
var
  ind     : integer;
  Form    : TWorkTableForm;
  Tab     : TWorkTable;
begin
  ind:=StrToInt(copy((sender as TPanel).Name,3,maxint));
  ind:=MainList.IndByNum(ind);
  if not FileExists(ExePath+DefBaseFolder+MainList.Item[ind].fname) then
    begin
      ShowMsg(self,'Файл не найден в базе!'+chr(13)+
        'Наряд будет исключен из расчетов!',[msbOK]);
      MainList.Item[ind].AddRec(dsDelete,now,User);
      Abort;
    end;
  //Создание таблицы работ, зарузка документа
  //Создание формы
  Form := TWorkTableForm.Create(application);
  Tab := TWorkTable.Create(Form);
  Tab.fname:=MainList.Item[ind].fname;
  Tab.LoadFromFile(ExePath+DefBaseFolder+MainList.Item[ind].fname);
  Tab.Align:=alClient;
  Tab.AlignWithMargins:=true;
  Tab.Bevel:=4;
  Form.InsertControl(Tab);
  WorkDocMainForm.ShowWindow(Form,Tab,alViewer);
  Form.Free;
end;

procedure TReportForm.OpenOneItemRep(Sender: TObject);
var
  str,code: string;
  dt1,dt2 : TDate;
  y,m,d   : word;
begin
  str:=copy((sender as TPanel).Name,3,maxint);
  d:=StrToInt(copy(str,1,2));
  m:=StrToInt(copy(str,3,2));
  y:=StrToInt(copy(str,5,4));
  dt1:=EncodeDate(y,m,d);
  d:=StrToInt(copy(str,9,2));
  m:=StrToInt(copy(str,11,2));
  y:=StrToInt(copy(str,13,4));
  dt2:=EncodeDate(y,m,d);
  code:=ItemList.Item[StrToInt(copy(str,17,maxint))].code;
  OneItemReport(dt1,dt2,code);
end;

procedure TReportForm.PrintBtnClick(Sender: TObject);
begin
  case (sender as TSpeedButton).tag of
    pmEmpPayList    : PrintMod.PrintEmpPayList(date1,date2,codelst,repPrint);
    pmItemList      : PrintMod.PrintItemList(date1,date2,codelst,repPrint);
    pmOneEmpPay     : PrintMod.PrintOneEmpPay(Date1,Date2,onecode,repPrint);
    pmOneItem       : PrintMod.PrintOneItem(Date1,Date2,onecode,repPrint);
    pmLstEmpBadItem : PrintMod.PrintLstEmpBadItem(Date1,Date2,codelst,repPrint);
    pmOneEmpBadItem : PrintMod.PrintOneEmpBadItem(Date1,Date2,onecode,repPrint);
  end;
end;

procedure TReportForm.SaveBtnClick(Sender: TObject);
begin
  if (strs<>nil)and(SaveDlg.Execute) then strs.SaveToFile(SaveDlg.FileName);
end;

procedure TReportForm.OpenEmpPayRep(Sender: TObject);
var
  str,code: string;
  dt1,dt2 : TDate;
  y,m,d   : word;
begin
  str:=copy((sender as TPanel).Name,3,maxint);
  d:=StrToInt(copy(str,1,2));
  m:=StrToInt(copy(str,3,2));
  y:=StrToInt(copy(str,5,4));
  dt1:=EncodeDate(y,m,d);
  d:=StrToInt(copy(str,9,2));
  m:=StrToInt(copy(str,11,2));
  y:=StrToInt(copy(str,13,4));
  dt2:=EncodeDate(y,m,d);
  code:=EmployList.Item[StrToInt(copy(str,17,maxint))].code;
  EmpPayReport(dt1,dt2,code);
end;

procedure TReportForm.OpenEmpBadRep(Sender: TObject);
var
  str,code: string;
  dt1,dt2 : TDate;
  y,m,d   : word;
begin
  str:=copy((sender as TPanel).Name,3,maxint);
  d:=StrToInt(copy(str,1,2));
  m:=StrToInt(copy(str,3,2));
  y:=StrToInt(copy(str,5,4));
  dt1:=EncodeDate(y,m,d);
  d:=StrToInt(copy(str,9,2));
  m:=StrToInt(copy(str,11,2));
  y:=StrToInt(copy(str,13,4));
  dt2:=EncodeDate(y,m,d);
  code:=EmployList.Item[StrToInt(copy(str,17,maxint))].code;
  EmpBadItemReport(dt1,dt2,code);
end;

function TReportForm.AddRow(capt,text,res,data:string):TPanel;
var
  ResLB,CapLb,TextLB : TLabel;
begin
  result:=TPanel.Create(SB);
  result.Align:=alTop;
  result.BorderStyle:=bsNone;
  result.BevelKind:=bkFlat;
  result.AlignWithMargins:=true;
  result.Name:=data;
  result.AutoSize:=true;
  result.Color:=clCream;
  CapLB:=TLabel.Create(result);
  CapLB.Align:=alTop;
  CapLB.Font.Size:=14;
  CapLB.Font.Style:=[fsBold];
  CapLB.AlignWithMargins:=true;
  CapLB.Caption:=capt;
  CapLB.OnClick:=LabelClick;
  result.InsertControl(CapLB);
  TextLB:=TLabel.Create(result);
  TextLB.Align:=alTop;
  TextLB.Font.Size:=12;
  TextLB.AlignWithMargins:=true;
  TextLB.Margins.Left:=10;
  if Length(res)=0 then TextLB.Margins.Bottom:=10;
  TextLB.Caption:=text;
  TextLB.OnClick:=LabelClick;
  result.InsertControl(TextLB);
  if Length(res)>0 then
    begin
      ResLB:=TLabel.Create(result);
      ResLB.Align:=alTop;
      ResLB.Font.Size:=12;
      ResLB.Font.Style:=[fsBold];
      ResLB.AlignWithMargins:=true;
      ResLB.Margins.Left:=10;
      ResLB.Margins.Bottom:=10;
      ResLB.Caption:=Res;
      ResLB.OnClick:=LabelClick;
      result.InsertControl(ResLB);
    end;
  result.Caption:='';
  SB.InsertControl(result);
end;

//------------------------------------------------------------------------------

procedure LstItemReport(Dt1,Dt2:TDate;Codes:TStringList);
var
  doc,i,j,datacnt : integer;
  item            : TListRec;
  fname,str,cap,data   : string;
  SimpData        : array of TItemResRec;
  NarDoc          : TWorkTable;
  RepForm         : TReportForm;
begin
  RepForm:= TReportForm.Create(application);
  RepForm.SaveBtn.Visible:=true;
  //записываем исх данные отчета для последующего вызова процедуры печати
  date1:=dt1;
  date2:=dt2;
  codelst:=codes;
  RepForm.PrintBtn.Tag:=pmItemList;
  //----------------------------------------------------------------------
  with RepForm do
  begin
  NameLB.Caption:='Отчет по производству';
  Name2LB.Caption:='за период c '+FormatDateTime('dd mmm yyyy (ddd)',Dt1)+
    ' по '+FormatDateTime('dd mmm yyyy (ddd)',Dt2);
  //создание выгрузки для 1С
  if strs<>nil then strs.Free;  
  strs := TStringList.Create;
  //Склад источник и склад получатель
  strs.Add('"Ц0084","Склад Цех ТПА"," - склад источник"');
  strs.Add('"Ц0084","Склад Цех ТПА"," - склад получатель"');
  //Загрузка данных
  datacnt:=0;
  SetLength(SimpData,datacnt);
  //цикл по списку документов
  for doc := 0 to MainList.Count - 1 do
    begin
      item:=MainList.Item[doc];
      //выбираем документы в заданом диапазоне и только проведенные
      if (Item.Date>=Dt1)and(Item.Date<=Dt2)and(Item.LastStatus.stat<>dsDelete) then
        begin
          fname:='doc'+IntTOStr(Item.Num)+'.nrd';
          if FileExists(ExePath+DefBaseFolder+fname) then
            begin
              //загружаем данные о работе сотрудников из документа
              NarDoc:=TWorkTable.Create(RepForm);
              NarDoc.LoadFromFile(ExePath+DefBaseFolder+fname);
              if NarDoc.Night then
                strs.Add('"'+FormatDateTime('dd.mm.yyyy',IncDay(NarDoc.MyDate))+' 08:00:00"')
              else
                strs.Add('"'+FormatDateTime('dd.mm.yyyy',NarDoc.MyDate)+' 18:00:00"');
              //записываем начисления сотрудников из списка
              for i:=0 to NarDoc.ItemCount-1 do
                begin
                  //создание выгрузки для 1С
                  strs.Add('"'+NarDoc.ItemList[i].Item.code+'","'+
                    NarDoc.ItemList[i].Item.name+'","'+
                    IntToStr(NarDoc.ItemList[i].good+NarDoc.ItemList[i].bad)+'"');
                  j:=0;
                  while(j<datacnt)and(SimpData[j].Item.code<>NarDoc.ItemList[i].Item.code)do inc(j);
                  if(j<datacnt)and(SimpData[j].Item.code=NarDoc.ItemList[i].Item.code)then
                      begin
                        SimpData[j].good:=SimpData[j].good+NarDoc.ItemList[i].good;
                        SimpData[j].bad:=SimpData[j].bad+NarDoc.ItemList[i].bad;
                        SimpData[j].hour:=SimpData[j].hour+NarDoc.ItemList[i].hour;
                        SimpData[j].cycle:=SimpData[j].cycle+NarDoc.ItemList[i].cycle;
                        //счетчик упаминаний для подсчета среднего времени цикла
                        SimpData[j].Item.time:=SimpData[j].Item.time+1;
                      end else
                      begin
                        inc(DataCnt);
                        SetLength(SimpData,datacnt);
                        SimpData[datacnt-1].Item:=NarDoc.ItemList[i].Item;
                        SimpData[datacnt-1].good:=NarDoc.ItemList[i].good;
                        SimpData[datacnt-1].bad:=NarDoc.ItemList[i].bad;
                        SimpData[datacnt-1].hour:=NarDoc.ItemList[i].hour;
                        SimpData[datacnt-1].cycle:=NarDoc.ItemList[i].cycle;
                        //счетчик упаминаний для подсчета среднего времени цикла
                        SimpData[datacnt-1].Item.time:=1;
                      end;
                  end;
              NarDoc.Free;
            end;
        end;
    end;
  //Вывод данных
  while(SB.ControlCount>0)do SB.Controls[0].Free;
  str:='';
  for j := 0 to Codes.Count - 1 do
    begin
      cap:=IntToStr(j+1)+'. '+ItemList.Item[ItemList.IndFromCode(codes[j])].Name;
      i:=0;
      while(i<datacnt)and(Codes[j]<>SimpData[i].Item.code)do inc(i);
      if(i<datacnt)and(Codes[j]=SimpData[i].Item.code)then
        begin
          str:='Затрачено '+FormatFloat('##0.0#',SimpData[i].hour)+' час, '
            +'произведено '+IntToStr(SimpData[i].good)+' ед готовой продукции и '+
            IntToStr(SimpData[i].bad)+' брака';
          if SimpData[i].good>0 then str:=str+' ('+FormatFloat('##0.##',SimpData[i].bad/(
            SimpData[i].good+SimpData[i].bad)*100)+'%)' else str:=str+' (100%)';
          str:=str+chr(13)+'Среднее время цикла '+FormatFloat('##0.0#',
            SimpData[i].cycle/SimpData[i].Item.time)+' сек.';
        end else
          str:='';
      //Добавляем строку
      data:='PN'+FormatDateTime('ddmmyyyy',dt1)+FormatDateTime('ddmmyyyy',dt2)+IntToStr(ItemList.IndFromCode(codes[j]));
      if length(str)>0 then AddRow(cap,str,'',data).OnClick:=OpenOneItemRep;
    end;
  ShowModal;
  end;
end;

procedure LstPayReport(Dt1,Dt2:TDate;Codes:TStringList);
var
  doc,i,j,datacnt : integer;
  item     : TListRec;
  fname,str: string;
  cap,data : string;
  SimpData : TSimpleNarPayLst;
  NarDoc   : TWorkTable;
  RepForm  : TReportForm;
begin
  RepForm:= TReportForm.Create(application);
  //записываем исх данные отчета для последующего вызова процедуры печати
  date1:=dt1;
  date2:=dt2;
  codelst:=codes;
  RepForm.PrintBtn.Tag:=pmEmpPayList;
  //----------------------------------------------------------------------
  with RepForm do
  begin
  NameLB.Caption:='Отчет по начислениям';
  Name2LB.Caption:='за период c '+FormatDateTime('dd mmm yyyy (ddd)',Dt1)+
    ' по '+FormatDateTime('dd mmm yyyy (ddd)',Dt2);
  //Загрузка данных
  datacnt:=0;
  SetLength(SimpData,datacnt);
  //цикл по списку документов
  for doc := 0 to MainList.Count - 1 do
    begin
      item:=MainList.Item[doc];
      //выбираем документы в заданом диапазоне и только проведенные
      if (Item.Date>=Dt1)and(Item.Date<=Dt2)and(Item.LastStatus.stat<>dsDelete) then
        begin
          fname:='doc'+IntTOStr(Item.Num)+'.nrd';
          if FileExists(ExePath+DefBaseFolder+fname) then
            begin
              //загружаем данные о работе сотрудников из документа
              NarDoc:=TWorkTable.Create(RepForm);
              NarDoc.LoadFromFile(ExePath+DefBaseFolder+fname);
              //сначала записываем начисления автора наряда
              if (NarDoc.autor.payroll>0) then
                begin
                  j:=0;
                  while(j<datacnt)and(SimpData[j].code<>NarDoc.autor.Employ.code)do inc(j);
                  if(j<datacnt)and(SimpData[j].code=NarDoc.autor.Employ.code)then
                    begin
                      SimpData[j].hour:=SimpData[j].hour+NarDoc.autor.time;
                      SimpData[j].pay:=SimpData[j].pay+NarDoc.autor.payroll;
                    end else
                    begin
                      inc(DataCnt);
                      SetLength(SimpData,datacnt);
                      SimpData[DataCnt-1].name:=NarDoc.autor.Employ.name;
                      SimpData[DataCnt-1].code:=NarDoc.autor.Employ.code;
                      SimpData[DataCnt-1].hour:=NarDoc.autor.time;
                      SimpData[DataCnt-1].pay:=NarDoc.autor.payroll;
                    end;
                end;
              //записываем начисления сотрудников из списка
              for i:=0 to NarDoc.EmployCount-1 do
                if (NarDoc.Employees[i].Employ.code<>NarDoc.autor.Employ.code) then
                  begin
                    j:=0;
                    while(j<datacnt)and(SimpData[j].code<>NarDoc.Employees[i].Employ.code)do inc(j);
                    if(j<datacnt)and(SimpData[j].code=NarDoc.Employees[i].Employ.code)then
                      begin
                        SimpData[j].hour:=SimpData[j].hour+NarDoc.Employees[i].time;
                        SimpData[j].pay:=SimpData[j].pay+NarDoc.Employees[i].payroll;
                      end else
                      begin
                        inc(DataCnt);
                        SetLength(SimpData,datacnt);
                        SimpData[DataCnt-1].name:=NarDoc.Employees[i].Employ.name;
                        SimpData[DataCnt-1].code:=NarDoc.Employees[i].Employ.code;
                        SimpData[DataCnt-1].hour:=NarDoc.Employees[i].time;
                        SimpData[DataCnt-1].pay:=NarDoc.Employees[i].payroll;
                      end;
                  end;
              NarDoc.Free;
            end;
        end;
    end;
  //Вывод данных
  while(SB.ControlCount>0)do SB.Controls[0].Free;
  str:='';
  for j := 0 to Codes.Count - 1 do
    begin
      cap:=IntToStr(j+1)+'. '+EmployList.NameFromCode(codes[j]);
      i:=0;
      while(i<datacnt)and(Codes[j]<>SimpData[i].code)do inc(i);
      if(i<datacnt)and(Codes[j]=SimpData[i].code)then
        begin
          str:='Учтено '+FormatFloat('##0.0#',SimpData[i].hour)+' час, '
            +'начислено '+FormatFloat('##0.0#',SimpData[i].pay)+' руб';
          if SimpData[i].hour>0 then str:=str+' ('+FormatFloat('##0.0#',SimpData[i].pay/SimpData[i].hour)+' руб/час)';
        end else
          str:='Данных о начислениях нет';
      data:='PN'+FormatDateTime('ddmmyyyy',dt1)+FormatDateTime('ddmmyyyy',dt2)+IntToStr(EmployList.IndFromName(EmployList.NameFromCode(codes[j])));
      AddRow(cap,str,'',data).OnClick:=OpenEmpPayRep;
    end;
  ShowModal;
  end;
end;

procedure EmpPayReport(Dt1,Dt2:TDate;Code:string);
var
  emp,i,j,k      : integer;
  sum,tsum,thour : real;
  str,cap,res    : string;
  NarDoc         : TWorkTable;
  DocLst         : TStringList;
  RepForm        : TReportForm;
begin
  RepForm:= TReportForm.Create(application);
  //записываем исх данные отчета для последующего вызова процедуры печати
  date1:=dt1;
  date2:=dt2;
  onecode:=code;
  RepForm.PrintBtn.Tag:=pmOneEmpPay;
  //----------------------------------------------------------------------
  with RepForm do
  begin
  while(SB.ControlCount>0)do SB.Controls[0].Free;
  NameLB.Caption:='Отчет по начислениям';
  Name2LB.Caption:=
    'для '+EmployList.NameFromCode(code)+chr(13)+
    'за период c '+FormatDateTime('dd mmm yyyy (ddd)',Dt1)+
    ' по '+FormatDateTime('dd mmm yyyy (ddd)',Dt2);
  //получаем список документов журнала
  GetDocList(Dt1,Dt2,DocLst);
  //загружаем данные о работе сотрудников из документов
  tsum:=0;
  thour:=0;
  NarDoc:=TWorkTable.Create(RepForm);
  for I := 0 to DocLst.Count - 1 do
    begin
      NarDoc.LoadFromFile(copy(DocLst[i],pos('=',DocLst[i])+1,MaxInt));
      //определяем, входит ли сотрудник в список работавших
      emp:=0;
      while(emp<NarDoc.EmployCount)and(code<>NarDoc.Employees[emp].Employ.code)do inc(emp);
      if((emp<NarDoc.EmployCount)and(code=NarDoc.Employees[emp].Employ.code))or
        (code=NarDoc.autor.Employ.code)then
        begin
          //Данные о наряде
          cap:='Наряд №'+FormatFloat('00000',NarDoc.number)+' от '+
            FormatDateTime('dd mmm yyyy (ddd)',NarDoc.MyDate);
          if NarDoc.Night then cap:=cap+' (ночь)' else cap:=cap+' (день)';
          //Строки начисления по ставкам
          str:='';
          sum:=0;
          k:=0;
          for j := 0 to NarDoc.Employees[emp].WorkCount - 1 do
          if NarDoc.Employees[emp].Works[j].payrol>0 then
            begin
              if k>0 then str:=str+chr(13);
              inc(k);
              str:=str+IntToStr(k)+'.  ';
              str:=str+NarDoc.Employees[emp].Works[j].Work.name+'. ';
              if (NarDoc.Employees[emp].Works[j].Work.TmPay)or
                (NarDoc.Employees[emp].Works[j].Work.Group) then
                str:=str+'Отработанно '+FormatFloat('###0.00',
                    NarDoc.Employees[emp].Works[j].time)+' час. Ставка '+
                    FormatFloat('###0.00',NarDoc.Employees[emp].Works[j].Work.PayRoll)+
                    ' руб/час.'
                else
                str:=str+'Изготовленно '+FormatFloat('###0.00',
                    NarDoc.Employees[emp].Works[j].count1)+' ед. Ставка '+
                    FormatFloat('###0.00',NarDoc.Employees[emp].Works[j].Work.PayRoll)+
                    ' руб/ед.';
              if (NarDoc.Employees[emp].Works[j].Work.Night)and(NarDoc.Night) then
                str:=str+' Доплата за работу в ночь '+FormatFloat('##0.0#',(NarDoc.NightPay-1)*100)+'%.';
              sum:=sum+NarDoc.Employees[emp].Works[j].payrol;
              str:=str+' Всего '+FormatFloat('###0.00',NarDoc.Employees[emp].Works[j].payrol)+' руб.';
            end;
          //Итог по ставкам
          sum:=sum+sum*NarDoc.Employees[emp].ratval/100;
          if sum>0 then
           str:=str+chr(13)+'Оценка "'+RatingStr[NarDoc.Employees[emp].rating]+'" (+'+FormatFloat('###0',NarDoc.Employees[emp].ratval)+'%)'
              +', итог по ставкам: '+FormatFloat('###0.00',sum)+' руб.' else
              str:='Начислений по ставкам нет.';
          //Если сотрудник - автор наряда
          if (code=NarDoc.autor.Employ.code)and(NarDoc.autor.payroll>=0) then
            begin
              if not NarDoc.datewrong then
                str:=str+chr(13)+'Премия начальнику смены:  '+
                  FormatFloat('##0',NarDoc.autor.ratval)+'% = '+
                  FormatFloat('###0.00',NarDoc.autor.payroll-sum)+' руб.'
                else str:=str+chr(13)+'Наряд выполнен с опозданием более чем 1 день. Премии нач смены не начисляется.';
              res:='Итого по наряду: '+
               FormatFloat('###0.00',NarDoc.autor.payroll)+' руб.  '+
               FormatFloat('###0.00',NarDoc.autor.time)+' час.';
              tsum:=tsum+NarDoc.autor.payroll;
              thour:=thour+NarDoc.autor.time;
            end else begin
              res:='Итого по наряду: '+
               FormatFloat('###0.00',NarDoc.Employees[emp].payroll)+' руб. '+
               FormatFloat('###0.00',NarDoc.Employees[emp].time)+' час.';
              if NarDoc.Employees[emp].timepay then res:=res+' (оплачено по часам)';
              tsum:=tsum+NarDoc.Employees[emp].payroll;
              thour:=thour+NarDoc.Employees[emp].time;
            end;
          AddRow(cap,str,res,'LB'+IntToStr(NarDoc.number)).OnClick:=OpenDoc;
        end;
    end;
  Name2LB.Caption:=Name2LB.Caption+chr(13)+
    'всего начислено '+FormatFloat('###0.00',tsum)+' руб, '+
    'всего часов '+FormatFloat('###0.00',thour)+' чаc';
  if thour>0 then Name2LB.Caption:=Name2LB.Caption+' ('+FormatFloat('###0.00',tsum/thour)+' руб/час)';
  ShowModal;
  end;
end;

procedure OneItemReport(Dt1,Dt2:TDate;Code:string);
var
  ind,i     : integer;
  str,cap   : string;
  NarDoc    : TWorkTable;
  DocLst    : TStringList;
  RepForm   : TReportForm;
  Item      : TItemResRec;
begin
  RepForm:= TReportForm.Create(application);
  //записываем исх данные отчета для последующего вызова процедуры печати
  date1:=dt1;
  date2:=dt2;
  onecode:=code;
  RepForm.PrintBtn.Tag:=pmOneItem;
  //----------------------------------------------------------------------
  with RepForm do begin
  while(SB.ControlCount>0)do SB.Controls[0].Free;
  Item.Item:=ItemList.Item[ItemList.IndFromCode(code)];
  NameLB.Caption:='Отчет по производству';
  Name2LB.Caption:=
    'для '+Item.item.name+chr(13)+
    'за период c '+FormatDateTime('dd mmm yyyy (ddd)',Dt1)+
    ' по '+FormatDateTime('dd mmm yyyy (ddd)',Dt2);
  //получаем список документов журнала
  GetDocList(Dt1,Dt2,DocLst);
  //загружаем данные о работе сотрудников из документов
  Item.good:=0;
  Item.bad:=0;
  Item.hour:=0;
  Item.Item.time:=0;
  NarDoc:=TWorkTable.Create(RepForm);
  for I := 0 to DocLst.Count - 1 do
    begin
      NarDoc.LoadFromFile(copy(DocLst[i],pos('=',DocLst[i])+1,MaxInt));
      //определяем, производилась ли данная деталь
      ind:=0;
      while(ind<NarDoc.ItemCount)and(code<>NarDoc.ItemList[ind].Item.code)do inc(ind);
      if(ind<NarDoc.ItemCount)and(code=NarDoc.ItemList[ind].Item.code)then
        begin
          //Данные о наряде
          cap:='Наряд №'+FormatFloat('00000',NarDoc.number)+' от '+FormatDateTime('dd mmm yyyy (ddd)',NarDoc.MyDate);
          if NarDoc.Night then cap:=cap+' (ночь)' else cap:=cap+' (день)';
          //Результаты производства по наряду
          str:='Затрачено '+FormatFloat('##0.0#',NarDoc.ItemList[ind].hour)+' час, ';
          str:=str+'произведено '+IntToStr(NarDoc.ItemList[ind].good)+' ед готовой продукции и '+
            IntToStr(NarDoc.ItemList[ind].bad)+' брака';
          if NarDoc.ItemList[ind].good>0 then str:=str+' ('+FormatFloat('##0.##',NarDoc.ItemList[ind].bad/
            (NarDoc.ItemList[ind].good+NarDoc.ItemList[ind].bad)*100)+'%)' else str:=str+' (100%)';
          str:=str+chr(13)+'Среднее время цикла '+FormatFloat('##0.0#',NarDoc.ItemList[ind].cycle)+' сек.';
          //сумирруем для статистики
          if Item.Item.time=0 then Item.Item.time:=1 else Item.Item.time:=Item.Item.time+1;
          item.hour:=Item.hour+NarDoc.ItemList[ind].hour;
          item.bad:=Item.bad+NarDoc.ItemList[ind].bad;
          item.good:=Item.good+NarDoc.ItemList[ind].good;
          item.cycle:=Item.cycle+NarDoc.ItemList[ind].cycle;
          //Выводим строку
          AddRow(cap,str,'','LB'+IntToStr(NarDoc.number)).OnClick:=OpenDoc;
        end;
    end;
  Name2LB.Caption:=Name2LB.Caption+chr(13)+
    'всего затрачено '+FormatFloat('###0.00',item.hour)+' час, '+
    'всего готовой продукции '+IntToStr(Item.good)+
    ', всего брака '+IntToStr(Item.bad);
  if Item.good>0 then Name2LB.Caption:=Name2LB.Caption+' ('+FormatFloat('##0.##',Item.bad/
    (Item.good+Item.bad)*100)+'%)' else Name2LB.Caption:=Name2LB.Caption+' (100%)';
  if Item.Item.time>0 then Name2LB.Caption:=Name2LB.Caption+chr(13)+'среднее время цикла '+
    FormatFloat('###0.00',item.cycle/item.Item.time)+' сек';
  ShowModal;
  end;
end;

procedure EmpBadItemReport(Dt1,Dt2:TDate;Code:string);
var
  emp,i,j,k      : integer;
  str,cap,res    : string;
  NarDoc         : TWorkTable;
  DocLst         : TStringList;
  RepForm        : TReportForm;
  good,bad       : real;
begin
  RepForm:= TReportForm.Create(application);
  //записываем исх данные отчета для последующего вызова процедуры печати
  date1:=dt1;
  date2:=dt2;
  onecode:=code;
  RepForm.PrintBtn.Tag:=pmOneEmpBadItem;
  //----------------------------------------------------------------------
  with RepForm do
  begin
  while(SB.ControlCount>0)do SB.Controls[0].Free;
  NameLB.Caption:='Отчет по расходу сырья';
  Name2LB.Caption:=
    'для '+EmployList.NameFromCode(code)+chr(13)+
    'за период c '+FormatDateTime('dd mmm yyyy (ddd)',Dt1)+
    ' по '+FormatDateTime('dd mmm yyyy (ddd)',Dt2);
  reptime:=0;
  //получаем список документов журнала
  GetDocList(Dt1,Dt2,DocLst);
  //загружаем данные о работе сотрудников из документов
  NarDoc:=TWorkTable.Create(RepForm);
  SetLength(DataList,0);
  for I := 0 to DocLst.Count - 1 do
    begin
      NarDoc.LoadFromFile(copy(DocLst[i],pos('=',DocLst[i])+1,MaxInt));
      //определяем, входит ли сотрудник в список работавших
      emp:=0;
      while(emp<NarDoc.EmployCount)and(code<>NarDoc.Employees[emp].Employ.code)do inc(emp);
      if((emp<NarDoc.EmployCount)and(code=NarDoc.Employees[emp].Employ.code))or
        (code=NarDoc.autor.Employ.code)then
        begin
          //Если сотрудник - автор наряда
          if (code=NarDoc.autor.Employ.code) then begin
            reptime:=reptime+NarDoc.autor.time;
            for j := 0 to NarDoc.ItemCount - 1 do
            if((NarDoc.ItemList[j].good)+(NarDoc.ItemList[j].bad))>0 then begin
              k:=0;
              while(k<=high(DataList))and(DataList[k].item.code<>NarDoc.ItemList[j].Item.code)do inc(k);
              if(k<=high(DataList))and(DataList[k].item.code=NarDoc.ItemList[j].Item.code)then begin
                DataList[k].good:=DataList[k].good+NarDoc.ItemList[j].good;
                DataList[k].bad:=DataList[k].bad+NarDoc.ItemList[j].bad;
              end else begin
                SetLength(DataList,high(DataList)+2);
                DataList[high(DataList)].item:=NarDoc.ItemList[j].Item;
                DataList[high(DataList)].good:=NarDoc.ItemList[j].good;
                DataList[high(DataList)].bad:=NarDoc.ItemList[j].bad;
              end;
            end;
          end else begin
          //Если сотрудник - литещик
            reptime:=reptime+NarDoc.Employees[emp].time;
            for j := 0 to NarDoc.Employees[emp].WorkCount - 1 do
              if NarDoc.Employees[emp].Works[j].Work.Item.code<>'' then begin
                k:=0;
                while(k<=high(DataList))and(DataList[k].item.code<>NarDoc.Employees[emp].Works[j].Work.Item.code)do inc(k);
                if(k<=high(DataList))and(DataList[k].item.code=NarDoc.Employees[emp].Works[j].Work.Item.code)then begin
                  DataList[k].good:=DataList[k].good+NarDoc.Employees[emp].Works[j].count1;
                  DataList[k].bad:=DataList[k].bad+NarDoc.Employees[emp].Works[j].count2;
                end else begin
                  SetLength(DataList,high(DataList)+2);
                  DataList[high(DataList)].item:=NarDoc.Employees[emp].Works[j].Work.Item;
                  DataList[high(DataList)].good:=NarDoc.Employees[emp].Works[j].count1;
                  DataList[high(DataList)].bad:=NarDoc.Employees[emp].Works[j].count2;
                end;
              end;
            end;
        end;
    end;
  //Загрузка данный о весе
  if FileExists(WeightFileName) then begin
    DocLst.LoadFromFile(WeightFileName);
    for k := 0 to high(DataList) do begin
      if Length(DocLst.Values[DataList[k].item.code])<>0 then
        DataList[k].weight:=StrToFloat(DocLst.Values[DataList[k].item.code]) else DataList[k].weight:=0;
    end;
  end;
  //Вывод на экран
  str:='';
  good:=0;
  bad:=0;
  for k := 0 to high(DataList) do begin
    good:=good+DataList[k].good*DataList[k].weight;
    bad:=bad+DataList[k].bad*DataList[k].weight;
    str:=str+DataList[k].item.name+' ('+FormatFloat('###0',DataList[k].weight)+' г): гот продукция - '+
      IntToStr(DataList[k].good)+' шт ('+FormatFloat('###0.00',DataList[k].weight*DataList[k].good/1000)+' кг), брак - '+
      IntToStr(DataList[k].bad)+' ('+FormatFloat('###0.00',DataList[k].weight*DataList[k].bad/1000)+' кг)';
    str:=str+chr(13);
  end;
  cap:='Всего израсходованно '+FormatFloat('###0.00',(good+bad)/1000)+' кг, из них брак '
    +FormatFloat('###0.00',bad/1000)+' кг. Отработано '+FormatFloat('###0.00',reptime)+' час. '
    +'Эффективность '+FormatFloat('###0.000',(good+bad)/1000/reptime)+' кг/час.'+chr(13);
  res:='Процент брака по сырью: '+FormatFloat('###0.00',bad/(good+bad)*100)+'%';
  AddRow(cap,str,res,'LB'+IntToStr(NarDoc.number)).OnClick:=OpenDoc;
  ShowModal;
  end;
end;

procedure LstEmpBadItemReport(Dt1,Dt2:TDate;Codes:TStringList);
var
  doc,i,j,k,e,datacnt : integer;
  item     : TListRec;
  fname,str: string;
  cap,data : string;
  SimpData : TSimpleNarPayLst;
  NarDoc   : TWorkTable;
  RepForm  : TReportForm;
  WeightLst: TStringList;
  weight   : real;
begin
  RepForm:= TReportForm.Create(application);
  //записываем исх данные отчета для последующего вызова процедуры печати
  date1:=dt1;
  date2:=dt2;
  codelst:=codes;
  RepForm.PrintBtn.Tag:=pmLstEmpBadItem;
  //----------------------------------------------------------------------
  with RepForm do
  begin
  NameLB.Caption:='Отчет по качеству работы персонала';
  Name2LB.Caption:='за период c '+FormatDateTime('dd mmm yyyy (ddd)',Dt1)+
    ' по '+FormatDateTime('dd mmm yyyy (ddd)',Dt2);
  //Загрузка данных
  datacnt:=0;
  SetLength(SimpData,datacnt);
  //загрузка файла с весами
  WeightLst:=TStringList.Create;
  if FileExists(WeightFileName) then WeightLst.LoadFromFile(WeightFileName);
  //цикл по списку документов
  for doc := 0 to MainList.Count - 1 do
    begin
      item:=MainList.Item[doc];
      //выбираем документы в заданом диапазоне и только проведенные
      if (Item.Date>=Dt1)and(Item.Date<=Dt2)and(Item.LastStatus.stat<>dsDelete) then
        begin
          fname:='doc'+IntTOStr(Item.Num)+'.nrd';
          if FileExists(ExePath+DefBaseFolder+fname) then
            begin
              //загружаем данные о работе сотрудников из документа
              NarDoc:=TWorkTable.Create(RepForm);
              NarDoc.LoadFromFile(ExePath+DefBaseFolder+fname);
              for I := 0 to codes.Count - 1 do
                begin
                  //если сотрудник автор наряда
                  if (NarDoc.autor.Employ.code=codes[i]) then
                    begin
                      //определяем, записан ли уже сотрудник ранее
                      k:=0;
                      while(k<datacnt)and(SimpData[k].code<>codes[i])do inc(k);
                      //если ранее не записан - записываем в объект данных
                      if(k=datacnt)then
                        begin
                          inc(datacnt);
                          SetLength(SimpData,datacnt);
                          SimpData[k].code:=codes[i];
                          SimpData[k].name:=EmployList.NameFromCode(codes[i]);
                          SimpData[k].pay:=0;
                          SimpData[k].hour:=0;
                          SimpData[k].fld1:=0;
                        end;
                      SimpData[k].fld1:=SimpData[k].fld1+NarDoc.autor.time;
                      //для автора наряда суммируются данные по всей продукции по наряду
                      for j := 0 to NarDoc.ItemCount - 1 do
                        begin
                          if Length(WeightLst.Values[NarDoc.ItemList[j].Item.code])>0 then
                            weight:=StrToFloat(WeightLst.Values[NarDoc.ItemList[j].Item.code])/1000
                            else weight:=0;
                          SimpData[k].pay:=SimpData[k].pay+NarDoc.ItemList[j].good*weight;
                          SimpData[k].hour:=SimpData[k].hour+NarDoc.ItemList[j].bad*weight;
                        end;
                    end else begin
                  //если сотрудник литейщик
                      //определяем, работал ли сотрудник в наряде
                      e:=0;
                      while(e<NarDoc.EmployCount)and(Codes[i]<>NarDoc.Employees[e].Employ.code)do inc(e);
                      if(e<NarDoc.EmployCount)and(Codes[i]=NarDoc.Employees[e].Employ.code)then
                        begin
                          //определяем, записаны ли данные ранее
                          k:=0;
                          while(k<datacnt)and(SimpData[k].code<>codes[i])do inc(k);
                          //если ранее не записан - записываем в объект данных
                          if(k=datacnt)then
                            begin
                              inc(datacnt);
                              SetLength(SimpData,datacnt);
                              SimpData[k].code:=codes[i];
                              SimpData[k].name:=NarDoc.Employees[e].Employ.name;
                              SimpData[k].pay:=0;
                              SimpData[k].hour:=0;
                              SimpData[k].fld1:=0;
                            end;
                          SimpData[k].fld1:=SimpData[k].fld1+NarDoc.Employees[e].time;
                          //для литейщика суммируются даннып по ставкам
                          //с признаком "процент нач смены" - те ставки за литье
                          for j := 0 to NarDoc.Employees[e].WorkCount - 1 do
                            if NarDoc.Employees[e].Works[j].Work.NSpay then
                            begin
                              if Length(WeightLst.Values[NarDoc.Employees[e].Works[j].Work.Item.code])>0 then
                                weight:=StrToFloat(WeightLst.Values[NarDoc.Employees[e].Works[j].Work.Item.code])/1000
                                else weight:=0;
                              SimpData[k].pay:=SimpData[k].pay+NarDoc.Employees[e].Works[j].count1*weight;
                              SimpData[k].hour:=SimpData[k].hour+NarDoc.Employees[e].Works[j].count2*weight;
                            end;
                        end;
                    end;
                end;
              NarDoc.Free;
            end;
        end;
    end;
  //Вывод данных
  while(SB.ControlCount>0)do SB.Controls[0].Free;
  k:=1;
  for j := 0 to Codes.Count - 1 do
    begin
      cap:=IntToStr(k)+'. '+EmployList.NameFromCode(codes[j]);
      str:='';
      i:=0;
      while(i<datacnt)and(Codes[j]<>SimpData[i].code)do inc(i);
      if(i<datacnt)and(SimpData[i].fld1>0)and(Codes[j]=SimpData[i].code)and((SimpData[i].hour+SimpData[i].pay)>0)then
        begin
          str:='Всего использован '+FormatFloat('####0.00',SimpData[i].pay+SimpData[i].hour)+' кг сырья. Из них '
            +FormatFloat('###0.00',SimpData[i].hour)+' брак (';
          if (SimpData[i].hour+SimpData[i].pay)>0 then str:=str+FormatFloat('##0.0#',
            (SimpData[i].hour/(SimpData[i].pay+SimpData[i].hour))*100)+'%).' else str:=str+'0%).';
          str:=str+' Отработано '+FormatFloat('###0.00',SimpData[i].fld1)+' час ('+
            FormatFloat('###0.000',(SimpData[i].pay+SimpData[i].hour)/SimpData[i].fld1)+' кг/час}';
        end;
      data:='PN'+FormatDateTime('ddmmyyyy',dt1)+FormatDateTime('ddmmyyyy',dt2)+IntToStr(EmployList.IndFromName(EmployList.NameFromCode(codes[j])));
      if Length(str)>0 then
        begin
          AddRow(cap,str,'',data).OnClick:=OpenEmpBadRep;
          inc(k);
        end;
    end;
  ShowModal;
  end;
end;

//------------------------------------------------------------------------------

procedure TReportForm.CloseBtnClick(Sender: TObject);
begin
  if high(DataList)>0 then  SetLength(DataList,0);
  self.ModalResult:=mrCancel;
end;

procedure TReportForm.FormResize(Sender: TObject);
begin
  self.Left:=0;
  self.Top:=0;
  PrintBtn.Margins.Left:=round((BtnPn.ClientWidth-(CloseBtn.Left+CloseBtn.Width-
    PrintBtn.Left))/2);
end;

procedure TReportForm.DownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')then
    SB.VertScrollBar.Position:=SB.VertScrollBar.Position+ScrollSpeed;
  if ((Sender as TSpeedButton).name='UpBtn')then
    SB.VertScrollBar.Position:=SB.VertScrollBar.Position-ScrollSpeed;
end;

end.
