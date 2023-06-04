unit DocListUnit;

interface

uses
  GlobalUnit, Windows, Messages, SysUtils, Variants, Classes,Dialogs,
  EmployData, Controls;

const
  //тип документа в журнале
  dtNar=0;
  //статус документа в журнале
  dsCreate    =0; //создан
  dsRewrite   =1; //изменен
  dsDelete    =2; //помечен на удаление
  dsUnDelete  =3; //восстановлен
  dsImport    =4; //импортирован (изменен в папке путем записи/перезаписи файла)

type
  //структура для хранения информации о состоянии документа
  TStatRec = record
    stat : byte;
    time : TDateTime;
    user : TEmploy;
  end;

  //единичная запись журнала документов
  TListRec = class (TObject)
  private
    function GetLastRec : TStatRec;
  public
    typedoc : integer;     //тип документа
    Date    : TDate;       //дата
    Night   : boolean;     //признак ночных доплат
    Num     : integer;     //номер
    Autor   : TEmploy;     //автор
    send    : boolean;     //признак отправки отчета
    note    : shortstring; //примечание
    fname   : shortstring; //имя файла документа
    StatCount : integer;   //кол-во строк состояния
    StatItems : array of TStatRec;  //строки состояния
    //последняя строка состояния
    property  LastStatus:TStatRec read GetLastRec;
    constructor Create;
    procedure AddRec(st:byte;tm:TDateTime;us:TEmploy);
  end;

  //жунал документов
  TDocList = class(TList)
  private
    function  GetItem(ind:integer):TListRec;
    procedure SetItem(ind:integer;item:TListRec);
  public
    property Item[ind:integer] : TListRec read GetItem write SetItem;
    constructor Create;
    function   CreateDoc(autor:TEmploy;doctype:byte):integer;
    procedure  DeleteDoc(ind:integer);
    procedure  SaveToFile(fname:string);
    function   LoadFromFile(fname:string):boolean;
    function   IndByNum(num:integer):integer;
    function   UpdateFromFolder(folder:string):integer;
  end;


var
  DocTypeLst : array [0..1] of string = ('наряд','премия');
  DocStatLst : array [0..4] of string = ('создан','изменен','удален','восстановлен','импортирован');
  MainList   : TDocList;

implementation

uses WorkTable;

constructor TDocList.Create;
begin
  inherited;
end;

function TDocList.UpdateFromFolder(folder:string):integer;
var
  i : integer;
  searchResult : TSearchRec;
  Tab    : TWorkTable;
  cnt    : integer;
begin
  result:=0;
  cnt:=0;
  if DirectoryExists(folder) then
    if FindFirst(folder+'*.nrd', faAnyFile, searchResult) = 0 then
      begin
        repeat
          // загружаем файл
          Tab:=TWorkTable.Create(nil);
          Tab.LoadFromFile(folder+searchResult.Name);
          //Определям, записан ли уже документ в журнал
          i:=0;
          while(i<self.Count)and(self.Item[i].Num<>Tab.number)do inc(i);
          if(i>=self.Count)then
            begin
              i:=self.CreateDoc(tab.autor.Employ,dtNar);
              self.Item[i].Num:=Tab.number;
              self.Item[i].fname:=searchResult.Name;
              self.Item[i].AddRec(dsImport,FileDateToDateTime(searchResult.Time),user);
              inc(cnt);
            end {else
            if FileDateToDateTime(searchResult.Time)>self.Item[i].LastStatus.time then
              begin
                self.Item[i].AddRec(dsImport,FileDateToDateTime(searchResult.Time),user);
                inc(cnt);
              end};
          self.Item[i].Date :=Tab.MyDate;
          self.Item[i].Night:=Tab.Night;
          self.Item[i].send :=false;
          self.Item[i].note:=Tab.note;
        until FindNext(searchResult) <> 0;

        // Должен освободить ресурсы, используемые этими успешными, поисками
        FindClose(searchResult);
      end;
  result:=cnt;      
end;

procedure TDocList.SaveToFile(fname:string);
var
  i,j    : integer;
  MyFile : TFileStream;
