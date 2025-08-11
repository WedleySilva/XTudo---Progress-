USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.

SESSION:DATE-FORMAT = "dmy".

CURRENT-WINDOW:WIDTH = 251.

DEFINE BUTTON bt-pri   LABEL "<<".
DEFINE BUTTON bt-ant   LABEL "<".
DEFINE BUTTON bt-prox  LABEL ">".
DEFINE BUTTON bt-ult   LABEL ">>".
DEFINE BUTTON bt-add   LABEL "Novo".
DEFINE BUTTON bt-mod   LABEL "Modificar".
DEFINE BUTTON bt-del   LABEL "Remover".
DEFINE BUTTON bt-rel   LABEL "Relat¢rio".
DEFINE BUTTON bt-exp   LABEL "Exportar".
DEFINE BUTTON bt-save  LABEL "Salvar".
DEFINE BUTTON bt-canc  LABEL "Cancelar".
DEFINE BUTTON bt-sair  LABEL "Sair" AUTO-ENDKEY.

DEFINE VARIABLE cAction AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNomCidade AS CHARACTER FORMAT "x(30)" LABEL "Nome da Cidade" NO-UNDO.

DEFINE BUFFER bClientes FOR Clientes.
DEFINE BUFFER bCidade FOR Cidades.
DEFINE BUFFER bPedidos FOR Pedidos.
DEFINE QUERY qClientes FOR bClientes SCROLLING.

DEFINE FRAME f-cli
    bt-pri AT 10
    bt-ant
    bt-prox
    bt-ult SPACE(3)
    bt-add bt-mod bt-del bt-rel bt-exp SPACE(3)
    bt-save bt-canc SPACE(3)
    bt-sair SKIP(1)
    bClientes.CodCliente LABEL "C¢digo" COLON 20
    bClientes.NomCliente LABEL "Nome" COLON 20
    bClientes.Endereco LABEL "Endereáo" COLON 20
    bClientes.CodCidade LABEL "Cod. Cidade" COLON 20
    cNomCidade COLON 52
    bClientes.Observacao LABEL "Observaá∆o" COLON 20
    WITH SIDE-LABELS THREE-D SIZE 140 BY 15
    VIEW-AS DIALOG-BOX TITLE "Cadastro de Clientes".

ON CHOOSE OF bt-pri DO:
    GET FIRST qClientes.
    IF AVAILABLE bClientes THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-ant DO:
    GET PREV qClientes.
    IF AVAILABLE bClientes THEN
        RUN piMostra.
    ELSE DO:
        GET FIRST qClientes.
        IF AVAILABLE bClientes THEN
            RUN piMostra.
    END.
END.

ON CHOOSE OF bt-prox DO:
    GET NEXT qClientes.
    IF AVAILABLE bClientes THEN
        RUN piMostra.
    ELSE DO:
        GET LAST qClientes.
        IF AVAILABLE bClientes THEN
            RUN piMostra.
    END.
END.

ON CHOOSE OF bt-ult DO:
    GET LAST qClientes.
    IF AVAILABLE bClientes THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-add DO:
    ASSIGN cAction = "add".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    CLEAR FRAME f-cli.

    FIND LAST bClientes NO-LOCK NO-ERROR.
    IF AVAILABLE bClientes THEN
        DISPLAY bClientes.CodCliente + 1 @ bClientes.CodCliente WITH FRAME f-cli.
    ELSE
        DISPLAY 1 @ bClientes.CodCliente WITH FRAME f-cli.

    DISABLE bClientes.CodCliente WITH FRAME f-cli.
END.

ON CHOOSE OF bt-mod DO:
    ASSIGN cAction = "mod".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    DISABLE bClientes.CodCliente WITH FRAME f-cli.
    RUN piMostra.
END.

