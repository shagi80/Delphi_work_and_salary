unit SettingUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, ValEdit, ComCtrls, Mask;

type
  TSettingForm = class(TForm)
    PC: TPageControl;
    TabSheet1: TTabSheet;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    TabSheet2: TTabSheet;
    DtLstGB: TGroupBox;
    Label1: TLabel;
    DtLstFNameEd: TEdit;
    DtLstBtn: TBitBtn;
    UpdateDtLstBtn: TBitBtn;
    FunctLstGB: TGroupBox;
    Label2: TLabel;
    FunctLstFNameED: TEdit;
    FunctLstBtn: TBitBtn;
    UpdateFunctLstBtn: TBitBtn;
    OpenDlg: TOpenDialog;
    TabSheet3: TTabSheet;
    ALSG: TStringGrid;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    DefTimeED: TEdit;
    DefNightPayED: TEdit;
    DefResCB: TComboBox;
    Label6: TLabel;
    MinPayED: TEdit;
    RatingValED: TMaskEdit;
    Label7: TLabel;
    AutorRatingValED: TMaskEdit;
    Label8: TLabel;
    Label9: TLabel;
    TimePayCB: TCheckBox;
    TabSheet4: TTabSheet;
    Label10: TLabel;
    Label11: TLabel;
    CloseDoc1CB: TCheckBox;
    CloseDate1ED: TEdit;
    CloseDate1UD: TUpDown;
    Label12: TLabel;
    Label13: TLabel;
    CloseDoc2CB: TCheckBox;
    Label14: TLabel;
    CloseDate2ED: TEdit;
    CloseDate2UD: TUpDown;
    Label15: TLabel;
    Label17: TLabel;
    AutorTimePayCB: TCheckBox;
    EmpTimePayCB: TCheckBox;
    Label18: TLabel;
    TabSheet5: TTabSheet;
    ShowRepCB: TCheckBox;
    Label19: TLabel;
    Label20: TLabel;
    MailMemo: TMemo;
    SendRepCB: TCheckBox;
    DefFunctCodeED: TEdit;
    UserSG: TStringGrid;
    Label21: TLabel;
    Label22: TLabel;
    LogMailMemo: TMemo;
    ExpWorkBtn: TBitBtn;
    SaveDlg: TSaveDialog;
    AutorMaxPayED: TEdit;
    EmplMaxPayED: TEdit;
    Label23: TLabel;
    Label24: TLabel;
    Label16: TLabel;
    AskCyleTimeCB: TCheckBox;
    Label25: TLabel;
    AutorCanWorkCB: TCheckBox;
    procedure UserSGClick(Sender: TObject);
    procedure ALSGSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure UpdateDtLstBtnClick(Sender: TObject);
    procedure DtLstBtnClick(Sender: TObject);
    procedure ExpWorkBtnClick(Sender: TObject);
    function  ShowWindow(sender: TComponent):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SettingForm: TSettingForm;

implementation

{$R *.dfm}

uses IniFiles, MsgForm, ShadowForm, EmployData,GlobalUnit, WorkData;

const
  ALLabel=' выбрано';

procedure TSettingForm.ALSGSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  if ACol=0 then CanSelect:=false
  else begin
    ALSG.Cells[1,ARow]:='';
    ALSG.Cells[2,ARow]:='';
    ALSG.Cells[3,ARow]:='';
    ALSG.Cells[4,ARow]:='';
    ALSG.Cells[ACol,ARow]:=ALLabel;
  end;
end;

procedure TSettingForm.DtLstBtnClick(Sender: TObject);
begin
  if OpenDlg.Execute then
    begin
      if (sender as TControl).Name='DtLstBtn' then DtLstFNameED.Text:=OpenDlg.FileName;
      if (sender as TControl).Name='FunctLstBtn' then FunctLstFNameED.Text:=OpenDlg.FileName;
    end;
end;

procedure TSettingForm.ExpWorkBtnClick(Sender: TObject);
var
  Strs : TStringList;
  i : integer;
  str : string;
begin
  SaveDlg.DefaultExt:='*.txt';
  SaveDlg.Filter:='Текстовые файлы|*.txt';
  if SaveDlg.Execute then begin
    Strs:=TStringList.Create;
    for I := 0 to WorkList.Count - 1 do begin
      str:=WorkList.Item[i].code+chr(9)+WorkList.Item[i].name+chr(9)+WorkList.Item[i].folder+chr(9)+
        floattostr(WorkList.Item[i].PayRoll)+chr(9)+floattostr(WorkList.Item[i].Norm)+chr(9)+
        WorkList.Item[i].Item.code+chr(9)+WorkList.Item[i].Item.name+chr(9)+
        floattostr(WorkList.Item[i].Item.time);
      Strs.Add(str);
    end;
    Strs.Sort;
    Strs.SaveToFile(SaveDlg.FileName);
    MessageDlg('Выгрузка успешно произведена!',mtInformation,[mbOk],0);
  end;
