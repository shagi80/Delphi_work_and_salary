unit EmpData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons,
  EmployData, ExtDlgs;

type
  TEmpDataForm = class(TForm)
    OKBtn: TSpeedButton;
    CanelBtn: TSpeedButton;
    NameLB: TLabel;
    EditNameBtn: TSpeedButton;
    Img: TImage;
    Label1: TLabel;
    CodeLB: TLabel;
    TabNumBtn: TSpeedButton;
    Label2: TLabel;
    FunctLB: TLabel;
    FunctEditBtn: TSpeedButton;
    Shape1: TShape;
    OpenDlg: TOpenPictureDialog;
    SysCodeLB: TLabel;
    procedure ImgClick(Sender: TObject);
    procedure FunctEditBtnClick(Sender: TObject);
    procedure TabNumBtnClick(Sender: TObject);
    procedure EditNameBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    function  ShowWindow(sender:TComponent;var Employ:TEmploy;var BsCode:string):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EmpDataForm: TEmpDataForm;

implementation

{$R *.dfm}

uses GlobalUnit, NumKeyboard, Keyboard, ListView, MsgForm, ShadowForm;

var
  NewImgFile : string; //имя файла аватра при изменении

//Основная процедура - возвращает "иситну" при нажатии кн "ОК"
//в окне вариантов действий
function TEmpDataForm.ShowWindow(sender:TComponent;var Employ:TEmploy;var BsCode:string):boolean;
var
  find    : integer;
  ImgFile : string;
begin
  NameLB.Caption:=Employ.name;
  if Length(Employ.code)>0 then SysCodeLB.Caption:='Код элемента: '+Employ.code
    else SysCodeLB.Caption:='Код элемента: новый элемент';
  CodeLB.Caption:=BaseCodeList.BaseCode[Employ.code];
  FunctLB.Caption:=Employ.funct.name;
  ImgFile:=ExePath+EmployList.ImgFolder+Employ.ImgFile;
  if FileExists(ImgFile)then Img.Picture.LoadFromFile(ImgFile)
    else Img.Picture.Bitmap.LoadFromResourceName(hInstance,'DefEmpImg');
  NewImgFile:='';
  ShadowShow(sender);
  result:=(self.ShowModal=mrOK);
  ShadowHide(sender);
  if result then
    begin
        Employ.name:=NameLB.Caption;
        //Employ.code:=CodeLB.Caption;
        BsCode:=CodeLb.Caption;
        if Length(NewImgFile)>0 then Employ.ImgFile:=NewImgFile;
        find:=FunctionList.IndFromName(FunctLB.Caption);
        if find>=0 then Employ.funct:=FunctionList.Item[find];
    end;
end;

procedure TEmpDataForm.CanelBtnClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TEmpDataForm.EditNameBtnClick(Sender: TObject);
var
  name : string;
begin
  name:=NameLB.Caption;
  if KeyBoardForm.GetString(self,name,true) then NameLB.Caption:=name;
end;

procedure TEmpDataForm.FunctEditBtnClick(Sender: TObject);
var
  i,ind  : integer;
  pind   : ^integer;
  LVItem : TListItem;
  Img    : TBitMap;
  ImgFile: string;
begin
  ListViewForm.CaptionLB.Caption:='Подбор должности для '+self.NameLB.Caption;
  ListViewForm.Cap2LB.Caption:='';
  //Заполнение списка из струтуры FunctionList
  ListViewForm.LV.Clear;
  ListViewForm.ImgLst.Clear;
  Img:=TbitMap.Create;
  for I := 0 to FunctionList.Count - 1 do
    begin
      LVItem:=ListViewForm.LV.Items.Add;
      LVItem.Caption:=FunctionList.Item[i].name+chr(13)+'('+
        FormatFloat('##0.0',FunctionList.Item[i].sum)+' р/ч)';
      new(pind);
      pind^:=i;
      LVItem.Data:=pind;
      ImgFile:=ExePath+FunctionList.ImgFolder+FunctionList.Item[i].ImgFile;
      if FileExists(ImgFile) then Img.LoadFromFile(ImgFile)
        else Img.LoadFromResourceName(hInstance, 'DefEmpImg');
      ind:=ListViewForm.ImgLst.Add(Img,nil);
      LVItem.ImageIndex:=ind;
    end;
  ind:=ListViewForm.ShowView(self);
  if ind>=0 then self.FunctLB.Caption:=FunctionList.Item[ind].name;
  img.Free;
end;

procedure TEmpDataForm.ImgClick(Sender: TObject);
var
  ind    : integer;
  pind   : ^integer;
  LVItem : TListItem;
  Img    : TBitMap;
  F      : TSearchRec;
begin
  ListViewForm.CaptionLB.Caption:='Выбор изображения для '+self.NameLB.Caption;
  ListViewForm.Cap2LB.Caption:=ExePath+EmployList.ImgFolder;
  //Заполнение списка перечнем файлов с расширемием BMP найденных
  //в папке, заданной соотв полем структуры EmployList
  ListViewForm.LV.Clear;
  ListViewForm.ImgLst.Clear;
  Img:=TBitMap.Create;
  if FindFirst(ExePath+EmployList.ImgFolder+'*.bmp',faAnyFile,F)=0 then
    repeat
      Img.LoadFromFile(ExePath+EmployList.ImgFolder+F.Name);
      //img.Width:=80;
      //img.Height:=80;
      try
        ind:=ListViewForm.ImgLst.Add(Img,nil);
        LVItem:=ListViewForm.LV.Items.Add;
        LVItem.Caption:=f.Name;
        LVItem.ImageIndex:=ind;
        new(pind);
        pind^:=ListViewForm.LV.Items.Count-1;
        LVItem.Data:=pind;
      except
        break;
      end;
    until FindNext(F)<>0;
  FindClose(F);
  ind:=ListViewForm.ShowView(self);
  if ind>=0 then
    begin
      ListViewForm.ImgLst.GetBitmap(ind,img);
      self.Img.Picture.Bitmap:=img;
      NewImgFile:=ListViewForm.LV.Selected.Caption;
    end;
end;

procedure TEmpDataForm.OKBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrOK;
end;

procedure TEmpDataForm.TabNumBtnClick(Sender: TObject);
var
  code : string;
begin
  code:=CodeLb.Caption;
  if NumKeyBoardForm.GetValue(self,code,true) then CodeLB.Caption:=code;
end;

end.
