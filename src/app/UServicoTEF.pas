unit UServicoTEF;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.TypInfo,
  IdHTTP, IdURI, IdSSLOpenSSL, IdGlobalProtocols, IdHTTPHeaderInfo;


var
  SERVICE: string = 'https://localhost:4090/v1/';
  MKTOKEN: string;

type
  TServicoTEF = class
  private
    class var
      HTTPClient: TIdHTTP;
      IdSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
    class procedure InicializarHTTPClient;

  public
    class procedure init();
    class procedure payment();
    class procedure confirm();
    class procedure cancelation();
    class procedure reversal();
    class procedure getPending();
    class procedure display();
    class function ExtractStatusFromResponse(const Response: string): string;
  end;

implementation

{ Inicializar }

class procedure TServicoTEF.InicializarHTTPClient;
begin
  try
    // Inicializando componentes necess�rios
    HTTPClient := TIdHTTP.Create;
    HTTPClient.AllowCookies := False;
    HTTPClient.HandleRedirects := True;

    // Configurando SSL
    HTTPClient.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
    TIdSSLIOHandlerSocketOpenSSL(HTTPClient.IOHandler).SSLOptions.SSLVersions := [sslvTLSv1_2];

    // Desabilitando a verifica��o de certificado (usado para fins de teste, n�o recomendado em produ��o)
    TIdSSLIOHandlerSocketOpenSSL(HTTPClient.IOHandler).SSLOptions.VerifyMode := [];

  except
    on E: Exception do
      Writeln('Erro ao inicializar o cliente HTTP: ' + E.Message);
  end;
end;

{ Extract Status }

class function TServicoTEF.ExtractStatusFromResponse(const Response: string): string;
var
  JSONValue: TJSONValue;
  JSONObject: TJSONObject;
begin
  Result := 'Undefined';

  JSONValue := TJSONObject.ParseJSONValue(Response);

  if Assigned(JSONValue) and (JSONValue is TJSONObject) then
  begin
    JSONObject := JSONValue as TJSONObject;

    if JSONObject.TryGetValue<string>('status', Result) then
      Exit; // Retorna imediatamente se 'status' for encontrado
  end;

  // Se chegou at� aqui, significa que 'status' n�o foi encontrado
  Result := 'Undefined';
end;

{ Servi�o TEF }

class procedure TServicoTEF.init();
var
  PostData: TStringStream;
  URL: string;
  Response: string;
  JsonData: UnicodeString;
  activationCode: string;
begin
  InicializarHTTPClient; // Inicialize o cliente HTTP antes de fazer a requisi��o
  try
    try
      Writeln('Digite o merchantToken do estabelecimento que deseja ativar: ');
      Readln(MKTOKEN);

      Writeln('Digite o c�digo de ativa��o do estabelecimento: (9 dig�tos)');
      Readln(activationCode);

      // Corpo da requisi��o POST
      JsonData := '{"applicationName": "MyApplication", "applicationVersion": "1.0.0", ' +
            '"activationCode": "' + activationCode + '", "contactless": true, ' +
            '"pinpadMessages": {"approvedMessage": "Aprovado", "declinedMessage": "Negado", ' +
            '"initializationMessage": "Iniciando...", "processingMessage": "Enviando..."} }';

      // Gerando TString para requisi��o POST
      PostData := TStringStream.Create(JsonData, TEncoding.UTF8);

      // Configurando URL para requisi��o
      URL := 'pinpad/init';
      URL := SERVICE + URL;

      // Adicionando o cabe�alho de autoriza��o � solicita��o
      HTTPClient.Request.CustomHeaders.Add('Authorization: ' + MKTOKEN);

      // Executando requisi��o POST
      Response := HTTPClient.Post(URL, PostData);

      // Exibindo a resposta no console Delphi
      WriteLn('Resposta da requisi��o POST:');
      WriteLn(Response);
    except
      on E: Exception do
        WriteLn('Erro durante a requisi��o POST: ' + E.Message);
    end;
  finally
    FreeAndNil(PostData); // Certifique-se de liberar o recurso
    FreeAndNil(HTTPClient); // Certifique-se de liberar o recurso
  end;
end;

class procedure TServicoTEF.payment();
var
  PostData: TStringStream;
  URL: string;
  Response: string;
  status: string;
  JsonData: string;
  paymentTypeUser: string;
  amountUser: Integer;
  cursorPaymentType: Integer;
begin
  InicializarHTTPClient; // Inicialize o cliente HTTP antes de fazer a requisi��o
  status := ''; // Inicialize a vari�vel antes de us�-la
    try
      Writeln('Digite o valor de pagamento sem ponto ou virgula, exemplo : (para 10,00R$) DIGITE => 1000');
      Readln(amountUser);

      Writeln('\n*-----------------------------------*');
      Writeln('| Selecione o m�todo de pagamento   |');
      Writeln('|-----------------------------------|');
      Writeln('| 1 - D�BITO                        |');
      Writeln('| 2 - CR�DITO                       |');
      Writeln('*-----------------------------------*');

      Readln(cursorPaymentType);

      case cursorPaymentType of
        1: paymentTypeUser := 'Debit';
        2: paymentTypeUser := 'Credit';
        else
          Writeln('Op��o Inv�lida!');
          paymentTypeUser := 'Undefined';
      end;

    repeat
      // Corpo da requisi��o POST
      JsonData := Format('{"amount": %d, "paymentType": "%s", "installmentType": "None"}',
        [amountUser, paymentTypeUser]);

      // Gerando TString para requisi��o POST
      PostData := TStringStream.Create(JsonData, TEncoding.UTF8);

      // Configurando URL para requisi��o
      URL := 'charge/authorization';
      URL := SERVICE + URL;

      HTTPClient.Request.CustomHeaders.Add('Authorization: ' + MKTOKEN);

      Response := HTTPClient.Post(URL, PostData);

      status := TServicoTEF.ExtractStatusFromResponse(Response);

      if status = 'FINISHED' then
      begin
        Writeln('Status extra�do da resposta JSON: ', status);
        Writeln('');
        WriteLn('Resposta da requisi��o POST:');
        WriteLn(Response);
      end;

    until (status = 'STARTING_PAYMENT') or
          (status = 'CHECK_CARD_EVENT') or
          (status = 'PROCESSING_ONLINE') or
          (status = 'SENDING_TRANSACTION');
    except
      on E: Exception do
        WriteLn('Erro durante a requisi��o POST: ' + E.Message);
    end;
