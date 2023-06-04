unit WorkData;

interface

uses
  GlobalUnit, Windows, Messages, SysUtils, Variants, Classes,Dialogs;

type
  TItem = record
    code    : string[10];
    name    : string[32];
    time    : real;
    ImgFile : string[255];
  end;

  TItemList = class(TList)
  private
    function  GetItem(ind:integer):TItem;
    procedure SetItem(ind:integer;item:TItem);
  public
    ImgFolder : string;
    property Item[ind:integer] : TItem read GetItem write SetItem;
    constructor Create;
    function  AddItem(item:TItem):integer;
    procedure SaveToFile(fname:string);
    function  LoadFromFile(fname:string):boolean;
    function  LoadFrom1C(fname:string):boolean;
    function  IndFromName(name:string):integer;
    function  IndFromCode(name:string):integer;
  end;

  TWork = record
    code    : string[10];
    name    : string[64];
    folder  : string[64];
    Item    : TItem;
    PayRoll : real;
    Norm    : real;
    Group   : boolean;
    Night   : boolean;
    NSpay   : boolean;
    TmPay   : boolean;
    ImgFile : string[255];
  end;

  TWorkList = class(TList)
  private
    function  GetItem(ind:integer):TWork;
    procedure SetItem(ind:integer;item:TWork);
  public
    ImgFolder : string;
    property Item[ind:integer] : TWork read GetItem write SetItem;
    constructor Create;
    function AddItem(item:TWork):integer;
    procedure SaveToFile(fname:string);
    function LoadFromFile(fname:string):boolean;
    function IndFromName(name:string):integer;
    function ShortName(ind:integer; fullname:string):string;
    procedure GetFolderList(var lst:TStringList);
    function GetItemByCode(code:string):TWork;
  end;

var
  WorkList      : TWorkList;
  ItemList      : TItemList;

implementation


constructor TWorkList.Create;
begin
  inherited;
  ImgFolder:=WorkImgFolder;
end;

procedure TWorkList.SaveToFile(fname:string);
var
  i   : integer;
  MyFile : TFileStream;
  pitem : ^TWork;
begin
  MyFile:=TFileStream.Create(fname, fmCreate);
  MyFile.Write(self.count,sizeof(integer));
  for I := 0 to self.Count - 1 do
    begin
      pitem:=self.Items[i];
      MyFile.Write(pitem^,sizeof(TWork));
    end;
  MyFile.Free;
end;

function TWorkList.LoadFromFile(fname:string):boolean;
var
  count,i: integer;
  MyFile : TFileStream;
  item   : TWork;
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
            MyFile.Read(item,sizeof(TWork));
            self.AddItem(item)
          end;
        result:=true;
      finally
        MyFile.Free;
      end;
    end;
end;

function TWorkList.GetItem(ind:integer):TWork;
var
  item : ^TWork;
begin
  item:=self.Items[ind];
  result:=item^;
end;

procedure TWorkList.SetItem(ind:integer;item:TWork);
var
  pitem : ^TWork;
begin
  new(pitem);
  pitem^:=item;
  self.Items[ind]:=pitem;
end;

function TWorkList.AddItem(item:TWork):integer;
var
  i : integer;
  newitem : ^TWork;
begin
  i:=0;
  while(i<self.Count)and(self.Item[i].code<>item.code)do inc(i);
  if(i=self.Count) then
    begin
      new(newitem);
      newitem^:=item;
      result:=self.Add(newitem);
    end else result:=-1;
end;

function  TWorkList.IndFromName(name:string):integer;
var
  i : integer;
begin
  i:=0;
  result:=-1;
  while (i<self.Count)and(name<>self.Item[i].name) do inc(i);
  if(i<self.Count)and(name=self.Item[i].name)then result:=i;
end;

function TWorkList.ShortName(ind:integer; fullname:string):string;
const len=20;
begin
  if(ind=1)then
    if(pos(' ',fullname)>0) then
        result:=copy(fullname,1,pos(' ',fullname)-1) else result:=copy(fullname,1,len);
  if(ind=2)then
    if(pos(' ',fullname)>0) then
        result:=copy(fullname,pos(' ',fullname)+1,len) else result:=copy(fullname,len+1,len);
