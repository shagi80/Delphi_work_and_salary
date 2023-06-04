unit PrintUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, Buttons, StdCtrls, ExtCtrls, frxCross,
  frxClass, frxExportODF, frxExportPDF, WorkData;

const
  pmNarEmpList    =0; //�����: ������ ����������� ���������� �����������
  pmNarItemList   =1; //�����: ������ ����������� ������������
  pmEmpPayList    =2; //����� �� ����������� �� ������
  pmItemList      =3; //����� �� ������������ �� ������
  pmOneEmpPay     =4; //����� �� ����������� ��� ����� �������
  pmOneItem       =5; //����� �� ����������� ��� ����� ������
  pmOneEmpBadItem =6; //����� �� �������� ������ ��� ������ ����������
  pmLstEmpBadItem =7; //����� �� �������� ������ ��� ������ �����������
  repPrint = 1;
  repExp   = 2;

type
  TPrintMod = class(TDataModule)
    Report: TfrxReport;
    UDS: TfrxUserDataSet;
    UDS1: TfrxUserDataSet;
    frxODSExport1: TfrxODSExport;
    frxPDFExport1: TfrxPDFExport;
    frxODTExport1: TfrxODTExport;
    procedure UDSNext(Sender: TObject);
    procedure NarEmplListGetValue(const VarName: string; var Value: Variant);
    procedure NarItemListGetValue(const VarName: string; var Value: Variant);
    procedure EmpPayListGetValue(const VarName: string; var Value: Variant);
    procedure ItemListGetValue(const VarName: string; var Value: Variant);
    procedure OneItemGetValue(const VarName: string; var Value: Variant);
    procedure OneEmpPayGetValue(const VarName: string; var Value: Variant);
    procedure LstEmpBadItemValue(const VarName: string; var Value: Variant);
    procedure OneEmpBadItemValue(const VarName: string; var Value: Variant);
    procedure PrintNarEmplList(fname:string);
    procedure PrintNarItemList(fname:string);
    procedure PrintEmpPayList(Dt1,Dt2:TDate;Codes:TStringList;mode:word);
    procedure PrintItemList(Dt1,Dt2:TDate;Codes:TStringList;mode:word);
    procedure PrintOneEmpPay(Dt1,Dt2:TDate;Code:string;mode:word);
    procedure PrintOneItem(Dt1,Dt2:TDate;Code:string;mode:word);
    procedure PrintLstEmpBadItem(Dt1,Dt2:TDate;Codes:TStringList;mode:word);
    procedure PrintOneEmpBadItem(Dt1,Dt2:TDate;Code:string;mode:word);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TBadReportData = record
    item   : TItem;
    good   : integer;
    bad    : integer;
    weight : real;
  end;

  TBadReportDataList = array of TBadReportData;

var

  PrintMod  : TPrintMod;
  printmode : word;
  RepTime      : real;
  DataList  : TBadReportDataList;

procedure GetDocList(Dt1,Dt2:TDate;var DocLst:TStringList);

implementation

{$R *.dfm}

uses GlobalUnit,EmployData,WorkTable,DateUtils,DocListUnit, EmployLst;

const
  NarEmpListFile='\naremplist.fr3';
  //NarItmListFile='\naritmlist.fr3';
  NarItmListFile='\naritmlist1.fr3';
  EmpPayListFile='\emppaylist.fr3';
  ItemListFile  ='\itemlist.fr3';
  OneItemFile   ='\oneitem.fr3';
  OneEmpPayFile ='\oneemppay.fr3';
  OneEmpbadItemFile ='\oneempbaditem.fr3';
  LstEmpBadItemFile ='\lstempbaditem.fr3';

type
  //������ ��� ������ ������ ��� ������ �����������
  TRec = record
    code,name : string;
    pay,hour,time  : real;
  end;

  //������ ��� ������  ������ �� ����������� ��� ������ ����������
  TOneEmpRec = record
    num       : integer;
    Date      : TDate;
    Night     : boolean;
    AutTimePay: boolean;
    EmpTimePay: boolean;
    NigthPay  : real;
    NSPaySum  : real;
    DateWrong : boolean;
    Note      : string;
    Autor     : TWTEmploy;
    Employ    : TWTEmploy;
  end;
  TOneEmpRep = record
    Employ    : TEmploy;
    doccnt    : integer;
    docs      : array of ToneEmpRec;
    tpay      : real;
    ttime     : real;
  end;


var
  WorkTab          : TWorkTable;
  cnt              : integer;
  res              : array of TRec;
  OneEmpRep        : TOneEmpRep;
  itemres          : array of TItemResRec;
  date1,date2      : Tdate;
  empcode          : string;


procedure GetDocList(Dt1,Dt2:TDate;var DocLst:TStringList);
var
  i,j       : integer;
  item      : TListRec;
  fname,str : string;
begin
  DocLst:=TStringList.Create;
  DocLst.Clear;
  //���������� ������ ���������� �� ��������� ���������
  for i := 0 to MainList.Count - 1 do
    begin
      item:=MainList.Item[i];
      //�������� ��������� � ������� ��������� � ������ �����������
      if (Item.Date>=StartOfTheDay(Dt1))and(Item.Date<=EndOfTheDay(Dt2))and(Item.LastStatus.stat<>dsDelete) then
        begin
          fname:='doc'+IntTOStr(Item.Num)+'.nrd';
          if FileExists(ExePath+DefBaseFolder+fname) then
            begin
              str:=DateToStr(item.Date)+'='+ExePath+DefBaseFolder+fname;
              DocLst.Add(str);
            end;
        end;
    end;
  //��������� ������ �� �����
  for i:=0 to DocLst.Count-2 do
    for j:=i+1 to DocLst.Count-1 do
      if StrToDate(DocLst.Names[i])>StrToDate(DocLst.Names[j])then
        begin
          str := DocLst[i];
          DocLst[i] := DocLst[j];
          DocLst[j] := str;
        end;
end;

procedure TPrintMod.UDSNext(Sender: TObject);
begin
  case printmode of
    pmNarEmpList : if WorkTab.Employees[uds.RecNo].WorkCount>0 then UDS1.RangeEndCount:=WorkTab.Employees[uds.RecNo].WorkCount
                      else UDS1.RangeEndCount:=1;
    pmOneEmpPay  : begin
                    UDS1.RangeEndCount:=OneEmpRep.Docs[uds.RecNo].Employ.WorkCount;
                    if UDS1.RangeEndCount=0 then UDS1.RangeEndCount:=1;
                   end;
  end;
