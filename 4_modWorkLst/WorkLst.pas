unit WorkLst;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Tabs, StdCtrls, ComCtrls, ToolWin, ImgList, Buttons,
  ButtonGroup;

type
  TWorkListForm = class(TForm)
    MainPanel: TPanel;
    Label1: TLabel;
    ImgLst: TImageList;
    LV: TListView;
    BtnPanel: TPanel;
    AddBtn: TSpeedButton;
    CanelBtn: TSpeedButton;
    DownBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    Panel1: TPanel;
    BtnDownBtn: TSpeedButton;
    BtnUpBtn: TSpeedButton;
    BtnSB: TScrollBox;
    GrLB: TLabel;
    AllGroupBtn: TSpeedButton;
    LoadBtn: TSpeedButton;
    procedure BtnDownBtnClick(Sender: TObject);
    procedure DownBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure LVClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    procedure AddWorkToLV(ind : integer);
    procedure UpdateBtnLst(newbtn:string);
    procedure UpdateLV(group:string);
    procedure CatBtnDown(sender:TObject);
    procedure LoadBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetWorkListItem(var ind : integer):boolean;

implementation

{$R *.dfm}

uses GlobalUnit, WorkData, Keyboard, MsgForm, ShadowForm, WorkDtForm;

const
  AllGroupCaption = 'Все группы';

var
  WorkListForm : TWorkListForm;
  CurGroup     : string;

function GetWorkListItem(var ind : integer):boolean;
begin
  WorkListForm:=TWorkListForm.Create(application);
  WorkListForm.AddBtn.Visible:=(Acsses<=alForeman);
  WorkListForm.AllGroupBtn.Caption:=AllGroupCaption;
  WorkListForm.UpdateBtnLst('');
  WorkListForm.UpdateLV('');
  if (WorkListForm.ShowModal=mrOK)and(WorkListForm.LV.Selected<>nil) then
    begin
      ind:=WorkList.IndFromName(WorkListForm.LV.Selected.Caption);
      result:=true;
    end else result:=false;
  WorkListForm.Free;
end;

procedure TWorkListForm.CatBtnDown(sender:TObject);
var
  str : string;
begin
  str:=(sender as TSpeedButton).Caption;
  while(pos(chr(13),str)<>0)do str[pos(chr(13),str)]:=' ';
  if str=AllGroupCaption then WorkListForm.UpdateLV('') else WorkListForm.UpdateLV(str);
end;


procedure TWorkListForm.UpdateBtnLst(newbtn:string);
var
  i       : integer;
  Folders : TStringList;
  Bt      : TSpeedButton;

procedure CreateBtn(cap:string);
begin
  bt:=TSpeedButton.Create(BtnSB);
  bt.Align:=alTop;
  bt.Height:=80;
  while(pos(' ',cap)<>0)do cap[pos(' ',cap)]:=chr(13);
  bt.Caption:=cap;
  bt.AlignWithMargins:=true;
  bt.Font.Style:=[fsBold];
  bt.Font.Size:=10;
  bt.OnClick:=self.CatBtnDown;
  //bt.Name:='bt'+inttostr(ind);
  BtnSB.InsertControl(bt);
end;

begin
  Folders:=TStringList.Create;
  WorkList.GetFolderList(Folders);
  Folders.Sort;
  if Length(newbtn)=0 then
    begin
      while BtnSB.ControlCount>0 do BtnSB.Controls[0].Free;
      for I := 0 to Folders.Count - 1 do
        if length(folders[i])>0 then CreateBtn(Folders[i]);
    end else
    begin
      while(pos(' ',newbtn)<>0)do newbtn[pos(' ',newbtn)]:=chr(13);
      i:=0;
      while(i<BtnSB.ControlCount)and(newbtn<>(BtnSB.Controls[i] as TSpeedButton).Caption)do inc(i);
      if(i=BtnSB.ControlCount)then CreateBtn(newbtn);
    end;
  Folders.Free;
  BtnSB.Realign;
  BTNSB.Repaint;
end;

procedure TWorkListForm.UpdateLV(group:string);
var
  i       : integer;
begin
  CurGroup:=group;
  if Length(group)=0 then GrLb.Caption:=AllGroupCaption else GrLB.Caption:=group;
  WorkListForm.LV.Clear;
  for I := 0 to WorkList.Count - 1 do
    if (WorkList.Item[i].folder=group)or(Length(group)=0) then
      WorkListForm.AddWorkToLV(i);
end;

procedure TWorkListForm.LoadBtnClick(Sender: TObject);
var
  newname   : string;
  item      : TWork;
  ind,ps,k  : integer;
  strlst    : TstringList;
  str,val   : string;
begin
  if FileExists(ExtractFilePath(application.ExeName)+'worklist.txt') then begin
    strlst:=TstringList.Create;
    strlst.LoadFromFile(ExtractFilePath(application.ExeName)+'worklist.txt');
    for ind:=0 to strlst.Count - 1 do begin
      str:=strlst[ind];
      ps:=pos(chr(9),str);
      k:=1;
      while ps>0 do begin
        val:=copy(str,1,ps-1);
        delete(str,1,ps);
        case k of
          1 : item.name:=val;
          2 : item.code:=val;
          3 : item.folder:=val;
          4 : item.Group:=(val='TRUE');
          5 : item.Night:=(val='TRUE');
          6 : item.NSpay:=(val='TRUE');
          7 : item.TmPay:=(val='TRUE');
          8 : item.PayRoll:=StrToFloat(val);
          9 : item.Norm:=StrToInt(val);
          10 : item.item.code:=val;
          11 : item.item.name:=val;
          12 : item.item.time:=StrToInt(val);
          13 : item.item.ImgFile:=val;
        end;
        inc(k);
        ps:=pos(chr(9),str);
      end;
      item.ImgFile:=val;
      if WorkList.AddItem(item)<0 then ShowMsg(self,'Элемент с таким кодом '+item.code+' уже существует. Добавление не возможно!',[msbOk]);
    end;
    strlst.Free;
    MsgForm.ShowMSG(self,'Загрузка завершена !',[msbOK]);
    WorkList.SaveToFile(WorkFileName);
    self.UpdateBtnLst('');
    self.UpdateLV(item.folder);
  end else MsgForm.ShowMSG(self,'Файл worklist.txt не найден !',[msbOK]);
