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
  private {����� ����������� ������ ���������� ���������� � ��������� - "��� ���������� �����������"}
  {�������� �����, �.�. ���������� ������� �������� ������ ������ ������, "�������" ��� ��
  ��������.}
    ColCount     : integer;
    RowCount     : integer;
    HeaderHeight : integer;
    procedure Paint(Sender: TObject); reintroduce;
    procedure DrawCellText(c,r : integer);
    procedure DrawHeadText(c : integer);
    procedure MouseDown(Sender:TOBject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer); reintroduce;
    procedure GetItemData(var item:TItemResRec);
  public {��������� ����� �������� ��� ������������ ������}
    FName        : string;
    MyDate       : TDate;     //���� ������
    number       : integer;   //����� ������
    createtime   : TDateTime; //����� ��������
    autorcalck   : boolean;   //������� ���������� ������
    datewrong    : boolean;   //������������ �����
    autor        : TWTEmploy; //����� � ��� ����
    note         : string;    //����� ����������
    Bevel        : integer;   //������
    EmployCount  : integer;   //���-�� ����������
    Employees    : array of TWTEmploy;  //������ ����������
    GroupWork    : array of TGroupWork; //������ �������� ������
    Cells        : array of array of TRect; //������
    GroupRowCnt  : integer;  //���������� ��������� ������
    BtnRect      : TRect;    //������ ������
    Night        : boolean;  //������� � ����
    NightPay     : real;     //������ ������� � ����
    AutorTimePay : boolean;  //���������� �� ��������� ������ ��� ������
    EmployTimePay: boolean;  //���������� �� ��������� ������ ��� �����������
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
  //FList.Free;{��������� ��������� ������ ������}
  inherited;
end;

function TWorkTable.CalckAutorPay(var pay1,pay2:real):real;
//pay1 - ����� �� �������
//pay2 - ����� �� ������, �� ������� ����������� % ������
//result - ����� �� �����
//������� AUTOR.PAYROLL ��������������� �� ���������� �����
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
  //�������� ������ � ���������� ���������� �� ����� �������
  pay1:=0;
  for emp := 0 to self.EmployCount - 1 do
    if self.Employees[emp].Employ.code=self.autor.Employ.code then
      pay1:=self.Employees[emp].payroll;
  //��������� ����� ����� �� �������, % �� ������� ���� ��� �����
  sum:=0;
  for emp := 0 to self.EmployCount - 1 do
    for wrk := 0 to self.Employees[emp].WorkCount - 1 do
      if self.Employees[emp].Works[wrk].Work.NSpay then
        sum:=sum+self.Employees[emp].Works[wrk].payrol;
  //��������� % ���������� ����
  if (not self.datewrong) then pay2:=sum*self.autor.ratval/100 else pay2:=0;
  //��������� ����� �� ����� (� ������ �������� �� ����) � � ������ ������
 if not (self.Night) then tpay:=self.autor.Employ.funct.sum*self.autor.time else
    tpay:=self.autor.Employ.funct.sum*self.autor.time*self.NightPay;
  {//���� ��������� ��������� ������ � ��������� ������ ��� ����� �������
  self.autor.timepay:=((self.AutorTimePay)and((pay1+pay2)<tpay));
  //���� ���� ������ �� �����
  if self.autor.timepay then self.autor.payroll:=tpay else  self.autor.payroll:=(pay1+pay2); }

  //����� ������ � 1 �������� 2020 ����\
  //��� ����� = �� ����� + % �� ����� ��������� �����
  self.autor.timepay:=true;
  self.autor.payroll:=tpay+pay1+pay2;

  {showmessage('tpay='+FloatTostr(tpay)+chr(13)+
    'pay1='+FloatTostr(pay1)+chr(13)+'pay2='+FloatTostr(pay2)+chr(13)+
    'sum='+FloatTostr(sum)+chr(13)+'ratval='+FloatTostr(self.autor.ratval/100)); }

  //���������� ����� ��������� ����� �� ������� ��� �������� ������
  pay2:=sum;
  //��������� �� ���������� ������������� ���������
  if (AutorMaxPay>0)and(self.autor.payroll>AutorMaxPay) then self.autor.payroll:=AutorMaxPay;

  result:=tpay;
  end;
end;

