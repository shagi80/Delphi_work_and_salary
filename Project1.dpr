program Project1;

uses
  Windows,
  Forms,
  Keyboard in 'Keyboard.pas' {KeyboardForm},
  ListView in 'ListView.pas' {ListViewForm},
  CalendarUnit in 'CalendarUnit.pas' {CalendarForm},
  MainFormUnit in 'MainFormUnit.pas' {MainForm},
  DocListUnit in 'DocListUnit.pas',
  WorkTable in '2_modWorkTable\WorkTable.pas' {WorkTableForm},
  AutorEmpData in '5_modDocNar\AutorEmpData.pas' {AutorEmpDataForm},
  DocStatUnit in 'DocStatUnit.pas' {DocStatForm},
  SettingUnit in 'SettingUnit.pas' {SettingForm},
  WorkLst in '4_modWorkLst\WorkLst.pas' {WorkListForm},
  WorkEmpData in '2_modWorkTable\WorkEmpData.pas' {WorkEmpDataForm},
  DateUnit in '3_modTools\DateUnit.pas' {DateForm},
  WorkDocMainUnit in '5_modDocNar\WorkDocMainUnit.pas' {WorkDocMainForm},
  ReportSetUnit in '6_Report\ReportSetUnit.pas' {ReportSetForm},
  ReportUnit in '6_Report\ReportUnit.pas' {ReportForm},
  WorkDtForm in '4_modWorkLst\WorkDtForm.pas' {WorkForm},
  MasterUnit in '5_modDocNar\MasterUnit.pas' {NarMasterForm},
  ShadowForm in '3_modTools\ShadowForm.pas' {Shadow},
  EmpWorkData in '2_modWorkTable\EmpWorkData.pas' {EmpWorkDataForm},
  PrintUnit in 'PrintUnit.pas' {PrintMod: TDataModule},
  WorkData in '4_modWorkLst\WorkData.pas',
  NumKeyboard in '3_modTools\NumKeyboard.pas' {NumKeyboardForm},
  MsgForm in '3_modTools\MsgForm.pas' {MessageForm},
  MailUnit in 'MailUnit.pas',
  MsgForUsersUnit in 'MsgForUsersUnit.pas' {MsgForUsersForm},
  EmployData in 'EmployData.pas',
  EmpData in 'EmpData.pas' {EmpDataForm};

{$R *.res}

var
  Mutex : THandle;
begin
  Mutex := CreateMutex(nil, False, 'MyMutexTPA');
  if Mutex = 0 then
    MessageBox(0,'Невозможно создать мьютекс', 'Ошибка',
      MB_OK or MB_ICONSTOP)
  else if GetLastError = ERROR_ALREADY_EXISTS then
    MessageBox(0,'Программа уже запущена', 'Ошибка',
      MB_OK or MB_ICONSTOP)
  else
  begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TKeyboardForm, KeyboardForm);
  Application.CreateForm(TListViewForm, ListViewForm);
  Application.CreateForm(TCalendarForm, CalendarForm);
  Application.CreateForm(TAutorEmpDataForm, AutorEmpDataForm);
  Application.CreateForm(TDocStatForm, DocStatForm);
  Application.CreateForm(TSettingForm, SettingForm);
  Application.CreateForm(TWorkEmpDataForm, WorkEmpDataForm);
  Application.CreateForm(TDateForm, DateForm);
  Application.CreateForm(TWorkDocMainForm, WorkDocMainForm);
  Application.CreateForm(TReportSetForm, ReportSetForm);
  Application.CreateForm(TWorkForm, WorkForm);
  Application.CreateForm(TNarMasterForm, NarMasterForm);
  Application.CreateForm(TEmpWorkDataForm, EmpWorkDataForm);
  Application.CreateForm(TPrintMod, PrintMod);
  Application.CreateForm(TNumKeyboardForm, NumKeyboardForm);
  Application.CreateForm(TEmpDataForm, EmpDataForm);
  Application.CreateForm(TEmpDataForm, EmpDataForm);
  Application.Run;
  CloseHandle(Mutex);
  end;
end.
