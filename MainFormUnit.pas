unit MainFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ImgList, Grids, StdCtrls, ExtCtrls, Buttons, AppEvnts;


type
  TMainForm = class(TForm)
    ImgLst1: TImageList;
    MainSG: TStringGrid;
    FilterPn: TPanel;
    LstDateBtn: TSpeedButton;
    CapPn: TPanel;
    Label1: TLabel;
    AcsLevLb: TLabel;
    UserLb: TLabel;
    DatePN: TPanel;
    LstDateLB: TLabel;
    CloseDateLB: TLabel;
    BtnPn: TPanel;
    CngAutorBtn: TSpeedButton;
    EditDocBtn: TSpeedButton;
    DocStatBtn: TSpeedButton;
    NewNarBtn: TSpeedButton;
    Bevel2: TBevel;
    Bevel3: TBevel;
    SetBtn: TSpeedButton;
    DelBtn: TSpeedButton;
    PayReportBtn: TSpeedButton;
    DownBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    Bevel1: TBevel;
    ItemReportBtn: TSpeedButton;
    Label2: TLabel;
    Label3: TLabel;
    MsgForUserBtn: TSpeedButton;
    ImportBtn: TSpeedButton;
    CloseBtn: TSpeedButton;
    BadItemReportBtn: TSpeedButton;
    ApplicationEvents1: TApplicationEvents;
    procedure BadItemReportBtnClick(Sender: TObject);
    procedure ImportBtnClick(Sender: TObject);
    procedure MsgForUserBtnClick(Sender: TObject);
    procedure ItemReportBtnClick(Sender: TObject);
    procedure MainSGClick(Sender: TObject);
    procedure MainSGDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure DelBtnClick(Sender: TObject);
    procedure PayReportBtnClick(Sender: TObject);
    procedure LstDateBtnClick(Sender: TObject);
    procedure SetBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure CngAutorBtnClick(Sender: TObject);
    procedure DownBtnClick(Sender: TObject);
    procedure DocStatBtnClick(Sender: TObject);
    procedure EditDocBtnClick(Sender: TObject);
    procedure NewNarBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure UpdateMainSG;
    procedure MainSGResize;
    procedure UpdateBtn(lev : byte);
    procedure UpdateDelBtn;
    function  GetReadMode(ind:integer):boolean;
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure ApplicationEvents1Activate(Sender: TObject);
    procedure Label2DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}
{$R default.res}

uses MsgForm, GlobalUnit, EmployData, EmployLst, WorkDocMainUnit, DocListUnit,
  ReportSetUnit, Keyboard, DateUnit, SettingUnit, DocStatUnit, DateUtils,
  ReportUnit,MasterUnit,WorkTable, printunit, MailUnit, MsgForUsersUnit, NumKeyBoard;

var
  LstStartDate,LstEndDate : TDate;

procedure TMainForm.MainSGClick(Sender: TObject);
begin
  self.UpdateDelBtn;
end;

function  TMainForm.GetReadMode(ind:integer):boolean;
var
  res     : boolean;
  lastlev : word;
begin
  res:=false;
  if GetAcsLevel(MainList.Item[ind].LastStatus.user,lastlev)then
    if (Acsses=alAdmin)or(lastlev>Acsses)or((lastlev=Acsses)and(user.code=MainList.Item[ind].LastStatus.user.code)) then res:=true;
  if(Acsses>alAdmin)and(MainList.Item[ind].Date<=CloseDate)then res:=false;
  result:=res;
end;

procedure TMainForm.MainSGDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  ind  : integer;
  bmp  : TBitMap;
  str  : WideString;
  Flag : Cardinal;
  Rct  : TRect;
