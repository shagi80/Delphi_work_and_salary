unit ReportSetUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons,
  ExtDlgs, DateUtils;

const
  rtAllPay  = 0;
  rtAllItem = 1;
  rtBadItem = 2;

type
  TReportSetForm = class(TForm)
    CloseBtn: TSpeedButton;
    LB: TListBox;
    BtnPN: TPanel;
    DownBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    Bevel3: TBevel;
    AddAllBtn: TSpeedButton;
    DelBtn: TSpeedButton;
    Addbtn: TSpeedButton;
    FilterPn: TPanel;
    LstDateBtn: TSpeedButton;
    LstDateLB: TLabel;
    NameLB: TLabel;
    PrintBtn: TSpeedButton;
    procedure FormActivate(Sender: TObject);
    procedure PrintBtnClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure DownBtnClick(Sender: TObject);
    procedure AddbtnClick(Sender: TObject);
    procedure AddAllBtnClick(Sender: TObject);
    procedure LstDateBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    function  ShowWindow(sender:TComponent; reporttype:byte; dt1,dt2:TDate):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ReportSetForm: TReportSetForm;

implementation

{$R *.dfm}

uses ReportUnit, WorkData, ShadowForm, MsgForm, DateUnit, EmployData, EmployLst,
     ListView, GlobalUnit;

type
  TLstData = class(TObject)
    code : string;
    constructor Create;
  end;

var
  Date1,Date2 : TDate;
  rtype       : byte;

constructor TLstData.Create;
begin
  inherited;
  self.code:='';
end;

function  TReportSetForm.ShowWindow(sender:TComponent; reporttype:byte; dt1,dt2:TDate):boolean;
begin
  LB.Clear;
  rtype:=reporttype;
  Date1:=Dt1;
  Date2:=Dt2;
  Date1:=IncDay(Date2,-5);
  LstDateLB.Caption:='c '+FormatDateTime('dd mmm yyyy (ddd)',Date1)+chr(13)+
    'по '+FormatDateTime('dd mmm yyyy (ddd)',Date2);
  case rtype of
    rtAllPay : NameLB.Caption:='Отчет'+chr(13)+'по начислениям';
    rtAllItem : NameLB.Caption:='Отчет'+chr(13)+'по производству';
    rtBadItem : NameLB.Caption:='Отчет'+chr(13)+'по качеству работы'+chr(13)+'персонала';
  end;
  ShadowShow(sender);
  self.ShowModal;
  ShadowHide(sender);
  result:=true;
end;

procedure TReportSetForm.CloseBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

procedure TReportSetForm.DownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')and(LB.ItemIndex<LB.Count-1) then LB.ItemIndex:=LB.ItemIndex+1;
  if ((Sender as TSpeedButton).name='UpBtn')and(LB.ItemIndex>0) then LB.ItemIndex:=LB.ItemIndex-1;
end;

procedure TReportSetForm.DelBtnClick(Sender: TObject);
var
  ind:integer;
begin
  ind:=LB.ItemIndex;
  if (LB.ItemIndex<>-1) then LB.DeleteSelected;
  if ind<LB.Count then LB.ItemIndex:=ind else LB.ItemIndex:=LB.Count-1;
end;

procedure TReportSetForm.AddAllBtnClick(Sender: TObject);
var
  i,j  : integer;
  code : TLstData;
begin
  if (rtype=rtAllPay)or(rtype=rtBadItem) then
    begin
      LB.Items.Clear;
      for I := 0 to EmployList.Count - 1 do
        begin
          code:=TLstData.Create;
          code.code:=EmployList.Item[i].code;
          //проверяем список скрываемых сотрудников
          j:=0;
          while(j<DontShowEmpl.Count)and(DontShowEmpl[j]<>code.code)do inc(j);
          if(j=DontShowEmpl.Count)then LB.Items.AddObject(EmployList.Item[i].name,code);
        end;
      LB.Enabled:=(LB.Count>0);
      if LB.Enabled then LB.ItemIndex:=0;
    end;
  if rtype=rtAllItem then
    begin
      LB.Items.Clear;
      for I := 0 to ItemList.Count - 1 do
      if (Length(ItemList.Item[i].code)>0)and((ItemList.Item[i].code)<>'0') then
        begin
          code:=TLstData.Create;
          code.code:=ItemList.Item[i].code;
          LB.Items.AddObject(ItemList.Item[i].name,code);
        end;
      LB.Enabled:=(LB.Count>0);
      if LB.Enabled then LB.ItemIndex:=0;
    end;