end;

function TSettingForm.ShowWindow(sender:TComponent):boolean;
var
  strs  : TStringList;
  str   : string;
  i,ind : integer;
  PayDefFile : TIniFile;
begin
  result:=false;
  ShadowShow(sender);
  //Вкладака пользователи
  if EmployList.Count=0 then
    begin
      UserSG.RowCount:=2;
      UserSG.Rows[1].Clear;
    end else UserSG.RowCount:=EmployList.Count+1;
  UserSG.Enabled:=(EmployList.Count>0);
  UserSG.Cells[0,0]:=' Пользователь';
  UserSG.Cells[1,0]:=' Пароль';
  UserSG.Cells[2,0]:=' E-mail';
  UserSG.ColWidths[0]:=UserSG.ClientWidth-UserSG.ColWidths[1]-UserSG.ColWidths[2]-20;
  strs:=TstringList.Create;
  //Заполняем фамилии и пароли
  if FileExists(ExePath+PasswordFile) then strs.LoadFromFile(ExePath+PasswordFile);
  for I := 0 to EmployList.Count - 1 do
    begin
      UserSG.Cells[0,i+1]:=EmployList.ShortName(EmployList.Item[i].name);
      str:=strs.Values[EmployList.Item[i].code];
      UserSG.Cells[1,i+1]:=str;
    end;
  //Заполнияем адреса эл почты
  strs.Clear;
  if FileExists(ExePath+UserMailFileName) then strs.LoadFromFile(ExePath+UserMailFileName);
  for I := 0 to EmployList.Count - 1 do
      UserSG.Cells[2,i+1]:=strs.Values[EmployList.Item[i].code];
  //Вкладака уровни доступа
  ALSG.ColWidths[0]:=ALSG.ClientWidth-ALSG.ColWidths[1]-ALSG.ColWidths[2]-
    ALSG.ColWidths[3]-ALSG.ColWidths[4]-15;
  ALSG.Cells[0,0]:=' Сотрудник';
  ALSG.Cells[1,0]:=' Админ';
  ALSG.Cells[2,0]:=' Нач цеха';
  ALSG.Cells[3,0]:=' Нач смены';
  ALSG.Cells[4,0]:=' Рабочий';
  strs:=TstringList.Create;
  if FileExists(ExePath+AcsLevelFile) then strs.LoadFromFile(ExePath+AcsLevelFile);
  if EmployList.Count>0 then
    begin
      ALSG.RowCount:=EmployList.Count+1;
      for I := 0 to EmployList.Count - 1 do
        begin
          ALSG.Cells[0,i+1]:=EmployList.Item[i].name;
          str:=strs.Values[EmployList.Item[i].code];
          if Length(str)>0 then ind:=StrToInt(str) else ind:=alWorker;
          if ind=alAdmin then ALSG.Cells[1,i+1]:=ALLabel;
          if ind=alForeman then ALSG.Cells[2,i+1]:=ALLabel;
          if ind=alBrigadier then ALSG.Cells[3,i+1]:=ALLabel;
          if ind=alWorker then ALSG.Cells[4,i+1]:=ALLabel;
        end;
      ALSG.Enabled:=true;
    end else
    begin
      ALSG.RowCount:=2;
      ALSG.Rows[1].Clear;
      ALSG.Enabled:=false;
    end;
  //Вкладака списки
  DtLstFNameED.Text:=ExePath+'item.txt';
  FunctLstFNameED.Text:=ExePath+'function.txt';
  //Вкладка расчеты
  DefResCB.Items.Clear;
  for I := 1 to 5 do DefResCB.Items.Add(RatingStr[i]);
  DefResCB.ItemIndex:=DefRating-1;
  DefTimeED.Text:=FormatFloat('###0.00',DefTime);
  MinPayED.Text:=FormatFloat('###0.00',DefFunctionSum);
  DefFunctCodeED.Text:=DefFunctCode;
  DefNightPayED.Text:=FormatFloat('###0.00',NightPay);
  AutorRatingValED.Text:=FormatFloat('00',AutorRatingVal[1])+','+FormatFloat('00',AutorRatingVal[2])+','
    +FormatFloat('00',AutorRatingVal[3])+','+FormatFloat('00',AutorRatingVal[4])+','+FormatFloat('00',AutorRatingVal[5]);
  RatingValED.Text:=FormatFloat('00',RatingVal[1])+','+FormatFloat('00',RatingVal[2])+','
    +FormatFloat('00',RatingVal[3])+','+FormatFloat('00',RatingVal[4])+','+FormatFloat('00',RatingVal[5]);
  TimePayCB.Checked:=TimePay;
  EmpTimePayCB.Checked:=EmpTimePay;
  AutorTimePayCB.Checked:=AutorTimePay;
  AutorMaxPayED.Text:=FormatFloat('###0.00',AutorMaxPay);
  EmplMaxPayED.Text:=FormatFloat('###0.00',EmplMaxPay);
  AutorCanWorkCB.Checked:=AutorCanWork;
  //Вкладка закрытия базы
  CloseDoc1CB.Checked:=CloseDoc1;
  CloseDate1UD.Position:=CloseDate1;
  CloseDoc2CB.Checked:=CloseDoc2;
  CloseDate2UD.Position:=CloseDate2;
  AskCyleTimeCB.Checked:=AskCycleTime;
  //Вкладка отчетов
  ShowRepCB.Checked:=ShowRep;
  SendRepCB.Checked:=SendRep;
  MailMemo.Lines:=MailLst;
  LogMailMemo.Lines:=LogMailLst;

  if self.ShowModal=mrOK then
    begin
      //Запись паролей и адресов эл почты
      strs.Clear;
      UserMailLst.Clear;
      for I := 1 to UserSG.RowCount-1 do
        begin
          str:=EmployList.Item[i-1].code+'='+UserSG.Cells[1,i];
          strs.Add(str);
          str:=EmployList.Item[i-1].code+'='+UserSG.Cells[2,i];
          UserMailLst.Add(str);
        end;
      strs.SaveToFile(ExePath+PasswordFile);
      UserMailLst.SaveToFile(ExePath+UserMailFileName);
      //Запись уронвя доступа
      strs.Clear;
      for I := 1 to ALSG.RowCount-1 do
        begin
          ind:=EmployList.IndFromName(ALSG.Cells[0,i]);
          str:=IntToStr(alWorker);
          if ALSG.Cells[1,i]=ALLabel then str:=IntToStr(alAdmin);
          if ALSG.Cells[2,i]=ALLabel then str:=IntToStr(alForeman);
          if ALSG.Cells[3,i]=ALLabel then str:=IntToStr(alBrigadier);
          str:=EmployList.Item[ind].code+'='+str;
          strs.Add(str);
        end;
      strs.SaveToFile(ExePath+AcsLevelFile);
      //Вкладка расчеты
      DefRating:=DefResCB.ItemIndex+1;
      DefTime:=StrToFloat(DefTimeED.Text);
      DefFunctionSum:=StrToFloat(MinPayED.Text);
      DefFunctCode:=DefFunctCodeED.Text;
      NightPay:=StrToFloat(DefNightPayED.Text);
      str:=RatingValED.Text;
      RatingVal[1]:=StrToInt(copy(str,1,2));
      RatingVal[2]:=StrToInt(copy(str,4,2));
      RatingVal[3]:=StrToInt(copy(str,7,2));
      RatingVal[4]:=StrToInt(copy(str,10,2));
      RatingVal[5]:=StrToInt(copy(str,13,2));
      str:=AutorRatingValED.Text;
      AutorRatingVal[1]:=StrToInt(copy(str,1,2));
      AutorRatingVal[2]:=StrToInt(copy(str,4,2));
      AutorRatingVal[3]:=StrToInt(copy(str,7,2));
      AutorRatingVal[4]:=StrToInt(copy(str,10,2));
      AutorRatingVal[5]:=StrToInt(copy(str,13,2));
      TimePay:=TimePayCB.Checked;
      EmpTimePay:=EmpTimePayCB.Checked;
      AutorTimePay:=AutorTimePayCB.Checked;
      AutorMaxPay:=StrToFloatDef(AutorMaxPayED.Text,AutorMaxPay);
      EmplMaxPay:=StrToFloatDef(EmplMaxPayED.Text,EmplMaxPay);
      AutorCanWork:=AutorCanWorkCB.Checked;
      //Вкладка закрытия базы
      CloseDoc1:=CloseDoc1CB.Checked;
      CloseDate1:=CloseDate1UD.Position;
      CloseDoc2:=CloseDoc2CB.Checked;
      CloseDate2:=CloseDate2UD.Position;
      AskCycleTime:=AskCyleTimeCB.Checked;
      //Вкладка отчетов
      ShowRep:=ShowRepCB.Checked;
      SendRep:=SendRepCB.Checked;
      MailLst.Clear;
      for i := 0 to MailMemo.Lines.Count - 1 do
        if Length(MailMemo.Lines[i])>0 then mailLst.Add(MailMemo.Lines[i]);
      LogMailLst.Clear;
      for i := 0 to LogMailMemo.Lines.Count - 1 do
        if Length(LogMailMemo.Lines[i])>0 then logmailLst.Add(LogMailMemo.Lines[i]);
      //Запись в файл
      PayDefFile:=TIniFile.Create(ExePath+PayDefFileName);
      PayDefFile.WriteInteger('PAYDEF','DEFRATING',DefRating);
      PayDefFile.WriteFloat('PAYDEF','DEFTIME',DefTime);
      PayDefFile.WriteFloat('PAYDEF','MINPAY',DefFunctionSum);
      PayDefFile.WriteFloat('PAYDEF','NIGHTPAY',NightPay);
      PayDefFile.WriteString('PAYDEF','RATINGVAL',RatingValED.Text);
      PayDefFile.WriteString('PAYDEF','AUTORRATINGVAL',AutorRatingValED.Text);
      PayDefFile.WriteBool('PAYDEF','TIMEPAY',TimePay);
      PayDefFile.WriteBool('PAYDEF','EMPTIMEPAY',EmpTimePay);
      PayDefFile.WriteBool('PAYDEF','AUTORTIMEPAY',AutorTimePay);
      PayDefFile.WriteFloat('PAYDEF','AUTORMAXPAY',AutorMaxPay);
      PayDefFile.WriteFloat('PAYDEF','EMPLMAXPAY',EmplMaxPay);
      PayDefFile.WriteBool('PAYDEF','AUTORCANWORK',AutorCanWork);
      //настройки закрытия базы
      PayDefFile.WriteBool('CLOSEDOC','CLOSEDOC1',CloseDoc1);
      PayDefFile.WriteBool('CLOSEDOC','CLOSEDOC2',CloseDoc2);
      PayDefFile.WriteInteger('CLOSEDOC','CLOSEDATE1',CloseDate1);
      PayDefFile.WriteInteger('CLOSEDOC','CLOSEDATE2',CloseDate2);
      PayDefFile.WriteBool('CLOSEDOC','ASCKCYCLETIME',AskCycleTime);
      //настройки отчетов
      PayDefFile.WriteBool('REPORT','SHOWREP',ShowRep);
      PayDefFile.WriteBool('REPORT','SENDREP',SendRep);
      PayDefFile.WriteInteger('REPORT','MAILCNT',MailLst.Count);
      for I := 0 to MailLst.Count - 1 do
        PayDefFile.WriteString('REPORT','MAIL'+IntToStr(i+1),MailLst[i]);
      PayDefFile.WriteInteger('REPORT','LOGMAILCNT',LogMailLst.Count);
      for I := 0 to LogMailLst.Count - 1 do
        PayDefFile.WriteString('REPORT','LOGMAIL'+IntToStr(i+1),LogMailLst[i]);
      PayDefFile.Free;
      result:=true;
    end;
  strs.Free;
  ShadowHide(sender);