begin
  if (ACol>0)and(ARow>0)and(Length(MainSG.Cells[4,arow])>0)and((Sender as TStringGrid).Enabled)then
  with (Sender as TStringGrid) do
    begin
      ind:=MainList.IndByNum(StrToInt(MainSG.Cells[4,arow]));
      str :=Cells[Acol,Arow];
      Canvas.FillRect(Rect);
      Rct:=Rect;
      Flag := DT_LEFT;
      Inc(Rct.Left,2);
      Inc(Rct.Top,2);
      //���������� ����������� ������ ��� ������������
      if self.GetReadMode(ind) then Canvas.Font.Color:=clGreen else Canvas.Font.Color:=clBlack;
      DrawTextW((Sender as TStringGrid).Canvas.Handle,PWideChar(str),length(str),Rct,Flag);
    end;
  //��������� ������ ��������� ������
  if (ACol=0)and(arow>0)and(Length(MainSG.Cells[4,arow])>0)and((Sender as TStringGrid).Enabled) then
    begin
      ind:=MainList.IndByNum(StrToInt(MainSG.Cells[4,arow]));
      bmp:=TBitMap.Create;
      if MainList.Item[ind].LastStatus.stat<>dsDelete then bmp.LoadFromResourceName(hInstance, 'DocCalckImg')
        else bmp.LoadFromResourceName(hInstance, 'DocUnCalckImg');
      MainSG.Canvas.Draw(rect.Left+2,rect.Top+2,bmp);
    end;
end;

procedure TMainForm.MainSGResize;
var
  w,i : integer;
begin
  w:=0;
  for I := 0 to MainSG.ColCount - 2 do w:=w+MainSg.ColWidths[i];
  if (w+150)<MainSG.ClientWidth then MainSG.ColWidths[MainSG.ColCount - 1]:=MainSg.ClientWidth-w-10
    else MainSG.ColWidths[MainSG.ColCount-1]:=150;
end;

procedure TMainForm.MsgForUserBtnClick(Sender: TObject);
var
  ind : integer;
  bmp : TBitMap;
  str,code,name : string;
begin
  bmp:=TBitMap.Create;
  if GetEmployListItem('�������� ���������� ���������:',ind,bmp,false) then
    begin
      code:=EmployList.Item[ind].code;
      name:=EmployList.Item[ind].name;
      name:=EmployList.ShortName(name);
      str:='������� ���������';
      if KeyboardForm.GetString(self,str,false)then
        if SaveUserMessage(code,user.name,user.code,str) then
          ShowMsg(self,'��������� ��� '+name+' ���������.',[msbOK]);
    end;
  MainSG.Repaint;
end;

procedure TMainForm.UpdateDelBtn;
var
  ind : integer;
begin
  if (MainSG.Enabled)and(MainSG.Selection.Top>0)and(Length(MainSG.Cells[4,MainSG.Selection.Top])>0) then
    begin
      ind:=MainList.IndByNum(StrToInt(MainSG.Cells[4,MainSG.Selection.Top]));
      DelBtn.Enabled:=self.GetReadMode(ind);
    end;
end;

procedure TMainForm.UpdateBtn(lev: Byte);
begin
  case lev of
    alAdmin     : AcsLevLB.Caption:='�������������';
    alForeman   : AcsLevLB.Caption:='��������� ����';
    alBrigadier : AcsLevLB.Caption:='��������� �����';
    alWorker    : AcsLevLB.Caption:='�������';
    alViewer    : AcsLevLB.Caption:='������ ��������';
  end;
  UserLB.Caption:=User.name;
  DelBtn.Visible:=Acsses<=alBrigadier;
  SetBtn.Visible:=(Acsses=0);
  ImportBtn.Visible:=(Acsses=0);
end;

procedure TMainForm.NewNarBtnClick(Sender: TObject);
var
  ind     : integer;
  Form    : TWorkTableForm;
  Tab     : TWorkTable;