end;

//------------------------------------------------------------------------------

//����� �� ����������� ������������ �� ������ �������
procedure TPrintMod.PrintItemList(Dt1,Dt2:TDate;Codes:TStringList;mode:word);
var
  DocList : TStringList;
  i,j,k   : integer;
begin
  printmode:=pmEmpPayList;
  date1:=dt1;
  date2:=dt2;
  //�������� ������ ����������
  DocList:=TstringList.Create;
  GetDocList(Dt1,Dt2,DocList);
  //������� �������� ������ � ��������� ���� � �����
  cnt:=Codes.Count;
  SetLength(itemres,cnt);
  for I := 0 to codes.Count - 1 do
    begin
      itemres[i].Item:=ItemList.Item[ItemList.IndFromCode(codes[i])];
      itemres[i].good:=0;
      itemres[i].bad:=0;
      itemres[i].hour:=0;
      itemres[i].cycle:=0;
      itemres[i].Item.time:=0;
    end;
  //��������� � ������������� ���������
  WorkTab:=TWorkTable.Create(self);
  for I := 0 to DocList.Count - 1 do
    begin
      WorkTab.LoadFromFile(copy(DocList[i],pos('=',DocList[i])+1,MaxInt));
      for j := 0 to WorkTab.ItemCount - 1 do
        begin
          k:=0;
          while(k<cnt)and(itemres[k].Item.code<>worktab.ItemList[j].Item.code)do inc(k);
          if(k<cnt)and(itemres[k].Item.code=worktab.ItemList[j].Item.code)then
            begin
              itemres[k].good:=itemres[k].good+worktab.ItemList[j].good;
              itemres[k].bad:=itemres[k].bad+worktab.ItemList[j].bad;
              itemres[k].hour:=itemres[k].hour+worktab.ItemList[j].hour;
              itemres[k].cycle:=itemres[k].cycle+worktab.ItemList[j].cycle;
              itemres[k].Item.time:=itemres[k].Item.time+1;;
            end;
        end;
    end;
  //06.12.21 �������� ����� � �������� ������������
  if cnt>0 then begin
      i:=0;
      while(i<=high(itemres))do begin
        if (itemres[i].bad=0)and(itemres[i].good=0) then begin
          for j := i to high(itemres)-1 do itemres[j]:=itemres[j+1];
          SetLength(itemres,high(itemres));
        end else inc(i);
      end;
    cnt:=high(itemres)+1;
  end;
  //------------------------------------------------
  if cnt>0 then
    begin
      report.OnGetValue:=ItemListGetValue;
      UDS.RangeEnd:=reCount;
      uds.RangeEndCount:=cnt;
      uds.First;

      report.LoadFromFile(ExePath+ItemListFile,true);
      report.PrepareReport(true);
      if mode=repPrint then if ShowRep then report.ShowPreparedReport else report.Print;
      if mode=repExp then report.Export(self.frxODSExport1);
    end;
  WorkTab.Free;
end;

//����� �� ����������� ��� ����� ������
procedure TPrintMod.PrintOneItem(Dt1,Dt2:TDate;Code:string;mode:word);
var
  DocList : TStringList;
  i,j     : integer;
begin
  printmode:=pmOneItem;
  date1:=dt1;
  date2:=dt2;
  //�������� ������ ����������
  DocList:=TstringList.Create;
  GetDocList(Dt1,Dt2,DocList);
  //������� �������� ������
  cnt:=1;
  SetLength(itemres,cnt);
  itemres[0].Item:=ItemList.Item[ItemList.IndFromCode(code)];
  itemres[0].good:=0;
  itemres[0].bad:=0;
  itemres[0].hour:=0;
  itemres[0].cycle:=0;
  //��������� � ������������� ���������
  WorkTab:=TWorkTable.Create(self);
  for I := 0 to DocList.Count - 1 do
    begin
      WorkTab.LoadFromFile(copy(DocList[i],pos('=',DocList[i])+1,MaxInt));
      for j := 0 to WorkTab.ItemCount - 1 do
        if WorkTab.ItemList[j].Item.code=code then
          begin
            inc(cnt);
            SetLength(itemres,cnt);
            itemres[cnt-1]:=WorkTab.ItemList[j];
            itemres[cnt-1].Item.name:=FormatDateTime('dd.mm.yyyy (ddd)',WorkTab.MyDate);
            if WorkTab.Night then itemres[cnt-1].Item.name:=itemres[cnt-1].Item.name+' (����)'
              else itemres[cnt-1].Item.name:=itemres[cnt-1].Item.name+' (����)';
            itemres[cnt-1].Item.time:=WorkTab.number;
            itemres[cnt-1].Item.code:=WorkTab.autor.Employ.code;
            itemres[0].good:=itemres[0].good+itemres[cnt-1].good;
            itemres[0].bad:=itemres[0].bad+itemres[cnt-1].bad;
            itemres[0].hour:=itemres[0].hour+itemres[cnt-1].hour;
            itemres[0].cycle:=itemres[0].cycle+itemres[cnt-1].cycle;
            end;
    end;
  if cnt>1 then
    begin
      report.OnGetValue:=OneItemGetValue;
      UDS.RangeEnd:=reCount;
      uds.RangeEndCount:=cnt-1;
      uds.First;

      report.LoadFromFile(ExePath+OneItemFile,true);
      report.PrepareReport(true);
      if mode=repPrint then if ShowRep then report.ShowPreparedReport else report.Print;
      if mode=repExp then report.Export(self.frxODSExport1);
    end;
  WorkTab.Free;
end;

//����� �� ����������� ��� ������ ����������
procedure TPrintMod.PrintOneEmpPay(Dt1,Dt2:TDate;Code:string;mode:word);
var
  DocList    : TStringList;
  i,j        : integer;
  pay1,pay2  : real;
