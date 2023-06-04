unit GlobalUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ImgList, Grids, EmployData;


const
  //мой код по 1С
  MyCode  = '0000000001';
  MyFunct = '00001';
  MyComp  = 'SERGEYSHAGINYAN';
  //Скорость скроллинга при нажатии кн вверх и вниз
  ScrollSpeed = 30;
  //Уровни доступа
  alAdmin     =  0;
  alForeman   =  10;
  alBrigadier =  20;
  alWorker    =  30;
  alViewer    =  100;
  //дирректории и файлы
  DefWorkFileName        = 'work.lst';
  DefItemImgFolder       = 'Images\Items\';
  DefItemFileName        = 'Item.lst';
  DefWorkImgFolder       = 'Images\Works\';
  DefBaseFolder          = 'Base\';
  DefEmployFileName      = 'employ.lst';
  DefFunctImgFolder      = 'Images\Function\';
  DefEmplImgFolder       = 'EmplFoto\';
  DefUserMsgFolder       = 'UserMsg\';
  DefUserMailFileName    = 'usermail.lst';
  DefFunctionFileName    = 'function.lst';
  DefDocListFileName     = 'Base\doclst.lst';
  PasswordFile           = 'password.lst';
  AcsLevelFile           = 'acslevel.lst';
  PayDefFileName         = 'mainset.ini';
  DefDontShowEmpFileName = 'dontshowempl.lst'; //файл кодов сотрудников которых надо скрыть
  DefBaseCodeFileName    = 'code.txt'; //файл кодов 1С
  WeightFileName         = 'weightdata.txt'; //файл с весами
var
  ExePath   : string;
  Acsses    : word=alViewer;
  User      : TEmploy;
  //файлы
  EmpFileName      : string = DefEmployFileName;
  EmplImgFolder    : string = DefEmplImgFolder;
  FunctFileName    : string = DefFunctionFileName;
  FunctImgFolder   : string = DefFunctImgFolder;
  WorkFileName     : string = DefWorkFileName;
  WorkImgFolder    : string = DefWorkImgFolder;
  ItemFileName     : string = DefItemFileName;
  ItemImgFolder    : string = DefItemImgFolder;
  DocListFileName  : string = DefDocListFileName;
  UserMsgFolder    : string = DefUserMsgFolder;
  UserMailFileName : string = DefUserMsgFolder+DefUserMailFileName;
  DontShowEmpFileName : string = DefDontShowEmpFileName;
  BaseCodeFileName : string = DefBaseCodeFileName;
  //Настройки начислений
  DefRating : integer;  //оценка по умолчанию
  DefTime   : real;    //длительность смены по умалчанию
  RatingVal : array [1..6] of integer;
  AutorRatingVal : array [1..5] of integer;
  DefFunctionSum : real; //минимальная часовая ставка
  DefFunctCode   : string[10]; //код должности по умолчанию
  NightPay     : real;    //размер оплаты в ночь
  EmpTimePay   : boolean; //почасовая оплата рабочих
  AutorTimePay : boolean; //почасовая оплата автора
  TimePay      : boolean; //разрешить изменение установок почасовых ставок
  AskCycleTime : boolean; //запрашивать время цикла при вводе данных
  //Настройки закрытия базы
  CloseDoc1  : boolean;
  CloseDoc2  : boolean;
  CloseDate1 : integer;
  CloseDate2 : integer;
  CloseDate  : TDate;
  RatingStr  : array [1..6] of string = ('оч плохо','плохо','норма','хорошо','оч хорошо','нет оценки');
  //Настройки отчетов и почты
  ShowRep    : boolean = true; //показывать отчет перед печатью
  SendRep    : boolean = true; //автоматически отпралять почту при сохранении
  MailLst    : TStringList;    //список адресов рассылки
  LogMailLst : TStringList;    //список адресов рассылки сокращенного логистического отчета
  UserMailLst: TStringList;    //список адресов пользователей (для дублирования сообщений)
  AutorMaxPay: real;           //ограничение заработка нач смены
  EmplMaxPay : real;           //ограничение заработка рабочего
  AutorCanWork: boolean;       //разрешение автору работать
  DefEmpCnt  : word = 6;       //кол-во столбцов в наряде
  DefWrkCnt  : word= 6;        //кол-во строк в наряде
  ActiveForm : HWND;