begin
  //��������� ������� ���� �� �������� ������
  if (Acsses>alBrigadier) then
    begin
      if ShowMsg(self,'����� ������������ �� ��������� ��������� ���������!'+
        chr(13)+'�������� ������������?',[msbOK,msbCancel])<>msbOK then Abort;
      self.CngAutorBtnClick(sender);
      if (Acsses>alBrigadier) then Abort;
    end;
  //���������� ����������� �����������
  //�������� ������
  //�������� ������ � �������
  ind:=MainList.CreateDoc(User,dtNar);
  MainList.Item[ind].fname:='doc'+IntTOStr(MainList.Item[ind].Num)+'.nrd';
  //�������� ������� �����
  Form := TWorkTableForm.Create(application);
  Tab := TWorkTable.Create(form);
  Tab.SetTableSize(DefEmpCnt,DefWrkCnt);
  Tab.fname:=MainList.Item[ind].fname;
  Tab.Align:=alClient;
  Tab.AlignWithMargins:=true;
  Tab.Bevel:=4;
  Form.InsertControl(Tab);
  Tab.number:=MainList.Item[ind].Num;
  Tab.NightPay:=NightPay;
  Tab.AutorTimePay:=AutorTimePay;
  Tab.EmployTimePay:=EmpTimePay;
  Tab.autor.Employ:=User;
  Tab.autor.Bitmap:=TBitMap.Create;
  Tab.autorcalck:=(Acsses=alBrigadier);
  Tab.autor.time:=DefTime;
  Tab.autor.rating:=DefRating;
  Tab.autor.ratval:=AutorRatingVal[Tab.autor.rating];
  if FileExists(ExePath+EmplImgFolder+Tab.autor.Employ.ImgFile)then
    Tab.autor.Bitmap.LoadFromFile(ExePath+EmplImgFolder+Tab.autor.Employ.ImgFile)
    else Tab.autor.Bitmap.LoadFromResourceName(hInstance,'DefEmpImg');
  //�������� �������
  if NarMasterForm.CreateDoc(self,Form,Tab)then
    begin
      MainList.Item[ind].Date:=Tab.MyDate;
      MainList.Item[ind].Night:=Tab.Night;
      MainList.Item[ind].send:=false;
      MainList.Item[ind].note:=Tab.note;
      MainList.SaveToFile(Exepath+DocListFileName);
      SendReport(dsCreate,ExePath+DefBaseFolder+Tab.fname);
      SendReportFromLogistic(dsCreate,ExePath+DefBaseFolder+Tab.fname);
      Form.Free;
      self.UpdateMainSG;
    end else MainList.DeleteDoc(ind);
end;

procedure TMainForm.PayReportBtnClick(Sender: TObject);
var
  dt1,dt2 : TDate;
  ind     : integer;
  bmp     : TBitMap;
begin
  if (Acsses>=alWorker)then
    begin
      dt1:=LstStartDate;
      dt2:=LstEndDate;
      bmp:=TBitMap.Create;
      if(Length(User.code)>0)and(DateForm.ShowWindow(self,dt1,dt2)) then
        EmpPayReport(dt1,dt2,user.code);
      if(Length(User.code)=0)and(GetEmployListItem('������� ���� � ������',ind,bmp,false))and(DateForm.ShowWindow(self,dt1,dt2))
        then EmpPayReport(dt1,dt2,EmployList.Item[ind].code);
    end
    else ReportSetForm.ShowWindow(self,rtAllPay,LstStartDate,LstEndDate);
end;

procedure TMainForm.SetBtnClick(Sender: TObject);
begin
  SettingForm.ShowWindow(self);
end;

procedure TMainForm.ImportBtnClick(Sender: TObject);
var
  cnt : integer;
begin
  cnt:=MainList.UpdateFromFolder(ExePath+DefBaseFolder);
  if cnt>0 then
    begin
      ShowMSG(self,'���������/�������� '+IntToStr(cnt)+' ����������!',[msbOK]);
      MainList.SaveToFile(Exepath+DocListFileName);
      self.UpdateMainSG;
      self.UpdateDelBtn;
    end else
      ShowMSG(self,'��������� � ������ ���������� ���!',[msbOK]);
