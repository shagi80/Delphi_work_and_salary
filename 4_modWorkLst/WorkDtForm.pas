unit WorkDtForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons,
  WorkData, ExtDlgs;

type
  TWorkForm = class(TForm)
    OKBtn: TSpeedButton;
    CanelBtn: TSpeedButton;
    NameLB: TLabel;
    EditNameBtn: TSpeedButton;
    Img: TImage;
    Label1: TLabel;
    CodeLB: TLabel;
    CodeBtn: TSpeedButton;
    Label2: TLabel;
    ItemLB: TLabel;
    ItemBtn: TSpeedButton;
    Shape1: TShape;
    OpenDlg: TOpenPictureDialog;
    Label3: TLabel;
    Label4: TLabel;
    FolderLB: TLabel;
    SpeedButton1: TSpeedButton;
    PayRollLB: TLabel;
    SumBtn: TSpeedButton;
    Label5: TLabel;
    NormLB: TLabel;
    NormBtn: TSpeedButton;
    GroupBtn: TSpeedButton;
    NigthBtn: TSpeedButton;
    NSpayBtn: TSpeedButton;
    TmPayBtn: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
    procedure NormBtnClick(Sender: TObject);
    procedure SumBtnClick(Sender: TObject);
    procedure ImgClick(Sender: TObject);
    procedure ItemBtnClick(Sender: TObject);
    procedure CodeBtnClick(Sender: TObject);
    procedure EditNameBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    function  ShowWindow(sender:TComponent;var Work:TWork):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WorkForm: TWorkForm;

implementation

{$R *.dfm}

uses GlobalUnit, NumKeyboard, Keyboard, ListView, MsgForm, ShadowForm;

var
  NewImgFile : string; //имя файла аватра при изменении

//Основная процедура - возвращает "иситну" при нажатии кн "ОК"
//в окне вариантов действий
function TWorkForm.ShowWindow(sender:TComponent;var Work:TWork):boolean;
var
  find    : integer;
  ImgFile : string;
begin
  NameLB.Caption:=Work.name;
  CodeLB.Caption:=Work.code;
  ItemLB.Caption:=Work.Item.name;
  FolderLB.Caption:=Work.folder;
  GroupBtn.Down:=Work.Group;
  NigthBtn.Down:=Work.Night;
  NSpayBtn.Down:=Work.NSPay;
  TmPayBtn.Down:=Work.TmPay;
  TmPayBtn.Enabled:=TimePay;
  PayRollLB.Caption:=FormatFloat('###0.00',Work.PayRoll);
  NormLB.Caption:=FormatFloat('###0.00',Work.Norm);
  ImgFile:=ExePath+WorkList.ImgFolder+Work.ImgFile;
  if FileExists(ImgFile)then Img.Picture.LoadFromFile(ImgFile)
    else Img.Picture.Bitmap.LoadFromResourceName(hInstance, 'DefItemImg');
  NewImgFile:='';
  ShadowShow(sender);
  result:=(self.ShowModal=mrOK);
  ShadowHide(sender);
  if result then
    begin
        Work.name:=NameLB.Caption;
        Work.code:=CodeLB.Caption;
        Work.folder:=FolderLB.Caption;
        Work.PayRoll:=StrToFloat(PayRollLB.Caption);
        Work.Norm:=StrToFloat(NormLB.Caption);
        Work.Group:=GroupBtn.Down;
        Work.Night:=NigthBtn.Down;
        Work.NSpay:=NSpayBtn.Down;
        Work.TmPay:=TmPayBtn.Down;
        if Length(NewImgFile)>0 then Work.ImgFile:=NewImgFile;
        find:=ItemList.IndFromName(ItemLB.Caption);
        if find>=0 then Work.Item:=ItemList.Item[find];
    end;
end;

procedure TWorkForm.SpeedButton1Click(Sender: TObject);
var
  folder : string;
begin
  folder:=FolderLb.Caption;
  if KeyBoardForm.GetString(self,folder,false) then FolderLB.Caption:=folder;
end;

procedure TWorkForm.SumBtnClick(Sender: TObject);
var
  sum : string;