begin
  printmode:=pmOneEmpPay;
  date1:=dt1;
  date2:=dt2;
  //�������� ������ ����������
  DocList:=TstringList.Create;
  GetDocList(Dt1,Dt2,DocList);
  //������� �������� ������ � ��������� ���� � �����
  OneEmpRep.doccnt:=0;
  SetLength(OneEmpRep.docs,OneEmpRep.doccnt);
  OneEmpRep.Employ:=EmployList.Item[EmployList.IndFromName(EmployList.NameFromCode(code))];
  OneEmpRep.tpay:=0;
  OneEmpRep.ttime:=0;
  //��������� � ������������� ���������
  WorkTab:=TWorkTable.Create(self);
  for I := 0 to DocList.Count - 1 do
    begin
      WorkTab.LoadFromFile(copy(DocList[i],pos('=',DocList[i])+1,MaxInt));
      //����������, ���� �� ��������� � � ������
      j:=0;
      while(j<WorkTab.EmployCount)and(WorkTab.Employees[j].Employ.code<>code)do inc(j);
      if((j<WorkTab.EmployCount)and(WorkTab.Employees[j].Employ.code=code))or
          (WorkTab.autor.Employ.code=code)then
        begin
          inc(OneEmpRep.doccnt);
          SetLength(OneEmpRep.docs,OneEmpRep.doccnt);
          //���������� ����� ������ �� ������ � ������ ������
          OneEmpRep.docs[OneEmpRep.doccnt-1].num:=Worktab.number;
          OneEmpRep.docs[OneEmpRep.doccnt-1].Date:=WorkTab.MyDate;
          OneEmpRep.docs[OneEmpRep.doccnt-1].Night:=WorkTab.Night;
          OneEmpRep.docs[OneEmpRep.doccnt-1].EmpTimePay:=WorkTab.EmployTimePay;
          OneEmpRep.docs[OneEmpRep.doccnt-1].NigthPay:=WorkTab.NightPay;
          OneEmpRep.docs[OneEmpRep.doccnt-1].DateWrong:=WorkTab.datewrong;
          OneEmpRep.docs[OneEmpRep.doccnt-1].Note:=WorkTab.Note;
          WorkTab.CalckAutorPay(pay1,pay2);
          OneEmpRep.docs[OneEmpRep.doccnt-1].NSPaySum:=pay2;
          OneEmpRep.docs[OneEmpRep.doccnt-1].AutTimePay:=WorkTab.AutorTimePay;
          OneEmpRep.docs[OneEmpRep.doccnt-1].Autor:=WorkTab.autor;
          if WorkTab.autor.Employ.code=code then
            begin
              OneEmpRep.tpay :=OneEmpRep.tpay +WorkTab.autor.payroll;
              OneEmpRep.ttime:=OneEmpRep.ttime+WorkTab.autor.time;
            end;
          //���� ��������� � ������ ������ ���������� ������ � ���
          //���� ��� - ������������� ������ ���������� ������ 0 � �������� �����
          if(j<WorkTab.EmployCount)and(WorkTab.Employees[j].Employ.code=code)then
            begin
              OneEmpRep.docs[OneEmpRep.doccnt-1].Employ:=WorkTab.Employees[j];
              if WorkTab.autor.Employ.code<>code then
                begin
                  OneEmpRep.tpay :=OneEmpRep.tpay +WorkTab.Employees[j].payroll;
                  OneEmpRep.ttime:=OneEmpRep.ttime+WorkTab.Employees[j].time;
                end;
            end else OneEmpRep.docs[OneEmpRep.doccnt-1].Employ.payroll:=0;
        end;
    end;
  if OneEmpRep.doccnt>0 then
    begin
      report.OnGetValue:=OneEmpPayGetValue;
      UDS.RangeEnd:=reCount;
      UDS.RangeEndCount:=OneEmpRep.doccnt;
      UDS1.RangeEnd:=reCount;
      uds1.RangeEndCount:=OneEmpRep.docs[0].Employ.WorkCount;
      uds.First;

      report.LoadFromFile(ExePath+OneEmpPayFile,true);
      report.PrepareReport(true);
      if mode=repPrint then if ShowRep then report.ShowPreparedReport else report.Print;
      if mode=repExp then report.Export(self.frxODSExport1);
    end;
  WorkTab.Free;
end;

//�����: ������ ����������� ���������� �����������
procedure TPrintMod.PrintNarEmplList(fname:string);
begin
  printmode:=pmNarEmpList;
  WorkTab:=TWorkTable.Create(self);
  WorkTab.LoadFromFile(fname);
  if WorkTab.EmployCount>0 then
    begin
      report.OnGetValue:=NarEmplListGetValue;
      UDS.RangeEnd:=reCount;
      UDS1.RangeEnd:=reCount;
      uds.RangeEndCount:=WorkTab.EmployCount;
      uds.First;
      if WorkTab.EmployCount>0 then
        if WorkTab.Employees[uds.RecNo].WorkCount>0 then
          UDS1.RangeEndCount:=WorkTab.Employees[uds.RecNo].WorkCount
          else UDS1.RangeEndCount:=1;

      report.LoadFromFile(ExePath+NarEmpListFile,true);
      report.ShowReport(true);
    end;
  WorkTab.Free;
end;

//�����: ����� �� ���������� ���������� ���������
procedure TPrintMod.PrintNarItemList(fname:string);
begin
  printmode:=pmNarItemList;
  WorkTab:=TWorkTable.Create(self);
  WorkTab.LoadFromFile(fname);
  if WorkTab.ItemCount>0 then
    begin
      report.OnGetValue:=NarItemListGetValue;
      UDS.RangeEnd:=reCount;
      uds.RangeEndCount:=WorkTab.ItemCount;
      uds.First;

      report.LoadFromFile(ExePath+NarItmListFile,true);
      report.ShowReport(true);
    end;
  WorkTab.Free;
end;

//����� �� ����������� �� ������ �����������
procedure TPrintMod.PrintEmpPayList(Dt1,Dt2:TDate;Codes:TStringList;mode:word);
var
  DocList  : TStringList;
  i,j    : integer;

procedure Sum(code:string; pay,hour : real);
var
  k : integer;
begin
  k:=0;
  while(k<cnt)and(res[k].code<>code)do inc(k);
  if(k<cnt)and(res[k].code=code)then
    begin
      res[k].pay:=res[k].pay+pay;
      res[k].hour:=res[k].hour+hour;
    end;
end;