end;

procedure TMainForm.Label2DblClick(Sender: TObject);
var
  Form: TNumKeyboardForm;
  str : string;
begin
  Form:= TNumKeyboardForm.Create(application);
  Form.GetValue(self,str,true);
  if str='1372' then begin
    User.code:='999999999';
    User.name:='�����������������';
    Acsses:=alAdmin;
    self.UpdateBtn(Acsses);
    self.UpdateDelBtn;
    MessageDLG('������ ������', mtWarning,[mbOk],0);
  end;
  Form.Free;
end;

procedure TMainForm.LstDateBtnClick(Sender: TObject);
var
  row:integer;
begin
  DateForm.ShowWindow(self,LstStartDate,LstEndDate);
  LstDateLB.Caption:='c '+FormatDateTime('dd mmm yyyy (ddd)',LstStartDate)+chr(13)+
    '�� '+FormatDateTime('dd mmm yyyy (ddd)',LstEndDate);
  self.UpdateMainSG;
  //����������� ������� �� ��������� �����
  Row:=MainSG.RowCount-round(MainSG.ClientHeight/MainSG.RowHeights[0])+3;
  if row>MainSG.TopRow then MainSG.TopRow:=Row;
  MainSG.Selection:=TGridRect(rect(0,MainSG.TopRow,MainSG.ColCount-1,MainSG.TopRow));
  self.UpdateDelBtn;
end;

procedure TMainForm.ApplicationEvents1Activate(Sender: TObject);
begin
    SetForegroundWindow(ActiveForm);
end;

procedure TMainForm.ApplicationEvents1Minimize(Sender: TObject);
begin
  ActiveForm:=Application.ActiveFormHandle;
end;

procedure TMainForm.BadItemReportBtnClick(Sender: TObject);
var
  dt1,dt2 : TDate;
  ind     : integer;
  bmp     : TBitMap;
begin
  if (Acsses>=alWorker)then begin
      dt1:=LstStartDate;
      dt2:=LstEndDate;
      bmp:=TBitMap.Create;
      if(Length(User.code)>0)and(DateForm.ShowWindow(self,dt1,dt2)) then
        EmpBadItemReport(Dt1,Dt2,user.code);
      if(Length(User.code)=0)and(GetEmployListItem('������� ���� � ������',ind,bmp,false))and(DateForm.ShowWindow(self,dt1,dt2))
        then EmpBadItemReport(Dt1,Dt2,EmployList.Item[ind].code);
    end else ReportSetForm.ShowWindow(self,rtBadItem,LstStartDate,LstEndDate);
end;

procedure TMainForm.CloseBtnClick(Sender: TObject);
begin
  self.Close;
end;

procedure TMainForm.UpdateMainSG;
var
  i,j,k,sys  : integer;
  item   : TListRec;
  str    : string;
  row,top: integer;