begin
  sum:=PayRollLb.Caption;
  if NumKeyBoardForm.GetValue(self,sum,false) then PayRollLB.Caption:=sum;
end;

procedure TWorkForm.CanelBtnClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TWorkForm.EditNameBtnClick(Sender: TObject);
var
  name : string;
begin
  name:=NameLB.Caption;
  if KeyBoardForm.GetString(self,name,true) then NameLB.Caption:=name;
end;

procedure TWorkForm.ItemBtnClick(Sender: TObject);
var
  i,ind  : integer;
  pind   : ^integer;
  LVItem : TListItem;
  Img    : TBitMap;
  ImgFile: string;
begin
  ListViewForm.CaptionLB.Caption:='Подбор детали для '+self.NameLB.Caption;
  ListViewForm.Cap2LB.Caption:='';
  //Заполнение списка из струтуры FunctionList
  ListViewForm.LV.Clear;
  ListViewForm.ImgLst.Clear;
  Img:=TbitMap.Create;
  for I := 0 to ItemList.Count - 1 do
    begin
      LVItem:=ListViewForm.LV.Items.Add;
      LVItem.Caption:=ItemList.Item[i].name;
      new(pind);
      pind^:=i;
      LVItem.Data:=pind;
      ImgFile:=ExePath+ItemList.ImgFolder+ItemList.Item[i].ImgFile;
      if FileExists(ImgFile) then Img.LoadFromFile(ImgFile)
        else Img.LoadFromResourceName(hInstance, 'DefItemImg');
      ind:=ListViewForm.ImgLst.Add(Img,nil);
      LVItem.ImageIndex:=ind;
    end;
  ind:=ListViewForm.ShowView(self);
  if ind>=0 then
    begin
      self.ItemLB.Caption:=ItemList.Item[ind].name;
      if  (FileExists(ExePath+ItemList.ImgFolder+ItemList.Item[ind].ImgFile))and
          (copyfile(pchar(ExePath+ItemList.ImgFolder+ItemList.Item[ind].ImgFile),
            pchar(ExePath+WorkList.ImgFolder+ItemList.Item[ind].ImgFile),false)) then
        begin
          self.Img.Picture.LoadFromFile(ExePath+ItemList.ImgFolder+ItemList.Item[ind].ImgFile);
          NewImgFile:=ItemList.Item[ind].ImgFile;
        end;
    end;
  img.Free;
end;

procedure TWorkForm.ImgClick(Sender: TObject);
var
  ind    : integer;
  pind   : ^integer;
  LVItem : TListItem;
  Img    : TBitMap;
  F      : TSearchRec;
begin
  ListViewForm.CaptionLB.Caption:='Выбор изображения для '+self.NameLB.Caption;
  ListViewForm.Cap2LB.Caption:=ExePath+WorkList.ImgFolder;
  //Заполнение списка перечнем файлов с расширемием BMP найденных
  //в папке, заданной соотв полем структуры EmployList
  ListViewForm.LV.Clear;
  ListViewForm.ImgLst.Clear;
  Img:=TBitMap.Create;
  if FindFirst(ExePath+WorkList.ImgFolder+'*.bmp',faAnyFile,F)=0 then
    repeat
      Img.LoadFromFile(ExePath+WorkList.ImgFolder+F.Name);
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

procedure TWorkForm.NormBtnClick(Sender: TObject);
var
  norm : string;
begin
  norm:=NormLb.Caption;
  if NumKeyBoardForm.GetValue(self,norm,false) then NormLB.Caption:=norm;
end;

procedure TWorkForm.OKBtnClick(Sender: TObject);
begin
  if TmPayBtn.Down and NSPayBtn.Down then
    ShowMsg(self,'Начисление % начальнику смены по часовым ставкам недопустимо !',[msbOK])else  self.ModalResult:=mrOK;
end;

procedure TWorkForm.CodeBtnClick(Sender: TObject);
var
  code : string;
begin
  code:=CodeLb.Caption;
  if NumKeyBoardForm.GetValue(self,code,true) then CodeLB.Caption:=code;
end;

end.
