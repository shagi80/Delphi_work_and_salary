unit MasterUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  WorkTable, EmployData, Dialogs, Buttons, StdCtrls, ExtCtrls;

type
  TNarMasterForm = class(TForm)
    Panel1: TPanel;
    NameLB: TLabel;
    DateLB: TLabel;
    DateBtn: TSpeedButton;
    TimeBtn: TSpeedButton;
    EmployBtn: TSpeedButton;
    St1LB: TLabel;
    AutorBtn: TSpeedButton;
    AutorLB: TLabel;
    DocBtn: TSpeedButton;
    St3LB: TLabel;
    CloseBtn: TSpeedButton;
    procedure DocBtnClick(Sender: TObject);
    procedure AutorBtnClick(Sender: TObject);
    procedure EmployBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure DateBtnClick(Sender: TObject);
    procedure TimeBtnClick(Sender: TObject);
    function  CreateDoc(sender:TComponent;var TableForm:TWorkTableForm; var Table:TWorkTable):boolean;
    procedure SetTimeBtn(night:boolean);
    procedure SetBtnImg(btn:TSpeedButton;green:boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NarMasterForm: TNarMasterForm;

implementation

{$R *.dfm}

uses ShadowForm,DateUtils,MsgForm,CalendarUnit,GlobalUnit,
     WorkDocMainUnit,AutorEmpData;

var
  WorkTab    : TWorkTable;
  Form       : TWorkTableForm;
  EmpSet,AutSet,ResSet:boolean;

procedure TNarMasterForm.SetBtnImg(btn:TSpeedButton;green:boolean);
var
  bmp : TBitMap;
begin
  //������������� ��� ������
  bmp:=TBitMap.Create;
  if green then bmp.LoadFromResourceName(hInstance,'GreenRingBtnImg')
    else bmp.LoadFromResourceName(hInstance,'RedRingBtnImg');
  btn.Glyph:=bmp;
  bmp.Free;
end;

procedure TNarMasterForm.AutorBtnClick(Sender: TObject);
begin
  if (not EmpSet) then ShowMSG(self,'������� ������� ������ � ������ �����������!',[msbOk])
  else if AutorEmpDataForm.ShowWindow(self,WorkTab,false) then
    begin
      AutSet:=true;
      self.SetBtnImg((sender as TSpeedButton),true);
    end;
end;

procedure TNarMasterForm.CloseBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

function  TNarMasterForm.CreateDoc(sender:TComponent;var TableForm:TWorkTableForm; var Table:TWorkTable):boolean;
begin
  Form:=TableForm;
  WorkTab:=Table;
  //���� ����� ��������� �� 12-�� ��� ������ �� �� ���������� ����
  //���� ����� 12-�� - ������ �� ����������� ����
  if HourOfTheDay(now)<12 then
    begin
      WorkTab.MyDate:=IncDay(now,-1);
      WorkTab.Night:=true
    end else
    begin
      WorkTab.MyDate:=TDate(now);
      Worktab.Night:=false;
    end;
  self.SetTimeBtn(WorkTab.night);
  DateLB.Caption:=FormatDateTime('dd mmm yyyy',WorkTab.MyDate)+chr(13)+
    FormatDateTime('dddd',WorkTab.MyDate);
  //�������� ������������� ����� ������ � ������ ��� �����
  AutorBtn.Enabled:=(Acsses=alBrigadier);
  AutorLB.Enabled:=(Acsses=alBrigadier);
  //�������� ����� ����� ������
  EmpSet:=false;
  AutSet:=false;
  ResSet:=false;
  //������������� ��� ������
  self.SetBtnImg(EmployBtn,false);
  self.SetBtnImg(AutorBtn,false);
  self.SetBtnImg(DocBtn,false);
  //����� ����
  ShadowShow(sender);
  result:=(self.ShowModal=mrOk);
  ShadowHide(sender);
end;

procedure TNarMasterForm.DateBtnClick(Sender: TObject);
var
  dt        : Tdate;
begin
  dt:=WorkTab.MyDate;
  if CalendarForm.GetDate(self,dt) then
    begin
      if dt>date then
        begin
          ShowMsg(self,'���� ����� �����������!',[msbOk]);
          Abort;
        end;
      if dt<=CloseDate then
        begin
          ShowMsg(self,'���� ������� � '+FormatDateTime('dd mmm yyyy',CloseDate)+chr(13)
            +'������ � ��������� ���� ����� ����������!',[msbOk]);
          Abort;
        end;
      if (WorkTab.AutorCalck)then
        if (dt<IncDay(DateOf(WorkTab.createtime),-1))then
            begin
              if(ShowMsg(self,'����� ����������� � ���������� ����� ��� � 1 ����. '+
                '���������� ������ ���������� ����� ������������ �� �����. ����������?',[msbOk,msbCancel])=msbOK)
                  then WorkTab.datewrong:=true else Abort;
            end else WorkTab.datewrong:=false;
      WorkTab.MyDate:=dt;
      DateLB.Caption:=FormatDateTime('dd mmm yyyy',WorkTab.MyDate)+chr(13)+
        FormatDateTime('dddd',WorkTab.MyDate);
    end;
end;

procedure TNarMasterForm.DocBtnClick(Sender: TObject);
begin
  if (not EmpSet) then ShowMSG(self,'������� ������� ������ � ������ �����������!',[msbOk])
    else
      if(AutorBtn.Enabled)and(not AutSet) then ShowMSG(self,'������� ������� ������ � ������ ������ ������!',[msbOk])
        else
          if WorkDocMainForm.ShowWindow(form,worktab,Acsses)then self.ModalResult:=mrOK;
end;

procedure TNarMasterForm.EmployBtnClick(Sender: TObject);
begin
  Form.ShowModal;
  EmpSet:=true;
  self.SetBtnImg((sender as TSpeedButton),true);
end;

procedure TNarMasterForm.FormShow(Sender: TObject);
begin
  CloseBtn.Left:=round((self.ClientWidth-CloseBtn.Width)/2);
end;

procedure TNarMasterForm.SetTimeBtn(night:boolean);
var
  bmp : TBitMap;
begin
  bmp:=TbitMap.Create;
  if night then bmp.LoadFromResourceName(hInstance, 'NightBtnImg')
    else bmp.LoadFromResourceName(hInstance, 'SunBtnImg');
  TimeBtn.Glyph:=bmp;
  bmp.Free;
end;

procedure TNarMasterForm.TimeBtnClick(Sender: TObject);
begin
  WorkTab.night:=not WorkTab.night;
  WorkTab.ChangeAndRepaint;
  self.SetTimeBtn(WorkTab.night);
end;

end.