end;

procedure TReportSetForm.FormActivate(Sender: TObject);
begin
  if LB.Count>0 then LB.ItemIndex:=0;
end;

procedure TReportSetForm.FormShow(Sender: TObject);
begin
  BtnPn.Left:=round((self.ClientWidth-BtnPn.Width)/2);
end;

procedure TReportSetForm.LstDateBtnClick(Sender: TObject);
begin
  DateForm.ShowWindow(self,Date1,Date2);
  LstDateLB.Caption:='c '+FormatDateTime('dd mmm yyyy (ddd)',Date1)+chr(13)+
    'по '+FormatDateTime('dd mmm yyyy (ddd)',Date2);
end;

procedure TReportSetForm.PrintBtnClick(Sender: TObject);
var
  i    : integer;
  Lst  : TStringList;
begin
  Lst:=TstringList.Create;
  for I := 0 to LB.Count - 1 do Lst.Add(TLstData(LB.Items.Objects[i]).code);
  if rtype=rtAllPay then
    begin
      if Lst.Count>1 then LstPayReport(Date1,Date2,Lst);
      if Lst.Count=1 then EmpPayReport(Date1,Date2,Lst[0]);
    end;
  if rtype=rtAllItem then
    begin
      if Lst.Count>1 then LstItemReport(Date1,Date2,Lst);
      if Lst.Count=1 then OneItemReport(Date1,Date2,Lst[0]);
    end;
  if rtype=rtBadItem then
    begin
      if Lst.Count>1 then LstEmpBadItemReport(Date1,Date2,Lst);
      if Lst.Count=1 then EmpBadItemReport(Date1,Date2,Lst[0]);
    end;
end;

procedure TReportSetForm.AddbtnClick(Sender: TObject);
var
  bmp     : TBitMap;
  ind,i   : integer;
  code    : TLstData;
  pind    : ^integer;
  LVItem  : TListItem;
  ImgFile : string;
begin
  if rtype=rtAllItem then
    begin
      ListViewForm.CaptionLB.Caption:='Подбор детали для'+chr(13)+'отчета по производству';
      ListViewForm.Cap2LB.Caption:='';
      //Заполнение списка из струтуры FunctionList
      ListViewForm.LV.Clear;
      ListViewForm.ImgLst.Clear;
      Bmp:=TbitMap.Create;
      for I := 0 to ItemList.Count - 1 do
        begin
          LVItem:=ListViewForm.LV.Items.Add;
          LVItem.Caption:=ItemList.Item[i].name;
          new(pind);
          pind^:=i;
          LVItem.Data:=pind;
          ImgFile:=ExePath+ItemList.ImgFolder+ItemList.Item[i].ImgFile;
          if FileExists(ImgFile) then Bmp.LoadFromFile(ImgFile)
        else Bmp.LoadFromResourceName(hInstance, 'DefItemImg');
        ind:=ListViewForm.ImgLst.Add(Bmp,nil);
        LVItem.ImageIndex:=ind;
      end;
      ind:=ListViewForm.ShowView(self);
      if ind>=0 then
        begin
          i:=0;
          while(i<LB.Count)and(TLstData(LB.Items.Objects[i]).code<>ItemList.Item[ind].code)do inc(i);
          if(i=LB.Count)then
            begin
              code:=TLstData.Create;
              code.code:=ItemList.Item[ind].code;
              LB.Items.AddObject(ItemList.Item[ind].name,code);
              LB.ItemIndex:=LB.Count-1;
            end else ShowMsg(self,ItemList.Item[ind].name+chr(13)+' уже есть в списке!',[msbOK]);
        end;
      bmp.Free;
    end;
  if (rtype=rtAllPay)or(rtype=rtBadItem) then
    begin
      bmp:=TBitMap.Create;
      if GetEmployListItem('Подбор сотрудника в отчет',ind,bmp,false)then
        begin
          i:=0;
          while(i<LB.Count)and(TLstData(LB.Items.Objects[i]).code<>EmployList.Item[ind].code)do inc(i);
          if(i=LB.Count)then
            begin
              code:=TLstData.Create;
              code.code:=EmployList.Item[ind].code;
              LB.Items.AddObject(EmployList.Item[ind].name,code);
              LB.ItemIndex:=LB.Count-1;
            end else ShowMsg(self,EmployList.Item[ind].name+chr(13)+' уже есть в списке!',[msbOK]);
        end;
    end;
end;

end.