ON CHOOSE OF bt-del DO:
    DEFINE VARIABLE iCod AS INTEGER NO-UNDO.
    DEFINE VARIABLE lConfirm AS LOGICAL NO-UNDO.

    IF NOT AVAILABLE bClientes THEN DO:
        MESSAGE "Nenhum cliente selecionado para exclus∆o." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    ASSIGN iCod = bClientes.CodCliente.
    
    FIND FIRST bPedidos WHERE bPedidos.CodCliente = iCod NO-LOCK NO-ERROR.
    IF AVAILABLE bPedidos THEN DO:
        MESSAGE "Cliente vinculado a pedido. Exclus∆o n∆o permitida." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    MESSAGE "Tem certeza que deseja excluir o cliente '" + bClientes.NomCliente + "'?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE lConfirm.

    IF lConfirm THEN DO:
        FIND bClientes WHERE bClientes.CodCliente = iCod EXCLUSIVE-LOCK NO-ERROR.
        IF AVAILABLE bClientes THEN DO:
            DELETE bClientes.
            MESSAGE "Cliente exclu°do com sucesso!" VIEW-AS ALERT-BOX INFORMATION.
            RUN piOpenQuery.
            GET NEXT qClientes.
            IF NOT AVAILABLE bClientes THEN
                GET LAST qClientes.
            RUN piMostra.
        END.
    END.
END.

ON CHOOSE OF bt-save DO:
    DEFINE VARIABLE rAtual AS ROWID NO-UNDO.
    DEFINE VARIABLE iCidade AS INTEGER NO-UNDO.

    ASSIGN iCidade = INTEGER(bClientes.CodCidade:SCREEN-VALUE IN FRAME f-cli).

    FIND FIRST bCidade WHERE bCidade.CodCidade = iCidade NO-LOCK NO-ERROR.
    IF NOT AVAILABLE bCidade THEN DO:
        MESSAGE "Cidade inv†lida! Informe um c¢digo v†lido." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    IF cAction = "add" THEN DO:
        CREATE bClientes.
    END.

    ASSIGN
        bClientes.CodCliente = INTEGER(bClientes.CodCliente:SCREEN-VALUE IN FRAME f-cli)
        bClientes.NomCliente = bClientes.NomCliente:SCREEN-VALUE
        bClientes.Endereco   = bClientes.Endereco:SCREEN-VALUE
        bClientes.CodCidade  = iCidade
        bClientes.Observacao = bClientes.Observacao:SCREEN-VALUE.

    ASSIGN rAtual = ROWID(bClientes).

    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piOpenQuery.
    REPOSITION qClientes TO ROWID rAtual NO-ERROR.
    RUN piMostra.
END.

ON CHOOSE OF bt-canc DO:
    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piMostra.
END.

ON CHOOSE OF bt-exp DO:
    DEFINE VARIABLE cArqJson AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cArqCsv  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE oObj     AS JsonObject NO-UNDO.
    DEFINE VARIABLE aCli     AS JsonArray  NO-UNDO.

    ASSIGN
        cArqJson = SESSION:TEMP-DIRECTORY + "clientes.json"
        cArqCsv  = SESSION:TEMP-DIRECTORY + "clientes.csv".

    aCli = NEW JsonArray().
    FOR EACH bClientes NO-LOCK:
        oObj = NEW JsonObject().
        oObj:Add("CodCliente", bClientes.CodCliente).
        oObj:Add("Endereco", bClientes.Endereco).
        oObj:Add("CodCidade", bClientes.CodCidade).
        aCli:Add(oObj).
    END.
    aCli:WriteFile(cArqJson, TRUE, "UTF-8").

    OUTPUT TO VALUE(cArqCsv).
    FOR EACH bClientes NO-LOCK:
        PUT UNFORMATTED
            bClientes.CodCliente ";" 
            bClientes.Endereco   ";" 
            bClientes.CodCidade  SKIP.
    END.
    OUTPUT CLOSE.

    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqJson).
    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqCsv).
END.

