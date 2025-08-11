USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.

SESSION:DATE-FORMAT = "dmy".

DEFINE INPUT PARAMETER piCodPedido AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piCodItem   AS INTEGER NO-UNDO.

DEFINE BUFFER bItens    FOR Itens.
DEFINE BUFFER bProdutos FOR Produtos.
DEFINE BUFFER bPedidos  FOR Pedidos.
DEFINE QUERY qItens FOR bItens SCROLLING.

DEFINE VARIABLE cAction AS CHARACTER NO-UNDO.

DEFINE BUTTON bt-add    LABEL "Novo".
DEFINE BUTTON bt-save   LABEL "Salvar Item".
DEFINE BUTTON bt-canc   LABEL "Cancelar".
DEFINE BUTTON bt-sair   LABEL "Sair".

DEFINE FRAME f-itens
    bt-add bt-save bt-canc bt-sair SKIP(1)
    bItens.CodItem      LABEL "C¢digo Item"     COLON 20
    bItens.CodPedido    LABEL "Pedido"          COLON 20
    bItens.CodProduto   LABEL "Produto"         COLON 20
    bProdutos.NomProduto LABEL "Nome Produto"    COLON 20
    bItens.NumQuantidade LABEL "Quantidade"      COLON 20
    bItens.ValTotal     LABEL "Valor Total"     COLON 20
    WITH SIDE-LABELS THREE-D 
          VIEW-AS DIALOG-BOX TITLE "Cadastro de Itens"
          SIZE 100 BY 18.

ON CHOOSE OF bt-add DO:
    ASSIGN cAction = "add".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    CLEAR FRAME f-itens.

    FIND LAST bItens NO-ERROR.
    ASSIGN bItens.CodItem = IF AVAILABLE bItens THEN bItens.CodItem + 1 ELSE 1.

    ASSIGN bItens.CodPedido = piCodPedido.
    DISPLAY bItens.CodPedido WITH FRAME f-itens.

    DISABLE bItens.CodItem WITH FRAME f-itens.
    DISABLE bItens.ValTotal WITH FRAME f-itens.
    APPLY "ENTRY" TO bItens.CodProduto IN FRAME f-itens.
END.

ON CHOOSE OF bt-save DO:
    DEFINE VARIABLE rAtual      AS ROWID  NO-UNDO.
    DEFINE VARIABLE iProduto    AS INTEGER NO-UNDO.
    DEFINE VARIABLE iPedido     AS INTEGER NO-UNDO.
    DEFINE VARIABLE dValorUnit  AS DECIMAL NO-UNDO.
    DEFINE VARIABLE iCodItem    AS INTEGER NO-UNDO.
    DEFINE VARIABLE iQtd        AS INTEGER NO-UNDO.
    DEFINE VARIABLE dValTotal   AS DECIMAL NO-UNDO.

    ASSIGN
        iProduto = INTEGER(bItens.CodProduto:SCREEN-VALUE IN FRAME f-itens)
        iPedido  = INTEGER(bItens.CodPedido:SCREEN-VALUE IN FRAME f-itens)
        iQtd     = INTEGER(bItens.NumQuantidade:SCREEN-VALUE IN FRAME f-itens).

    FIND FIRST bProdutos WHERE bProdutos.CodProduto = iProduto NO-LOCK NO-ERROR.
    IF NOT AVAILABLE bProdutos THEN DO:
        MESSAGE "Produto inv lido!" VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    FIND FIRST bPedidos WHERE bPedidos.CodPedido = iPedido NO-LOCK NO-ERROR.
    IF NOT AVAILABLE bPedidos THEN DO:
        MESSAGE "Pedido inv lido!" VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    dValorUnit = bProdutos.ValProduto.
    dValTotal = dValorUnit * iQtd.

    IF cAction = "add" THEN DO:
        FIND LAST bItens NO-ERROR.
        iCodItem = IF AVAILABLE bItens THEN bItens.CodItem + 1 ELSE 1.

        CREATE bItens.
        ASSIGN
            bItens.CodItem      = iCodItem
            bItens.CodPedido    = iPedido
            bItens.CodProduto   = iProduto
            bItens.NumQuantidade = iQtd
            bItens.ValTotal      = dValTotal.
            
        rAtual = ROWID(bItens).
        MESSAGE "Item salvo com sucesso!" VIEW-AS ALERT-BOX INFORMATION.
    END.
    ELSE IF cAction = "mod" THEN DO:
        ASSIGN iCodItem = INTEGER(bItens.CodItem:SCREEN-VALUE IN FRAME f-itens).

        FIND FIRST bItens WHERE 
            bItens.CodPedido = iPedido AND 
            bItens.CodItem = iCodItem
            EXCLUSIVE-LOCK NO-ERROR.
            
        IF NOT AVAILABLE bItens THEN DO:
            MESSAGE "Item nÆo encontrado para modifica‡Æo." VIEW-AS ALERT-BOX ERROR.
            RETURN.
        END.

        ASSIGN
            bItens.CodProduto    = iProduto
            bItens.NumQuantidade = iQtd
            bItens.ValTotal      = dValTotal.
            
        rAtual = ROWID(bItens).
        MESSAGE "Item modificado com sucesso!" VIEW-AS ALERT-BOX INFORMATION.
    END.

    DISPLAY bItens.ValTotal WITH FRAME f-itens.
    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piOpenQuery.
    REPOSITION qItens TO ROWID rAtual NO-ERROR.
    RUN piMostra.
