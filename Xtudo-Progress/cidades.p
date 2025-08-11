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
DEFINE BUTTON bt-rel LABEL "Relat¢rio".
DEFINE BUTTON bt-exp LABEL "Exportar".
DEFINE VARIABLE cAction AS CHARACTER NO-UNDO.
DEFINE VARIABLE iProximoCod AS INTEGER NO-UNDO.

DEFINE BUFFER bCidades FOR Cidades.
DEFINE QUERY qCidades FOR bCidades SCROLLING.

DEFINE FRAME f-cid
    bt-pri AT 10
    bt-ant
    bt-prox
    bt-ult SPACE(3)
    bt-add bt-mod bt-del bt-rel bt-exp SPACE(3)
    bt-save bt-canc SPACE(3)
    bt-sair SKIP(1)
    bCidades.CodCidade LABEL "C¢digo" COLON 20
    bCidades.NomCidade LABEL "Cidade" COLON 20
    bCidades.CodUF     LABEL "UF"     COLON 20
    WITH SIDE-LABELS THREE-D SIZE 140 BY 15
    VIEW-AS DIALOG-BOX TITLE "Cadastro de Cidades".

ON CHOOSE OF bt-pri DO:
    GET FIRST qCidades.
    IF AVAILABLE bCidades THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-ant DO:
    GET PREV qCidades.
    IF AVAILABLE bCidades THEN DO:
        RUN piMostra.
    END.
    ELSE DO:
        GET FIRST qCidades.
    END.
END.

ON CHOOSE OF bt-prox DO:
    GET NEXT qCidades.
    IF AVAILABLE bCidades THEN DO:
        RUN piMostra.
    END.
    ELSE DO:
        GET LAST qCidades.
    END.
END.

ON CHOOSE OF bt-ult DO:
    GET LAST qCidades.
    IF AVAILABLE bCidades THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-add DO:
    ASSIGN cAction = "add".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    CLEAR FRAME f-cid.
    GET LAST qCidades.
    IF AVAILABLE bCidades THEN
        iProximoCod = bCidades.CodCidade + 1.
    ELSE
        iProximoCod = 1.
    DISPLAY iProximoCod @ bCidades.CodCidade WITH FRAME f-cid.
    DISABLE bCidades.CodCidade WITH FRAME f-cid.
END.

ON CHOOSE OF bt-mod DO:
    ASSIGN cAction = "mod".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    DISABLE bCidades.CodCidade WITH FRAME f-cid.
    RUN piMostra.
END.

ON CHOOSE OF bt-del DO:
    DEFINE VARIABLE iCod AS INTEGER NO-UNDO.
    DEFINE VARIABLE lConfirmacao AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lTemCliente AS LOGICAL NO-UNDO.
    IF NOT AVAILABLE bCidades THEN DO:
        MESSAGE "Nenhuma cidade selecionada para exclus∆o." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.
    lTemCliente = FALSE.
    FOR EACH Clientes WHERE Clientes.CodCidade = bCidades.CodCidade NO-LOCK:
        lTemCliente = TRUE.
        LEAVE.
    END.
    IF lTemCliente THEN DO:
        MESSAGE "N∆o Ç poss°vel excluir. Cidade usada por um ou mais clientes." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.
    MESSAGE "Tem certeza que deseja excluir a cidade '" + bCidades.NomCidade + "'?" VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE lConfirmacao.
    IF NOT lConfirmacao THEN RETURN.
    iCod = bCidades.CodCidade.
    FIND FIRST bCidades WHERE bCidades.CodCidade = iCod EXCLUSIVE-LOCK NO-ERROR.
    IF AVAILABLE bCidades THEN DO:
        DELETE bCidades.
        MESSAGE "Cidade exclu°da com sucesso!" VIEW-AS ALERT-BOX INFORMATION.
        RUN piOpenQuery.
        GET NEXT qCidades.
        IF NOT AVAILABLE bCidades THEN GET LAST qCidades.
        RUN piMostra.
    END.
    ELSE DO:
        MESSAGE "Cidade n∆o encontrada para exclus∆o." VIEW-AS ALERT-BOX ERROR.
    END.
END.

