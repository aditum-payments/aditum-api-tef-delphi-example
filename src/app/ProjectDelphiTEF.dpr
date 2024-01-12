program ProjectDelphiTEF;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  UServicoTEF;

var
  ServicoTEF: TServicoTEF;
  cursor: Integer;

begin
  ServicoTEF := TServicoTEF.Create;
  try
    try
      repeat
        Writeln('');
        Writeln('Atenção ! É necessário passar ao menos uma vez pelo init assim que iniciar o programa.');
        Writeln('*---------------------------*');
        Writeln('| Bem-vindo ao TEF Aditum   |');
        Writeln('|---------------------------|');
        Writeln('| 1 - Init                  |');
        Writeln('| 2 - Cobrança              |');
        Writeln('| 3 - Confirmar             |');
        Writeln('| 4 - Cancelar              |');
        Writeln('| 5 - Reverter              |');
        Writeln('| 6 - Transações Pendentes  |');
        Writeln('| 7 - Display               |');
        Writeln('*---------------------------*');
        Readln(cursor);

        case cursor of
          1:
            ServicoTEF.init();
          2:
            ServicoTEF.payment();
          3:
            ServicoTEF.confirm();
          4:
            ServicoTEF.cancelation();
          5:
            ServicoTEF.reversal();
          6:
            ServicoTEF.getPending();
          7:
            ServicoTEF.display();
          else
            Writeln('Opção inválida');
        end;
      until False;
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;

  finally

  end;
 end.