function GetShortName(fullname:string):string;
//Procedure SortToTableASC(StrGrid:TStringGrid;SortColumn:integer);
procedure InitList;
// получение пароля по имени пользователя
//возвращает false если пароль не найден
function GetPassword(empl:TEmploy;var password:string):boolean;
function GetAcsLevel(empl:TEmploy;var acslev:word):boolean;

implementation

uses WorkData, DateUtils, IniFiles;


function GetPassword(empl:TEmploy;var password:string):boolean;
var
  strs : TStringList;
  i    : integer;
begin
  result:=false;
  if FileExists(ExePath+PasswordFile) then
    begin
      strs := TStringList.Create;
      strs.LoadFromFile(ExePath+PasswordFile);
      i:=0;
      while(i<strs.Count)and(empl.code<>strs.Names[i])do inc(i);
      if(i<strs.Count)and(empl.code=strs.Names[i])then
        begin
          password:=strs.Values[strs.Names[i]];
          result:=(length(password)>0);
        end;
      strs.Free;
    end;
end;

function GetAcsLevel(empl:TEmploy;var acslev:word):boolean;
var
  strs : TStringList;
  i    : integer;
begin
  result:=false;
  if FileExists(ExePath+AcsLevelFile) then
    begin
      strs := TStringList.Create;
      strs.LoadFromFile(ExePath+AcsLevelFile);
      i:=0;
      while(i<strs.Count)and(empl.code<>strs.Names[i])do inc(i);
      if(i<strs.Count)and(empl.code=strs.Names[i])then
        if Length(strs.Values[strs.Names[i]])>0 then AcsLev:=StrToInt(strs.Values[strs.Names[i]]) else result:=true;
      strs.Free;
      result:=true;
    end;
end;

procedure InitList;
var
  PayDefFile : TIniFile;
  str        : string;
  dt         : TDate;
  i,cnt      : integer;
