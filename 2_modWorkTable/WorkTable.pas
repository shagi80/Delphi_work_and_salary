unit WorkTable;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, EmployData, WorkData;

type
TEmployWork = record
    Work   : TWork;
    time   : real;
    rating : integer;
    count1 : integer;
    count2 : integer;
    payrol : real;
  end;

TGroupWork = record
    Work   : TWork;
    count  : integer;
    payrol : real;
  end;

TWTEmploy = record
    Employ    : TEmploy;
    Bitmap    : TBitMap;
    funct     : TFunction;
    rating    : integer;
    ratval    : integer;
    time      : real;
    timepay   : boolean;
    payroll   : real;
    note      : string[255];
    WorkCount : integer;
    Works     : array of TEmployWork;
    rect      : TRect;
  end;

TItemResRec = record
    Item : TItem;
    good : integer;
    bad  : integer;
    hour : real;
    cycle: real;
  end;


TWorkTable = Class(TPaintBox)
  private {здесь описываются только внутренние переменные и процедуры - "для служебного пользования"}
  {Описание полей, т.е. переменных которые работают только внутри класса, "снаружи" они не
  доступны.}
    ColCount     : integer;
    RowCount     : integer;
    HeaderHeight : integer;
    procedure Paint(Sender: TObject); reintroduce;
    procedure DrawCellText(c,r : integer);
    procedure DrawHeadText(c : integer);
    procedure MouseDown(Sender:TOBject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer); reintroduce;
    procedure GetItemData(var item:TItemResRec);
  public {Описанное здесь доступно для пользователя класса}
    FName        : string;
    MyDate       : TDate;     //дата наряда
    number       : integer;   //номер наряда
    createtime   : TDateTime; //время создания
    autorcalck   : boolean;   //считать начисления автору
    datewrong    : boolean;   //просроченный наряд
    autor        : TWTEmploy; //аутор и его труд
    note         : string;    //общее примечание
    Bevel        : integer;   //бордюр
    EmployCount  : integer;   //кол-во работавших
    Employees    : array of TWTEmploy;  //список работавших
    GroupWork    : array of TGroupWork; //список груповых ставок
    Cells        : array of array of TRect; //ячейки
    GroupRowCnt  : integer;  //Количество групповых ставок
    BtnRect      : TRect;    //кнопка выхода
    Night        : boolean;  //доплата в ночь
    NightPay     : real;     //размер доплаты в ночь
    AutorTimePay : boolean;  //разрешение на почасовой расчет для автора
    EmployTimePay: boolean;  //разрешение на почасовой расчет для сотрудников
    ItemCount    : integer;
    ItemList     : array of TItemResRec;
    change       : boolean;
    itmchange    : boolean;
    Constructor Create(owner:TComponent); reintroduce;
    Destructor  Destroy; override;
    procedure   SetTableSize(Col,Row : integer);
    procedure   SaveToFile(Fname:string);
    function    LoadFromFile(Fname:string):boolean;
    procedure   ChangeAndRepaint;
    procedure   DelGroup(col,ind:integer;verify:boolean);
    function    CalckAutorPay(var pay1,pay2:real):real;
  end;

TWorkTableForm = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;


implementation

{$R *.dfm}

uses GlobalUnit, EmployLst, MsgForm, WorkEmpData, ShadowForm, WorkLst,
     EmpWorkData, DateUtils, NumKeyboard;


constructor TWorkTable.Create(owner:TComponent);
begin
  inherited;
  self.FName        :='';
  self.MyDate       :=now;
  self.number       :=0;
  self.createtime   :=now;
  self.autorcalck   :=false;
  self.datewrong    :=false;
  self.autor.timepay:=false;
  self.note         :='';
  self.OnPaint:=self.Paint;
  self.OnMouseDown:=self.MouseDown;
  self.Left:=0;
  self.Top:=0;
  self.Width:=100;
  self.Height:=150;
  self.Bevel:=6;
  self.GroupRowCnt:=0;
  self.EmployCount:=0;
  self.SetTableSize(6,8);
  self.Night:=false;
  self.NightPay:=0;
  self.AutorTimePay:=false;
  self.EmployTimePay:=false;
  self.ItemCount:=0;
  SetLength(self.ItemList,self.ItemCount);
end;

destructor TWorkTable.Destroy;
begin
  //FList.Free;{Разрушаем структуры нашего класса}
  inherited;
end;

function TWorkTable.CalckAutorPay(var pay1,pay2:real):real;
//pay1 - сумма по ставкам
//pay2 - сумма по наряду, от которой начисляется % автору
//result - сумма по часам
//знчение AUTOR.PAYROLL уставнавливаетя по наибольшей сумме
var
  emp,wrk   : integer;
  tpay,sum  : real;
begin
  if not self.autorcalck then
    begin
      pay1:=0;
      pay2:=0;
      self.autor.payroll:=0;
      result:=0;
    end else
  begin
  //получаем данные о начисления сотрудника из общей таблицы
  pay1:=0;
  for emp := 0 to self.EmployCount - 1 do
    if self.Employees[emp].Employ.code=self.autor.Employ.code then
      pay1:=self.Employees[emp].payroll;
  //вычисляем общую сумму по ставкам, % от которых идет нач смены
  sum:=0;
  for emp := 0 to self.EmployCount - 1 do
    for wrk := 0 to self.Employees[emp].WorkCount - 1 do
      if self.Employees[emp].Works[wrk].Work.NSpay then
        sum:=sum+self.Employees[emp].Works[wrk].payrol;
  //Вычисляем % начальника смен
  if (not self.datewrong) then pay2:=sum*self.autor.ratval/100 else pay2:=0;
  //вычисляем сумму по часам (с учетом надбавки за ночь) и с учетом оценка
 if not (self.Night) then tpay:=self.autor.Employ.funct.sum*self.autor.time else
    tpay:=self.autor.Employ.funct.sum*self.autor.time*self.NightPay;
  {//если разрешена почасовая оплата и почасовка больше уст соотв признак
  self.autor.timepay:=((self.AutorTimePay)and((pay1+pay2)<tpay));
  //если надо платим по часам
  if self.autor.timepay then self.autor.payroll:=tpay else  self.autor.payroll:=(pay1+pay2); }

  //новый расчте с 1 сентября 2020 года\
  //общ сумма = по часам + % от всего заработка смены
  self.autor.timepay:=true;
  self.autor.payroll:=tpay+pay1+pay2;

  {showmessage('tpay='+FloatTostr(tpay)+chr(13)+
    'pay1='+FloatTostr(pay1)+chr(13)+'pay2='+FloatTostr(pay2)+chr(13)+
    'sum='+FloatTostr(sum)+chr(13)+'ratval='+FloatTostr(self.autor.ratval/100)); }

  //записываем общий заработок смены по ставкам для передачи дальше
  pay2:=sum;
  //Проверяем на превышение максимального заработка
  if (AutorMaxPay>0)and(self.autor.payroll>AutorMaxPay) then self.autor.payroll:=AutorMaxPay;

  result:=tpay;
  end;
