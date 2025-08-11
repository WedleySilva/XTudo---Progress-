USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.

SESSION:DATE-FORMAT = "dmy".

CURRENT-WINDOW:WIDTH = 251.

DEFINE BUTTON bt-pri LABEL "<<".
DEFINE BUTTON bt-ant LABEL "<".
DEFINE BUTTON bt-prox LABEL ">".
DEFINE BUTTON bt-ult LABEL ">>".
DEFINE BUTTON bt-add LABEL "Novo".
DEFINE BUTTON bt-mod LABEL "Modificar".
DEFINE BUTTON bt-del LABEL "Remover".
DEFINE BUTTON bt-save LABEL "Salvar".
DEFINE BUTTON bt-canc LABEL "Cancelar".
DEFINE BUTTON bt-sair LABEL "Sair" AUTO-ENDKEY.
DEFINE BUTTON bt-rel LABEL "Relatorio".
DEFINE BUTTON bt-exp LABEL "Exportar".
DEFINE VARIABLE cAction AS CHARACTER NO-UNDO.

DEFINE BUFFER bProdutos FOR Produtos.
DEFINE BUFFER bItens FOR Itens.
DEFINE QUERY qProdutos FOR bProdutos SCROLLING.

DEFINE FRAME f-prod
    bt-pri AT 10
    bt-ant
    bt-prox
    bt-ult SPACE(3)
    bt-add bt-mod bt-del bt-rel bt-exp SPACE(3)
    bt-save bt-canc SPACE(3)
    bt-sair SKIP(1)
    bProdutos.CodProduto LABEL "C¢digo" COLON 20
    bProdutos.NomProduto LABEL "Nome" COLON 20
    bProdutos.ValProduto LABEL "Valor (R$)" COLON 20
    WITH SIDE-LABELS THREE-D SIZE 140 BY 15
    VIEW-AS DIALOG-BOX TITLE "Controle de Produtos".

ON CHOOSE OF bt-pri DO:
    GET FIRST qProdutos.
    IF AVAILABLE bProdutos THEN
        RUN piMostra.
    ELSE
        GET FIRST qProdutos.
END.

ON CHOOSE OF bt-ant DO:
    GET PREV qProdutos.
    IF AVAILABLE bProdutos THEN
        RUN piMostra.
    ELSE DO:
        GET FIRST qProdutos.
        IF AVAILABLE bProdutos THEN
            RUN piMostra.
        GET FIRST qProdutos.
    END.
END.

ON CHOOSE OF bt-prox DO:
    GET NEXT qProdutos.
    IF AVAILABLE bProdutos THEN
        RUN piMostra.
    ELSE DO:
        GET LAST qProdutos.
        IF AVAILABLE bProdutos THEN
            RUN piMostra.
        GET LAST qProdutos.
    END.
END.

ON CHOOSE OF bt-ult DO:
    GET LAST qProdutos.
    IF AVAILABLE bProdutos THEN
        RUN piMostra.
    ELSE
        GET LAST qProdutos.
END.


ON CHOOSE OF bt-add DO:
    DEFINE VARIABLE iProxCod AS INTEGER NO-UNDO.

    ASSIGN cAction = "add".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    CLEAR FRAME f-prod.

    FIND LAST bProdutos NO-LOCK NO-ERROR.
    IF AVAILABLE bProdutos THEN
        ASSIGN iProxCod = bProdutos.CodProduto + 1.
    ELSE
        ASSIGN iProxCod = 1.

    DISPLAY iProxCod @ bProdutos.CodProduto WITH FRAME f-prod.
    DISABLE bProdutos.CodProduto WITH FRAME f-prod.
END.


ON CHOOSE OF bt-mod DO:
    IF NOT AVAILABLE bProdutos THEN DO:
        MESSAGE "Nenhum produto selecionado para modificar." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    ASSIGN cAction = "mod".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    DISABLE bProdutos.CodProduto WITH FRAME f-prod.
    RUN piMostra.
END.


ON CHOOSE OF bt-del DO:
    DEFINE VARIABLE iCod AS INTEGER NO-UNDO.
    DEFINE VARIABLE lConfirmacao AS LOGICAL NO-UNDO.

    IF NOT AVAILABLE bProdutos THEN DO:
        MESSAGE "Nenhum produto selecionado para exclus∆o." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.
    FIND FIRST Itens WHERE Itens.CodProduto = bProdutos.CodProduto NO-LOCK NO-ERROR.
    IF AVAILABLE Itens THEN DO:
        MESSAGE "N∆o Ç poss°vel excluir. Este produto est† sendo usado em pelo menos um item de pedido." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    MESSAGE "Tem certeza que deseja excluir o produto '" + bProdutos.NomProduto + "'?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE lConfirmacao.

    IF lConfirmacao THEN DO:
        ASSIGN iCod = bProdutos.CodProduto.

        FIND FIRST bProdutos WHERE bProdutos.CodProduto = iCod EXCLUSIVE-LOCK NO-ERROR.

        IF AVAILABLE bProdutos THEN DO:
            DELETE bProdutos.
            MESSAGE "Produto exclu°do com sucesso!" VIEW-AS ALERT-BOX INFORMATION.

            RUN piOpenQuery.
            GET NEXT qProdutos.
            IF NOT AVAILABLE bProdutos THEN
                GET LAST qProdutos.
            RUN piMostra.
        END.
        ELSE DO:
            MESSAGE "Produto n∆o encontrado para exclus∆o." VIEW-AS ALERT-BOX ERROR.
        END.
    END.