begin
  //Загрузка списков сотрудников, функций, деталей, ставок
  FunctionList:=TFunctionList.Create;
  FunctionList.LoadFromFile(ExePath+FunctFileName);
  EmployList:=TEmployList.Create;
  EmployList.LoadFromFile(ExePath+EmpFileName);
  //создание и загрузка файла списка кодов сотрудников который надо скрыть
  DontShowEmpl:=TstringList.Create;
  if FileExists(ExePath+DontShowEmpFileName) then
    DontShowEmpl.LoadFromFile(ExePath+DontShowEmpFileName);
  ItemList:=TItemList.Create;
  ItemList.LoadFromFile(ExePath+ItemFileName);
  WorkList:=TWorkList.Create;
  WorkList.LoadFromFile(ExePath+WorkFileName);
  User.code:='';
  User.name:='';
  //создание списка кодов 1с
  BaseCodeList:=TBaseCodeList.Create;
  BaseCodeList.LoadFromFile(ExePath+BaseCodeFileName);
  //расчеты
  PayDefFile:=TIniFile.Create(ExePath+PayDefFileName);
  DefRating:=PayDefFile.ReadInteger('PAYDEF','DEFRATING',3);
  DefTime:=PayDefFile.ReadFloat('PAYDEF','DEFTIME',12);
  DefFunctionSum:=PayDefFile.ReadFloat ('PAYDEF','MINPAY',102);
  DefFunctCode:=PayDefFile.ReadString ('PAYDEF','DEFFUNCT','');
  NightPay:=PayDefFile.ReadFloat('PAYDEF','NIGHTPAY',1.2);
  str:=PayDefFile.ReadString('PAYDEF','RATINGVAL','00,10,20,30,40');
  RatingVal[1]:=StrToInt(copy(str,1,2));
  RatingVal[2]:=StrToInt(copy(str,4,2));
  RatingVal[3]:=StrToInt(copy(str,7,2));
  RatingVal[4]:=StrToInt(copy(str,10,2));
  RatingVal[5]:=StrToInt(copy(str,13,2));
  RatingVal[6]:=0;
  str:=PayDefFile.ReadString('PAYDEF','AUTORRATINGVAL','10,20,30,40,50');
  AutorRatingVal[1]:=StrToInt(copy(str,1,2));
  AutorRatingVal[2]:=StrToInt(copy(str,4,2));
  AutorRatingVal[3]:=StrToInt(copy(str,7,2));
  AutorRatingVal[4]:=StrToInt(copy(str,10,2));
  AutorRatingVal[5]:=StrToInt(copy(str,13,2));
  TimePay:=PayDefFile.ReadBool('PAYDEF','TIMEPAY',false);
  EmpTimePay:=PayDefFile.ReadBool('PAYDEF','EMPTIMEPAY',false);
  AutorTimePay:=PayDefFile.ReadBool('PAYDEF','AUTORTIMEPAY',false);
  AutorMaxPay:=PayDefFile.ReadFloat ('PAYDEF','AUTORMAXPAY',0);
  EmplMaxPay:=PayDefFile.ReadFloat ('PAYDEF','EMPLMAXPAY',0);
  DefEmpCnt:=PayDefFile.ReadInteger ('PAYDEF','EMPCNT',6);
  DefWrkCnt:=PayDefFile.ReadInteger ('PAYDEF','WRKCNT',6);
  AutorCanWork:=PayDefFile.ReadBool('PAYDEF','AUTORCANWORK',false);
  //настройки закрытия базы
  CloseDoc1:=PayDefFile.ReadBool('CLOSEDOC','CLOSEDOC1',true);
  CloseDoc2:=PayDefFile.ReadBool('CLOSEDOC','CLOSEDOC2',true);
  CloseDate1:=PayDefFile.ReadInteger('CLOSEDOC','CLOSEDATE1',8);
  CloseDate2:=PayDefFile.ReadInteger('CLOSEDOC','CLOSEDATE2',22);
  CloseDate:=PayDefFile.ReadDate('CLOSEDOC','CLOSEDATE',IncDay(Date,-32));
  AskCycleTime:=PayDefFile.ReadBool('CLOSEDOC','ASCKCYCLETIME',true);
  //Настройки отчетов и почты
  ShowRep:=PayDefFile.ReadBool('REPORT','SHOWREP',true);
  SendRep:=PayDefFile.ReadBool('REPORT','SENDREP',false);
  cnt:=PayDefFile.ReadInteger('REPORT','MAILCNT',0);
  MailLst:=TstringList.Create;
  for I := 0 to cnt - 1 do
    MailLst.Add(PayDefFile.ReadString('REPORT','MAIL'+IntToStr(i+1),''));
  cnt:=PayDefFile.ReadInteger('REPORT','LOGMAILCNT',0);
  LogMailLst:=TstringList.Create;
  for I := 0 to cnt - 1 do
    LogMailLst.Add(PayDefFile.ReadString('REPORT','LOGMAIL'+IntToStr(i+1),''));
  //Загрузка списка адресов почты пользователей
  UserMailLst:=TstringList.Create;
  if FileExists(Exepath+UserMailFileName) then UserMailLst.LoadFromFile(ExePath+UserMailFileName);
  //Автоматическое закрытие базы
  //сначала предыдущий месяц
  if CloseDoc2 then
    begin
      dt:=IncDay(TDate(StartOfTheMonth(now)),CloseDate2-1);
      if (now>=dt)and(CloseDate<dt) then CloseDate:=TDate(EndOfTheMonth((StartOfTheMonth(now)-1)));
    end;
  //первый период текущего месяца
  if CloseDoc1 then
    begin
      dt:=IncDay(TDate(StartOfTheMonth(now)),CloseDate1-1);
      if (now>=dt)and(CloseDate<dt) then CloseDate:=TDate(IncDay(TDate(StartOfTheMonth(now)),15));
    end;
  PayDefFile.WriteDate('CLOSEDOC','CLOSEDATE',CloseDate);
  PayDefFile.Free;
end;

function GetShortName(fullname:string):string;
begin
  if pos(' ',fullname)>0 then
    begin
      result:=copy(fullname,1,pos(' ',fullname)-1);
      fullname:=copy(fullname,pos(' ',fullname)+1,maxint);
      result:=result+' '+AnsiUpperCase(copy(fullname,1,1));
      if pos(' ',fullname)>0 then
          result:=result+AnsiUpperCase(copy(fullname,pos(' ',fullname)+1,1));
    end else result:=fullname;
end;


end.