//��������� ��������� ������ � ������
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
  //������� �������������� ������
  for e := 0 to self.EmployCount - 1 do
    for w := 0 to self.Employees[e].WorkCount - 1 do
      if self.Employees[e].Works[w].Work.Item.code=item.Item.code then
        begin
          item.good:=item.good+self.Employees[e].Works[w].count1;
          item.bad:=item.bad+self.Employees[e].Works[w].count2;
          item.hour:=item.hour+self.Employees[e].Works[w].time;
        end;
  //������� ��������� ������
  for i := 0 to high(self.GroupWork) do
    if self.GroupWork[i].Work.Item.code=item.Item.code then begin
      item.good:=item.good+self.GroupWork[i].count;
      //item.bad:=item.bad+self.Employees[e].Works[w].count2;
      //������� ���� ������������ �� ������ ������ ����� ������������
      hour:=0;
      for e := 0 to self.EmployCount - 1 do
        for w := 0 to Employees[e].WorkCount - 1 do
          if Employees[e].Works[w].Work.code=GroupWork[i].Work.code then
            hour:=hour+Employees[e].Works[w].time;
      item.hour:=item.hour+hour;
    end;
  //����������� ������������ �����
  if AskCycleTime then begin
    if (item.good+item.bad)>0 then
      item.cycle:=item.hour*3600/(item.good+item.bad) else item.cycle:=0;
    if (item.cycle>(Item.Item.time+Item.Item.time*0.2))or
      (item.cycle<(Item.Item.time-Item.Item.time*0.2))then item.cycle:=0;
  end else item.cycle:= Item.Item.time;
end;

//��������� �������� �������
procedure TWorkTable.SetTableSize(Col,Row : integer);
var
  r : integer;
begin
  //���������� �������� ������ �� ������� ��� ���� ��� ��
  //���������� ������� ����� ��� ���� � ��������� �������
  self.ColCount:=col;
  self.RowCount:=row;
  //������� ��������
  SetLength(self.Employees,self.ColCount);
  for r := 0 to self.ColCount-1 do
    begin
      self.Employees[r].Bitmap:=Tbitmap.Create;
      self.Employees[r].Bitmap.LoadFromResourceName(hInstance, 'DefEmpImg');
      self.Employees[r].WorkCount:=0;
      SetLength(self.Employees[r].Works,self.Employees[r].WorkCount);
    end;
  //������� �����
  SetLength(self.Cells,self.ColCount+1);
  for r := 0 to self.ColCount do
    SetLength(self.Cells[r],self.RowCount);
  //������ ��������� ������
  SetLength(self.GroupWork,self.RowCount);
end;

//�������� ��������� ������
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
      //������������ ���� ��������� ������
      for j := ind to self.GroupRowCnt - 2 do self.GroupWork[j]:=self.GroupWork[j+1];
      dec(self.GroupRowCnt);
      SetLength(self.GroupWork,self.GroupRowCnt);
    end;
end;