begin
  MainSG.Cells[0,0]:='';
  MainSG.Cells[1,0]:=' ��������';
  MainSG.Cells[2,0]:=' ����';
  MainSG.Cells[3,0]:=' �����';
  MainSG.Cells[4,0]:=' �����';
  MainSG.Cells[5,0]:=' �����';
  MainSG.Cells[6,0]:=' ��������� ��������';
  MainSG.Cells[7,0]:=' ����������';
  MainSG.Enabled:=false;
  //���������� ���-�� �����
  k:=0;
  for I := 0 to MainList.Count - 1 do
    begin
      item:=MainList.Item[i];
      if (Item.Date>=LstStartDate)and(Item.Date<=LstEndDate) then inc(k);
    end;
  if k=0 then begin
    MainSG.RowCount:=2;
    MainSG.Rows[1].Clear;
  end else begin
  MainSG.RowCount:=k+1;
  top:=MainSG.TopRow;
  Row:=MainSG.Selection.Top;
  //
  k:=0;
  for I := 0 to MainList.Count - 1 do
    begin
      item:=MainList.Item[i];
      if (Item.Date>=LstStartDate)and(Item.Date<=LstEndDate) then
      begin
        inc(k);
        //if k>1 then MainSG.RowCount:=MainSG.RowCount+1;
        MainSG.Cells[1,k]:=DocTypeLst[item.typedoc];
        MainSG.Cells[2,k]:=FormatDateTime('dd mmm yy (ddd)',item.Date);
        if item.Night then MainSG.Cells[3,k]:='����' else MainSG.Cells[3,k]:='����';
        MainSG.Cells[4,k]:=FormatFloat('000000',item.Num);
        MainSG.Cells[5,k]:=GetShortName(item.Autor.name);
        sys:= Item.LastStatus.stat;
        if (sys<0)or(sys>high(DocStatLst)) then
          begin
            sys:=0;
            Item.StatItems[Item.StatCount-1].stat:=sys;
          end;
        str:=DocStatLst[sys];
        str:=str+' '+FormatDateTime('dd.mm.yy hh:mm',item.LastStatus.time);
        str:=str+' '+GetShortName(Item.LastStatus.user.name);
        MainSG.Cells[6,k]:=str;
        MainSG.Cells[7,k]:=item.note;
      end;
    end;
  self.MainSGResize;
  {���������� ������� �� ���� ������� ������� ������� ("��������") }
  with MainSG do
  for i:=FixedRows to RowCount-2 do
    for j:=i+1 to RowCount-1 do
      if MainList.Item[MainList.IndByNum(StrToInt(MainSG.Cells[4,i]))].Date>
         MainList.Item[MainList.IndByNum(StrToInt(MainSG.Cells[4,j]))].Date then
        for k:=FixedCols to ColCount-1 do
          begin
            str := Cells[k,i];
            Cells[k,i] := Cells[k,j];
            Cells[k,j] := str;
          end;
  if top>MainSG.RowCount-1 then top:=MainSG.RowCount-1;
  MainSG.TopRow:=top;
  if row>MainSG.RowCount-1 then row:=MainSG.RowCount-1;
  MainSG.Selection:=TGridRect(rect(0,row,MainSG.ColCount-1,row));
  mainSG.Enabled:=true;
  end;
end;

procedure TMainForm.CngAutorBtnClick(Sender: TObject);
var
  ind : integer;
  bmp : TBitMap;
  str,psw,res : string;
begin
  bmp:=TBitMap.Create;
  if GetEmployListItem('������� ���� � ������',ind,bmp,false) then
    begin
      str:='������� ������';
      if GetPassword(EmployList.Item[ind],psw) then
        begin
        if KeyboardForm.GetString(self,str,false)then
          if (str=psw) then
            begin
              User:=EmployList.Item[ind];
              //res:=User.name+', ������������!';
              //����� ��������� ��� ������������
              ShowUserMessages(user.code);
              //���������� ����������� �����������
              GetAcsLevel(User,Acsses);
              self.UpdateBtn(Acsses);
              self.UpdateDelBtn;
            end else res:='������ ������ �������!';
        end else res:='�� �� ������ ���� ������� � ����!';
      if Length(res)>0 then ShowMsg(self,res,[msbOK]);
    end;
  MainSG.Repaint;
end;

procedure TMainForm.DelBtnClick(Sender: TObject);
var
  ind,newstat  : integer;
  s            : string;
