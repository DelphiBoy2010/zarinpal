unit MainForm;
 {Version 4}
interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, asanyab.zarinpal.payment,
  FMX.ScrollBox, FMX.Memo, System.Messaging, Androidapi.JNI.GraphicsContentViewText
  ,FMX.Platform, FMX.Platform.Android, FMX.Edit;

type

  TfrmMain = class(TForm)
    Label1: TLabel;
    btnPay: TButton;
    Layout1: TLayout;
    Layout2: TLayout;
    Memo1: TMemo;
    edtMerchantID: TEdit;
    Layout3: TLayout;
    edtEmail: TEdit;
    Layout4: TLayout;
    edtCellphone: TEdit;
    Layout5: TLayout;
    edtAmount: TEdit;
    Layout6: TLayout;
    edtDescription: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPayClick(Sender: TObject);
  private
    { Private declarations }
    AsanyabZarinpal: TAsanyabZarinpal;
    function HandleIntentAction(const aIntent: JIntent): Boolean;
    procedure CheckResult(aData: string);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}
uses
  Rest.JSON, Androidapi.JNI.Net, Androidapi.JNI.Widget,
  FMX.Helpers.Android,Androidapi.JNI.Os,
  Androidapi.JNI.JavaTypes, Androidapi.Helpers, Androidapi.JNI.App;

procedure TfrmMain.btnPayClick(Sender: TObject);
var
  Res: string;
  paymentResult: TPaymentResult;
  authority: string;
  URL: string;
  Intent: JIntent;
begin
  AsanyabZarinpal.PaymentRequest.merchantID := edtMerchantID.Text;
  AsanyabZarinpal.PaymentRequest.amount := edtAmount.Text.ToInteger;
  AsanyabZarinpal.PaymentRequest.mobile := edtCellphone.Text;
  AsanyabZarinpal.PaymentRequest.email := edtEmail.Text;
  AsanyabZarinpal.PaymentRequest.description := edtDescription.Text;
  AsanyabZarinpal.PaymentRequest.callBackURL := 'return://zarinpalpayment';
  AsanyabZarinpal.PaymentRequest.authority := '';
  Res := AsanyabZarinpal.DoPayment(AsanyabZarinpal.PaymentRequest);
  paymentResult := Rest.JSON.TJson.JsonToObject<TPaymentResult>(Res);
  if paymentResult.Status = 100 then
  begin
    //درخواست موفق
    authority := paymentResult.Authority;
    URL := format('https://www.zarinpal.com/pg/StartPay/%s/ZarinGate', [authority]);
    Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW,
      TJnet_Uri.JavaClass.parse(StringToJString(URL)));
    TAndroidHelper.Activity.startActivity(Intent);
  end
  else
  begin
    //خطا
    Memo1.Lines.Add('خطا');
  end;
end;

procedure TfrmMain.CheckResult(aData: string);
var
  authority: string;
  status: string;
  Pos1,Pos2: Integer;
  Res: string;
  intAuthority: Integer;
begin
  Pos1 := aData.IndexOf('Authority=');
  Pos2 := aData.IndexOf('Status=');
  pos1 := Pos1 + 10;
  authority := aData.Substring(Pos1, Pos2-Pos1);
  authority := StringReplace(authority, '&', '', [rfReplaceAll,rfIgnoreCase]);

  pos1 := pos2;
  pos1 := pos1 + 7;
  status := aData.Substring(Pos1, 10);
  if status = 'OK' then
  begin
    //پرداخت موفقیت آمیز
    Res := AsanyabZarinpal.Verification(authority);
    TThread.Synchronize(TThread.CurrentThread,
    procedure
    begin
      Memo1.Lines.Add(Res);
      //ShowMessage('پرداخت موفق');
      Memo1.Lines.Add('پرداخت موفق');
      //Do your action here....
    end);
  end
  else
  begin
    //NOK
    //    پرداخت ناموفق
    Memo1.Lines.Add('پرداخت ناموفق');
    //ShowMessage('پرداخت ناموفق');
  end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AsanyabZarinpal := TAsanyabZarinpal.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(AsanyabZarinpal);
end;

function TfrmMain.HandleIntentAction(const aIntent: JIntent): Boolean;
var
  data: Jnet_Uri;
begin
  Result := False;
  if aIntent <> nil then
  begin
    data := aIntent.getData;
    if data <> nil then
    begin
      CheckResult(JStringToString(data.toString));
    end;
    Invalidate;
  end;

end;
procedure OnNewIntent(const Sender: TObject; const M: TMessage);
var
  n: JIntent;
  u: Jnet_Uri;
begin
  if M is TMessageReceivedNotification then
  begin
    TAndroidHelper.Activity.setIntent(TMessageReceivedNotification(M).Value);
    n := TAndroidHelper.Activity.getIntent;
    u := n.getData;
    frmMain.HandleIntentAction(n)
  end;
end;

procedure RegisterOnNewIntent();
begin
  MainActivity.registerIntentAction(TJIntent.JavaClass.ACTION_VIEW);
  TMessageManager.DefaultManager.SubscribeToMessage
    (TMessageReceivedNotification, OnNewIntent);
end;

initialization
RegisterOnNewIntent();

end.