END.

ON CHOOSE OF bt-save DO:
    DEFINE VARIABLE rAtual AS ROWID NO-UNDO.

    IF cAction = "add" THEN DO:
        CREATE bProdutos.
        ASSIGN
            bProdutos.CodProduto = INTEGER(bProdutos.CodProduto:SCREEN-VALUE IN FRAME f-prod).
    END.
    ELSE IF cAction = "mod" THEN DO:
        FIND CURRENT bProdutos EXCLUSIVE-LOCK NO-ERROR.
        IF NOT AVAILABLE bProdutos THEN DO:
            MESSAGE "Produto n∆o encontrado para modificaá∆o." VIEW-AS ALERT-BOX ERROR.
            RETURN.
        END.
    END.


    ASSIGN
        bProdutos.NomProduto = bProdutos.NomProduto:SCREEN-VALUE IN FRAME f-prod
        bProdutos.ValProduto = DECIMAL(bProdutos.ValProduto:SCREEN-VALUE IN FRAME f-prod).

    ASSIGN rAtual = ROWID(bProdutos).

    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    ASSIGN cAction = "".

    RUN piOpenQuery.
    REPOSITION qProdutos TO ROWID rAtual NO-ERROR.
    RUN piMostra.
END.


ON CHOOSE OF bt-canc DO:
    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piMostra.
END.

ON CHOOSE OF bt-rel DO:
    DEFINE VARIABLE cArq AS CHARACTER NO-UNDO.
    DEFINE FRAME f-cab HEADER
        "Relat¢rio de Produtos" AT 1
        TODAY AT 90
        WITH PAGE-TOP WIDTH 150.
    DEFINE FRAME f-dados
        bProdutos.CodProduto
        bProdutos.NomProduto
        bProdutos.ValProduto
        WITH DOWN WIDTH 150.

    ASSIGN cArq = SESSION:TEMP-DIRECTORY + "produtos.txt".
    OUTPUT TO VALUE(cArq) PAGE-SIZE 20 PAGED.
    VIEW FRAME f-cab.
    FOR EACH bProdutos NO-LOCK WITH FRAME f-dados:
        DISPLAY bProdutos.CodProduto bProdutos.NomProduto bProdutos.ValProduto WITH FRAME f-dados.
    END.
    OUTPUT CLOSE.
    OS-COMMAND NO-WAIT VALUE(cArq).
END.

ON CHOOSE OF bt-exp DO:
    DEFINE VARIABLE cArqCsv AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cArqJson AS CHARACTER NO-UNDO.
    DEFINE VARIABLE oObj AS JsonObject NO-UNDO.
    DEFINE VARIABLE aProd AS JsonArray NO-UNDO.

    ASSIGN
        cArqCsv  = SESSION:TEMP-DIRECTORY + "produtos.csv"
        cArqJson = SESSION:TEMP-DIRECTORY + "produtos.json".

    OUTPUT TO VALUE(cArqCsv).
    FOR EACH bProdutos NO-LOCK:
        PUT UNFORMATTED
            bProdutos.CodProduto ";" 
            bProdutos.NomProduto ";" 
            bProdutos.ValProduto SKIP.
    END.
    OUTPUT CLOSE.

    aProd = NEW JsonArray().
    FOR EACH bProdutos NO-LOCK:
        oObj = NEW JsonObject().
        oObj:Add("CodProduto", bProdutos.CodProduto).
        oObj:Add("NomProduto", bProdutos.NomProduto).
        oObj:Add("ValProduto", bProdutos.ValProduto).
        aProd:Add(oObj).
    END.
    aProd:WriteFile(cArqJson, TRUE, "utf-8").

    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqCsv).
    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqJson).
END.

RUN piOpenQuery.
RUN piHabilitaBotoes(TRUE).
APPLY "choose" TO bt-pri.

VIEW FRAME f-prod.

WAIT-FOR WINDOW-CLOSE OF FRAME f-prod.

PROCEDURE piMostra:
    IF AVAILABLE bProdutos THEN
        DISPLAY bProdutos.CodProduto bProdutos.NomProduto bProdutos.ValProduto WITH FRAME f-prod.
    ELSE
        CLEAR FRAME f-prod.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.

    IF AVAILABLE bProdutos THEN
        ASSIGN rRecord = ROWID(bProdutos).

    OPEN QUERY qProdutos FOR EACH bProdutos.
    REPOSITION qProdutos TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    DO WITH FRAME f-prod:
        ASSIGN
            bt-pri:SENSITIVE = pEnable
            bt-ant:SENSITIVE = pEnable
            bt-prox:SENSITIVE = pEnable
            bt-ult:SENSITIVE = pEnable
            bt-sair:SENSITIVE = pEnable
            bt-add:SENSITIVE = pEnable
            bt-mod:SENSITIVE = pEnable
            bt-del:SENSITIVE = pEnable
            bt-rel:SENSITIVE = pEnable
            bt-exp:SENSITIVE = pEnable
            bt-save:SENSITIVE = NOT pEnable
            bt-canc:SENSITIVE = NOT pEnable.
    END.
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    DO WITH FRAME f-prod:
        ASSIGN
            bProdutos.NomProduto:SENSITIVE = pEnable
            bProdutos.ValProduto:SENSITIVE = pEnable.
    END.
END PROCEDURE.
