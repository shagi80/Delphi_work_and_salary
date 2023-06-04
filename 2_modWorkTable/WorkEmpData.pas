unit WorkEmpData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons,
  EmployData;

const
  alBrigadier =  20;
  alForeman   =  10;

type
  TWorkEmpDataForm = class(TForm)
    CanelBtn: TSpeedButton;
    OKBtn: TSpeedButton;
    Img: TImage;
    NameLB: TLabel;
    Label1: TLabel;
    TabNumBtn: TSpeedButton;
    RatLB: TLabel;
    rt1: TSpeedButton;
    TimeLB: TLabel;
    Label2: TLabel;
    FunctEditBtn: TSpeedButton;
    FunctLB: TLabel;
    Label4: TLabel;
    NoteLB: TLabel;
    EditNameBtn: TSpeedButton;
    Shape1: TShape;
    rt2: TSpeedButton;
    rt3: TSpeedButton;
    rt4: TSpeedButton;
    rt5: TSpeedButton;
    TmPayLB: TLabel;
    procedure EditNameBtnClick(Sender: TObject);
    procedure rt1Click(Sender: TObject);
    procedure FunctEditBtnClick(Sender: TObject);
    procedure TabNumBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    procedure SetRtBtn(num:integer);
    function  ShowWindow(sender:TComponent;name:string;var funct:TFunction;var Time:real;var rating:integer;var note:string;bmp:TbitMap;tmpay:boolean; alevel:byte):boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WorkEmpDataForm: TWorkEmpDataForm;

implementation

{$R *.dfm}

uses GlobalUnit, NumKeyboard, Keyboard, ListView, ShadowForm, MsgForm;

var
  resrating   : integer;
  AccsesLevel : byte;

procedure TWorkEmpDataForm.SetRtBtn(num:integer);
var
  i   : integer;
begin
  resrating:=num;
  for I := 0 to self.ControlCount-1 do
    if copy(self.Controls[i].Name,1,2)='rt' then
    begin
      if self.Controls[i].Name='rt'+IntToStr(num) then
        begin
          (self.Controls[i] as TSpeedButton).Font.Color:=clNavy;
          (self.Controls[i] as TSpeedButton).Font.Style:=[fsBold];
        end else
        begin
          (self.Controls[i] as TSpeedButton).Font.Color:=clSilver;
          (self.Controls[i] as TSpeedButton).Font.Style:=[];
        end;
    end;
end;

function  TWorkEmpDataForm.ShowWindow(sender:TComponent;name:string;var funct:TFunction;var Time:real;var rating:integer;var note:string;bmp:TbitMap;tmpay:boolean; alevel:byte):boolean;
var
  find    : integer;
begin
  AccsesLevel:=alevel;
  NameLB.Caption:=name;
  TimeLB.Caption:=FormatFloat('#0.##',time);
  FunctLB.Caption:=funct.name;
  NoteLb.Caption:=note;
  Img.Picture.Bitmap:=bmp;
  rt1.Visible:=true;
  rt2.Visible:=true;
  rt3.Visible:=true;
  rt4.Visible:=true;
  rt5.Visible:=true;
  RatLB.Caption:='Общая оценка:';
  rt1.Caption:='+'+IntToStr(RatingVal[1])+'%';
  rt2.Caption:='+'+IntToStr(RatingVal[2])+'%';
  rt3.Caption:='+'+IntToStr(RatingVal[3])+'%';
  rt4.Caption:='+'+IntToStr(RatingVal[4])+'%';
  rt5.Caption:='+'+IntToStr(RatingVal[5])+'%';
  //если сотрудник автор наряда он не получает премию. Его рейтинг, передаваемый в эту процедуру
  //больше 5
  if rating>5 then
    begin
      RatLB.Caption:='Премия не начисляется.';
      rt1.Visible:=false;
      rt2.Visible:=false;
      rt3.Visible:=false;
      rt4.Visible:=false;
      rt5.Visible:=false;
      resrating:=6;
    end else self.SetRtBtn(rating);
  if tmpay then TmPayLB.Caption:='(оплата по часам разрешена)' else TmPayLB.Caption:='(оплата по часам запрещена)';
  ShadowShow(sender);
  result:=(self.ShowModal=mrOK);
  ShadowHide(sender);
  if result then
    begin
        time:=StrToFloat(TimeLB.Caption);
        rating:=resrating;
        note:=NoteLB.Caption;
        find:=FunctionList.IndFromName(FunctLB.Caption);
        if find>=0 then funct:=FunctionList.Item[find];
    end;
end;

procedure TWorkEmpDataForm.CanelBtnClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TWorkEmpDataForm.EditNameBtnClick(Sender: TObject);
var
  str : string;
begin
  str:=NoteLb.Caption;
  if KeyBoardForm.GetString(self,str,false) then NoteLB.Caption:=str;
end;

procedure TWorkEmpDataForm.FunctEditBtnClick(Sender: TObject);
var
  i,ind  : integer;
  pind   : ^integer;
  LVItem : TListItem;
  Img    : TBitMap;
  ImgFile: string;
begin
  ListViewForm.CaptionLB.Caption:='Подбор должности для '+self.NameLB.Caption;
  ListViewForm.LV.Clear;
  ListViewForm.ImgLst.Clear;
  Img:=TbitMap.Create;
  for I := 0 to FunctionList.Count - 1 do
    begin
      LVItem:=ListViewForm.LV.Items.Add;
      LVItem.Caption:=FunctionList.Item[i].name;
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

procedure TWorkEmpDataForm.OKBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrOK;
end;

procedure TWorkEmpDataForm.rt1Click(Sender: TObject);
begin
  if (AccsesLevel>alForeman)and(((sender as TSpeedButton).Name='rt1')or((sender as TSpeedButton).Name='rt5')) then
    begin
      ShowMSG(self,'Недостаточно прав доступа !',[msbOK]);
      Abort;
    end;
  self.SetRtBtn(strtoint(copy((sender as TSpeedButton).Name,3,maxint)));
end;

procedure TWorkEmpDataForm.TabNumBtnClick(Sender: TObject);
var
  str : string;
begin
  str:=TimeLb.Caption;
  if NumKeyBoardForm.GetValue(self,str,false) then TimeLB.Caption:=str;
end;

end.