begin
  printmode:=pmEmpPayList;
  date1:=dt1;
  date2:=dt2;
  //�������� ������ ����������
  DocList:=TstringList.Create;
  GetDocList(Dt1,Dt2,DocList);
  //������� �������� ������ � ��������� ���� � �����
  cnt:=Codes.Count;
  SetLength(res,cnt);
  for I := 0 to codes.Count - 1 do
    begin
      res[i].code:=codes[i];
      res[i].name:=EmployList.NameFromCode(res[i].code);
      res[i].pay:=0;
      res[i].hour:=0;
    end;
  //��������� � ������������� ���������
  WorkTab:=TWorkTable.Create(self);
  for I := 0 to DocList.Count - 1 do
    begin
      WorkTab.LoadFromFile(copy(DocList[i],pos('=',DocList[i])+1,MaxInt));
      //�������� ������ � ����� � ����������� ��� ����������
      //��� ����������� �� ��������� �����
      for j := 0 to WorkTab.EmployCount - 1 do
        if WorkTab.Employees[j].Employ.code<>WorkTab.autor.Employ.code then
            Sum(WorkTab.Employees[j].Employ.code,WorkTab.Employees[j].payroll,WorkTab.Employees[j].time);
      //��� ������ ������
      if WorkTab.autor.payroll>0 then
        Sum(WorkTab.autor.Employ.code,WorkTab.autor.payroll,WorkTab.autor.time);
    end;
  if cnt>0 then
    begin
      report.OnGetValue:=EmpPayListGetValue;
      UDS.RangeEnd:=reCount;
      uds.RangeEndCount:=cnt;
      uds.First;

      report.LoadFromFile(ExePath+EmpPayListFile,true);
      report.PrepareReport(true);
      if mode=repPrint then if ShowRep then report.ShowPreparedReport else report.Print;
      if mode=repExp then report.Export(self.frxODSExport1);
    end;
  WorkTab.Free;
end;

//����� �� �������� ������ �� ������ �����������
procedure TPrintMod.PrintLstEmpBadItem(Dt1,Dt2:TDate;Codes:TStringList;mode:word);
var
  DocList  : TStringList;
  i,j,l,e  : integer;
  WeightLst: TStringList;
  weight   : real;

procedure Sum(code:string; pay,hour,time : real);
var
  k : integer;
begin
  k:=0;
  while(k<cnt)and(res[k].code<>code)do inc(k);
  if(k<cnt)and(res[k].code=code)then
    begin
      res[k].pay:=res[k].pay+pay;
      res[k].hour:=res[k].hour+hour;
      res[k].time:=res[k].time+time;
    end;
end;

begin
  printmode:=pmLstEmpBadItem;
  date1:=dt1;
  date2:=dt2;
  //�������� ������ ����������
  DocList:=TstringList.Create;
  GetDocList(Dt1,Dt2,DocList);
  //������� �������� ������ � ��������� ���� � �����
  cnt:=Codes.Count;
  SetLength(res,cnt);
  for I := 0 to codes.Count - 1 do
    begin
      res[i].code:=codes[i];
      res[i].name:=EmployList.NameFromCode(res[i].code);
      res[i].pay:=0;
      res[i].hour:=0;
      res[i].time:=0;
    end;
  //�������� ����� � ������
  WeightLst:=TStringList.Create;
  if FileExists(WeightFileName) then WeightLst.LoadFromFile(WeightFileName);
  //��������� � ������������� ���������
  WorkTab:=TWorkTable.Create(self);
  for I := 0 to DocList.Count - 1 do
    begin
      WorkTab.LoadFromFile(copy(DocList[i],pos('=',DocList[i])+1,MaxInt));
      //�������� ������ � ����� � ����������� ��� ����������
      for j := 0 to Codes.Count - 1 do
        begin
          //��� ������ ������
          if WorkTab.autor.Employ.code=codes[j] then begin
            sum(codes[j],0,0,WorkTab.autor.time);
            for l := 0 to Worktab.ItemCount - 1 do begin
              if Length(WeightLst.Values[Worktab.ItemList[l].Item.code])>0 then
                weight:=StrToFloat(WeightLst.Values[Worktab.ItemList[l].Item.code])/1000
                else weight:=0;
              Sum(codes[j],Worktab.ItemList[l].good*weight,Worktab.ItemList[l].bad*weight,0);
            end;
          end else begin
          //��� ����������� �� ��������� �����
            //����������, ������ �� ��������� � ��������� �����
            e:=0;
            while(e<WorkTab.EmployCount)and(WorkTab.Employees[e].Employ.code<>codes[j])do inc(e);
            if(e<WorkTab.EmployCount)and(WorkTab.Employees[e].Employ.code=codes[j])then begin
              sum(codes[j],0,0,WorkTab.Employees[e].time);
              //���������� ���������� ��� ������
              //� ��������� "���� ������" - �� ������ �� �����
              for l:= 0 to WorkTab.Employees[e].WorkCount - 1 do
                if WorkTab.Employees[e].Works[l].Work.NSpay then begin
                  if Length(WeightLst.Values[WorkTab.Employees[e].Works[l].Work.Item.code])>0 then
                    weight:=StrToFloat(WeightLst.Values[WorkTab.Employees[e].Works[l].Work.Item.code])/1000
                    else weight:=0;
                  Sum(codes[j],WorkTab.Employees[e].Works[l].count1*weight,WorkTab.Employees[e].Works[l].count2*weight,0);
                end;
            end;
          end;
        end;
    end;
  // ������� �� ������ ����������� � �������� ��� ������������
  I := 0;
  while(i<cnt)do
    if (res[i].pay+res[i].hour)=0 then
      begin
        j:=i+1;
        while(j<cnt)do
          begin
            res[i]:=res[j];
            inc(j);
          end;
        dec(cnt);
        SetLength(res,cnt);
      end else inc(i);
  //����� �� ������
  if cnt>0 then
    begin
      report.OnGetValue:=LstEmpBadItemValue;
      UDS.RangeEnd:=reCount;
      uds.RangeEndCount:=cnt;
      uds.First;
      report.LoadFromFile(ExePath+LstEmpBadItemFile,true);
      report.PrepareReport(true);
      if mode=repPrint then if ShowRep then report.ShowPreparedReport else report.Print;
      if mode=repExp then report.Export(self.frxODSExport1);
    end;
  WorkTab.Free;
end;

//����� �� �������� ������ ��� ������ ����������
procedure TPrintMod.PrintOneEmpBadItem(Dt1,Dt2:TDate;Code:string;mode:word);
var
  DocList    : TStringList;
  i,j,k      : integer;
begin
  printmode:=pmOneEmpBadItem;
  date1:=dt1;
  date2:=dt2;
  empcode:=code;
  if high(DataList)>=0 then
    begin
      report.OnGetValue:=OneEmpBadItemValue;
      UDS.RangeEnd:=reCount;
      UDS.RangeEndCount:=high(DataList)+1;
      UDS1.RangeEnd:=reCount;

      report.LoadFromFile(ExePath+OneEmpBadItemFile,true);
      report.PrepareReport(true);
      if mode=repPrint then if ShowRep then report.ShowPreparedReport else report.Print;
      if mode=repExp then report.Export(self.frxODSExport1);
    end;
  WorkTab.Free;