end;

//Получение количесва детали в наряде
procedure  TWorkTable.GetItemData(var item:TItemResRec);
const
  def = 0.2;
var
  i,e,w : integer;
  hour : real;
begin
  item.good:=0;
  item.bad:=0;
  item.hour:=0;
  //считаем индивидуальные ставки
  for e := 0 to self.EmployCount - 1 do
    for w := 0 to self.Employees[e].WorkCount - 1 do
      if self.Employees[e].Works[w].Work.Item.code=item.Item.code then
        begin
          item.good:=item.good+self.Employees[e].Works[w].count1;
          item.bad:=item.bad+self.Employees[e].Works[w].count2;
          item.hour:=item.hour+self.Employees[e].Works[w].time;
        end;
  //считаем групповые ставки
  for i := 0 to high(self.GroupWork) do
    if self.GroupWork[i].Work.Item.code=item.Item.code then begin
      item.good:=item.good+self.GroupWork[i].count;
      //item.bad:=item.bad+self.Employees[e].Works[w].count2;
      //считаем часы отработанные по данной ставки всеми сотрудниками
      hour:=0;
      for e := 0 to self.EmployCount - 1 do
        for w := 0 to Employees[e].WorkCount - 1 do
          if Employees[e].Works[w].Work.code=GroupWork[i].Work.code then
            hour:=hour+Employees[e].Works[w].time;
      item.hour:=item.hour+hour;
    end;
  //определение фактического цикла
  if AskCycleTime then begin
    if (item.good+item.bad)>0 then
      item.cycle:=item.hour*3600/(item.good+item.bad) else item.cycle:=0;
    if (item.cycle>(Item.Item.time+Item.Item.time*0.2))or
      (item.cycle<(Item.Item.time-Item.Item.time*0.2))then item.cycle:=0;
  end else item.cycle:= Item.Item.time;
end;

//Установка размеров таблицы
procedure TWorkTable.SetTableSize(Col,Row : integer);
var
  r : integer;
begin
  //Количество столбцов больше на единицу для того что бы
  //обеспечить наличие ячеек для инфо о групповых ставках
  self.ColCount:=col;
  self.RowCount:=row;
  //Массивы столбцов
  SetLength(self.Employees,self.ColCount);
  for r := 0 to self.ColCount-1 do
    begin
      self.Employees[r].Bitmap:=Tbitmap.Create;
      self.Employees[r].Bitmap.LoadFromResourceName(hInstance, 'DefEmpImg');
      self.Employees[r].WorkCount:=0;
      SetLength(self.Employees[r].Works,self.Employees[r].WorkCount);
    end;
  //Массивы строк
  SetLength(self.Cells,self.ColCount+1);
  for r := 0 to self.ColCount do
    SetLength(self.Cells[r],self.RowCount);
  //Массив групповых ставок
  SetLength(self.GroupWork,self.RowCount);
end;

//Удаление групповой ставки
procedure TWorkTable.DelGroup(col,ind:integer;verify:boolean);
var
  empty : boolean;
  i,j   : integer;
begin
  empty:=true;
  i:=0;
  if verify then
    begin
      self.Employees[col].Works[ind].time:=0;
      while(i<self.EmployCount)and(empty)do
        if self.Employees[i].Works[ind].time>0 then empty:=false else inc(i);
    end;
  if (empty) then
    begin
      for I := 0 to self.EmployCount - 1 do
        begin
          for j := ind to self.Employees[i].WorkCount	 - 2 do
            self.Employees[i].Works[j]:=self.Employees[i].Works[j+1];
          dec(self.Employees[i].WorkCount);
          SetLength(self.Employees[i].Works,self.Employees[i].WorkCount);
        end;
      //переписываем итог групповой ставки
      for j := ind to self.GroupRowCnt - 2 do self.GroupWork[j]:=self.GroupWork[j+1];
      dec(self.GroupRowCnt);
      SetLength(self.GroupWork,self.GroupRowCnt);
    end;
end;

