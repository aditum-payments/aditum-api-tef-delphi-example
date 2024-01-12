# Example-Delphi-API-TEF

Este é um projeto para exemplo de integração com a API REST TEF da Aditum feito em Pascal (Delphi). Ele demonstra como integrar e utilizar as funcionalidades do TEF em um ambiente de automação Delphi.

### Funções disponíveis neste projeto:

- `init`: Para inicializar o PinPad com nosso Gerenciador padrão.
- `payment`: Realizar um pagamento.
- `Confirm`: Confirmar uma transação.
- `Cancelation`: Cancelar uma transação.
- `Reversal`: Reverter uma transação (Que esteja como Pendente).
- `GetPeding`: Buscar transações pendentes.
- `Display`: Disparar uma mensagem para o PinPad (com até 32 caracteres).

### Estrutura do Projeto

- `app/`: Arquivos pascal (.pas) e arquivos de projeto como (.dproj/.dpr).
    - `Win32/Debug/`: Arquivos executáveis do projeto, arquivos dcu e dlls. 
- `lib/`: Contém todos arquivos de bibliotecas externas utilizadas no projeto.

## Executar o Programa

Para executar o programa, basta acessar o caminho : 
```
src/app/Win32/Debug/ProjectDelphiTEF.exe
```
E executar o programa ele será iniciado.
### Atenção

- Sempre que o projeto for executado é necessário passar pelo init
antes das outras funções, para que a autenticação da API seja realizada ao menos
uma vez.