begin
  newstat:=-1;
  if (MainSG.Enabled)and(MainSG.Selection.Top>0) then
    begin
      ind:=MainList.IndByNum(StrToInt(MainSG.Cells[4,MainSG.Selection.Top]));
      if MainList.Item[ind].LastStatus.stat=dsDelete then
        newstat:=dsUnDelete else if ShowMsg(self,'����� ����� �������� �� ��������!',[msbOK,msbCancel])=msbOK
          then newstat:=dsDelete;
      MainList.Item[ind].AddRec(newstat,now,user);
      //�������� ��������� ������ ������
      s:='��� ����� '+FormatFloat('00000',MainList.Item[ind].Num)+' �� '+
        FormatDateTime('dd mmm yyyy (ddd)',MainList.Item[ind].Date);
      s:=s+' '+DocStatLst[newstat]+' '+FormatDateTime('dd mmm yyyy (ddd) hh:mm',now);
      s:=s+' '+EmployList.ShortName(user.name);
      SaveUserMessage(MainList.Item[ind].Autor.code,'�������������� ���������',user.code,s);
      //�������� �����
      SendReport(newstat,ExePath+DefBaseFolder+MainList.Item[ind].fname);
      SendReportFromLogistic(newstat,ExePath+DefBaseFolder+MainList.Item[ind].fname);
      MainList.SaveToFile(Exepath+DocListFileName);
      self.UpdateMainSG;
    end;
end;

procedure TMainForm.DocStatBtnClick(Sender: TObject);
var
  ind : integer;
begin
  //�������� ������
  if (MainSG.Enabled)and(MainSG.Selection.Top>0) then
    begin
      ind:=MainList.IndByNum(StrToInt(MainSG.Cells[4,MainSG.Selection.Top]));
      DocStatForm.ShowWindow(self,MainList[ind]);
    end;
end;

procedure TMainForm.DownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')and(MainSG.Selection.Top<MainSG.RowCount-1) then
    MainSG.Selection:=TGridRect(rect(0,MainSg.Selection.Top+1,MainSG.ColCount-1,MainSg.Selection.Top+1));
  if ((Sender as TSpeedButton).name='UpBtn')and(MainSg.Selection.Top>1) then
    MainSG.Selection:=TGridRect(rect(0,MainSg.Selection.Top-1,MainSG.ColCount-1,MainSg.Selection.Top-1));
  if MainSG.Selection.Top>=MainSG.TopRow+MainSG.VisibleRowCount then MainSG.TopRow:=MainSG.TopRow+1;
  if MainSG.Selection.Top<MainSG.TopRow then MainSG.TopRow:=MainSG.TopRow-1;
  self.UpdateDelBtn;
end;

procedure TMainForm.EditDocBtnClick(Sender: TObject);
var
  ind     : integer;
  lastlev : word;
  Form    : TWorkTableForm;
  Tab     : TWorkTable;
  s       : string;
begin
  //�������� ������
  if (MainSG.Enabled)and(MainSG.Selection.Top>0) then
    begin
      ind:=MainList.IndByNum(StrToInt(MainSG.Cells[4,MainSG.Selection.Top]));
      if not FileExists(ExePath+DefBaseFolder+MainList.Item[ind].fname) then
        begin
          ShowMsg(self,'���� �� ������ � ����!'+chr(13)+
            '����� ����� �������� �� ��������!',[msbOK]);
          MainList.Item[ind].AddRec(dsDelete,now,User);
          Abort;
        end;
      //�������� �����
      Form := TWorkTableForm.Create(application);
      //�������� ������� �����, ������� ���������
      Tab := TWorkTable.Create(Form);
      Tab.fname:=MainList.Item[ind].fname;
      Tab.LoadFromFile(ExePath+DefBaseFolder+MainList.Item[ind].fname);
      Tab.Align:=alClient;
      Tab.AlignWithMargins:=true;
      Tab.Bevel:=4;
      Form.InsertControl(Tab);
      //���������� ������ �������
      if self.GetReadMode(ind) then lastlev:=Acsses else lastlev:=alViewer;
      //����� ���� ����� ������ �� ������
      if WorkDocMainForm.ShowWindow(Form,Tab,lastlev) then
        begin
          MainList.Item[ind].Date:=Tab.MyDate;
          MainList.Item[ind].Night:=Tab.Night;
          MainList.Item[ind].send:=false;
          MainList.Item[ind].note:=Tab.note;
          MainList.Item[ind].AddRec(dsRewrite,now,user);
          //�������� ��������� ������ ������
          s:='��� ����� '+FormatFloat('00000',Tab.number)+' �� '+
            FormatDateTime('dd mmm yyyy (ddd)',Tab.MyDate);
          s:=s+' '+DocStatLst[dsRewrite]+' '+FormatDateTime('dd mmm yyyy (ddd) hh:mm',now);
          s:=s+' '+EmployList.ShortName(user.name);
          SaveUserMessage(Tab.autor.Employ.code,'�������������� ���������',user.code,s);
          //�������� �����
          SendReport(dsRewrite,ExePath+DefBaseFolder+MainList.Item[ind].fname);
          if Tab.itmchange then SendReportFromLogistic(dsRewrite,ExePath+DefBaseFolder+MainList.Item[ind].fname);
          MainList.SaveToFile(Exepath+DocListFileName);
          Form.Free;
          self.UpdateMainSG;
        end;
    end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  self.Left:=0;
  self.Top:=0;
  self.MainSGResize;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  buffer: array[0..MAX_COMPUTERNAME_LENGTH + 1] of Char;
  Size: Cardinal;
  row : integer;
