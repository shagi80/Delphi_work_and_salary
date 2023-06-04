unit EmployLst;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons;

type
  TEmployListForm = class(TForm)
    MainPanel: TPanel;
    CapLB: TLabel;
    ImgLst: TImageList;
    LV: TListView;
    BtnPanel: TPanel;
    AddBtn: TSpeedButton;
    CanelBtn: TSpeedButton;
    DownBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    procedure UpBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure LVClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    procedure AddEmpToLV(ind : integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetEmployListItem(Cap:string;var ind : integer; var Img: TBitMap; GetAndChange:boolean):boolean;

implementation

{$R *.dfm}

uses GlobalUnit, EmpData, Keyboard, EmployData,MsgForm, ShadowForm;

var
  EmployListForm   : TEmployListForm;
  GetAndChangeMode : boolean; //режим "выбор с возожностью изменения"

function GetEmployListItem(Cap:string; var ind : integer; var Img: TBitMap; GetAndChange:boolean):boolean;
var
  i,j    : integer;
begin
  EmployListForm:=TEmployListForm.Create(application);
  EmployListForm.LV.Clear;
  EmployListForm.AddBtn.Visible:=GetAndChange;
  EmployListForm.CapLB.Caption:=cap;
  GetAndChangeMode:=GetAndChange;
  for I := 0 to EmployList.Count - 1 do begin
    //проверяем список скрываемых сотрудников
    j:=0;
    while(j<DontShowEmpl.Count)and(DontShowEmpl[j]<>EmployList.Item[i].code)do inc(j);
    if(j=DontShowEmpl.Count)then EmployListForm.AddEmpToLV(i);
  end;
  if (EmployListForm.ShowModal=mrOK)and(EmployListForm.LV.Selected<>nil) then
    begin
      ind:=EmployList.IndFromName(EmployListForm.LV.Selected.Caption);
      EmployListForm.ImgLst.GetBitmap(EmployListForm.LV.Selected.ImageIndex,img);
      result:=true;
    end else result:=false;
  EmployListForm.Free;
end;

procedure TEmployListForm.LVClick(Sender: TObject);
var
  ind   : integer;
  pind  : integer;
  Employ: TEmploy;
  img   : TBitMap;
  BsCode: string;
begin
  if LV.Selected=nil then Exit;
  if GetAndChangeMode then
    ind:=ShowMsg(self,LV.Selected.Caption,[msbOK,msbEdit,msbDel,msbCancel])
    else ind:=msbOK;
  if ind=msbOK then self.ModalResult:=mrOK;
  if ind=msbDel then
    begin
      if ShowMsg(self,'Сведения о сотруднике '+ LV.Selected.Caption+chr(13)+
        'будут удалены безвозвратно !',[msbOK,msbCancel])=msbOK then
      begin
        pind:=EmployList.IndFromName(LV.Selected.Caption);
        EmployList.Delete(pind);
        EmployList.SaveToFile(EmpFileName);
        LV.Items.Delete(LV.Selected.Index);
      end;
    end;
  if ind=msbEdit then
    begin
      pind:=EmployList.IndFromName(LV.Selected.Caption);
      Employ:=EmployList.Item[pind];
      BsCode:=BaseCodeList.BaseCode[Employ.code];
      if EmpDataForm.ShowWindow(self,Employ,BsCode) then
        begin
          EmployList.Item[pind]:=Employ;
          LV.Selected.Caption:=Employ.name;
          if FileExists(ExePath+EmployList.ImgFolder+Employ.ImgFile) then
            begin
              img:=TBitmap.Create;
              img.LoadFromFile(ExePath+EmployList.ImgFolder+Employ.ImgFile);
              LV.Selected.ImageIndex:=self.ImgLst.Add(img,nil);
            end;
          EmployList.SaveToFile(EmpFileName);
          BaseCodeList.BaseCode[Employ.Code]:=BsCode;
          BaseCodeList.SaveToFile(BaseCodeFileName);
        end;
    end;
end;

procedure TEmployListForm.UpBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')then LV.Scroll(0,ScrollSpeed);
  if ((Sender as TSpeedButton).name='UpBtn')then LV.Scroll(0,-ScrollSpeed);
end;

procedure TEmployListForm.AddBtnClick(Sender: TObject);
var
  newname : string;
  item    : TEmploy;
  ind     : integer;
  BsCode  : string;
begin
  newname:='';
  if KeyBoardForm.GetString(self,newname,true) then
    begin
      item.name:=newname;
      item.code:='';
      item.funct.code:='';
      item.funct.name:='неизвестно';
      item.funct.sum:=DefFunctionSum;
      item.funct.ImgFile:='';
      item.ImgFile:='';
      bsCode:='';
      if EmpDataForm.ShowWindow(self,item,bscode) then
        begin
          ind:=EmployList.AddItem(item);
          if ind>=0 then
            begin
              self.AddEmpToLV(ind);
              EmployList.SaveToFile(EmpFileName);
              BaseCodeList.AddItem(EmployList.Item[ind].code,BsCode);
              BaseCodeList.SaveToFile(BaseCodeFileName);
            end else
              ShowMsg(self,'Добавление не возможно!',[msbOk]);
        end;
    end;
end;

procedure TEmployListForm.CanelBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

procedure TEmployListForm.FormActivate(Sender: TObject);
begin
  EmployListForm.Left:=0;
  EmployListForm.Top:=0;
  EmployListForm.Width:=screen.Width;
  EmployListForm.Height:=screen.Height;
end;

procedure TEmployListForm.FormResize(Sender: TObject);
begin
  if AddBtn.Visible then
    begin
      CanelBtn.Margins.Left:=10;
      AddBtn.Margins.Left:=round((BtnPanel.ClientWidth-(CanelBtn.Left+CanelBtn.Width-AddBtn.Left))/2);
    end else
    begin
      DownBtn.Margins.Left:=round((BtnPanel.ClientWidth-(CanelBtn.Left+CanelBtn.Width-DownBtn.Left))/2);
    end;
end;

procedure TEmployListForm.AddEmpToLV(ind : integer);
//Процедура добавления элемента в ListView
var
  LVI  : TListItem;
  img  : TBitMap;
begin
  LVI:=LV.Items.Add;
  LVI.Caption:=EmployList.Item[ind].name;
  if FileExists(ExePath+EmployList.ImgFolder+EmployList.Item[ind].ImgFile) then
    begin
      img:=TBitmap.Create;
      img.LoadFromFile(ExePath+EmployList.ImgFolder+EmployList.Item[ind].ImgFile);
      LVI.ImageIndex:=self.ImgLst.Add(img,nil);
      Img.Free;
    end else LVI.ImageIndex:=0;
end;

end.