end;

//------------------------------------------------------------------------------

//�����: ������ ����������� ���������� �����������
procedure TPrintMod.NarEmplListGetValue(const VarName: string; var Value: Variant);
var
  pay1,pay2:real;
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'number') = 0 then Value :=FormatFloat('000000',WorkTab.number);
  if CompareText(VarName, 'datetime') = 0 then
    begin
      Value :=FormatDateTime('dd mmmm yyyy (dddd)',WorkTab.MyDate);
      if WorkTab.Night then Value:=Value+' (����)' else Value:=Value+' (����)';
    end;
  if CompareText(VarName, 'createtime') = 0 then Value :=FormatDateTime('dd mmm yy (ddd) hh:mm',WorkTab.createtime);
  //���� �����������
  //������ ������� ������ - ����� ���������� � ������ ����������
  if CompareText(VarName, 'empName') = 0 then Value :=WorkTab.Employees[uds.RecNo].Employ.name;
  if CompareText(VarName, 'empNote') = 0 then
    if (Length(WorkTab.Employees[uds.RecNo].note)>0) then Value :='('+WorkTab.Employees[uds.RecNo].note+')' else Value:='';
  if CompareText(VarName, 'empFunct') = 0 then
    begin
      Value :=WorkTab.Employees[uds.RecNo].funct.name;
      if EmpTimePay then Value:=Value+' ('+FormatFloat('##0.0#',WorkTab.Employees[uds.RecNo].funct.sum)+' ���/�)';
    end;
  if CompareText(VarName, 'empHour') = 0 then Value :=FormatFloat('#0.0#',WorkTab.Employees[uds.RecNo].time);
  //������ ������� ����� - ������ �����
  if CompareText(VarName, 'empWork') = 0 then
    if WorkTab.Employees[uds.RecNo].WorkCount>0 then Value := WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.name
      else value:='�� ������� �� �������';
  if CompareText(VarName, 'empWorkRes') = 0 then
    if WorkTab.Employees[uds.RecNo].WorkCount>0 then
    begin
      if (WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.TmPay)or(WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.Group) then
          Value := '�����������: '+FormatFloat('#0.0#',WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].time)+' ���.'
        else
          Value := '������������: '+FormatFloat('#0.0#',WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].count1)+' ��.';
      if (WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.Group) then
          Value:=Value+' ������ ��� �������: '+FormatFloat('####0.0#',WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.PayRoll)+' ���.'
        else
          begin
            Value:=Value+' C�����: '+FormatFloat('####0.0#',WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.PayRoll);
            if (WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.TmPay) then Value:=Value+' ���/�' else Value:=Value+' ���/��'
          end;
      if (WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].Work.Night)and(WorkTab.Night) then
        Value:=Value+' ������� �� ������ � ���� '+FormatFloat('##0.0#',(WorkTab.NightPay-1)*100)+'%';
    end else Value:='';
  if CompareText(VarName, 'empWorkPay') = 0 then
    if WorkTab.Employees[uds.RecNo].WorkCount>0 then Value := FormatFloat('####0.0#',WorkTab.Employees[uds.RecNo].Works[uds1.RecNo].payrol)
      else Value:='';
  //������ ������ ������� ������
  if CompareText(VarName, 'empTimePay') = 0 then
    if not(WorkTab.Employees[uds.RecNo].timepay) then Value:='(�� �������)' else Value:='(�� �����)';
  if CompareText(VarName, 'empRating') = 0 then
    if WorkTab.Employees[uds.RecNo].WorkCount>0 then Value := RatingStr[WorkTab.Employees[uds.RecNo].rating]
      else Value:='��� ������';
  if CompareText(VarName, 'empRatval') = 0 then
    if WorkTab.Employees[uds.RecNo].WorkCount>0 then Value := IntToStr(WorkTab.Employees[uds.RecNo].ratval)
      else Value:=0;
  if CompareText(VarName, 'empPayroll') = 0 then Value :=FormatFloat('####0.0#',WorkTab.Employees[uds.RecNo].payroll);
  //���� ������� ������
  if CompareText(VarName, 'AutorName') = 0 then Value := WorkTab.autor.Employ.name;
  if CompareText(VarName, 'AutorFunct') = 0 then
    if WorkTab.autorcalck then
      begin
        Value :=WorkTab.Autor.Employ.funct.name;
        if AutorTimePay then Value:=Value+' ('+FormatFloat('##0.0#',WorkTab.Autor.Employ.funct.sum)+' ���/�)'
      end else Value:='';
  if CompareText(VarName, 'AutorNote') = 0 then
    if (Length(WorkTab.autor.note)>0) then Value :='('+WorkTab.autor.note+')' else Value:='';
  if pos('AutorPay',VarName)>0 then
    if WorkTab.autor.payroll>0 then
    begin
      WorkTab.CalckAutorPay(pay1,pay2);
      if CompareText(VarName, 'AutorPay1') = 0 then
        if (pay1>0) then Value :='���������� �� ������: '+FormatFloat('####0.0#',pay1)+' ���.' else Value:='�� ������� �� �������.';
      if CompareText(VarName, 'AutorPay2') = 0 then
        if (WorkTab.datewrong) then Value:='����� �������� � ���������� ����� 1 �����.'
          else Value :='������ "'+RatingStr[WorkTab.autor.rating]+'". ������ +'+
              IntToStr(WorkTab.autor.ratval)+'% �� ����� '+FormatFloat('###0.0#',pay2)+' ���. ����� '
              +FormatFloat('####0.00',pay2*WorkTab.autor.ratval/100)+' ���.';
      if CompareText(VarName, 'AutorPayRoll') = 0 then
        begin
          Value:='����� ������: '+FormatFloat('#0.0#',WorkTab.autor.time)+' ���. '+
          '����� ���������� '+FormatFloat('####0.00',WorkTab.autor.payroll)+' ���';
          if WorkTab.autor.timepay then Value:=Value+' (�� �����)' else Value:=Value+' (������+������)';
        end;
    end else Value:='';
  //�������
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;