begin
  MyFile:=TFileStream.Create(fname, fmCreate);
  MyFile.Write(self.count,sizeof(integer));
  for I := 0 to self.Count - 1 do
    begin
      MyFile.Write(self.Item[i].typedoc,sizeof(integer));
      MyFile.Write(self.Item[i].Date,sizeof(TDate));
      MyFile.Write(self.Item[i].Night,sizeof(boolean));
      MyFile.Write(self.Item[i].Num,sizeof(integer));
      MyFile.Write(self.Item[i].Autor,sizeof(TEmploy));
      MyFile.Write(self.Item[i].send,sizeof(boolean));
      MyFile.Write(self.Item[i].note,sizeof(shortstring));
      MyFile.Write(self.Item[i].fname,sizeof(shortstring));
      MyFile.Write(self.Item[i].StatCount,sizeof(integer));
      for j := 0 to self.Item[i].StatCount - 1 do
        MyFile.Write(self.Item[i].StatItems[j],sizeof(TStatRec));
    end;
  MyFile.Free;
end;

function TDocList.LoadFromFile(fname:string):boolean;
var
  count,i,j,k : integer;
  MyFile : TFileStream;
  item   : TListRec;
  StRec  : TStatRec;
begin
  result:=false;
  if FileExists(fname) then
    begin
      self.Clear;
      MyFile:=TFileStream.Create(fname, fmOpenRead);
      try
        myfile.Read(count,sizeof(integer));
        for I := 0 to count - 1 do
          begin
            Item:=TListRec.Create;
            MyFile.Read(Item.typedoc,sizeof(integer));
            MyFile.Read(Item.Date,sizeof(TDate));
            MyFile.Read(Item.Night,sizeof(boolean));
            MyFile.Read(Item.Num,sizeof(integer));
            MyFile.Read(Item.Autor,sizeof(TEmploy));
            MyFile.Read(Item.send,sizeof(boolean));
            MyFile.Read(Item.note,sizeof(shortstring));
            MyFile.Read(Item.fname,sizeof(shortstring));
            MyFile.Read(k,sizeof(integer));
            for j := 0 to k - 1 do
              begin
                MyFile.Read(StRec,sizeof(TStatRec));
                Item.AddRec(StRec.stat,StRec.time,StRec.user);
              end;
            self.Add(item);
          end;
        result:=true;
      finally
        MyFile.Free;
      end;
    end;
end;

function TDocList.GetItem(ind:integer):TListRec;
begin
  result:=self.Items[ind];
end;

procedure TDocList.SetItem(ind:integer;item:TListRec);
begin
  self.Items[ind]:=item;
end;

function TDocList.CreateDoc(autor:TEmploy;doctype:byte):integer;
var
  newitem : TListRec;
begin
  newitem:=TListRec.Create;
  newitem.typedoc:=doctype;
  newitem.Num:=self.Count+1;
  newitem.Autor:=autor;
  newitem.AddRec(dsCreate,Now,Autor);
  result:=self.Add(newitem);
end;

procedure TDocList.DeleteDoc(ind: Integer);
begin
  self.Item[ind].Free;
  self.Delete(ind);
end;

function TDocList.IndByNum(num:integer):integer;
var
  i : integer;
begin
  i:=0;
  while(i<self.Count)and(self.Item[i].Num<>num)do inc(i);
  if (i<self.Count)and(self.Item[i].Num=num) then result:=i
    else result:=-1;
end;

//------------------------------------------------------------------------------

constructor TListRec.Create;
begin
  inherited;
  self.Num:=0;
  self.StatCount:=0;
  SetLength(self.StatItems,self.StatCount);
end;

procedure TListRec.AddRec(st:byte;tm:TDateTime;us:TEmploy);
begin
  inc(self.StatCount);
  SetLength(self.StatItems,self.StatCount);
  self.StatItems[self.StatCount-1].stat:=st;
  self.StatItems[self.StatCount-1].time:=tm;
  self.StatItems[self.StatCount-1].user:=us;
end;

function TListRec.GetLastRec:TStatRec;
begin
  result:=self.StatItems[self.StatCount-1];
end;


end.