end;

procedure TSettingForm.UserSGClick(Sender: TObject);
begin
  if UserSG.Selection.Left>0 then UserSG.Options:=UserSG.Options+[goEditing]
   else UserSG.Options:=UserSG.Options-[goEditing];
end;

procedure TSettingForm.UpdateDtLstBtnClick(Sender: TObject);
var
  res : boolean;
  i : integer;
  str : string;
begin
  res:=false;
  if (sender as TControl).Name='UpdateDtLstBtn' then
    begin
      res:=ItemList.LoadFrom1C(DtLstFNameED.Text);
      if res then ItemList.SaveToFile(ExePath+ItemFilename);
    end;
  if (sender as TControl).Name='UpdateFunctLstBtn' then
    begin
      FunctionList.Destroy;
      FunctionList:=TFunctionList.Create;
      res:=FunctionList.LoadFrom1C(FunctLstFNameED.Text);
      if res then FunctionList.SaveToFile(ExePath+FunctFilename);
      for I := 0 to FunctionList.Count-1 do
        str:=str+FunctionList.Item[i].name+' =  '+floattostr(FunctionList.Item[i].sum)+chr(13);
     // showmessage(str);
    end;
  if res then ShowMsg(self,'Список обновлен!',[msbOK])
    else ShowMsg(self,'Обновление не удалось!',[msbOK]);
end;

end.
