SESSION:DATE-FORMAT = "dmy".

DEFINE VARIABLE cArq AS CHARACTER NO-UNDO.

DEFINE BUFFER bClientes  FOR Clientes.
DEFINE BUFFER bPedidos   FOR Pedidos.
DEFINE BUFFER bCidades   FOR Cidades.
DEFINE BUFFER bItens     FOR Itens.
DEFINE BUFFER bProdutos  FOR Produtos.


DEFINE BUTTON bt-cidades     LABEL "Cidades".
DEFINE BUTTON bt-produtos    LABEL "Produtos".
DEFINE BUTTON bt-clientes    LABEL "Clientes".
DEFINE BUTTON bt-pedidos     LABEL "Pedidos".
DEFINE BUTTON bt-sair        LABEL "Sair".
DEFINE BUTTON bt-relClientes LABEL "Relatório de Clientes".
DEFINE BUTTON bt-relPedidos  LABEL "Relatório de Pedidos".


DEFINE FRAME fMenu
    bt-cidades     AT ROW 3 COL 2
    bt-produtos    AT ROW 3 COL 18
    bt-clientes    AT ROW 3 COL 34
    bt-pedidos     AT ROW 3 COL 50
    bt-sair        AT ROW 3 COL 66
    bt-relClientes AT ROW 5 COL 10
    bt-relPedidos  AT ROW 5 COL 46
    WITH VIEW-AS DIALOG-BOX TITLE "Hamburgueria XTudo" 
         SIZE 80 BY 10 CENTERED.


ON CHOOSE OF bt-cidades DO:
    RUN cidades.p NO-ERROR.
END.

ON CHOOSE OF bt-produtos DO:
    RUN produtos.p NO-ERROR.
END.

ON CHOOSE OF bt-clientes DO:
    RUN clientes.p NO-ERROR.
END.

ON CHOOSE OF bt-pedidos DO:
    RUN pedidos.p NO-ERROR.
END.


ON CHOOSE OF bt-relClientes DO:
    ASSIGN cArq = SESSION:TEMP-DIRECTORY + "clientes.txt".
    OUTPUT TO VALUE(cArq) PAGE-SIZE 60 PAGED.

    PUT UNFORMATTED 
        "Relatório de Clientes" SKIP
        STRING(TODAY, "99/99/9999") SKIP(2).

    PUT UNFORMATTED 
        FILL("-", 120) SKIP
        "Cod"        FORMAT "x(4)"  SPACE(2)
        "Nome"       FORMAT "x(25)" SPACE(2)
        "Endereco"   FORMAT "x(30)" SPACE(2)
        "Cidade"     FORMAT "x(20)" SPACE(2)
        "Observacao" FORMAT "x(30)" SKIP
        FILL("-", 120) SKIP.

    FOR EACH bClientes NO-LOCK BY bClientes.CodCliente:
        FIND FIRST bCidades WHERE bCidades.CodCidade = bClientes.CodCidade NO-LOCK NO-ERROR.

        PUT UNFORMATTED
            STRING(bClientes.CodCliente, "9999") FORMAT "x(4)" SPACE(2)
            TRIM(bClientes.NomCliente) FORMAT "x(25)" SPACE(2)
            TRIM(bClientes.Endereco) FORMAT "x(30)" SPACE(2)
            (IF AVAILABLE bCidades THEN TRIM(bCidades.NomCidade) ELSE "?") FORMAT "x(20)" SPACE(2)
            TRIM(bClientes.Observacao) FORMAT "x(30)" SKIP.
    END.

    OUTPUT CLOSE.
    OS-COMMAND NO-WAIT VALUE(cArq).
END.



ON CHOOSE OF bt-relPedidos DO:
    ASSIGN cArq = SESSION:TEMP-DIRECTORY + "pedidos.txt".
    OUTPUT TO VALUE(cArq) PAGE-SIZE 60 PAGED.

    PUT UNFORMATTED
        "Relatório de Pedidos" SKIP
        STRING(TODAY, "99/99/9999") SKIP(2).

    FOR EACH bPedidos NO-LOCK BY bPedidos.CodPedido:
        FIND FIRST bClientes WHERE bClientes.CodCliente = bPedidos.CodCliente NO-LOCK NO-ERROR.
        FIND FIRST bCidades WHERE bCidades.CodCidade = bClientes.CodCidade NO-LOCK NO-ERROR.

        PUT UNFORMATTED
            FILL("-", 100) SKIP
            "Pedido nº: " STRING(bPedidos.CodPedido, "9999") SPACE(5)
            "Data: " STRING(bPedidos.DatPedido, "99/99/9999") SKIP
            "Cliente: " STRING(bClientes.CodCliente, "9999") + " - " + TRIM(bClientes.NomCliente) SKIP
            "Endereço: " TRIM(bClientes.Endereco) + " - " +
            (IF AVAILABLE bCidades THEN TRIM(bCidades.NomCidade) + " - " + bCidades.CodUF ELSE "?") SKIP
            "Observação: " TRIM(bPedidos.Observacao) SKIP(1).

        PUT UNFORMATTED
            "  Cod  Produto                        Quantidade   Valor Total" SKIP
            "  ---- ----------------------------   ----------   ------------" SKIP.

        DEFINE VARIABLE iTotal AS DECIMAL NO-UNDO.
        iTotal = 0.

        FOR EACH bItens WHERE bItens.CodPedido = bPedidos.CodPedido NO-LOCK:
            FIND FIRST bProdutos WHERE bProdutos.CodProduto = bItens.CodProduto NO-LOCK NO-ERROR.

            PUT UNFORMATTED
                "  " STRING(bItens.CodItem, "9999") SPACE
                TRIM(bProdutos.NomProduto) FORMAT "x(28)" SPACE(2)
                STRING(bItens.NumQuantidade, "->>>>>9") FORMAT "x(10)" SPACE(3)
                STRING(bItens.ValTotal, "->>>>>>9.99") FORMAT "x(12)" SKIP.

            iTotal = iTotal + bItens.ValTotal.
        END.

        PUT UNFORMATTED
            SKIP
            FILL("-", 100) SKIP
            "  Total do Pedido: " STRING(iTotal, "->>>>>>9.99") SKIP(2).
    END.

    OUTPUT CLOSE.
    OS-COMMAND NO-WAIT VALUE(cArq).
END.



ON CHOOSE OF bt-sair DO:
    MESSAGE "Saindo do sistema..." VIEW-AS ALERT-BOX INFO BUTTONS OK.
    APPLY "WINDOW-CLOSE" TO FRAME fMenu.
    QUIT.
END.


ENABLE ALL WITH FRAME fMenu.
WAIT-FOR "WINDOW-CLOSE" OF FRAME fMenu.
