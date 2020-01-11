unit asanyab.zarinpal.payment;
//written by: Komail Afshar
//Copyright:2019
interface
type
  TPaymentRequest = class(TObject)
  private
    FEmail: string;
    FMobile: string;
    FMerchantID: string;
    FCallBackURL: string;
    FAuthority: string;
    FAmount: Integer;
    Fdescription: string;
    procedure Setamount(const Value: Integer);
    procedure Setauthority(const Value: string);
    procedure SetcallBackURL(const Value: string);
    procedure Setdescription(const Value: string);
    procedure Setemail(const Value: string);
    procedure SetmerchantID(const Value: string);
    procedure Setmobile(const Value: string);
  public
    property MerchantID: string read FmerchantID write SetmerchantID;
    property amount: Integer read Famount write Setamount;
    property Mobile: string read Fmobile write Setmobile;
    property Email: string read Femail write Setemail;
    property Description: string read Fdescription write Setdescription;
    property CallBackURL: string read FcallBackURL write SetcallBackURL;
    property Authority: string read Fauthority write Setauthority;
  end;
  TPaymentResult = class(TObject)
  private
    FAuthority: string;
    FStatus: Integer;
    Ferrors: string;
    procedure SetAuthority(const Value: string);
    procedure SetStatus(const Value: Integer);
    procedure Seterrors(const Value: string);
  public
    property Status: Integer read FStatus write SetStatus;
    property Authority: string read FAuthority write SetAuthority;
    property errors: string read Ferrors write Seterrors;
  end;

  TAsanyabZarinpal = class(TObject)
  private
    FPaymentRequest: TPaymentRequest;
    function StartPayment(aUrl: string; aData: string): string;
    procedure SetPaymentRequest(const Value: TPaymentRequest);
  public
    constructor Create;
    destructor Destroy; override;
    function DoPayment(aPaymentRequest: TPaymentRequest): string;
    function SendToPayment(aAuthorityCode: string): string;
    function Verification(aAuthorityCode: string): string;
    function Verification2(aAuthorityCode, aMerchantID: string; aAmount: Integer): string;

    property PaymentRequest: TPaymentRequest read FPaymentRequest write SetPaymentRequest;

  end;
implementation

{ TAsanyabZarinpal }

uses
  System.SysUtils {$IFDEF UseLogger}, LoggerManager{$ENDIF}
  , REST.Authenticator.OAuth, Rest.Client, REST.Response.Adapter, REST.Types, Rest.JSON,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.Helpers, Androidapi.JNI.Net;

constructor TAsanyabZarinpal.Create();
begin
   FPaymentRequest := TPaymentRequest.Create;

end;

destructor TAsanyabZarinpal.Destroy;
begin
  FreeAndNil(FPaymentRequest);
  inherited;
end;

function TAsanyabZarinpal.DoPayment(aPaymentRequest: TPaymentRequest): string;
var
  Url, data: string;
  status: Integer;
  authority: string;

begin
  Url := 'https://www.zarinpal.com/pg/rest/WebGate/PaymentRequest.json';
  Data := Rest.JSON.TJson.ObjectToJsonString(aPaymentRequest);
  Data := StringReplace(Data, 'email', 'Email', [rfReplaceAll,rfIgnoreCase]);
  Data := StringReplace(Data, 'mobile', 'Mobile', [rfReplaceAll,rfIgnoreCase]);
  Data := StringReplace(Data, 'merchantID', 'MerchantID', [rfReplaceAll,rfIgnoreCase]);
  Data := StringReplace(Data, 'callBackURL', 'CallbackURL', [rfReplaceAll,rfIgnoreCase]);
  Data := StringReplace(Data, 'amount', 'Amount', [rfReplaceAll,rfIgnoreCase]);
  Data := StringReplace(Data, 'description', 'Description', [rfReplaceAll,rfIgnoreCase]);

  Result := StartPayment(Url, Data);
  {
    "Status": 100,
    "Authority": "000000000000000000000000000139867871"
  }
end;

function TAsanyabZarinpal.SendToPayment(aAuthorityCode: string): string;
var
  Command: string;
  URL: string;
  Intent: JIntent;
begin
  URL := format('https://www.zarinpal.com/pg/StartPay/%s/ZarinGate', [aAuthorityCode]);
  Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW,
    TJnet_Uri.JavaClass.parse(StringToJString(URL)));
  TAndroidHelper.Activity.startActivity(Intent);
end;

procedure TAsanyabZarinpal.SetPaymentRequest(const Value: TPaymentRequest);
begin
  FPaymentRequest := Value;
end;

function TAsanyabZarinpal.StartPayment(aUrl: string; aData: string): string;
var
  OAuth1_WooCammerce: TOAuth1Authenticator;
  EndPoint: string;
  RESTClient: TRESTClient;
  RESTRequest: TRESTRequest;
  RESTResponse: TRESTResponse;
  RESTResponseDataSetAdapter: TRESTResponseDataSetAdapter;