end;

procedure TWorkListForm.LVClick(Sender: TObject);
var
  ind   : integer;
  pind  : integer;
  Work  : TWork;
  img   : TBitMap;
begin
  if LV.Selected=nil then Exit;
  //Для уровня достпа нач цеха и выше предлагаем выбор действий
  //для низших уровней доступа - срсазу выбираем элемент
  if Acsses<=alForeman then
    ind:=ShowMsg(self,LV.Selected.Caption,[msbOK,msbEdit,msbDel,msbCancel])
  else ind:=msbOk;
  if ind=msbOK then self.ModalResult:=mrOK;
  if ind=msbDel then
    begin
      if ShowMsg(self,'Сведения о ставке '+ LV.Selected.Caption+chr(13)+
        'будут удалены безвозвратно !',[msbOK,msbCancel])=msbOK then
      begin
        pind:=WorkList.IndFromName(LV.Selected.Caption);
        WorkList.Delete(pind);
        WorkList.SaveToFile(WorkFileName);
        LV.Items.Delete(LV.Selected.Index);
        self.UpdateBtnLst('');
      end;
    end;
  if ind=msbEdit then
    begin
      pind:=WorkList.IndFromName(LV.Selected.Caption);
      Work:=WorkList.Item[pind];
      if WorkForm.ShowWindow(self,Work) then
        begin
          self.UpdateBtnLst(Work.folder);
          WorkList.Item[pind]:=Work;
          WorkList.SaveToFile(WorkFileName);
          if (Work.folder=CurGroup)or(Length(CurGroup)=0) then
            begin
              LV.Selected.Caption:=Work.name;
              if FileExists(ExePath+WorkList.ImgFolder+Work.ImgFile) then
                begin
                  img:=TBitmap.Create;
                  img.LoadFromFile(ExePath+WorkList.ImgFolder+Work.ImgFile);
                  LV.Selected.ImageIndex:=self.ImgLst.Add(img,nil);
                end;
            end else
            begin
              self.UpdateBtnLst(work.folder);
              self.UpdateLV(work.folder);
            end;
        end;
    end;
end;

procedure TWorkListForm.AddBtnClick(Sender: TObject);
var
  newname : string;
  item    : TWork;
  ind     : integer;
begin
  newname:='';
  if KeyBoardForm.GetString(self,newname,true) then
    begin
      item.name:=newname;
      item.code:='';
      item.folder:='';
      item.Group:=false;
      item.Night:=false;
      item.NSpay:=false;
      item.TmPay:=false;
      item.PayRoll:=0;
      item.Norm:=0;
      item.item.code:='';
      item.item.name:='неизвестно';
      item.item.time:=0;
      item.item.ImgFile:='';
      item.ImgFile:='';
      if WorkForm.ShowWindow(self,item) then
        begin
          ind:=WorkList.AddItem(item);
          if ind>=0 then
            begin
              WorkList.SaveToFile(WorkFileName);
              self.UpdateBtnLst('');
              if (item.folder=CurGroup)or(Length(CurGroup)=0) then self.AddWorkToLV(ind)
                else self.UpdateLV(item.folder);
            end else
              ShowMsg(self,'Элемент с таким кодом 1С уже существует. Добавление не возможно!',[msbOk]);
        end;
    end;
end;

procedure TWorkListForm.CanelBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

procedure TWorkListForm.DownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')then LV.Scroll(0,ScrollSpeed);
  if ((Sender as TSpeedButton).name='UpBtn')then LV.Scroll(0,-ScrollSpeed);
end;

procedure TWorkListForm.FormActivate(Sender: TObject);
begin
  WorkListForm.Left:=0;
  WorkListForm.Top:=0;
  WorkListForm.Width:=screen.Width;
  WorkListForm.Height:=screen.Height;
end;

procedure TWorkListForm.FormResize(Sender: TObject);
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

procedure TWorkListForm.AddWorkToLV(ind : integer);
//Процедура добавления элемента в ListView
var
  LVI  : TListItem;
  img  : TBitMap;
begin
  LVI:=LV.Items.Add;
  LVI.Caption:=WorkList.Item[ind].name;
  if FileExists(ExePath+WorkList.ImgFolder+WorkList.Item[ind].ImgFile) then
    begin
      img:=TBitmap.Create;
      img.LoadFromFile(ExePath+WorkList.ImgFolder+WorkList.Item[ind].ImgFile);
      LVI.ImageIndex:=self.ImgLst.Add(img,nil);
      Img.Free;
    end else LVI.ImageIndex:=0;
end;

procedure TWorkListForm.BtnDownBtnClick(Sender: TObject);
begin
  if (Sender as TSpeedButton).Name='BtnDownBtn' then
    BtnSB.VertScrollBar.Position:=BtnSB.VertScrollBar.Position+ScrollSpeed;
  if (Sender as TSpeedButton).Name='BtnUpBtn' then
    BtnSB.VertScrollBar.Position:=BtnSB.VertScrollBar.Position-ScrollSpeed;
end;

end.