//�����: ����� �� ���������� ���������� ���������
procedure TPrintMod.NarItemListGetValue(const VarName: string; var Value: Variant);
var
  i,j : integer;
  str : string;
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'number') = 0 then Value :=FormatFloat('000000',WorkTab.number);
  if CompareText(VarName, 'datetime') = 0 then
    begin
      Value :=FormatDateTime('dd mmmm yyyy (dddd)',WorkTab.MyDate);
      if WorkTab.Night then Value:=Value+' (����)' else Value:=Value+' (����)';
    end;
  if CompareText(VarName, 'createtime') = 0 then Value :=FormatDateTime('dd mmm yy (ddd) hh:mm',WorkTab.createtime);
  if CompareText(VarName, 'Autor') = 0 then Value := WorkTab.autor.Employ.name;
  //�������
  if CompareText(VarName, 'name') = 0 then Value :=WorkTab.ItemList[uds.RecNo].Item.name;
  if CompareText(VarName, 'count1') = 0 then Value := IntToStr(WorkTab.ItemList[uds.RecNo].good);
  if CompareText(VarName, 'count2') = 0 then Value := IntToStr(WorkTab.ItemList[uds.RecNo].bad);
  if CompareText(VarName, 'badproc') = 0 then
    if WorkTab.ItemList[uds.RecNo].good>0 then Value := FormatFloat('##0.00',WorkTab.ItemList[uds.RecNo].bad/(WorkTab.ItemList[uds.RecNo].good+WorkTab.ItemList[uds.RecNo].bad)*100)
      else if WorkTab.ItemList[uds.RecNo].bad>0 then Value :='100' else Value :='0';
  if CompareText(VarName, 'hour') = 0 then Value := FormatFloat('###0.0#',WorkTab.ItemList[uds.RecNo].hour);
  if CompareText(VarName, 'startcycle') = 0 then Value := FormatFloat('###0.0#',WorkTab.ItemList[uds.RecNo].Item.time);
  if CompareText(VarName, 'cycle') = 0 then Value := FormatFloat('###0.0#',WorkTab.ItemList[uds.RecNo].cycle);
  if CompareText(VarName, 'employs') = 0 then begin
      str:='';
      for I := 0 to WorkTab.EmployCount - 1 do begin
        j:=0;
        while (j<WorkTab.Employees[i].WorkCount)and(WorkTab.Employees[i].Works[j].Work.Item.code<>WorkTab.ItemList[uds.RecNo].Item.code) do inc(j);
        if(j<WorkTab.Employees[i].WorkCount)and(WorkTab.Employees[i].Works[j].Work.Item.code=WorkTab.ItemList[uds.RecNo].Item.code) then
           str:=str+GetShortName(WorkTab.Employees[i].Employ.name)+' - '+
            IntToStr(WorkTab.Employees[i].Works[j].count1)+'/'+
            IntToStr(WorkTab.Employees[i].Works[j].count2)+'; '+chr(13);
          end;
      if length(str)>0 then delete(str,length(str),1);
      Value := str;
    end;

  //�������
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;

//����� �� ����������� �� ������ �����������
procedure TPrintMod.EmpPayListGetValue(const VarName: string; var Value: Variant);
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'date1') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date1);
  if CompareText(VarName, 'date2') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date2);
  //�������
  if CompareText(VarName, 'code') = 0 then Value :=res[uds.RecNo].code;
  if CompareText(VarName, 'name') = 0 then Value :=res[uds.RecNo].name;
  if CompareText(VarName, 'pay') = 0 then Value := FormatFloat('###0.0#',res[uds.RecNo].pay);
  if CompareText(VarName, 'hour') = 0 then Value := FormatFloat('###0.0#',res[uds.RecNo].hour);
  if CompareText(VarName, 'timepay') = 0 then
    if res[uds.RecNo].hour>0 then Value := FormatFloat('###0.0#',res[uds.RecNo].pay/res[uds.RecNo].hour)
      else Value:='0';
  //�������
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;

//����� �� ����������� ������������ �� ������ �������
procedure TPrintMod.ItemListGetValue(const VarName: string; var Value: Variant);
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'date1') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date1);
  if CompareText(VarName, 'date2') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date2);
  //�������
  if CompareText(VarName, 'code') = 0 then Value :=itemres[uds.RecNo].Item.code;
  if CompareText(VarName, 'name') = 0 then Value :=itemres[uds.RecNo].Item.name;
  if CompareText(VarName, 'good') = 0 then Value := IntToStr(itemres[uds.RecNo].good);
  if CompareText(VarName, 'bad') = 0 then  Value := IntToStr(itemres[uds.RecNo].bad);
  if CompareText(VarName, 'badproc') = 0 then
    if itemres[uds.RecNo].good>0 then Value := FormatFloat('##0.00',itemres[uds.RecNo].bad/(itemres[uds.RecNo].good+itemres[uds.RecNo].bad)*100)
      else if itemres[uds.RecNo].bad>0 then Value :='100' else Value :='0';
  if CompareText(VarName, 'hour') = 0 then Value := FormatFloat('###0.0#',itemres[uds.RecNo].hour);
  if CompareText(VarName, 'startcycle') = 0 then Value := FormatFloat('###0.0#',ItemList.Item[ItemList.IndFromCode(itemres[uds.RecNo].Item.code)].time);
  if CompareText(VarName, 'cycle') = 0 then
    if itemres[uds.RecNo].Item.time>0 then Value := FormatFloat('###0.0#',itemres[uds.RecNo].cycle/itemres[uds.RecNo].Item.time)
      else Value:='0';
  //�������
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;

//����� �� ����������� ������������ ��� ������ ������
procedure TPrintMod.OneItemGetValue(const VarName: string; var Value: Variant);
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'date1') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date1);
  if CompareText(VarName, 'date2') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date2);
  if CompareText(VarName, 'code') = 0 then Value :=itemres[0].Item.code;
  if CompareText(VarName, 'name') = 0 then Value :=itemres[0].Item.name;
  if CompareText(VarName, 'startcycle') = 0 then Value := FormatFloat('###0.0#',itemres[0].Item.time);
  //�������
  if CompareText(VarName, 'docdate') = 0 then Value := itemres[uds.RecNo+1].Item.name;
  if CompareText(VarName, 'docnum') = 0 then Value := FormatFloat('00000',itemres[uds.RecNo+1].Item.time);
  if CompareText(VarName, 'docautor') = 0 then Value := EmployList.ShortName(EmployList.NameFromCode(itemres[uds.RecNo+1].Item.code));
  if CompareText(VarName, 'good') = 0 then Value := IntToStr(itemres[uds.RecNo+1].good);
  if CompareText(VarName, 'bad') = 0 then Value := IntToStr(itemres[uds.RecNo+1].bad);
  if CompareText(VarName, 'badproc') = 0 then
    if itemres[uds.RecNo+1].good>0 then Value := FormatFloat('##0.00',itemres[uds.RecNo+1].bad/(itemres[uds.RecNo+1].good+itemres[uds.RecNo+1].bad)*100)
      else if itemres[uds.RecNo+1].bad>0 then Value :='100' else Value :='0';
  if CompareText(VarName, 'hour') = 0 then Value := FormatFloat('###0.0#',itemres[uds.RecNo+1].hour);
  if CompareText(VarName, 'cycle') = 0 then Value := FormatFloat('###0.0#',itemres[uds.RecNo+1].cycle);
  //�������
  if CompareText(VarName, 'resgood') = 0 then Value := IntToStr(itemres[0].good);
  if CompareText(VarName, 'resbad') = 0 then Value := IntToStr(itemres[0].bad);
  if CompareText(VarName, 'resbadproc') = 0 then
    if itemres[0].good>0 then Value := FormatFloat('##0.00',itemres[0].bad/(itemres[0].good+itemres[0].bad)*100)
      else if itemres[0].bad>0 then Value :='100' else Value :='0';
  if CompareText(VarName, 'reshour') = 0 then Value := FormatFloat('###0.0#',itemres[0].hour);
  if CompareText(VarName, 'rescycle') = 0 then Value := FormatFloat('###0.0#',itemres[0].cycle/(cnt-1));
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;