ON CHOOSE OF bt-rel DO:
    DEFINE VARIABLE cArq     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCidade  AS CHARACTER NO-UNDO.

    ASSIGN cArq = SESSION:TEMP-DIRECTORY + "clientes.txt".
    OUTPUT TO VALUE(cArq) PAGE-SIZE 50 PAGED.

    PUT UNFORMATTED
        "Relat¢rio de Clientes" SKIP
        STRING(TODAY, "99/99/9999") SKIP(2).

    PUT UNFORMATTED
        "Cod  " +
        "Nome                  " +
        "Endereco                       " +
        "CodCid  " +
        "Cidade              " +
        "Observacao" SKIP.

    PUT UNFORMATTED
        FILL("-", 5) + " " +
        FILL("-", 20) + " " +
        FILL("-", 30) + " " +
        FILL("-", 7) + " " +
        FILL("-", 18) + " " +
        FILL("-", 50) SKIP.

    FOR EACH bClientes NO-LOCK:
        FIND FIRST bCidade WHERE bCidade.CodCidade = bClientes.CodCidade NO-LOCK NO-ERROR.
        ASSIGN cCidade = IF AVAILABLE bCidade THEN bCidade.NomCidade ELSE "N/A".

        PUT UNFORMATTED
            STRING(bClientes.CodCliente, "9999") + "  "
            + LEFT-TRIM(SUBSTRING(bClientes.NomCliente, 1, 20)) + FILL(" ", 20 - LENGTH(TRIM(SUBSTRING(bClientes.NomCliente, 1, 20)))) + " "
            + LEFT-TRIM(SUBSTRING(bClientes.Endereco, 1, 30)) + FILL(" ", 30 - LENGTH(TRIM(SUBSTRING(bClientes.Endereco, 1, 30)))) + " "
            + STRING(bClientes.CodCidade, "999999") + "  "
            + LEFT-TRIM(SUBSTRING(cCidade, 1, 18)) + FILL(" ", 18 - LENGTH(TRIM(SUBSTRING(cCidade, 1, 18)))) + " "
            + LEFT-TRIM(SUBSTRING(bClientes.Observacao, 1, 50)) SKIP.
    END.

    OUTPUT CLOSE.
    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArq).
END.

RUN piOpenQuery.
RUN piHabilitaBotoes(TRUE).
APPLY "choose" TO bt-pri.
VIEW FRAME f-cli.
WAIT-FOR WINDOW-CLOSE OF FRAME f-cli.

PROCEDURE piMostra:
    IF AVAILABLE bClientes THEN DO:
        FIND FIRST bCidade WHERE bCidade.CodCidade = bClientes.CodCidade NO-LOCK NO-ERROR.
        IF AVAILABLE bCidade THEN
            ASSIGN cNomCidade = bCidade.NomCidade.
        ELSE
            ASSIGN cNomCidade = "Cidade n∆o encontrada".

        DISPLAY
            bClientes.CodCliente
            bClientes.NomCliente
            bClientes.Endereco
            bClientes.CodCidade
            cNomCidade
            bClientes.Observacao
            WITH FRAME f-cli.
    END.
    ELSE
        CLEAR FRAME f-cli.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRow AS ROWID NO-UNDO.
    IF AVAILABLE bClientes THEN
        rRow = ROWID(bClientes).
    OPEN QUERY qClientes FOR EACH bClientes.
    REPOSITION qClientes TO ROWID rRow NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    DO WITH FRAME f-cli:
        ASSIGN
            bt-pri:SENSITIVE   = pEnable
            bt-ant:SENSITIVE   = pEnable
            bt-prox:SENSITIVE  = pEnable
            bt-ult:SENSITIVE   = pEnable
            bt-add:SENSITIVE   = pEnable
            bt-mod:SENSITIVE   = pEnable
            bt-del:SENSITIVE   = pEnable
            bt-exp:SENSITIVE   = pEnable
            bt-rel:SENSITIVE   = pEnable
            bt-sair:SENSITIVE  = pEnable
            bt-save:SENSITIVE  = NOT pEnable
            bt-canc:SENSITIVE  = NOT pEnable.
    END.
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    DO WITH FRAME f-cli:
        ASSIGN
            bClientes.NomCliente:SENSITIVE = pEnable
            bClientes.Endereco:SENSITIVE   = pEnable
            bClientes.CodCidade:SENSITIVE  = pEnable
            bClientes.Observacao:SENSITIVE = pEnable.
    END.
END PROCEDURE.