END.

ON CHOOSE OF bt-canc DO:
    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piMostra.
END.

ON CHOOSE OF bt-sair DO:
    APPLY "WINDOW-CLOSE" TO FRAME f-itens.
END.

ON LEAVE OF bItens.CodProduto IN FRAME f-itens DO:
    DEFINE VARIABLE iCod AS INTEGER NO-UNDO.
    ASSIGN iCod = INTEGER(bItens.CodProduto:SCREEN-VALUE) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN.

    FIND FIRST bProdutos WHERE bProdutos.CodProduto = iCod NO-LOCK NO-ERROR.
    DISPLAY IF AVAILABLE bProdutos THEN bProdutos.NomProduto ELSE ""
        @ bProdutos.NomProduto WITH FRAME f-itens.

    IF AVAILABLE bProdutos THEN DO:
        DISPLAY bProdutos.ValProduto @ bItens.ValTotal WITH FRAME f-itens.
    END.
END.

ON LEAVE OF bItens.NumQuantidade IN FRAME f-itens DO:
    DEFINE VARIABLE iCodProduto AS INTEGER NO-UNDO.
    DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
    
    ASSIGN
        iCodProduto = INTEGER(bItens.CodProduto:SCREEN-VALUE)
        iQuantidade = INTEGER(bItens.NumQuantidade:SCREEN-VALUE).

    FIND FIRST bProdutos WHERE bProdutos.CodProduto = iCodProduto NO-LOCK NO-ERROR.
    
    IF AVAILABLE bProdutos THEN DO:
        DISPLAY (bProdutos.ValProduto * iQuantidade) @ bItens.ValTotal WITH FRAME f-itens.
    END.
END.

PROCEDURE piMostra:
    IF AVAILABLE bItens THEN DO:
        FIND FIRST bProdutos WHERE bProdutos.CodProduto = bItens.CodProduto NO-LOCK NO-ERROR.
        DISPLAY
            bItens.CodItem
            bItens.CodPedido
            bItens.CodProduto
            bItens.NumQuantidade
            bItens.ValTotal
            IF AVAILABLE bProdutos THEN bProdutos.NomProduto ELSE ""
                @ bProdutos.NomProduto
            WITH FRAME f-itens.
    END.
    ELSE
        CLEAR FRAME f-itens.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRow AS ROWID NO-UNDO.
    IF AVAILABLE bItens THEN rRow = ROWID(bItens).
    OPEN QUERY qItens FOR EACH bItens.
    REPOSITION qItens TO ROWID rRow NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    DO WITH FRAME f-itens:
        ASSIGN
            bt-add:SENSITIVE  = pEnable
            bt-save:SENSITIVE = NOT pEnable
            bt-canc:SENSITIVE = NOT pEnable
            bt-sair:SENSITIVE = pEnable.
    END.        
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    DO WITH FRAME f-itens:
        ASSIGN
            bItens.CodPedido:SENSITIVE      = pEnable
            bItens.CodProduto:SENSITIVE     = pEnable
            bItens.NumQuantidade:SENSITIVE  = pEnable.
    END.
END PROCEDURE.

RUN piOpenQuery.
RUN piHabilitaBotoes(TRUE).

IF piCodItem > 0 THEN DO:
    FIND FIRST bItens WHERE bItens.CodPedido = piCodPedido AND bItens.CodItem = piCodItem EXCLUSIVE-LOCK NO-ERROR.
    IF AVAILABLE bItens THEN DO:
        ASSIGN cAction = "mod".
        RUN piMostra.
        RUN piHabilitaCampos(TRUE).
        RUN piHabilitaBotoes(FALSE).
        DISABLE bItens.CodItem WITH FRAME f-itens.
        DISABLE bItens.ValTotal WITH FRAME f-itens.
    END.
END.

VIEW FRAME f-itens.
WAIT-FOR WINDOW-CLOSE OF FRAME f-itens.
