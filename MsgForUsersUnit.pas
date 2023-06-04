unit MsgForUsersUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, StdCtrls, ComCtrls;

type
  TMsgForUsersForm = class(TForm)
    BtnPn: TPanel;
    CloseBtn: TSpeedButton;
    DownBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    PrintBtn: TSpeedButton;
    Bevel1: TBevel;
    Bevel2: TBevel;
    CapLB: TLabel;
    SB: TScrollBox;
    procedure FormActivate(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure DownBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure ShowUserMessages(code:string);
function  SaveUserMessage(code,autorname,autorcode,msg:string):boolean;

implementation

{$R *.dfm}

uses GlobalUnit, EmployData, ShadowForm, MailUnit;

var
  fname : string;
  Strs  : TStringList;

procedure ShowUserMessages(code:string);
var
  form : TMsgForUsersForm;
  Str  : TStringList;
  LB1  : TLabel;
  Memo : TLabel;
  s1,s : string;
  i    : integer;
  PN   : TPanel;
begin
  fname:=ExePath+UserMsgFolder+code+'.txt';
  if FileExists(fname) then
    begin
      Str:=TStringList.Create;
      str.LoadFromFile(fname);
      if str.Count>0 then
        begin
          Form:=TMsgForUsersForm.Create(application);
          with Form do
            begin
              CapLB.Caption:=EmployList.ShortName(EmployList.NameFromCode(code));
              CapLB.Caption:=CapLB.Caption+chr(13)+'для вас есть сообщения:';
              //
              while SB.ControlCount>0 do SB.Controls[0].Free;
              Strs:=TstringList.Create;
              i := 0;
              while(i<str.Count) do
                begin
                  s1:=str[i];
                  inc(i);
                  s:='';
                  while(i<str.Count)and(Length(str[i])>0)do
                    begin
                      s:=s+str[i]+' ';
                      inc(i);
                    end;
                  inc(i);
                  if (Length(s1)+Length(s))>0 then
                    begin
                      PN:=TPanel.Create(SB);
                      PN.Align:=alTop;
                      PN.BorderStyle:=bsNone;
                      PN.BevelKind:=bkFlat;
                      PN.AlignWithMargins:=true;
                      PN.Name:='PN'+IntTOStr(SB.ControlCount+1);;
                      PN.AutoSize:=true;
                      PN.Color:=clCream;
                      PN.Caption:='';
                      //первая строчка
                      LB1:=TLabel.Create(PN);
                      LB1.Name:=PN.Name+'LB1';
                      LB1.Caption:=s1;
                      LB1.Align:=alTop;
                      LB1.AlignWithMargins:=true;
                      LB1.Margins.Bottom:=0;
                      LB1.Font.Size:=10;
                      LB1.Font.Style:=[fsBold];
                      PN.InsertControl(LB1);
                      //остальной текст
                      Memo:=TLabel.Create(PN);
                      Memo.Name:=PN.Name+'Memo';
                      Memo.AutoSize:=true;
                      Memo.Align:=alTop;
                      Memo.AlignWithMargins:=true;
                      Memo.Font.Size:=10;
                      Memo.Font.Style:=[];
                      PN.InsertControl(Memo);
                      Memo.WordWrap:=true;
                      //Приходистя записывать текст в отдельный список
                      //что бы при показе формы правильно отображался
                      //размер панелей
                      Strs.Add(s);
                      //
                      SB.InsertControl(PN);
                    end;
                end;
              PrintBtn.Margins.Left:=round((BtnPn.ClientWidth-(CloseBtn.Left+CloseBtn.Width-
              PrintBtn.Left))/2);
              ShadowShow(Form);
              Form.ShowModal;
              ShadowHide(Form);
            end;
          Form.Free;
        end;
      str.Free;
    end;
end;

function SaveUserMessage(code,autorname,autorcode,msg:string):boolean;
var
  fname : string;
  Strs  : TStringList;
  s     : string;
begin
  result:=false;
  if code<>autorcode then //нельзя отправлять сообщения самому себе
    begin
      try
      fname:=ExePath+UserMsgFolder+code+'.txt';
      Strs:=TStringList.Create;
      if FileExists(fname) then Strs.LoadFromFile(fname);
      s:=FormatDateTime('dd mmm yyyy (ddd) hh:mm',now);
      s:=s+' '+autorname;
      Strs.Add(s);
      Strs.Add(msg);
      Strs.Add('');
      Strs.SaveToFile(fname);
      Strs.Free;
      //отправка почтой
      SendUserMsg(autorname,code,msg);
      result:=true;
      finally
      //
      end;
    end;
end;

procedure TMsgForUsersForm.CloseBtnClick(Sender: TObject);
begin
  if FileExists(fname) then
    begin
      DeleteFile(fname);
      self.Close
    end;
end;

procedure TMsgForUsersForm.DownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')then
    SB.VertScrollBar.Position:=SB.VertScrollBar.Position+ScrollSpeed;
  if ((Sender as TSpeedButton).name='UpBtn')then
    SB.VertScrollBar.Position:=SB.VertScrollBar.Position-ScrollSpeed;
end;

procedure TMsgForUsersForm.FormActivate(Sender: TObject);
var
  i  : integer;
begin
  for I := 0 to SB.ControlCount - 1 do
    ((SB.Controls[i] as TPanel).FindComponent('PN'+IntToStr(i+1)+'Memo') as TLabel).Caption:=Strs[i];
end;

end.