//����� �� ����������� ������������ ��� ������� ����������
procedure TPrintMod.OneEmpPayGetValue(const VarName: string; var Value: Variant);
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'date1') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date1);
  if CompareText(VarName, 'date2') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date2);
  if CompareText(VarName, 'code') = 0 then Value :=OneEmpRep.Employ.code;
  if CompareText(VarName, 'name') = 0 then Value :=OneEmpRep.Employ.name;
  if CompareText(VarName, 'funct') = 0 then Value :=OneEmpRep.Employ.funct.name;
  if CompareText(VarName, 'tpay') = 0 then Value :=FormatFloat('####0.0#',OneEmpRep.tpay);
  if CompareText(VarName, 'ttime') = 0 then Value :=FormatFloat('####0.0#',OneEmpRep.ttime);
  if CompareText(VarName, 'hourpay') = 0 then
    if OneEmpRep.ttime>0 then Value:='������� ��������� � ��� '+ FormatFloat('####0.0#',OneEmpRep.tpay/OneEmpRep.ttime)+' ���/���.'
    else Value:='';
  //������ ������� ������ - ����� ���������� � ������ �� ������
  if CompareText(VarName, 'docdate') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',OneEmpRep.docs[uds.RecNo].Date);
  if CompareText(VarName, 'docnum') = 0 then Value := FormatFloat('00000',OneEmpRep.docs[uds.RecNo].num);
  //���� ��������� ����� ������ ����� ���������� �� ������ �� ������
  if CompareText(VarName, 'docfunct') = 0 then
    if OneEmpRep.Employ.code=OneEmpRep.Docs[uds.RecNo].Autor.Employ.code then
    begin
      Value :=OneEmpRep.Docs[uds.RecNo].Autor.Employ.funct.name;
      if OneEmpRep.Docs[uds.RecNo].AutTimePay then Value:=Value+' ('+FormatFloat('##0.0#',OneEmpRep.Docs[uds.RecNo].Autor.Employ.funct.sum)+' ���/�)';
    end else
    begin
      Value :=OneEmpRep.Docs[uds.RecNo].Employ.funct.name;
      if EmpTimePay then Value:=Value+' ('+FormatFloat('##0.0#',OneEmpRep.Docs[uds.RecNo].Employ.funct.sum)+' ���/�)';
    end;
  if CompareText(VarName, 'doctime') = 0 then
    if OneEmpRep.Employ.code=OneEmpRep.Docs[uds.RecNo].Autor.Employ.code then
      Value :=FormatFloat('#0.0#',OneEmpRep.Docs[uds.RecNo].Autor.time)else
      Value :=FormatFloat('#0.0#',OneEmpRep.Docs[uds.RecNo].Employ.time);
  if CompareText(VarName, 'docnote') = 0 then
    if (Length(OneEmpRep.Docs[uds.RecNo].Note)>0) then Value :='('+OneEmpRep.Docs[uds.RecNo].Note+')' else Value:='';
  //������ ������� ������ - ������ ����� �� ������
  if OneEmpRep.Docs[uds.RecNo].Employ.WorkCount=0 then
    begin
      if CompareText(VarName, 'work') = 0 then Value :='�� ������� �� �������.';
      if CompareText(VarName, 'workres') = 0 then Value :='';
      if CompareText(VarName, 'workpay') = 0 then Value :='0.0';
    end else
    begin
      if CompareText(VarName, 'work') = 0 then Value := OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.name;
      if CompareText(VarName, 'workres') = 0 then
        begin
          if (OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.TmPay)or(OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.Group) then
            Value := '�����������: '+FormatFloat('#0.0#',OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].time)+' ���.'
          else
            Value := '������������: '+FormatFloat('#0.0#',OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].count1)+' ��.';
          if (OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.Group) then
            Value:=Value+' ������ ��� �������: '+FormatFloat('####0.0#',OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.PayRoll)+' ���.'
          else
            begin
              Value:=Value+' C�����: '+FormatFloat('####0.0#',OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.PayRoll);
              if (OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.TmPay) then Value:=Value+' ���/�' else Value:=Value+' ���/��'
            end;
          if (OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].Work.Night)and(OneEmpRep.Docs[uds.RecNo].Night) then
            Value:=Value+' ������� �� ������ � ���� '+FormatFloat('##0.0#',(OneEmpRep.Docs[uds.RecNo].NigthPay-1)*100)+'%';
        end;
      if CompareText(VarName, 'workpay') = 0 then Value := FormatFloat('###0.0#',OneEmpRep.Docs[uds.RecNo].Employ.Works[uds1.RecNo].payrol);
    end;
  //������ ������ ������� ������
  if OneEmpRep.Docs[uds.RecNo].Employ.WorkCount>0 then
    begin
      if CompareText(VarName, 'timepay') = 0 then
        if not(OneEmpRep.Docs[uds.RecNo].Employ.timepay) then Value:='(�� �������)' else Value:='(�� �����)';
      if CompareText(VarName, 'rating') = 0 then Value :='����� ������: "'+RatingStr[OneEmpRep.Docs[uds.RecNo].Employ.rating]+'" (+'+
        IntToStr(OneEmpRep.Docs[uds.RecNo].Employ.ratval)+'%)';
      if CompareText(VarName, 'payroll') = 0 then Value :=FormatFloat('####0.0#',OneEmpRep.Docs[uds.RecNo].Employ.payroll);
    end else
    begin
      if CompareText(VarName, 'timepay') = 0 then Value:='';
      if CompareText(VarName, 'rating') = 0 then Value:='';
      if CompareText(VarName, 'payroll') = 0 then Value:='0.0';
    end;
  //
  if OneEmpRep.Employ.code=OneEmpRep.Docs[uds.RecNo].Autor.Employ.code then
    begin
      if CompareText(VarName, 'autortimepay') = 0 then
        if not(OneEmpRep.Docs[uds.RecNo].Autor.timepay) then Value:='(������+%)' else Value:='(�� �����)';
      if CompareText(VarName, 'autorpaystr') = 0 then
        if OneEmpRep.docs[uds.RecNo].DateWrong then Value:='����� �������� � ���������� ����� 1 �����'
        else Value:='������ ��� ����� "'+RatingStr[OneEmpRep.Docs[uds.RecNo].Autor.rating]+'", ������ '+FormatFloat('##0.0#',
        OneEmpRep.Docs[uds.RecNo].Autor.ratval)+'% �� '+FormatFloat('####0.0#',OneEmpRep.Docs[uds.RecNo].NSPaySum)
        +' ��� = '+FormatFloat('####0.0#',OneEmpRep.Docs[uds.RecNo].NSPaySum*OneEmpRep.Docs[uds.RecNo].Autor.ratval/100)+' ���';
      if CompareText(VarName, 'autorpayroll') = 0 then Value :=FormatFloat('####0.0#',OneEmpRep.Docs[uds.RecNo].Autor.payroll);
    end else
    begin
      if CompareText(VarName, 'autortimepay') = 0 then Value:='';
      if CompareText(VarName, 'autorpaystr') = 0 then Value:='';
      if CompareText(VarName, 'autorpayroll') = 0 then Value:=FormatFloat('####0.0#',OneEmpRep.Docs[uds.RecNo].Employ.payroll);
    end;
  //�������
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;