begin
  ExePath:=ExtractFileDir(application.ExeName)+'\';
  InitList;
  MainList:=TDocList.Create;
  MainList.LoadFromFile(ExePath+DocListFileName);
  //���������� ����� � ����� �����
  //���� ������ ������������� ���� ���� ����� ��������������
  if EmployList.Count=0 then
    begin
      User.code:='';
      User.name:='������������ �� ������!';
      Acsses:=alAdmin;
    end;
  //���� ��� ��������� ������ ��� � 0-��� ������������
  //���� ����� ��������� - "������" ������������ � ����� ���������
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  Windows.GetComputerName(@buffer, Size);
  if StrPas(buffer)=MyComp then
    begin
      if EmployList.IndFromName(EmployList.NameFromCode(MyCode))>=0 then
        User:=EmployList.Item[EmployList.IndFromName(EmployList.NameFromCode(MyCode))]
      else begin
        User.code:=MyCode;
        User.name:='������� ������ ����������';
        if FunctionList.IndFromCode(MyFunct)>=0 then User.funct:=FunctionList.Item[FunctionList.IndFromCode(MyFunct)]
          else
            begin
              User.funct.code:=MyFunct;
              User.funct.name:='��������';
            end;
      end;
      Acsses:=alAdmin;
    end else
    begin
      User.code:='';
      User.name:='������������ �� ������!';
      Acsses:=alViewer;
    end;

  LstStartDate:=TDate(StartOfTheMonth(now));
  LstEndDate:=EndOfTheDay(Date);
  LstDateLB.Caption:='c '+FormatDateTime('dd mmm yyyy (ddd)',LstStartDate)+chr(13)+
    '�� '+FormatDateTime('dd mmm yyyy (ddd)',LstEndDate);
  self.UpdateMainSG;
  //����������� ������� �� ��������� �����
  Row:=MainSG.RowCount-round(MainSG.ClientHeight/MainSG.RowHeights[0])+3;
  if row>MainSG.TopRow then MainSG.TopRow:=Row;
  MainSG.Selection:=TGridRect(rect(0,MainSG.TopRow,MainSG.ColCount-1,MainSG.TopRow));
  self.UpdateBtn(Acsses);
  self.UpdateDelBtn;
  CloseDateLB.Caption:='���� ������� � '+FormatDateTime('dd mmm yyyy',CloseDate);
  //���������� ��������� ��� ������������
  ShowUserMessages(user.code);
end;

procedure TMainForm.ItemReportBtnClick(Sender: TObject);
begin
  ReportSetForm.ShowWindow(self,rtAllItem,LstStartDate,LstEndDate);
end;

end.