begin
  Result := '';
  OAuth1_WooCammerce := TOAuth1Authenticator.Create(nil);
  RESTClient := TRESTClient.Create('');
  RESTRequest := TRESTRequest.Create(nil);
  RESTResponse := TRESTResponse.Create(nil);
  RESTResponseDataSetAdapter := TRESTResponseDataSetAdapter.Create(nil);
  try
    try
      EndPoint := aUrl;


      OAuth1_WooCammerce.ConsumerKey := '';
      OAuth1_WooCammerce.ConsumerSecret := '';

      OAuth1_WooCammerce.AccessTokenEndpoint := EndPoint;
      OAuth1_WooCammerce.AuthenticationEndpoint := EndPoint;
      OAuth1_WooCammerce.RequestTokenEndpoint := EndPoint;


      OAuth1_WooCammerce.AccessToken := '';
      OAuth1_WooCammerce.AccessTokenSecret := '';
      OAuth1_WooCammerce.RequestToken := '';
      OAuth1_WooCammerce.RequestTokenSecret := '';
      OAuth1_WooCammerce.VerifierPIN := '';

      /// step #1, get request-token
      RESTClient.BaseURL := OAuth1_WooCammerce.RequestTokenEndpoint;
      RESTClient.Authenticator := OAuth1_WooCammerce;

      RESTRequest.Client := RESTClient;
      RESTRequest.Response := RESTResponse;
      RESTRequest.Method := rmPOST;
      if not aData.IsEmpty then
      begin
        RESTRequest.Body.JSONWriter.WriteRaw(aData);
      end;

      RESTRequest.Execute;

      if not RESTResponse.JSONText.IsEmpty then
      begin
        //RESTResponseDataSetAdapter.StringFieldSize := 2000;
        //RESTResponseDataSetAdapter.Dataset := aDataSet;
        //RESTResponseDataSetAdapter.Response := RESTResponse;
        RESTResponseDataSetAdapter.ResponseJSON := RESTResponse;
        RESTResponseDataSetAdapter.Active := True;
        Result := RESTResponse.JSONText;
      end;

      //RESTResponseDataSetAdapter.Active := True;
      //ClientDataSet.Open;
    except
      on E: Exception do
      begin
        {$IFDEF UseLogger}
        Logger.DoLog(ltError, ClassName + '.' + MethodName, FCategory, [E.Message]);
        {$ENDIF}
        raise Exception.Create(E.Message);
      end;
    end;
  finally
    OAuth1_WooCammerce.Free;
    RESTResponseDataSetAdapter.Free;
    RESTResponse.Free;
    RESTRequest.Free;
    RESTClient.Free;
  end;

end;

function TAsanyabZarinpal.Verification(aAuthorityCode: string): string;
var
  Url, data: string;
begin
  Url := 'https://www.zarinpal.com/pg/rest/WebGate/PaymentVerification.json';
  data := '{"MerchantID":"%s", "Authority":"%s","Amount":%d}';
  data := format(data,[FPaymentRequest.MerchantID,aAuthorityCode,FPaymentRequest.Amount]);
  Result := StartPayment(Url, Data);
end;

function TAsanyabZarinpal.Verification2(aAuthorityCode, aMerchantID: string;
  aAmount: Integer): string;
var
  Url, data: string;
begin
  Url := 'https://www.zarinpal.com/pg/rest/WebGate/PaymentVerification.json';
  data := '{"MerchantID":"%s", "Authority":"%s","Amount":%d}';
  data := format(data,[aMerchantID,aAuthorityCode,aAmount]);
  Result := StartPayment(Url, Data);

end;

{ TPaymentRequest }

procedure TPaymentRequest.Setamount(const Value: Integer);
begin
  Famount := Value;
end;

procedure TPaymentRequest.Setauthority(const Value: string);
begin
  Fauthority := Value;
end;

procedure TPaymentRequest.SetcallBackURL(const Value: string);
begin
  FcallBackURL := Value;
end;

procedure TPaymentRequest.Setdescription(const Value: string);
begin
  Fdescription := Value;
end;

procedure TPaymentRequest.Setemail(const Value: string);
begin
  Femail := Value;
end;

procedure TPaymentRequest.SetmerchantID(const Value: string);
begin
  FmerchantID := Value;
end;

procedure TPaymentRequest.Setmobile(const Value: string);
begin
  Fmobile := Value;
end;

{ TPaymentResult }

procedure TPaymentResult.SetAuthority(const Value: string);
begin
  FAuthority := Value;
end;

procedure TPaymentResult.Seterrors(const Value: string);
begin
  Ferrors := Value;
end;

procedure TPaymentResult.SetStatus(const Value: Integer);
begin
  FStatus := Value;
end;

end.