end;

class procedure TServicoTEF.confirm();
var
  response: string;
  URL: string;
  NSU: string;
begin
  InicializarHTTPClient; // Inicialize o cliente HTTP antes de fazer a requisi��o
      try
      Writeln('Digite o c�digo NSU da transa��o que deseja confirmar (9 dig�tos): ');
      Readln(NSU);

      // Adicionando o cabe�alho de autoriza��o � solicita��o
      HTTPClient.Request.CustomHeaders.Add('Authorization: ' + MKTOKEN);

      URL := 'charge/confirmation?nsu=';
      URL := SERVICE + URL + NSU;

      Response := HTTPClient.Get(URL);

      // Exibindo a resposta no console Delphi
      WriteLn('Resposta da requisi��o GET:');
      WriteLn(Response);
    except
      on E: Exception do
        WriteLn('Erro durante a requisi��o GET: ' + E.Message);
    end;
  end;

class procedure TServicoTEF.cancelation();
var
  response: string;
  URL: string;
  NSU: string;
begin
  InicializarHTTPClient; // Inicialize o cliente HTTP antes de fazer a requisi��o
    try
      Writeln('Digite o c�digo NSU da transa��o que deseja cancelar (9 dig�tos): ');
      Readln(NSU);

      // Adicionando o cabe�alho de autoriza��o � solicita��o
      HTTPClient.Request.CustomHeaders.Add('Authorization: ' + MKTOKEN);

      URL := 'charge/cancelation?nsu=';
      URL := SERVICE + URL + NSU;

      Response := HTTPClient.Get(URL);

      // Exibindo a resposta no console Delphi
      WriteLn('Resposta da requisi��o GET:');
      WriteLn(Response);
    except
      on E: Exception do
        WriteLn('Erro durante a requisi��o GET: ' + E.Message);
    end;
  end;

class procedure TServicoTEF.reversal();
var
  response: string;
  URL: string;
  NSU: string;
begin
  InicializarHTTPClient; // Inicialize o cliente HTTP antes de fazer a requisi��o
    try
      Writeln('Digite o c�digo NSU da transa��o que deseja reverter (9 dig�tos): ');
      Readln(NSU);

      // Adicionando o cabe�alho de autoriza��o � solicita��o
      HTTPClient.Request.CustomHeaders.Add('Authorization: ' + MKTOKEN);

      URL := 'charge/reversal?nsu=';
      URL := SERVICE + URL + NSU;

      Response := HTTPClient.Get(URL);

      // Exibindo a resposta no console Delphi
      WriteLn('Resposta da requisi��o GET:');
      WriteLn(Response);
    except
      on E: Exception do
        WriteLn('Erro durante a requisi��o GET: ' + E.Message);
    end;
  end;

class procedure TServicoTEF.getPending();
var
  response: string;
  URL: string;
begin
  InicializarHTTPClient; // Inicialize o cliente HTTP antes de fazer a requisi��o
    try
      // Adicionando o cabe�alho de autoriza��o � solicita��o
      HTTPClient.Request.CustomHeaders.Add('Authorization: ' + MKTOKEN);

      URL := 'charge/pending';
      URL := SERVICE + URL;

      Response := HTTPClient.Get(URL);

      // Exibindo a resposta no console Delphi
      WriteLn('Resposta da requisi��o GET:');
      WriteLn(Response);
    except
      on E: Exception do
        WriteLn('Erro durante a requisi��o GET: ' + E.Message);
    end;
  end;

class procedure TServicoTEF.display();
var
  response: string;
  URL: string;
  DISPLAY: string;
begin
  InicializarHTTPClient; // Inicialize o cliente HTTP antes de fazer a requisi��o
    try
      Writeln('Digite a mesagem que deseja exibir no Pinpad (at� 32 caracteres): ');
      Readln(DISPLAY);

      // Adicionando o cabe�alho de autoriza��o � solicita��o
      HTTPClient.Request.CustomHeaders.Add('Authorization: ' + MKTOKEN);

      URL := 'pinpad/display?message=';
      URL := TIdURI.URLEncode(SERVICE + URL + DISPLAY);

      Response := HTTPClient.Get(URL);

      // Exibindo a resposta no console Delphi
      WriteLn('Resposta da requisi��o GET:');
      WriteLn(Response);
    except
      on E: Exception do
        WriteLn('Erro durante a requisi��o GET: ' + E.Message);
    end;
  end;

end.