//����� �� �������� ������ �� ������ �����������
procedure TPrintMod.LstEmpBadItemValue(const VarName: string; var Value: Variant);
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'date1') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date1);
  if CompareText(VarName, 'date2') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date2);
  //�������
  if CompareText(VarName, 'code') = 0 then Value :=res[uds.RecNo].code;
  if CompareText(VarName, 'name') = 0 then Value :=res[uds.RecNo].name;
  if CompareText(VarName, 'total') = 0 then Value := FormatFloat('####0.00',res[uds.RecNo].pay+res[uds.RecNo].hour);
  if CompareText(VarName, 'good') = 0 then Value := FormatFloat('####0.00',res[uds.RecNo].pay);
  if CompareText(VarName, 'bad') = 0 then Value := FormatFloat('####0.00',res[uds.RecNo].hour);
  if CompareText(VarName, 'proc') = 0 then
    if (res[uds.RecNo].pay+res[uds.RecNo].hour)>0 then Value := FormatFloat('##0.0#',(res[uds.RecNo].hour/(res[uds.RecNo].pay+res[uds.RecNo].hour))*100)
      else Value:='0';
  if CompareText(VarName, 'tottime') = 0 then Value :=FormatFloat('####0.00',res[uds.RecNo].time);
  if CompareText(VarName, 'restime') = 0 then Value :=FormatFloat('####0.00',(res[uds.RecNo].pay+res[uds.RecNo].hour)/res[uds.RecNo].time);
  //�������
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;

//����� �� �������� ������ ��� ��� ������� ����������
procedure TPrintMod.OneEmpBadItemValue(const VarName: string; var Value: Variant);
var
  i           : integer;
  tot, totbad : real;
begin
  value:=varname;
  //�����
  if CompareText(VarName, 'date1') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date1);
  if CompareText(VarName, 'date2') = 0 then Value :=FormatDateTime('dd mmm yyyy (ddd)',date2);
  if CompareText(VarName, 'code') = 0 then Value :=empcode;
  if CompareText(VarName, 'name') = 0 then Value :=EmployData.EmployList.NameFromCode(empcode);
  if CompareText(VarName, 'tcnt') = 0 then Value :=FormatFloat('####0.00',(DataList[uds.RecNo].bad+DataList[uds.RecNo].good)*DataList[uds.RecNo].weight/1000);
  if CompareText(VarName, 'badcount') = 0 then Value :=FormatFloat('####0.00',DataList[uds.RecNo].bad*DataList[uds.RecNo].weight/1000);
  if CompareText(VarName, 'badproc') = 0 then
    if (DataList[uds.RecNo].bad+DataList[uds.RecNo].good)>0 then
      Value:=FormatFloat('##0.00',(DataList[uds.RecNo].bad/(DataList[uds.RecNo].good+DataList[uds.RecNo].bad))*100)
    else Value:='0.00%';
  //������ ������� ������ - ����� ���������� � ������ �� ������
  if CompareText(VarName, 'itemcode') = 0 then Value :=DataList[uds.RecNo].item.code;
  if CompareText(VarName, 'itemname') = 0 then Value := DataList[uds.RecNo].item.name;
  if CompareText(VarName, 'TotalRes') = 0 then begin
      tot:=0;
      totbad:=0;
      for I :=0 to high(DataList) do  begin
        tot:=tot+DataList[i].good*DataList[i].weight/1000;
        totbad:=totbad+DataList[i].bad*DataList[i].weight/1000;
      end;
      Value:='����� ������������� '+FormatFloat('####0.00',tot+totbad)+' �� �����. �� ��� '+
        FormatFloat('####0.00',totbad)+' �� ���� ('+FormatFloat('####0.00',totbad/(totbad+tot)*100)+'% )';
    end;
  //���-�� ������������ ����� � ��-�� �����������
  if CompareText(VarName, 'reptime') = 0 then begin
      tot:=0;
      totbad:=0;
      for I :=0 to high(DataList) do  begin
        tot:=tot+DataList[i].good*DataList[i].weight/1000;
        totbad:=totbad+DataList[i].bad*DataList[i].weight/1000;
      end;
      Value:='���������� '+FormatFloat('####0.00',reptime)+' ��� ('
        +FormatFloat('####0.00',(tot+totbad)/reptime)+' ��/���}';
    end;
   //�������
  if CompareText(VarName, 'SignatureTime') = 0 then Value :=FormatDateTime('dd mmmm yyyy (dddd) hh:mm',now);
  if CompareText(VarName, 'SignatureName') = 0 then  Value :=user.name;
end;


end.