end;

procedure TWorkList.GetFolderList(var lst:TStringList);
var
  i,j : integer;
begin
  for I := 0 to self.Count - 1 do
    begin
      j:=0;
      while(j<lst.Count)and(lst[j]<>self.Item[i].folder)do inc(j);
      if(j=lst.Count)then lst.Add(self.Item[i].folder);
    end;
end;

function TWorkList.GetItemByCode(code:string):TWork;
var
  i : integer;
  item : ^TWork;
begin
  if(self.Count>0)then begin
    i:=-1;
    repeat
      inc(i);
      item:=self.Items[i];
    until(item.code=code)or(i=(self.Count-1)) ;
    if (item.code=code) then  result:=item^;
  end;
end;

// -----------------------------------------------------------------------------

constructor TItemList.Create;
begin
  inherited;
  ImgFolder:=ItemImgFolder;
end;

procedure TItemList.SaveToFile(fname:string);
var
  i      : integer;
  MyFile : TFileStream;
  pitem  : ^TItem;
begin
  MyFile:=TFileStream.Create(fname, fmCreate);
  MyFile.Write(self.count,sizeof(integer));
  for I := 0 to self.Count - 1 do
    begin
      pitem:=self.Items[i];
      MyFile.Write(pitem^,sizeof(TItem));
    end;
  MyFile.Free;
end;

function TItemList.LoadFromFile(fname:string):boolean;
var
  count,i: integer;
  MyFile : TFileStream;
  item   : TItem;
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
            MyFile.Read(item,sizeof(TItem));
            self.AddItem(item)
          end;
        result:=true;
      finally
        MyFile.Free;
      end;
    end;
end;

function TItemList.LoadFrom1C(fname:string):boolean;
var
  i      : integer;
  str    : string;
  MyFile : TStringList;
  item   : TItem;
begin
  result:=false;
  if FileExists(fname) then
    begin
      MyFile:=TstringList.Create;
      try
        MyFile.LoadFromFile(fname);
        for I := 0 to MyFile.Count - 1 do
          begin
            str:=MyFile[i];
            item.code:=copy(str,2,pos('","',str)-2);
            str:=copy(str,pos('","',str)+2,MaxInt);
            item.name:=copy(str,2,pos('","',str)-2);
            str:=copy(str,pos('","',str)+2,MaxInt);
            item.time:=StrToFloat(copy(str,2,pos('","',str)-2));
            str:=copy(str,pos('","',str)+2,MaxInt);
            item.ImgFile:=copy(str,2,Length(str)-2);
            self.AddItem(item);
          end;
        result:=true;
      finally
        MyFile.Free;
      end;
    end;
end;

function TItemList.GetItem(ind:integer):TItem;
var
  item : ^TItem;
begin
  item:=self.Items[ind];
  result:=item^;
end;

procedure TItemList.SetItem(ind:integer;item:TItem);
var
  pitem : ^TItem;
begin
  new(pitem);
  pitem^:=item;
  self.Items[ind]:=pitem;
end;

function TItemList.AddItem(item:TItem):integer;
var
  i : integer;
  newitem : ^TItem;
begin
  i:=0;
  while(i<self.Count)and(self.Item[i].code<>item.code)do inc(i);
  if(i=self.Count) then
    begin
      new(newitem);
      newitem^:=item;
      result:=self.Add(newitem);
    end else begin
      self.Item[i]:=item;
      result:=i;
    end;
end;

function  TItemList.IndFromName(name:string):integer;
var
  i : integer;
begin
  i:=0;
  result:=-1;
  while (i<self.Count)and(name<>self.Item[i].name) do inc(i);
  if(i<self.Count)and(name=self.Item[i].name)then result:=i;
end;

function  TItemList.IndFromCode(name:string):integer;
var
  i : integer;
begin
  i:=0;
  result:=-1;
  while (i<self.Count)and(name<>self.Item[i].code) do inc(i);
  if(i<self.Count)and(name=self.Item[i].code)then result:=i;
end;

end.