procedure TWorkTable.MouseDown(Sender:TOBject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
var
  c,r,ind,i,j : integer;
  img       : TbitMap;                    
  //Для работы с заголовком и ячейками
  Employ  : TEmploy;
  Work    : TWork;
  rating  : integer;
  time    : real;
  count1  : integer;
  count2  : integer;
  note    : string;
  funct   : TFunction;
  addempl : boolean;
begin
  //НАЖАТИЕ НА КНОПКУ ВЫХОД ----------------------------------------------------
  if (X<BtnRect.Right)and(X>BtnRect.Left)and
    (Y<BtnRect.Bottom)and(Y>BtnRect.top) then SendMessage(GetForegroundWindow,WM_CLOSE,0,0);
  //ЕСЛИ УРОВЕНЬ ДОСТУПА "ТОЛЬКО ПРОСМОТР" ВЫХОДИМ ИЗ ПРОЦЕДУРЫ-----------------
  if Acsses=alViewer then Abort;
  //ПОИСК НАЖАТИЯ ПО ЯЧЕЙКАМ ТАБЛИЦЫ -------------------------------------------
  for c := 0 to self.ColCount do
    for r := 0 to self.RowCount - 1 do
      if (X<self.Cells[c,r].Right)and(X>self.Cells[c,r].Left)and
       (Y<self.Cells[c,r].Bottom)and(Y>self.Cells[c,r].top) then
        begin
  //Клик на итоге групповой ставки ---------------------------------------------
          if c=self.ColCount then
            begin
              ind:=ShowMsg((self.Owner as TForm),self.GroupWork[r].Work.name,[msbEdit,msbDel,msbCancel]);
              //Изменение количества в груповой ставке
              if(ind=msbEdit)then
                begin
                  note:=IntToStr(self.GroupWork[r].count);
                  if NumKeyboardForm.GetValue((self.Owner as TForm),note,true) then
                    begin
                      self.GroupWork[r].count:=StrToInt(note);
                      self.ChangeAndRepaint;
                    end;
                end;
              //Удаление ставки (вне зависимости от заполненности)
              if(ind=msbDel)and(ShowMsg((self.Owner as TForm),'Удалить ставку из таблицы?',[msbOk,msbCancel])=msbOK)then
                begin
                  self.DelGroup(0,r,false);
                  self.ChangeAndRepaint;
                end;
            end;
  //Клик на заполненной индивидуальной ставке ----------------------------------
          if (c<self.EmployCount)and(r<self.employees[c].WorkCount) then
            begin
            //Предлагаем изменить или удалить запись
            if(self.Employees[c].Works[r].Work.Group)and(self.Employees[c].Works[r].time=0)then
              ind:=msbEdit
            else
              ind:=ShowMSG((self.Owner as TForm),self.Employees[c].Employ.name+chr(13)+
                self.Employees[c].Works[r].Work.name,[msbEdit,msbDel,msbCancel]);
            //Измение информации о рабоет сотрудника
            if (ind=msbEdit) then
              begin
                //Выводим окно измеенния информации
                time:=self.Employees[c].Works[r].time;
                rating:=self.Employees[c].Works[r].rating;
                count1:=self.Employees[c].Works[r].count1;
                count2:=self.Employees[c].Works[r].count2;
                if EmpWorkDataForm.ShowWindow((self.Owner as TForm),self.Employees[c].Works[r].Work.TmPay,
                  self.Employees[c].Works[r].Work.Group, self.Employees[c].Employ.name,
                  self.Employees[c].Works[r].Work.name,self.Employees[c].Works[r].Work.Norm,
                  self.Employees[c].Works[r].Work.PayRoll,time,count1,count2,rating,self.Employees[c].Bitmap) then
                  begin
                    self.Employees[c].Works[r].time:=time;
                    self.Employees[c].Works[r].rating:=rating;
                    self.Employees[c].Works[r].count1:=count1;
                    self.Employees[c].Works[r].count2:=count2;
                    self.Employees[c].Works[r].payrol:=0;
                    self.ChangeAndRepaint;
                  end;
              end;
            //Удаление записи о работе сотрудника по данной ставке
            if (ind=msbDel)and
              (ShowMsg((self.Owner as TForm),('Удалить запись о работе '+self.Employees[c].Employ.name+' по ставке "'+
              self.Employees[c].Works[r].Work.name+'" из наряда?'),[msbOK,msbCancel])=msbOK) then
              begin
                Work:=self.Employees[c].Works[r].Work;
                if Work.Group then
                  //Если ставка групповая
                  self.DelGroup(c,r,true)
                  else
                  //Если инидивидуальная
                  begin
                    dec(self.Employees[c].WorkCount);
                    for ind :=r to self.Employees[c].WorkCount do
                      self.Employees[c].Works[ind]:=self.Employees[c].Works[ind+1];
                    SetLength(Self.Employees[c].Works,self.Employees[c].WorkCount);
                  end;
                if work.Group then self.ChangeAndRepaint else self.ChangeAndRepaint;
              end;
            end else
    //Клик на пустой ячейке ----------------------------------------------------
          if (c<self.EmployCount)and(r>=self.employees[c].WorkCount) then
            if GetWorkListItem(ind) then
              begin
                Work:=WorkList.Item[ind];
                //начальник смены не может быть подсобным рабочим
                if (self.employees[c].funct.code='00031')and(WorkList.Item[ind].code='51') then begin
                  ShowMsg((self.Owner as TForm),'Начальник смены не может быть подсобным рабочим!',[msbOK]);
                  Abort;
                end;
                ind:=self.Employees[c].WorkCount;
                if (ind=self.Employees[c].WorkCount) then
                  begin
                  //Запрашиваем данные о работы по конкретной ставке
                  time:=0;
                  rating:=3;
                  count1:=0;
                  count2:=0;
                  if EmpWorkDataForm.ShowWindow((self.Owner as TForm),Work.TmPay,Work.Group,
                    self.Employees[c].Employ.name,Work.name,Work.Norm,
                    Work.PayRoll,time,count1,count2,
                    rating,self.Employees[c].Bitmap) then
                    begin
                      //Если добавлена групповая ставка ------------------------
                      if Work.Group then
                        begin
                          //Проверяем возможность добавленя ставки
                          i:=0;
                          while(i<self.EmployCount)and(self.Employees[i].WorkCount<self.RowCount)do inc(i);
                          if(self.Employees[i].WorkCount=self.RowCount)then
                            begin
                              ShowMsg((self.Owner as TForm),'Больше добавлять ставки невозможно!',[msbOK]);
                              Abort;
                            end;
                          //Добавляем ставку для всех сотрудников (вставляем самой первой)
                          for i :=0 to self.EmployCount - 1 do
                            begin
                              inc(self.Employees[i].WorkCount);
                              SetLength(self.Employees[i].Works,self.Employees[i].WorkCount);
                              for j := self.Employees[i].WorkCount-1 downto 1 do begin
                                self.Employees[i].Works[j]:=self.Employees[i].Works[j-1];
                              end;
                              self.Employees[i].Works[0].Work:=Work;
                              self.Employees[i].Works[0].time:=0;
                              self.Employees[i].Works[0].rating:=3;
                              self.Employees[i].Works[0].payrol:=0;
                              self.Employees[i].Works[0].Work.Group:=true;
                            end;
                          //Увеличиваем счетчик групповых ставок
                          inc(self.GroupRowCnt);
                          //"сдвигаем вниз" остальны групповые ставки
                          for j :=self.GroupRowCnt-1 downto 1 do self.GroupWork[j]:=self.GroupWork[j-1];
                          //добавляем новую ставку первой
                          self.GroupWork[0].Work:=Work;
                          if work.Norm>0 then
                            self.GroupWork[0].count:=round(work.Norm)
                            else self.GroupWork[0].count:=1;
                          self.GroupWork[0].payrol:=0;
                          //Данные о работе сотрудника записываем в первую строку
                          i:=0;
                        end
                      else
                        begin
                          //Если добавлена инд ставка --------------------------
                          inc(self.Employees[c].WorkCount);
                          SetLength(self.Employees[c].Works,self.Employees[c].WorkCount);
                          i:=self.Employees[c].WorkCount-1;
                        end;
                      //Записываем данные о работе в соотв ячейку
                      self.Employees[c].Works[i].Work:=Work;
                      self.Employees[c].Works[i].time:=time;
                      self.Employees[c].Works[i].rating:=rating;
                      self.Employees[c].Works[i].count1:=count1;
                      self.Employees[c].Works[i].count2:=count2;
                      self.Employees[c].Works[i].payrol:=0;
                      //Перерисовка ячек таблицы (или все или выбранный столбец)
                      if Work.Group then self.ChangeAndRepaint else self.ChangeAndRepaint;
                    end;
                  end else ShowMSG((self.Owner as TForm),'Эта ставка уже записана !',[msbOK]);
              end;
        end;
  //ПОИЗСК НАЖАТИЯ ПО ЯЧЕЙКАМ ЗАГОЛОВКА ----------------------------------------
  for c := 0 to self.ColCount do
    if (X<self.Employees[c].rect.Right)and(X>self.Employees[c].rect.Left)and
       (Y<self.Employees[c].rect.Bottom)and(Y>self.Employees[c].rect.top) then
       if c>=self.EmployCount then
        begin
    //Если нажат пустой заголовок - пытаемся добавить сотрудника в таблицу
          img:=TBitMap.Create;
          if GetEmployListItem('Подбор сотрудника в наряд',ind,img,true)then
            begin
              addempl:=true;
              Employ:=EmployList.Item[ind];
              //автор наряда не может быть в табличной части
              if (AutorCanWork=false)and(Employ.code=Autor.Employ.code)then begin
                ShowMsg((self.Owner as TForm),'Автор наряда не включается в "рабочую" часть наряда!',[msbOK]);
                addempl:=false;
              end;
              //Проверяем, не был ли сотрудник в таким именем уже добавлен ранее
              ind:=0;
              while(ind<self.EmployCount)and(self.Employees[ind].Employ.name<>Employ.name)do inc(ind);
              if(ind<>self.EmployCount)then begin
                ShowMSG((self.Owner as TForm),'Этот сотрудник уже записан!',[msbOK]);
                addempl:=false;
              end;
              //добавление сотрудника в наряд
              if addempl then begin
                  //Запрашиваем общую информацию о работе
                  if Employ.code<>self.autor.Employ.code then rating:=DefRating else rating:=6;
                  time:=DefTime;
                  note:='';
                  //устанавливаем функцию в наряде по умаолчанию (если задана)
                  if (Length(DefFunctCode)>0)and(FunctionList.IndFromCode(DefFunctCode)>=0) then
                    funct:=FunctionList.Item[FunctionList.IndFromCode(DefFunctCode)]
                    else funct:=Employ.funct;
                  if WorkEmpDataForm.ShowWindow((self.Owner as TForm),Employ.name,funct,time,rating,note,img,self.EmployTimePay,Acsses)then
                    begin
                      inc(self.EmployCount);
                      self.Employees[ind].Employ:=Employ;
                      self.Employees[ind].funct:=funct;
                      self.Employees[ind].rating:=rating;
                      self.Employees[ind].ratval:=RatingVal[rating];
                      self.Employees[ind].time:=time;
                      self.Employees[ind].payroll:=0;
                      self.Employees[ind].note:=note;
                      self.Employees[ind].Bitmap:=img;
                      self.Employees[ind].WorkCount:=self.GroupRowCnt;
                      SetLength(self.Employees[ind].Works,self.Employees[ind].WorkCount);
                      if self.GroupRowCnt>0 then
                        for I := 0 to self.GroupRowCnt - 1 do
                          begin
                            self.Employees[ind].Works[i].Work:=self.Employees[0].Works[i].Work;
                            self.Employees[ind].Works[i].time:=0;
                            self.Employees[ind].Works[i].rating:=3;
                          end;
                      self.ChangeAndRepaint;
                    end;
                end;
            end;
        end else
        begin
    //Если нажат заполненный заголовк предлагаем изменить или удалить запись
          ind:=ShowMSG((self.Owner as TForm),self.Employees[c].Employ.name,[msbEdit,msbDel,msbCancel]);
          //Измение общей информации о рабоет сотрудника
          if (ind=msbEdit) then
            begin
              //Запрашиваем общую информацию о работе
              rating:=self.Employees[c].rating;
              time:=self.Employees[c].time;
              note:=self.Employees[c].note;
              funct:=self.Employees[c].funct;
              img:=self.Employees[c].Bitmap;
              if (WorkEmpDataForm.ShowWindow((self.Owner as TForm),self.Employees[c].Employ.name,funct,time,rating,note,img,self.EmployTimePay,Acsses))then
                begin
                  self.Employees[c].funct:=funct;
                  self.Employees[c].rating:=rating;
                  self.Employees[c].ratval:=RatingVal[rating];
                  self.Employees[c].time:=time;
                  self.Employees[c].note:=note;
                  self.DrawHeadText(c);
                  self.ChangeAndRepaint;
                end;
            end;
          //Удаление сотрудника из закголовка
          if (ind=msbDel)and
            (ShowMsg((self.Owner as TForm),'Удалить '+self.Employees[c].Employ.name
            +' из наряда?',[msbOK,msbCancel])=msbOK) then
            begin
              dec(self.EmployCount);
              for r :=c to self.EmployCount do
                begin
                  self.Employees[r].Employ:=self.Employees[r+1].Employ;
                  self.Employees[r].funct:=self.Employees[r+1].funct;
                  self.Employees[r].rating:=self.Employees[r+1].rating;
                  self.Employees[r].time:=self.Employees[r+1].time;
                  self.Employees[r].payroll:=self.Employees[r+1].payroll;
                  self.Employees[r].note:=self.Employees[r+1].note;
                  self.Employees[r].Bitmap:=self.Employees[r+1].Bitmap;
                  self.Employees[r].WorkCount:=self.Employees[r+1].WorkCount;
                  SetLength(self.Employees[r].Works,self.Employees[r].WorkCount);
                  for ind := 0 to self.Employees[r].WorkCount-1 do
                    self.Employees[r].Works[ind]:=self.Employees[r+1].Works[ind];
                end;
              self.ChangeAndRepaint;
            end;
        end;
end;

//Вывод текста ячейки таблицы
procedure TWorkTable.DrawCellText(c,r : integer);
var
  s,h    : integer;
  str    : string;
  TxtFrm : cardinal;
  rct    : Trect;
begin
  //Высота единичной строки
  h:=round((self.Cells[c,r].Bottom-self.Cells[c,r].Top-4)/4);
  self.Canvas.Brush.Color:=self.Color;
  rct:=self.Cells[c,r];
  inc(rct.Left);
  dec(rct.Right);
  inc(rct.top);
  dec(rct.Bottom);
  self.Canvas.Pen.Color:=self.Color;
  self.Canvas.Rectangle(rct);
  self.Canvas.Pen.Color:=clBlack;
  for s := 1 to 4 do
    begin
      rct:=self.Cells[c,r];
      rct.Top:=self.Cells[c,r].Top+(s-1)*h;
      rct.Bottom:=rct.Top+h;
      inc(rct.Top,2);
      dec(rct.Right,4);
      self.Canvas.Font.Height:=h;
      TxtFrm:=0;
      case s of
        1 : begin
             TxtFrm:=DT_CENTER or DT_SINGLELINE or DT_VCENTER;
             self.Canvas.Font.Style:=[fsBold];
             self.Canvas.Font.Color:=clBlack;
            end;
        2 : begin
             TxtFrm:=DT_CENTER or DT_SINGLELINE or DT_VCENTER;
             self.Canvas.Font.Style:=[fsBold];
             self.Canvas.Font.Color:=clBlack;
            end;
        3 : begin
             TxtFrm:=DT_CENTER or DT_SINGLELINE or DT_VCENTER;
             self.Canvas.Font.Style:=[];
             self.Canvas.Font.Color:=clBlack;
            end;
        4 : begin
             TxtFrm:=DT_RIGHT or DT_SINGLELINE or DT_VCENTER;
             self.Canvas.Font.Style:=[fsBold,fsItalic];
             self.Canvas.Font.Color:=clRed;
            end;
      end;
      if (c<self.EmployCount)and(r<self.Employees[c].WorkCount) then
      begin
        case s of
          1 : if(self.Employees[c].Works[r].Work.Group)then
              if self.Employees[c].Works[r].time>0 then
                str:=RatingSTR[self.Employees[c].Works[r].Rating] else str:=''
            else str:=WorkList.ShortName(1,self.Employees[c].Works[r].Work.name);
          2 : if(self.Employees[c].Works[r].Work.Group)then
              if self.Employees[c].Works[r].time>0 then
                str:=FormatFloat('##0.0#',self.Employees[c].Works[r].time)+' час' else str:=''
            else str:=WorkList.ShortName(2,self.Employees[c].Works[r].Work.name);
          3 : if(self.Employees[c].Works[r].Work.Group)then
              str:=''
            else if (self.Employees[c].Works[r].Work.TmPay)then
              str:=FormatFloat('##0.0#',self.Employees[c].Works[r].time)+' час'
            else str:=IntToStr(self.Employees[c].Works[r].count1)+' ед';
          4 : if (self.Employees[c].Works[r].Work.Group)and(self.Employees[c].Works[r].time=0)
              then str:='' else str:=FormatFloat('###0.0#',self.Employees[c].Works[r].payrol)+' руб';
        end; end else str:='';
      if (c=self.ColCount) then
        case s of
          1: str:=WorkList.ShortName(1,self.GroupWork[r].Work.name);
          2: str:=WorkList.ShortName(2,self.GroupWork[r].Work.name);
          3: str:=IntToStr(self.GroupWork[r].count)+' ед';
          4: str:=FormatFloat('###0.0#',self.GroupWork[r].payrol)+' руб';
        end;
      DrawText(self.Canvas.Handle,pchar(str),Length(str),rct,TxtFrm);
    end;
end;

//Вывод текста ячейки заголовка
procedure TWorkTable.DrawHeadText(c : integer);
var
  s,h        : integer;
  ImgW,ImgH  : integer;
  str        : widestring;
  TxtFrm     : cardinal;
  rct        : Trect;
  bmp        : TbitMap;
begin
  //Закрашиваем облать
  rct:=self.Employees[c].rect;
  self.Canvas.Brush.Color:=self.Color;
  self.Canvas.Rectangle(rct);
  //Выводим рисунок
  ImgH:=round(self.HeaderHeight/2);
  ImgW:=ImgH;
  rct.Left:=rct.Left+round((rct.Right-rct.Left-ImgW)/2);
  rct.Top:=rct.Top+5;
  rct.Right:=rct.Left+ImgW;
  rct.Bottom:=rct.Top+ImgH;
  self.Canvas.Draw(rct.Left,rct.Top,self.Employees[c].Bitmap);
  //Выводим значек почаоовой оплаты
  if (self.Employees[c].timepay)and(c<self.EmployCount) then
    begin
      bmp:=TBitMap.Create;
      bmp.LoadFromResourceName(hInstance,'TimePayImg');
      self.Canvas.Draw(rct.Right-bmp.Width+5,rct.Bottom-bmp.Height+2,bmp);
    end;
  //Высота единичной строки
  h:=round((self.Employees[c].rect.Bottom-self.Employees[c].rect.Top-ImgH-10)/5);
  //Вывод строк
  for s := 1 to 5 do
    begin
      rct:=self.Employees[c].rect;
      rct.Top:=self.Employees[c].rect.Top+ImgH+6+(s-1)*h;
      rct.Bottom:=rct.Top+h;
      //Вывод значений
      if c<self.EmployCount then
      case s of
        1 : str:=EmployList.ShortName(self.Employees[c].Employ.name);
        2 : str:=self.Employees[c].funct.name;
        3 : str:=FormatFloat('###0.##',self.Employees[c].time)+' час';
        4 : str:=RatingStr[self.Employees[c].rating];
        5 : str:=FormatFloat('###0.00',self.Employees[c].payroll)+' руб';
      end else str:='';
      inc(rct.Top,2);
      dec(rct.Right,4);
      self.Canvas.Font.Height:=h;
      TxtFrm:=DT_CENTER or DT_SINGLELINE or DT_VCENTER;
      case s of
        1 : begin
             self.Canvas.Font.Style:=[fsBold];
             self.Canvas.Font.Color:=clBlack;
            end;
        2,3,4 : begin
             self.Canvas.Font.Style:=[];
             self.Canvas.Font.Color:=clBlack;
            end;
        5 : begin
             self.Canvas.Font.Style:=[fsBold,fsItalic];
             self.Canvas.Font.Color:=clRed;
            end;
      end;
      self.Canvas.Brush.Color:=self.Color;
      DrawTextW(self.Canvas.Handle,PWideChar(str),Length(str),rct,TxtFrm);
    end;
end;

//Отрисовка компонента
procedure TWorkTable.Paint(Sender: TObject);
const
  LineBevel = 16;
var
  ClipRect, rct          : TRect;
  c,r,ColWidth,RowHeight : integer;
  bmp                    : TBitMap;
begin
  self.HeaderHeight:=round(self.Height*0.2);
  self.Canvas.Pen.Color:=self.Color;
  self.Canvas.Rectangle(self.ClientRect);
  self.Canvas.Pen.Color:=clBlack;
  //Определение области рисования
  ClipRect:=self.ClientRect;
  self.Canvas.Brush.Color:=clWhite;
  //Отрисовка заголовков столбцов
  ColWidth:=round((ClipRect.Right-ClipRect.Left)/(self.ColCount+2));
  for c := 0 to self.ColCount - 1 do
    begin
      rct.Left:=round(ColWidth+1.5*self.Bevel)+c*ColWidth;
      rct.Top:=ClipRect.Top;
      rct.Bottom:=rct.Top+self.HeaderHeight;
      rct.Right:=rct.Left+ColWidth-self.Bevel;
      self.Employees[c].rect:=rct;
      self.Canvas.Rectangle(rct);
      self.DrawHeadText(c);
    end;
  //Отрисовка ячеек
  RowHeight:=round((ClipRect.Bottom-ClipRect.Top-Self.HeaderHeight-LineBevel)/self.RowCount);
  for r := 0 to self.RowCount - 1 do
    begin
      //Обрамление и отрисовка групповых ставок
      if r<self.GroupRowCnt then
        begin
          //Строка ставки
          rct.Left:=round(ColWidth+1.5*self.Bevel);
          rct.Top:=(ClipRect.Top+self.HeaderHeight+LineBevel+round(0.5*self.Bevel))+r*RowHeight;
          rct.Right:=rct.Left+ColWidth*self.ColCount-self.Bevel;
          rct.Bottom:=rct.Top+RowHeight-self.Bevel;
          self.Canvas.Rectangle(rct);
          //Информация о ставке
          rct.Left:=round(ColWidth+1.5*self.Bevel)+self.ColCount*ColWidth;
          rct.Right:=rct.Left+ColWidth-self.Bevel;
          self.Cells[self.ColCount,r]:=rct;
          self.Canvas.Rectangle(self.Cells[self.ColCount,r]);
          self.DrawCellText(self.ColCount,r);
        end;
      //Вывод текста в ячейках групповых и индвид ставок
      for c := 0 to self.ColCount - 1 do
        begin
          rct.Left:=round(ColWidth+1.5*self.Bevel)+c*ColWidth;
          rct.Right:=rct.Left+ColWidth-self.Bevel;
          rct.Top:=(ClipRect.Top+self.HeaderHeight+LineBevel+round(0.5*self.Bevel))+r*RowHeight;
          rct.Bottom:=rct.Top+RowHeight-self.Bevel;
          self.Cells[c,r]:=rct;
          if not(r<GroupRowCnt) then self.Canvas.Rectangle(self.Cells[c,r]);
          self.DrawCellText(c,r);
        end;
    end;
  //Линия под заголовком
  rct:=ClipRect;
  rct.Top:=rct.Top+self.HeaderHeight+round(LineBevel/2);
  rct.Bottom:=rct.Top+3;
  self.Canvas.Brush.Color:=clBlack;
  self.Canvas.Rectangle(rct);
  //Кнопка выхода
  BtnRect.Left:=self.ClientRect.Right-80-5;
  BtnRect.Top:=self.ClientRect.Bottom-80-5;
  BtnRect.Right:=BtnRect.Left+80;
  BtnRect.Bottom:=BtnRect.Top+80;
  bmp:=TBitMap.Create;
  bmp.LoadFromResourceName(hInstance,'CancelBtnImg');
  self.Canvas.Draw(BtnRect.Left,Btnrect.Top,bmp);
  self.Canvas.Brush.Color:=clWhite;
  self.Canvas.Font.Style:=[fsBold];
  self.Canvas.Font.Color:=clNavy;
  self.Canvas.TextOut(0,0,FormatDateTime('dd mmm yyyy (ddd)',self.MyDate));
  if self.Night then
    self.Canvas.TextOut(0,16,'ночь')else self.Canvas.TextOut(0,16,'день');
end;

//Запиь таблицы в файл
procedure TWorkTable.SaveToFile(Fname:string);
var
  MyFile : TfileStream;
  i,j    : integer;
  str    : shortstring;
begin
  //добавлено 01.09 для дозаписи детали "Вторичное сырье" в ранее провденные наряды
   {   for j := 0 to high(self.GroupWork) do    begin
        //добавлено 01.09 для дозаписи детали "Вторичное сырье" в ранее провденные наряды
        if self.GroupWork[j].Work.code='52' then begin
          self.GroupWork[j].Work.Item.code:='Ц9999999';
          self.GroupWork[j].Work.Item.name:='Вторичное сырье';

        end;
      end;  
  self.ChangeAndRepaint;  }
  //-----------------------
  MyFile:=TFileStream.Create(fname, fmCreate);
  str:=self.note;
  MyFile.Write(str,sizeof(shortstring));
  MyFile.Write(self.MyDate,sizeof(TDate));
  MyFile.Write(self.number,sizeof(integer));
  MyFile.Write(self.night,sizeof(boolean));
  MyFile.Write(self.nightpay,sizeof(real));
  MyFile.Write(self.datewrong,sizeof(boolean));
  MyFile.Write(self.AutorTimePay,sizeof(boolean));
  MyFile.Write(self.EmployTimePay,sizeof(boolean));
  MyFile.Write(self.createtime,sizeof(TDateTime));
  MyFile.Write(self.autorcalck,sizeof(boolean));
  MyFile.Write(self.autor.Employ,sizeof(TEmploy));
  self.autor.Bitmap.SaveToStream(MyFile);
  MyFile.Write(self.autor.rating,sizeof(integer));
  MyFile.Write(self.autor.ratval,sizeof(integer));
  MyFile.Write(self.autor.time,sizeof(real));
  str:=self.autor.note;
  MyFile.Write(str,sizeof(shortstring));
  MyFile.Write(self.autor.payroll,sizeof(real));
  //
  MyFile.Write(self.ColCount,sizeof(integer));
  MyFile.Write(self.RowCount,sizeof(integer));
  MyFile.Write(self.EmployCount,sizeof(integer));
  for I := 0 to self.EmployCount - 1 do
    begin
      MyFile.Write(self.Employees[i].Employ,sizeof(TEmploy));
      self.Employees[i].Bitmap.SaveToStream(MyFile);
      MyFile.Write(self.Employees[i].funct,sizeof(TFunction));
      MyFile.Write(self.Employees[i].rating,sizeof(integer));
      MyFile.Write(self.Employees[i].ratval,sizeof(integer));
      MyFile.Write(self.Employees[i].time,sizeof(real));
      MyFile.Write(self.Employees[i].timepay,sizeof(boolean));
      MyFile.Write(self.Employees[i].payroll,sizeof(real));
      str:=self.Employees[i].note;
      MyFile.Write(str,sizeof(shortstring));
      MyFile.Write(self.Employees[i].WorkCount,sizeof(integer));
      for j := 0 to self.Employees[i].WorkCount - 1 do
        MyFile.Write(self.Employees[i].Works[j],sizeof(TEmployWork));
    end;
  MyFile.Write(self.GroupRowCnt,sizeof(integer));
  for I := 0 to self.GroupRowCnt - 1 do
      MyFile.Write(self.GroupWork[i],sizeof(TGroupWork));
  MyFile.Write(self.ItemCount,sizeof(integer));
  for I := 0 to self.ItemCount - 1 do
      MyFile.Write(self.ItemList[i],sizeof(TitemResRec));
  MyFile.Free;
end;

function TWorkTable.LoadFromFile(Fname:string):boolean;
var
  MyFile    : TfileStream;
  count,i,j : integer;
  str       : shortstring;
  bmp       : TBitMap;
begin
  result:=false;
  if not FileExists(fname) then Abort;
  MyFile:=TFileStream.Create(fname, fmOpenRead);
  try
  MyFile.Read(str,sizeof(shortstring));
  self.note:=str;
  MyFile.Read(self.MyDate,sizeof(TDate));
  MyFile.Read(self.number,sizeof(integer));
  MyFile.Read(self.night,sizeof(boolean));
  MyFile.Read(self.nightpay,sizeof(real));
  MyFile.Read(self.datewrong,sizeof(boolean));
  MyFile.Read(self.AutorTimePay,sizeof(boolean));
  MyFile.Read(self.EmployTimePay,sizeof(boolean));
  MyFile.Read(self.createtime,sizeof(TDateTime));
  MyFile.Read(self.autorcalck,sizeof(boolean));
  MyFile.Read(self.autor.Employ,sizeof(TEmploy));
  self.autor.Bitmap:=TBitmap.Create;
  self.autor.Bitmap.SetSize(80,80);
  autor.Bitmap.LoadFromStream(MyFile);
  MyFile.Read(self.autor.rating,sizeof(integer));
  MyFile.Read(self.autor.ratval,sizeof(integer));
  MyFile.Read(self.autor.time,sizeof(real));
  MyFile.Read(str,sizeof(shortstring));
  self.autor.note:=str;
  MyFile.Read(self.autor.payroll,sizeof(real));
  //
  myfile.Read(i,sizeof(integer));
  myfile.Read(j,sizeof(integer));
  bmp:=TBitMap.Create;
  bmp.LoadFromResourceName(hInstance, 'DefEmpImg');
  self.SetTableSize(i,j);
  myfile.Read(count,sizeof(integer));
  self.EmployCount:=count;
  for I := 0 to count - 1 do
    begin
      MyFile.Read(self.Employees[i].Employ,sizeof(TEmploy));
      self.Employees[i].Bitmap:=TBitmap.Create;
      self.Employees[i].Bitmap.SetSize(80,80);
      self.Employees[i].Bitmap.LoadFromStream(MyFile);
      MyFile.Read(self.Employees[i].funct,sizeof(TFunction));
      MyFile.Read(self.Employees[i].rating,sizeof(integer));
      MyFile.Read(self.Employees[i].ratval,sizeof(integer));
      MyFile.Read(self.Employees[i].time,sizeof(real));
      MyFile.Read(self.Employees[i].timepay,sizeof(boolean));
      MyFile.Read(self.Employees[i].payroll,sizeof(real));
      MyFile.Read(str,sizeof(shortstring));
      self.Employees[i].note:=str;
      MyFile.Read(self.Employees[i].WorkCount,sizeof(integer));
      SetLength(self.Employees[i].Works,self.Employees[i].WorkCount);
      for j := 0 to self.Employees[i].WorkCount - 1 do
        MyFile.Read(self.Employees[i].Works[j],sizeof(TEmployWork));
    end;
  myfile.Read(count,sizeof(integer));
  self.GroupRowCnt:=count;
  for I := 0 to Count - 1 do
    myfile.Read(self.GroupWork[i],sizeof(TGroupWork));
  myfile.Read(self.ItemCount,sizeof(integer));
  SetLength(self.ItemList,self.ItemCount);
  for I := 0 to self.ItemCount - 1 do
    MyFile.Read(self.ItemList[i],sizeof(TitemResRec));
  //self.datewrong:=(self.MyDate<IncDay(DateOf(self.createtime),-1));
  finally
    MyFile.Free;
  end;
  result:=true;

  //self.ChangeAndRepaint;
end;

procedure TWorkTable.ChangeAndRepaint;
var
  i,j,k,cnt : integer;
  pay1,pay2 : real;
  Itm       : TItem;
  List      : array of TItemResRec;

procedure CalckWork(emp,wrk:integer);
var
  ksum  : real;
  e     : integer;
begin
  if self.Employees[emp].Works[wrk].Work.Group then
    begin
      //групповая ставка
      //рассчитываем общий заработок по ставке
      self.GroupWork[wrk].payrol:=self.GroupWork[wrk].count*self.GroupWork[wrk].Work.PayRoll;
      if self.Night and  self.GroupWork[wrk].Work.Night then
        self.GroupWork[wrk].payrol:=self.GroupWork[wrk].payrol*self.NightPay;
      //суммироуем коэффициенты (время*оценка) всех учавстваваших в работе
      ksum:=0;
      for e := 0 to self.EmployCount - 1 do
         ksum:=ksum+self.Employees[e].Works[wrk].time*self.Employees[e].Works[wrk].rating;
      //рассчитываем долю сотрудника
      if ksum>0 then
        self.Employees[emp].Works[wrk].payrol:=self.GroupWork[wrk].payrol/ksum*
          self.Employees[emp].Works[wrk].time*self.Employees[emp].Works[wrk].rating
        else self.Employees[emp].Works[wrk].payrol:=0;
    end else
      begin
        if self.Employees[emp].Works[wrk].Work.TmPay  then
          self.Employees[emp].Works[wrk].payrol:=self.Employees[emp].Works[wrk].time*
            self.Employees[emp].Works[wrk].Work.PayRoll
        else
          self.Employees[emp].Works[wrk].payrol:=self.Employees[emp].Works[wrk].count1*
            self.Employees[emp].Works[wrk].Work.PayRoll;

        if self.Night and self.Employees[emp].Works[wrk].Work.Night then
          self.Employees[emp].Works[wrk].payrol:=self.Employees[emp].Works[wrk].payrol*self.NightPay;
      end;
end;

procedure CalckEmpl(emp:integer);
var
  wrk  : integer;
  sum  : real;
  totime : real;
begin
  //считаем общую сумму по ставкам
  sum:=0;
  totime:=0;
  for wrk := 0 to self.Employees[emp].WorkCount - 1 do
    begin
      CalckWork(emp,wrk);
      sum:=sum+self.Employees[emp].Works[wrk].payrol;
      totime:=totime+self.Employees[emp].Works[wrk].time;
    end;
  //начисляем премию
  self.Employees[emp].payroll:=sum+sum*self.Employees[emp].ratval/100;
  //Определяем часовой тариф - если для выбранной должности не задан тариф используем знач по умолчанию
  if self.Employees[emp].funct.sum=0 then self.Employees[emp].funct.sum:=DefFunctionSum;
  //считаем оплату по тарифу в зависимости от времени
  if self.Night then sum:=self.Employees[emp].funct.sum*self.Employees[emp].time*self.NightPay
    else sum:=self.Employees[emp].funct.sum*self.Employees[emp].time;
  //если сотрудник не автор наряда и разрешена почасовая оплата и почасовка больше - уст признак почасовой оплаты
  //если сотрудник автор наряда - почасовая оплата запрещена
  if self.Employees[emp].Employ.code<>self.autor.Employ.code then
    self.Employees[emp].timepay:=((self.Employees[emp].payroll<sum)and(self.EmployTimePay))
    else self.Employees[emp].timepay:=false;
  //если нужно платим по часам
  if self.Employees[emp].timepay then self.Employees[emp].payroll:=sum;
  //проверка суммы работы по часам
  if (totime>Employees[emp].time)or(totime>DefTime) then begin
    MessageDlg('Общее количество часов по ставкам для сорудника '+chr(13)+
      Employees[emp].Employ.name+chr(13)+' превышает общее время его работы !'+
      'Исправьте данные и пересчитайте наряд заново !',mtError,[mbOK],0) ;
    Employees[emp].payroll:=0;
  end;
end;

begin
  self.change:=true;
  //расчет начислений сотрудников
  for I := 0 to self.EmployCount - 1 do CalckEmpl(i);
  //расчет начислений автора наряда
  self.CalckAutorPay(pay1,pay2);
  //расчет резултатов производства
  //для сохранения данных о ранее записанно цикле сохраняем имеющийся
  //список в буфер
  cnt:=self.ItemCount;
  setLength(List,cnt);
  for I := 0 to self.ItemCount - 1 do List[i]:=self.ItemList[i];
  //заполнение списка деталями
  self.ItemCount:=0;
  SetLength(self.ItemList,self.ItemCount);
  for I := 0 to self.EmployCount - 1 do
    for j := 0 to self.Employees[i].WorkCount - 1 do
    if (Length(self.Employees[i].Works[j].Work.Item.code)>0)and
       (self.Employees[i].Works[j].Work.Item.code<>'0')then
      begin
        itm:=self.Employees[i].Works[j].Work.Item;
        k:=0;
        while(k<self.ItemCount)and(self.ItemList[k].Item.code<>itm.code)do inc(k);
        if(k=self.ItemCount)then
          begin
            inc(self.ItemCount);
            SetLength(self.ItemList,self.ItemCount);
            self.ItemList[self.ItemCount-1].Item:=itm;
          end;
      end;
  //считаем групповые ставки
  for i := 0 to high(self.GroupWork) do
    if (Length(self.GroupWork[i].Work.Item.code)>0)and(self.GroupWork[i].Work.Item.code<>'0')then begin
        itm:=self.GroupWork[i].Work.Item;
        k:=0;
        while(k<self.ItemCount)and(self.ItemList[k].Item.code<>itm.code)do inc(k);
        if(k=self.ItemCount)then
          begin
            inc(self.ItemCount);
            SetLength(self.ItemList,self.ItemCount);
            self.ItemList[self.ItemCount-1].Item:=itm;
          end;
      end;
  //получение результатов производства
  //восстанавливаем ранее записанное время цикла из буфера и проверяем наличе изменений
  for I := 0 to self.ItemCount - 1 do
    begin
      self.GetItemData(self.ItemList[i]);
      j:=0;
      while(j<cnt)and(self.ItemList[i].Item.code<>List[j].Item.code)do inc(j);
      if(j<cnt)and(self.ItemList[i].Item.code=List[j].Item.code)then
        begin
          self.ItemList[i].cycle:=List[j].cycle;
          if not self.itmchange then self.itmchange:=(self.ItemList[i].good<>List[j].good);          
        end;
    end;
  //перирсовка таблицы
  self.Repaint;
end;

end.