ON CHOOSE OF bt-save DO:
    DEFINE VARIABLE rAtual AS ROWID NO-UNDO.
    DEFINE VARIABLE lExiste AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iCodCidade AS INTEGER NO-UNDO.
    IF cAction = "add" THEN 
        iCodCidade = iProximoCod.
    ELSE 
        iCodCidade = INT(bCidades.CodCidade:SCREEN-VALUE IN FRAME f-cid).
    FIND FIRST bCidades WHERE 
        bCidades.NomCidade = bCidades.NomCidade:SCREEN-VALUE IN FRAME f-cid AND
        bCidades.CodUF = bCidades.CodUF:SCREEN-VALUE IN FRAME f-cid AND
        bCidades.CodCidade <> iCodCidade NO-LOCK NO-ERROR.
    IF AVAILABLE bCidades THEN DO:
        MESSAGE "J† existe uma cidade registrada com este nome e UF." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.
    IF cAction = "add" THEN DO:
        CREATE bCidades.
        ASSIGN
            bCidades.CodCidade = iProximoCod
            bCidades.NomCidade = bCidades.NomCidade:SCREEN-VALUE IN FRAME f-cid
            bCidades.CodUF = bCidades.CodUF:SCREEN-VALUE IN FRAME f-cid.
    END.
    ELSE IF cAction = "mod" THEN DO:
        FIND FIRST bCidades WHERE bCidades.CodCidade = iCodCidade EXCLUSIVE-LOCK NO-ERROR.
        IF AVAILABLE bCidades THEN DO:
            ASSIGN
                bCidades.NomCidade = bCidades.NomCidade:SCREEN-VALUE IN FRAME f-cid
                bCidades.CodUF = bCidades.CodUF:SCREEN-VALUE IN FRAME f-cid.
        END.
        ELSE DO:
            MESSAGE "Registro para modificaá∆o n∆o encontrado." VIEW-AS ALERT-BOX ERROR.
            RETURN.
        END.
    END.
    ASSIGN rAtual = ROWID(bCidades).
    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piOpenQuery.
    REPOSITION qCidades TO ROWID rAtual NO-ERROR.
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
        "Relat¢rio de Cidades" AT 1
        TODAY AT 90
        WITH PAGE-TOP WIDTH 150.
    DEFINE FRAME f-dados
        bCidades.CodCidade
        bCidades.NomCidade
        bCidades.CodUF
        WITH DOWN WIDTH 150.
    ASSIGN cArq = SESSION:TEMP-DIRECTORY + "cidades.txt".
    OUTPUT TO VALUE(cArq) PAGE-SIZE 20 PAGED.
    VIEW FRAME f-cab.
    FOR EACH bCidades NO-LOCK WITH FRAME f-dados:
        DISPLAY bCidades.CodCidade bCidades.NomCidade bCidades.CodUF WITH FRAME f-dados.
    END.
    OUTPUT CLOSE.
    OS-COMMAND NO-WAIT VALUE(cArq).
END.

ON CHOOSE OF bt-exp DO:
    DEFINE VARIABLE cArqCsv  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cArqJson AS CHARACTER NO-UNDO.
    DEFINE VARIABLE oObj     AS JsonObject NO-UNDO.
    DEFINE VARIABLE aCid     AS JsonArray  NO-UNDO.
    ASSIGN
        cArqCsv  = SESSION:TEMP-DIRECTORY + "cidades.csv"
        cArqJson = SESSION:TEMP-DIRECTORY + "cidades.json".
    OUTPUT TO VALUE(cArqCsv).
    FOR EACH bCidades NO-LOCK:
        PUT UNFORMATTED
            bCidades.CodCidade ";" 
            bCidades.NomCidade ";" 
            bCidades.CodUF SKIP.
    END.
    OUTPUT CLOSE.
    aCid = NEW JsonArray().
    FOR EACH bCidades NO-LOCK:
        oObj = NEW JsonObject().
        oObj:Add("CodCidade", bCidades.CodCidade).
        oObj:Add("NomCidade", bCidades.NomCidade).
        oObj:Add("CodUF", bCidades.CodUF).
        aCid:Add(oObj).
    END.
    aCid:WriteFile(cArqJson, TRUE, "utf-8").
    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqCsv).
    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqJson).
END.

RUN piOpenQuery.
RUN piHabilitaBotoes(TRUE).
APPLY "choose" TO bt-pri.
VIEW FRAME f-cid.
WAIT-FOR WINDOW-CLOSE OF FRAME f-cid.

PROCEDURE piMostra:
    IF AVAILABLE bCidades THEN
        DISPLAY bCidades.CodCidade bCidades.NomCidade bCidades.CodUF WITH FRAME f-cid.
    ELSE
        CLEAR FRAME f-cid.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.
    IF AVAILABLE bCidades THEN
        ASSIGN rRecord = ROWID(bCidades).
    OPEN QUERY qCidades FOR EACH bCidades BY bCidades.CodCidade.
    REPOSITION qCidades TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    DO WITH FRAME f-cid:
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
    DO WITH FRAME f-cid:
        ASSIGN
            bCidades.NomCidade:SENSITIVE = pEnable
            bCidades.CodUF:SENSITIVE = pEnable.
    END.
END PROCEDURE.