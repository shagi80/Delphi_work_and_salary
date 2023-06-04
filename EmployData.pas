unit EmployData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes,Dialogs;

type
  TFunction = record
    code    : string[10];
    name    : string[32];
    sum     : real;
    ImgFile : string[255];
  end;

  TFunctionList = class(TList)
  private
    function  GetItem(ind:integer):TFunction;
    procedure SetItem(ind:integer;item:TFunction);
  public
    ImgFolder : string;
    property Item[ind:integer] : TFunction read GetItem write SetItem;
    constructor Create;
    function  AddItem(item:TFunction):integer;
    procedure SaveToFile(fname:string);
    function  LoadFromFile(fname:string):boolean;
    function  LoadFrom1C(fname:string):boolean;
    function  IndFromName(name:string):integer;
    function  IndFromCode(name:string):integer;
  end;

  TEmploy = record
    code    : string[10];
    name    : string[64];
    funct   : TFunction;
    ImgFile : string[255];
  end;

  TEmployList = class(TList)
  private
    function  GetItem(ind:integer):TEmploy;
    procedure SetItem(ind:integer;item:TEmploy);
  public
    ImgFolder : string;
    property Item[ind:integer] : TEmploy read GetItem write SetItem;
    constructor Create;
    function AddItem(item:TEmploy):integer;
    procedure SaveToFile(fname:string);
    function LoadFromFile(fname:string):boolean;
    function IndFromName(name:string):integer;
    function IndFromCode(code:string):integer;
    function NameFromCode(code:string):string;
    function LoadFrom1C(fname:string):boolean;
    function ShortName(fullname:string):string;
  end;


  TBaseCodeRec = record
    code     : string[10];
    BaseCode : string[10];
  end;

  TBaseCodeList = class(TList)
  private
    function  GetCode(code:string):string;
    procedure SetCode(code:string; basecode:string);
  public
    constructor Create;
    procedure   LoadFromFile(fname:string);
    procedure   SaveToFile(fname:string);
    procedure   AddItem(code,bscode:string);
    property    BaseCode[code:string] : string read GetCode write SetCode;
  end;


var
  EmployList    : TEmployList;
  FunctionList  : TFunctionList;
  DontShowEmpl  : TStringList;    //список кодов сотрудников которые надо скрыть
  BaseCodeList  : TBaseCodeList;  //список для сопоставления кодов с кодами 1С

implementation

uses
  GlobalUnit;


constructor TBaseCodeList.Create;
begin
  inherited;
end;

procedure TBaseCodeList.AddItem(code: string; bscode: string);
var
  pitem : ^TBaseCodeRec;
begin
  new(pitem);
  pitem^.code:=code;
  PItem^.BaseCode:=bscode;
  self.Add(pitem);
end;

procedure TBaseCodeList.LoadFromFile(fname:string);
var
  strs    : TStringList;
  i,j     : integer;
  pitem   : ^TBaseCodeRec;
begin
  //
  if FileExists(fname) then begin
    strs:=TStringList.Create;
    strs.LoadFromFile(fname);
    for I := 0 to EmployList.Count - 1 do begin
      new(pitem);
      pitem^.code:=EmployList.Item[i].code;
      j:=0;
      while(j<strs.Count)and(pitem^.code<>strs.ValueFromIndex[j])do inc(j);
      if(j<strs.Count)and(pitem^.code=strs.ValueFromIndex[j])then pitem^.BaseCode:=strs.Names[j]
        else pitem^.BaseCode:='';
      self.Add(pitem);
    end;
    strs.Free;
  end;
end;

function TBaseCodeList.GetCode(code:string):string;
var
  i : integer;
  pitem : ^TBaseCodeRec;
begin
  //
  if self.Count>0 then begin
    i:=0;
    pitem:=self.Items[i];
    while(i<self.Count)and(pitem^.code<>code)do begin
      inc(i);
      if(i<self.Count)then pitem:=self.Items[i];
    end;
    if(i<self.Count)and(pitem^.code=code)then result:=pitem^.BaseCode else result:='';
  end else result:='';
end;

procedure TBaseCodeList.SetCode(code:string;basecode:string);
var
  i : integer;
  pitem : ^TBaseCodeRec;
begin
  //
  if self.Count>0 then begin
    i:=0;
    pitem:=self.Items[i];
    while(i<self.Count)and(pitem^.code<>code)do begin
      inc(i);
      if(i<self.Count)then pitem:=self.Items[i];
    end;
    if(i<self.Count)and(pitem^.code=code)then pitem^.BaseCode:=basecode
      else begin
        new(pitem);
        pitem^.code:=code;
        pitem^.BaseCode:=BaseCode;
        self.Add(pitem);
      end;
  end else begin
    new(pitem);
    pitem^.code:=code;
    pitem^.BaseCode:=BaseCode;
    self.Add(pitem);
  end;
end;

procedure TBaseCodeList.SaveToFile(fname:string);
var
  strs : TStringList;
  i    : integer;
  pitem : ^TBaseCodeRec;
begin
  strs:=TStringList.Create;
  for I := 0 to self.Count - 1 do begin
    pitem:=self.Items[i];
    strs.Add(pitem^.BaseCode+'='+pitem^.code);
  end;
  strs.SaveToFile(fname);
end;

//-----------------------------------------------------------------------------

constructor TEmployList.Create;
begin
  inherited;
  ImgFolder:=EmplImgFolder;
end;

procedure TEmployList.SaveToFile(fname:string);
var
  i   : integer;
  MyFile : TFileStream;
  pitem : ^TEmploy;