procedure TWorkTable.MouseDown(Sender:TOBject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
var
  c,r,ind,i,j : integer;
  img       : TbitMap;                    
  //��� ������ � ���������� � ��������
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
  //������� �� ������ ����� ----------------------------------------------------
  if (X<BtnRect.Right)and(X>BtnRect.Left)and
    (Y<BtnRect.Bottom)and(Y>BtnRect.top) then SendMessage(GetForegroundWindow,WM_CLOSE,0,0);
  //���� ������� ������� "������ ��������" ������� �� ���������-----------------
  if Acsses=alViewer then Abort;
  //����� ������� �� ������� ������� -------------------------------------------
  for c := 0 to self.ColCount do
    for r := 0 to self.RowCount - 1 do
      if (X<self.Cells[c,r].Right)and(X>self.Cells[c,r].Left)and
       (Y<self.Cells[c,r].Bottom)and(Y>self.Cells[c,r].top) then
        begin
  //���� �� ����� ��������� ������ ---------------------------------------------
          if c=self.ColCount then
            begin
              ind:=ShowMsg((self.Owner as TForm),self.GroupWork[r].Work.name,[msbEdit,msbDel,msbCancel]);
              //��������� ���������� � �������� ������
              if(ind=msbEdit)then
                begin
                  note:=IntToStr(self.GroupWork[r].count);
                  if NumKeyboardForm.GetValue((self.Owner as TForm),note,true) then
                    begin
                      self.GroupWork[r].count:=StrToInt(note);
                      self.ChangeAndRepaint;
                    end;
                end;
              //�������� ������ (��� ����������� �� �������������)
              if(ind=msbDel)and(ShowMsg((self.Owner as TForm),'������� ������ �� �������?',[msbOk,msbCancel])=msbOK)then
                begin
                  self.DelGroup(0,r,false);
                  self.ChangeAndRepaint;
                end;
            end;
  //���� �� ����������� �������������� ������ ----------------------------------
          if (c<self.EmployCount)and(r<self.employees[c].WorkCount) then
            begin
            //���������� �������� ��� ������� ������
            if(self.Employees[c].Works[r].Work.Group)and(self.Employees[c].Works[r].time=0)then
              ind:=msbEdit
            else
              ind:=ShowMSG((self.Owner as TForm),self.Employees[c].Employ.name+chr(13)+
                self.Employees[c].Works[r].Work.name,[msbEdit,msbDel,msbCancel]);
            //������� ���������� � ������ ����������
            if (ind=msbEdit) then
              begin
                //������� ���� ��������� ����������
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
            //�������� ������ � ������ ���������� �� ������ ������
            if (ind=msbDel)and
              (ShowMsg((self.Owner as TForm),('������� ������ � ������ '+self.Employees[c].Employ.name+' �� ������ "'+
              self.Employees[c].Works[r].Work.name+'" �� ������?'),[msbOK,msbCancel])=msbOK) then
              begin
                Work:=self.Employees[c].Works[r].Work;
                if Work.Group then
                  //���� ������ ���������
                  self.DelGroup(c,r,true)
                  else
                  //���� ���������������
                  begin
                    dec(self.Employees[c].WorkCount);
                    for ind :=r to self.Employees[c].WorkCount do
                      self.Employees[c].Works[ind]:=self.Employees[c].Works[ind+1];
                    SetLength(Self.Employees[c].Works,self.Employees[c].WorkCount);
                  end;
                if work.Group then self.ChangeAndRepaint else self.ChangeAndRepaint;
              end;
            end else
    //���� �� ������ ������ ----------------------------------------------------
          if (c<self.EmployCount)and(r>=self.employees[c].WorkCount) then
            if GetWorkListItem(ind) then
              begin
                Work:=WorkList.Item[ind];
                //��������� ����� �� ����� ���� ��������� �������
                if (self.employees[c].funct.code='00031')and(WorkList.Item[ind].code='51') then begin
                  ShowMsg((self.Owner as TForm),'��������� ����� �� ����� ���� ��������� �������!',[msbOK]);
                  Abort;
                end;
                ind:=self.Employees[c].WorkCount;
                if (ind=self.Employees[c].WorkCount) then
                  begin
                  //����������� ������ � ������ �� ���������� ������
                  time:=0;
                  rating:=3;
                  count1:=0;
                  count2:=0;
                  if EmpWorkDataForm.ShowWindow((self.Owner as TForm),Work.TmPay,Work.Group,
                    self.Employees[c].Employ.name,Work.name,Work.Norm,
                    Work.PayRoll,time,count1,count2,
                    rating,self.Employees[c].Bitmap) then
                    begin
                      //���� ��������� ��������� ������ ------------------------
                      if Work.Group then
                        begin
                          //��������� ����������� ��������� ������
                          i:=0;
                          while(i<self.EmployCount)and(self.Employees[i].WorkCount<self.RowCount)do inc(i);
                          if(self.Employees[i].WorkCount=self.RowCount)then
                            begin
                              ShowMsg((self.Owner as TForm),'������ ��������� ������ ����������!',[msbOK]);
                              Abort;
                            end;
                          //��������� ������ ��� ���� ����������� (��������� ����� ������)
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
                          //����������� ������� ��������� ������
                          inc(self.GroupRowCnt);
                          //"�������� ����" �������� ��������� ������
                          for j :=self.GroupRowCnt-1 downto 1 do self.GroupWork[j]:=self.GroupWork[j-1];
                          //��������� ����� ������ ������
                          self.GroupWork[0].Work:=Work;
                          if work.Norm>0 then
                            self.GroupWork[0].count:=round(work.Norm)
                            else self.GroupWork[0].count:=1;
                          self.GroupWork[0].payrol:=0;
                          //������ � ������ ���������� ���������� � ������ ������
                          i:=0;
                        end
                      else
                        begin
                          //���� ��������� ��� ������ --------------------------
                          inc(self.Employees[c].WorkCount);
                          SetLength(self.Employees[c].Works,self.Employees[c].WorkCount);
                          i:=self.Employees[c].WorkCount-1;
                        end;
                      //���������� ������ � ������ � ����� ������
                      self.Employees[c].Works[i].Work:=Work;
                      self.Employees[c].Works[i].time:=time;
                      self.Employees[c].Works[i].rating:=rating;
                      self.Employees[c].Works[i].count1:=count1;
                      self.Employees[c].Works[i].count2:=count2;
                      self.Employees[c].Works[i].payrol:=0;
                      //����������� ���� ������� (��� ��� ��� ��������� �������)
                      if Work.Group then self.ChangeAndRepaint else self.ChangeAndRepaint;
                    end;
                  end else ShowMSG((self.Owner as TForm),'��� ������ ��� �������� !',[msbOK]);
              end;
        end;
  //������ ������� �� ������� ��������� ----------------------------------------
  for c := 0 to self.ColCount do
    if (X<self.Employees[c].rect.Right)and(X>self.Employees[c].rect.Left)and
       (Y<self.Employees[c].rect.Bottom)and(Y>self.Employees[c].rect.top) then
       if c>=self.EmployCount then
        begin
    //���� ����� ������ ��������� - �������� �������� ���������� � �������
          img:=TBitMap.Create;
          if GetEmployListItem('������ ���������� � �����',ind,img,true)then
            begin
              addempl:=true;
              Employ:=EmployList.Item[ind];
              //����� ������ �� ����� ���� � ��������� �����
              if (AutorCanWork=false)and(Employ.code=Autor.Employ.code)then begin
                ShowMsg((self.Owner as TForm),'����� ������ �� ���������� � "�������" ����� ������!',[msbOK]);
                addempl:=false;
              end;
              //���������, �� ��� �� ��������� � ����� ������ ��� �������� �����
              ind:=0;
              while(ind<self.EmployCount)and(self.Employees[ind].Employ.name<>Employ.name)do inc(ind);
              if(ind<>self.EmployCount)then begin
                ShowMSG((self.Owner as TForm),'���� ��������� ��� �������!',[msbOK]);
                addempl:=false;
              end;
              //���������� ���������� � �����
              if addempl then begin
                  //����������� ����� ���������� � ������
                  if Employ.code<>self.autor.Employ.code then rating:=DefRating else rating:=6;
                  time:=DefTime;
                  note:='';
                  //������������� ������� � ������ �� ���������� (���� ������)
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
    //���� ����� ����������� �������� ���������� �������� ��� ������� ������
          ind:=ShowMSG((self.Owner as TForm),self.Employees[c].Employ.name,[msbEdit,msbDel,msbCancel]);
          //������� ����� ���������� � ������ ����������
          if (ind=msbEdit) then
            begin
              //����������� ����� ���������� � ������
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
          //�������� ���������� �� ����������
          if (ind=msbDel)and
            (ShowMsg((self.Owner as TForm),'������� '+self.Employees[c].Employ.name
            +' �� ������?',[msbOK,msbCancel])=msbOK) then
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

//����� ������ ������ �������
procedure TWorkTable.DrawCellText(c,r : integer);
var
  s,h    : integer;
  str    : string;
  TxtFrm : cardinal;
  rct    : Trect;
begin
  //������ ��������� ������
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
                str:=FormatFloat('##0.0#',self.Employees[c].Works[r].time)+' ���' else str:=''
            else str:=WorkList.ShortName(2,self.Employees[c].Works[r].Work.name);
          3 : if(self.Employees[c].Works[r].Work.Group)then
              str:=''
            else if (self.Employees[c].Works[r].Work.TmPay)then
              str:=FormatFloat('##0.0#',self.Employees[c].Works[r].time)+' ���'
            else str:=IntToStr(self.Employees[c].Works[r].count1)+' ��';
          4 : if (self.Employees[c].Works[r].Work.Group)and(self.Employees[c].Works[r].time=0)
              then str:='' else str:=FormatFloat('###0.0#',self.Employees[c].Works[r].payrol)+' ���';
        end; end else str:='';
      if (c=self.ColCount) then
        case s of
          1: str:=WorkList.ShortName(1,self.GroupWork[r].Work.name);
          2: str:=WorkList.ShortName(2,self.GroupWork[r].Work.name);
          3: str:=IntToStr(self.GroupWork[r].count)+' ��';
          4: str:=FormatFloat('###0.0#',self.GroupWork[r].payrol)+' ���';
        end;
      DrawText(self.Canvas.Handle,pchar(str),Length(str),rct,TxtFrm);
    end;
end;

//����� ������ ������ ���������
procedure TWorkTable.DrawHeadText(c : integer);
var
  s,h        : integer;
  ImgW,ImgH  : integer;
  str        : widestring;
  TxtFrm     : cardinal;
  rct        : Trect;
  bmp        : TbitMap;
begin
  //����������� ������
  rct:=self.Employees[c].rect;
  self.Canvas.Brush.Color:=self.Color;
  self.Canvas.Rectangle(rct);
  //������� �������
  ImgH:=round(self.HeaderHeight/2);
  ImgW:=ImgH;
  rct.Left:=rct.Left+round((rct.Right-rct.Left-ImgW)/2);
  rct.Top:=rct.Top+5;
  rct.Right:=rct.Left+ImgW;
  rct.Bottom:=rct.Top+ImgH;
  self.Canvas.Draw(rct.Left,rct.Top,self.Employees[c].Bitmap);
  //������� ������ ��������� ������
  if (self.Employees[c].timepay)and(c<self.EmployCount) then
    begin
      bmp:=TBitMap.Create;
      bmp.LoadFromResourceName(hInstance,'TimePayImg');
      self.Canvas.Draw(rct.Right-bmp.Width+5,rct.Bottom-bmp.Height+2,bmp);
    end;
  //������ ��������� ������
  h:=round((self.Employees[c].rect.Bottom-self.Employees[c].rect.Top-ImgH-10)/5);
  //����� �����
  for s := 1 to 5 do
    begin
      rct:=self.Employees[c].rect;
      rct.Top:=self.Employees[c].rect.Top+ImgH+6+(s-1)*h;
      rct.Bottom:=rct.Top+h;
      //����� ��������
      if c<self.EmployCount then
      case s of
        1 : str:=EmployList.ShortName(self.Employees[c].Employ.name);
        2 : str:=self.Employees[c].funct.name;
        3 : str:=FormatFloat('###0.##',self.Employees[c].time)+' ���';
        4 : str:=RatingStr[self.Employees[c].rating];
        5 : str:=FormatFloat('###0.00',self.Employees[c].payroll)+' ���';
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

//��������� ����������
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
  //����������� ������� ���������
  ClipRect:=self.ClientRect;
  self.Canvas.Brush.Color:=clWhite;
  //��������� ���������� ��������
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
  //��������� �����
  RowHeight:=round((ClipRect.Bottom-ClipRect.Top-Self.HeaderHeight-LineBevel)/self.RowCount);
  for r := 0 to self.RowCount - 1 do
    begin
      //���������� � ��������� ��������� ������
      if r<self.GroupRowCnt then
        begin
          //������ ������
          rct.Left:=round(ColWidth+1.5*self.Bevel);
          rct.Top:=(ClipRect.Top+self.HeaderHeight+LineBevel+round(0.5*self.Bevel))+r*RowHeight;
          rct.Right:=rct.Left+ColWidth*self.ColCount-self.Bevel;
          rct.Bottom:=rct.Top+RowHeight-self.Bevel;
          self.Canvas.Rectangle(rct);
          //���������� � ������
          rct.Left:=round(ColWidth+1.5*self.Bevel)+self.ColCount*ColWidth;
          rct.Right:=rct.Left+ColWidth-self.Bevel;
          self.Cells[self.ColCount,r]:=rct;
          self.Canvas.Rectangle(self.Cells[self.ColCount,r]);
          self.DrawCellText(self.ColCount,r);
        end;
      //����� ������ � ������� ��������� � ������ ������
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
  //����� ��� ����������
  rct:=ClipRect;
  rct.Top:=rct.Top+self.HeaderHeight+round(LineBevel/2);
  rct.Bottom:=rct.Top+3;
  self.Canvas.Brush.Color:=clBlack;
  self.Canvas.Rectangle(rct);
  //������ ������
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
    self.Canvas.TextOut(0,16,'����')else self.Canvas.TextOut(0,16,'����');
end;

//����� ������� � ����
procedure TWorkTable.SaveToFile(Fname:string);
var
  MyFile : TfileStream;
  i,j    : integer;
  str    : shortstring;
begin
  //��������� 01.09 ��� �������� ������ "��������� �����" � ����� ���������� ������
   {   for j := 0 to high(self.GroupWork) do    begin
        //��������� 01.09 ��� �������� ������ "��������� �����" � ����� ���������� ������
        if self.GroupWork[j].Work.code='52' then begin
          self.GroupWork[j].Work.Item.code:='�9999999';
          self.GroupWork[j].Work.Item.name:='��������� �����';

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
      //��������� ������
      //������������ ����� ��������� �� ������
      self.GroupWork[wrk].payrol:=self.GroupWork[wrk].count*self.GroupWork[wrk].Work.PayRoll;
      if self.Night and  self.GroupWork[wrk].Work.Night then
        self.GroupWork[wrk].payrol:=self.GroupWork[wrk].payrol*self.NightPay;
      //���������� ������������ (�����*������) ���� ������������� � ������
      ksum:=0;
      for e := 0 to self.EmployCount - 1 do
         ksum:=ksum+self.Employees[e].Works[wrk].time*self.Employees[e].Works[wrk].rating;
      //������������ ���� ����������
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
  //������� ����� ����� �� �������
  sum:=0;
  totime:=0;
  for wrk := 0 to self.Employees[emp].WorkCount - 1 do
    begin
      CalckWork(emp,wrk);
      sum:=sum+self.Employees[emp].Works[wrk].payrol;
      totime:=totime+self.Employees[emp].Works[wrk].time;
    end;
  //��������� ������
  self.Employees[emp].payroll:=sum+sum*self.Employees[emp].ratval/100;
  //���������� ������� ����� - ���� ��� ��������� ��������� �� ����� ����� ���������� ���� �� ���������
  if self.Employees[emp].funct.sum=0 then self.Employees[emp].funct.sum:=DefFunctionSum;
  //������� ������ �� ������ � ����������� �� �������
  if self.Night then sum:=self.Employees[emp].funct.sum*self.Employees[emp].time*self.NightPay
    else sum:=self.Employees[emp].funct.sum*self.Employees[emp].time;
  //���� ��������� �� ����� ������ � ��������� ��������� ������ � ��������� ������ - ��� ������� ��������� ������
  //���� ��������� ����� ������ - ��������� ������ ���������
  if self.Employees[emp].Employ.code<>self.autor.Employ.code then
    self.Employees[emp].timepay:=((self.Employees[emp].payroll<sum)and(self.EmployTimePay))
    else self.Employees[emp].timepay:=false;
  //���� ����� ������ �� �����
  if self.Employees[emp].timepay then self.Employees[emp].payroll:=sum;
  //�������� ����� ������ �� �����
  if (totime>Employees[emp].time)or(totime>DefTime) then begin
    MessageDlg('����� ���������� ����� �� ������� ��� ��������� '+chr(13)+
      Employees[emp].Employ.name+chr(13)+' ��������� ����� ����� ��� ������ !'+
      '��������� ������ � ������������ ����� ������ !',mtError,[mbOK],0) ;
    Employees[emp].payroll:=0;
  end;
end;

begin
  self.change:=true;
  //������ ���������� �����������
  for I := 0 to self.EmployCount - 1 do CalckEmpl(i);
  //������ ���������� ������ ������
  self.CalckAutorPay(pay1,pay2);
  //������ ���������� ������������
  //��� ���������� ������ � ����� ��������� ����� ��������� ���������
  //������ � �����
  cnt:=self.ItemCount;
  setLength(List,cnt);
  for I := 0 to self.ItemCount - 1 do List[i]:=self.ItemList[i];
  //���������� ������ ��������
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
  //������� ��������� ������
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
  //��������� ����������� ������������
  //��������������� ����� ���������� ����� ����� �� ������ � ��������� ������ ���������
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
  //���������� �������
  self.Repaint;
end;

end.