begin
  MyFile:=TFileStream.Create(fname, fmCreate);
  MyFile.Write(self.count,sizeof(integer));
  for I := 0 to self.Count - 1 do
    begin
      pitem:=self.Items[i];
      MyFile.Write(pitem^,sizeof(TEmploy));
    end;
  MyFile.Free;
end;

function TEmployList.LoadFromFile(fname:string):boolean;
var
  count,i: integer;
  MyFile : TFileStream;
  item   : TEmploy;
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
            MyFile.Read(item,sizeof(TEmploy));
            //if item.name='Рахимов' then item.code:='1111';
            self.AddItem(item)
          end;
        result:=true;
      finally
        MyFile.Free;
      end;
    end;
    //self.SaveToFile(fname);
end;

function TEmployList.GetItem(ind:integer):TEmploy;
var
  item : ^TEmploy;
begin
  item:=self.Items[ind];
  result:=item^;
end;

procedure TEmployList.SetItem(ind:integer;item:TEmploy);
var
  pitem : ^TEmploy;
begin
  new(pitem);
  pitem^:=item;
  self.Items[ind]:=pitem;
end;

function TEmployList.AddItem(item:TEmploy):integer;
var
  i,j : integer;
  newitem : ^TEmploy;
begin
  j:=1000; //переменная для подобора кода
  repeat
  //цикл подбора ID добавляемого элемента
  i:=0;
  while(i<self.Count)and(self.Item[i].code<>item.code)do inc(i);
  if(i=self.Count)and(Length(item.code)>0) then
    begin
      new(newitem);
      newitem^:=item;
      result:=self.Add(newitem);
    end else
    begin
      inc(j);
      item.code:=inttostr(j);
      result:=-1;
    end;
  until result>-1;
end;

function TEmployList.NameFromCode(code:string):string;
var
  i : integer;
begin
  i:=0;
  result:='';
  while (i<self.Count)and(code<>self.Item[i].code) do inc(i);
  if(i<self.Count)and(code=self.Item[i].code)then result:=self.Item[i].name;
end;

function  TEmployList.IndFromCode(code:string):integer;
var
  i : integer;
begin
  i:=0;
  result:=-1;
  while (i<self.Count)and(code<>self.Item[i].code) do inc(i);
  if(i<self.Count)and(code=self.Item[i].code)then result:=i;
end;

function  TEmployList.IndFromName(name:string):integer;
var
  i : integer;
begin
  i:=0;
  result:=-1;
  while (i<self.Count)and(name<>self.Item[i].name) do inc(i);
  if(i<self.Count)and(name=self.Item[i].name)then result:=i;
end;

function TEmployList.ShortName(fullname:string):string;
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


function TEmployList.LoadFrom1C(fname:string):boolean;
var
  i, ind : integer;
  str,flt: string;
  MyFile : TStringList;
  item   : TEmploy;
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
            flt:=copy(str,2,pos('","',str)-2);
            item.funct.code:='';
            item.funct.name:='неизвестно';
            item.funct.sum:=DefFunctionSum;
            item.funct.ImgFile:='';
            if (Length(flt)>0) then
              begin
                ind:=FunctionList.IndFromCode(flt);
                if ind>=0 then item.funct:=FunctionList.Item[ind];
              end;
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

// -----------------------------------------------------------------------------

constructor TFunctionList.Create;
begin
  inherited;
  ImgFolder:=FunctImgFolder;
end;

procedure TFunctionList.SaveToFile(fname:string);
var
  i      : integer;
  MyFile : TFileStream;
  pitem  : ^TFunction;
begin
  MyFile:=TFileStream.Create(fname, fmCreate);
  MyFile.Write(self.count,sizeof(integer));
  for I := 0 to self.Count - 1 do
    begin
      pitem:=self.Items[i];
      MyFile.Write(pitem^,sizeof(TFunction));
    end;
  MyFile.Free;
end;

function TFunctionList.LoadFromFile(fname:string):boolean;
var
  count,i: integer;
  MyFile : TFileStream;
  item   : TFunction;
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
            MyFile.Read(item,sizeof(TFunction));
            self.AddItem(item)
          end;
        result:=true;
      finally
        MyFile.Free;
      end;
    end;
end;

function TFunctionList.LoadFrom1C(fname:string):boolean;
var
  i      : integer;
  str,flt: string;
  MyFile : TStringList;
  item   : TFunction;
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
            flt:=copy(str,2,pos('","',str)-2);
            if Length(flt)>0 then item.sum:=StrToFloat(flt)
              else item.sum:=DefFunctionSum;
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

function TFunctionList.GetItem(ind:integer):TFunction;
var
  item : ^TFunction;
begin
  item:=self.Items[ind];
  result:=item^;
end;

procedure TFunctionList.SetItem(ind:integer;item:TFunction);
var
  pitem : ^TFunction;
begin
  new(pitem);
  pitem^:=item;
  self.Items[ind]:=pitem;
end;

function TFunctionList.AddItem(item:TFunction):integer;
var
  i : integer;
  newitem : ^TFunction;
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

function  TFunctionList.IndFromName(name:string):integer;
var
  i : integer;
begin
  i:=0;
  result:=-1;
  while (i<self.Count)and(name<>self.Item[i].name) do inc(i);
  if(i<self.Count)and(name=self.Item[i].name)then result:=i;
end;

function  TFunctionList.IndFromCode(name:string):integer;
var
  i : integer;
begin
  i:=0;
  result:=-1;
  while (i<self.Count)and(name<>self.Item[i].code) do inc(i);
  if(i<self.Count)and(name=self.Item[i].code)then result:=i;
end;

end.
