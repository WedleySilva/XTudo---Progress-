USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.

SESSION:DATE-FORMAT = "dmy".

DEFINE BUFFER bpedidos FOR pedidos.
DEFINE BUFFER bcliente FOR clientes.
DEFINE BUFFER bcidade FOR cidades.
DEFINE BUFFER bitem FOR itens.
DEFINE BUFFER bprod FOR produtos.

DEFINE QUERY qpedidos FOR bpedidos SCROLLING.
DEFINE QUERY qitens FOR bitem, bprod SCROLLING.

DEFINE VARIABLE cAction AS CHARACTER NO-UNDO.
DEFINE VARIABLE iSeqItem AS INTEGER NO-UNDO.
DEFINE VARIABLE cItemAction AS CHARACTER NO-UNDO.

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
DEFINE BUTTON bt-rel LABEL "Relatório".
DEFINE BUTTON bt-exp LABEL "Exportar".
DEFINE BUTTON bt-additem LABEL "Adicionar Item".
DEFINE BUTTON bt-moditem LABEL "Modificar Item".
DEFINE BUTTON bt-delitem LABEL "Remover Item".

DEFINE TEMP-TABLE ttItens NO-UNDO
    FIELD SeqItem AS INTEGER
    FIELD CodItem AS INTEGER
    FIELD CodProduto AS INTEGER
    FIELD NomProduto AS CHARACTER
    FIELD NumQuantidade AS INTEGER
    FIELD ValProduto AS DECIMAL
    FIELD ValTotal AS DECIMAL.

DEFINE QUERY qttItens FOR ttItens SCROLLING.

DEFINE BROWSE br-itens QUERY qttItens
    DISPLAY
        ttItens.SeqItem LABEL "Seq"
        ttItens.CodProduto LABEL "Código"
        ttItens.NomProduto LABEL "Produto"
        ttItens.NumQuantidade LABEL "Qtd"
        ttItens.ValProduto LABEL "Vlr Unit."
        ttItens.ValTotal LABEL "Vlr Total"
    WITH SIZE 120 BY 15.
    
DEFINE FRAME f-ped
    bt-pri AT 10 bt-ant bt-prox bt-ult SPACE(3)
    bt-add bt-mod bt-del bt-rel bt-exp SPACE(3)
    bt-save bt-canc SPACE(3)
    bt-sair SKIP(1)
    bpedidos.Codpedido LABEL "Pedido" COLON 20
    bpedidos.DatPedido LABEL "Data" COLON 20
    bpedidos.Codcliente LABEL "Cod.Cliente" COLON 20
    bcliente.Nomcliente LABEL "Nome do Cliente" COLON 20
    bcliente.Endereco LABEL "Endereco" COLON 20
    bcliente.CodCidade LABEL " Cod.Cidade" COLON 20
    bcidade.NomCidade LABEL "Nome da Cidade" COLON 20
    bpedidos.Observacao LABEL "Observacao" COLON 20
    bpedidos.ValPedido LABEL "Valor Total" COLON 20
    br-itens AT ROW-OF bpedidos.Observacao + 3 COL 5
    bt-additem AT ROW-OF br-itens + 16 COL 5
    bt-moditem AT ROW-OF br-itens + 16 COL 22
    bt-delitem AT ROW-OF br-itens + 16 COL 39
    WITH SIDE-LABELS THREE-D
    VIEW-AS DIALOG-BOX TITLE "Cadastro de Pedidos e Itens"
    SIZE 130 BY 32.

ON CHOOSE OF bt-pri DO:
    GET FIRST qpedidos.
    IF AVAILABLE bpedidos THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-ant DO:
    GET PREV qpedidos.
    IF AVAILABLE bpedidos THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-prox DO:
    GET NEXT qpedidos.
    IF AVAILABLE bpedidos THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-ult DO:
    GET LAST qpedidos.
    IF AVAILABLE bpedidos THEN
        RUN piMostra.
END.

ON CHOOSE OF bt-add DO:
    ASSIGN cAction = "add".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    CLEAR FRAME f-ped.
    FIND LAST bpedidos NO-LOCK NO-ERROR.
    DISPLAY IF AVAILABLE bpedidos THEN bpedidos.Codpedido + 1 ELSE 1 @ bpedidos.Codpedido WITH FRAME f-ped.
    DISPLAY TODAY @ bpedidos.DatPedido WITH FRAME f-ped.
    DISABLE bpedidos.Codpedido WITH FRAME f-ped.
    DISPLAY "" @ bcliente.Nomcliente "" @ bcliente.Endereco "" @ bcliente.CodCidade "" @ bcidade.NomCidade WITH FRAME f-ped.
    RUN piCarregaItens(0).
    DISPLAY 0 @ bpedidos.ValPedido WITH FRAME f-ped.
END.

ON CHOOSE OF bt-save DO:
    DEFINE VARIABLE rAtual AS ROWID NO-UNDO.
    DEFINE VARIABLE iCliente AS INTEGER NO-UNDO.
    
    ASSIGN iCliente = INTEGER(bpedidos.Codcliente:SCREEN-VALUE IN FRAME f-ped).
    
    FIND FIRST bcliente WHERE bcliente.Codcliente = iCliente NO-LOCK NO-ERROR.
    IF NOT AVAILABLE bcliente THEN DO:
        MESSAGE "Cliente inválido." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    IF cAction = "add" THEN DO:
        CREATE bpedidos.
        ASSIGN bpedidos.DatPedido = TODAY.
    END.
    
    ASSIGN
        bpedidos.Codpedido = INTEGER(bpedidos.Codpedido:SCREEN-VALUE)
        bpedidos.Codcliente = iCliente
        bpedidos.DatPedido = DATE(bpedidos.DatPedido:SCREEN-VALUE)
        bpedidos.Observacao = bpedidos.Observacao:SCREEN-VALUE.
    
    RUN AtualizaValorTotalPedido(bpedidos.Codpedido).
    ASSIGN rAtual = ROWID(bpedidos).
    
    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piOpenQuery.
    REPOSITION qpedidos TO ROWID rAtual NO-ERROR.
    RUN piMostra.
    
    MESSAGE "Pedido salvo com sucesso!" VIEW-AS ALERT-BOX INFORMATION.
END.

ON CHOOSE OF bt-mod DO:
    ASSIGN cAction = "mod".
    RUN piHabilitaBotoes(FALSE).
    RUN piHabilitaCampos(TRUE).
    DISABLE bpedidos.Codpedido WITH FRAME f-ped.
    RUN piMostra.
END.

ON CHOOSE OF bt-del DO:
    DEFINE VARIABLE iCod AS INTEGER NO-UNDO.
    DEFINE VARIABLE lConfirm AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lItensExist AS LOGICAL NO-UNDO.
    
    IF NOT AVAILABLE bpedidos THEN DO:
        MESSAGE "Nenhum pedido selecionado para exclusão." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.
    
    ASSIGN iCod = bpedidos.Codpedido.
    FIND FIRST bitem WHERE bitem.CodPedido = iCod NO-LOCK NO-ERROR.
    IF AVAILABLE bitem THEN
        ASSIGN lItensExist = TRUE.
    ELSE
        ASSIGN lItensExist = FALSE.
    IF lItensExist THEN DO:
        MESSAGE "O pedido nº " + STRING(iCod) + " possui itens vinculados." + CHR(10) +
                "Deseja realmente apagar o pedido e todos os seus itens?"
            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE lConfirm.
    END.
    ELSE DO:
        MESSAGE "Tem certeza que deseja excluir o pedido nº " + STRING(iCod) + "?"
            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE lConfirm.
    END.
    
    IF lConfirm THEN DO:
        IF lItensExist THEN DO:
            FOR EACH bitem WHERE bitem.CodPedido = iCod EXCLUSIVE-LOCK:
                DELETE bitem.
            END.
        END.
        FIND bpedidos WHERE bpedidos.Codpedido = iCod EXCLUSIVE-LOCK NO-ERROR.
        IF AVAILABLE bpedidos THEN DO:
            DELETE bpedidos.
            MESSAGE "Pedido e seus itens excluídos com sucesso!" VIEW-AS ALERT-BOX INFORMATION.
            RUN piOpenQuery.
            GET NEXT qpedidos.
            IF NOT AVAILABLE bpedidos THEN
                GET LAST qpedidos.
            RUN piMostra.
        END.
        ELSE DO:
            MESSAGE "Pedido não encontrado para exclusão." VIEW-AS ALERT-BOX ERROR.
        END.
    END.
END.

ON CHOOSE OF bt-canc DO:
    RUN piHabilitaBotoes(TRUE).
    RUN piHabilitaCampos(FALSE).
    RUN piMostra.
END.

ON CHOOSE OF bt-exp DO:
    DEFINE VARIABLE cArqJson AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cArqCsv AS CHARACTER NO-UNDO.
    DEFINE VARIABLE oPedido AS JsonObject NO-UNDO.
    DEFINE VARIABLE aPedidos AS JsonArray NO-UNDO.
    DEFINE VARIABLE oItem AS JsonObject NO-UNDO.
    DEFINE VARIABLE aItens AS JsonArray NO-UNDO.
    DEFINE VARIABLE bCliNome AS CHARACTER NO-UNDO.
    DEFINE VARIABLE bCidNome AS CHARACTER NO-UNDO.
    DEFINE VARIABLE bCidUF AS CHARACTER NO-UNDO.
    
    ASSIGN
        cArqJson = SESSION:TEMP-DIRECTORY + "pedidos.json"
        cArqCsv = SESSION:TEMP-DIRECTORY + "pedidos.csv".
    
    aPedidos = NEW JsonArray().
    
    FOR EACH bpedidos NO-LOCK BY bpedidos.CodPedido:
        FIND FIRST bcliente WHERE bcliente.CodCliente = bpedidos.CodCliente NO-LOCK NO-ERROR.
        FIND FIRST bcidade WHERE bcidade.CodCidade = bcliente.CodCidade NO-LOCK NO-ERROR.
        
        ASSIGN
            bCliNome = IF AVAILABLE bcliente THEN bcliente.NomCliente ELSE "?"
            bCidNome = IF AVAILABLE bcidade THEN bcidade.NomCidade ELSE "?"
            bCidUF = IF AVAILABLE bcidade THEN bcidade.CodUF ELSE "?".
        
        oPedido = NEW JsonObject().
        oPedido:Add("CodPedido", bpedidos.CodPedido).
        oPedido:Add("Data", STRING(bpedidos.DatPedido, "99/99/9999")).
        oPedido:Add("Observacao", bpedidos.Observacao).
        oPedido:Add("ValorTotal", bpedidos.ValPedido).
        oPedido:Add("CodCliente", bpedidos.CodCliente).
        oPedido:Add("NomeCliente", bCliNome).
        oPedido:Add("Cidade", bCidNome).
        oPedido:Add("UF", bCidUF).
        
        aItens = NEW JsonArray().
        FOR EACH bitem WHERE bitem.CodPedido = bpedidos.CodPedido:
            FIND FIRST bprod WHERE bprod.CodProduto = bitem.CodProduto NO-LOCK NO-ERROR.
            
            oItem = NEW JsonObject().
            oItem:Add("CodProduto", bitem.CodProduto).
            oItem:Add("NomeProduto", IF AVAILABLE bprod THEN bprod.NomProduto ELSE "?").
            oItem:Add("Quantidade", bitem.NumQuantidade).
            oItem:Add("ValTotal", bitem.ValTotal).
            aItens:Add(oItem).
        END.
        
        oPedido:Add("Itens", aItens).
        aPedidos:Add(oPedido).
    END.
    
    aPedidos:WriteFile(cArqJson, TRUE, "UTF-8").
    
    OUTPUT TO VALUE(cArqCsv).
    PUT UNFORMATTED "CodPedido;Data;CodCliente;NomeCliente;Cidade;UF;Observacao;ValorTotal" SKIP.
    
    FOR EACH bpedidos NO-LOCK BY bpedidos.CodPedido:
        FIND FIRST bcliente WHERE bcliente.CodCliente = bpedidos.CodCliente NO-LOCK NO-ERROR.
        FIND FIRST bcidade WHERE bcidade.CodCidade = bcliente.CodCidade NO-LOCK NO-ERROR.
        PUT UNFORMATTED
            bpedidos.CodPedido ";"
            STRING(bpedidos.DatPedido, "99/99/9999") ";"
            bpedidos.CodCliente ";"
            (IF AVAILABLE bcliente THEN bcliente.NomCliente ELSE "?") ";"
            (IF AVAILABLE bcidade THEN bcidade.NomCidade ELSE "?") ";"
            (IF AVAILABLE bcidade THEN bcidade.CodUF ELSE "?") ";"
            REPLACE(bpedidos.Observacao, ";", ",") ";"
            STRING(bpedidos.ValPedido, "->>>>>>9.99") SKIP.
    END.
    
    OUTPUT CLOSE.
    
    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqJson).
    OS-COMMAND NO-WAIT VALUE("notepad.exe " + cArqCsv).
END.

ON CHOOSE OF bt-additem DO:
    IF NOT AVAILABLE bpedidos THEN DO:
        MESSAGE "Nenhum pedido selecionado. Salve um novo pedido antes de adicionar itens." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    RUN itens.p (INPUT bpedidos.Codpedido, INPUT 0).

    RUN piCarregaItens(bpedidos.Codpedido).
    RUN AtualizaValorTotalPedido(bpedidos.Codpedido).
END.

ON CHOOSE OF bt-moditem DO:
    IF NOT AVAILABLE ttItens THEN DO:
        MESSAGE "Nenhum item selecionado para modificar." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.
    RUN itens.p (INPUT bpedidos.Codpedido, INPUT ttItens.CodItem).
    RUN piCarregaItens(bpedidos.Codpedido).
    RUN AtualizaValorTotalPedido(bpedidos.Codpedido).
END.

ON CHOOSE OF bt-delitem DO:
    IF NOT AVAILABLE ttItens THEN DO:
        MESSAGE "Nenhum item selecionado para excluir." VIEW-AS ALERT-BOX ERROR.
        RETURN.
    END.

    MESSAGE "Deseja realmente excluir este item? CodPedido: " + STRING(bpedidos.Codpedido) + " CodItem: " + STRING(ttItens.CodItem)
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE lResp AS LOGICAL.

    IF lResp THEN DO:
        FIND bitem WHERE bitem.CodPedido = bpedidos.Codpedido AND bitem.CodItem = ttItens.CodItem EXCLUSIVE-LOCK NO-ERROR.
        IF AVAILABLE bitem THEN DO:
            DELETE bitem.
            MESSAGE "Item excluído com sucesso!" VIEW-AS ALERT-BOX INFORMATION.
        END.
        ELSE DO:
            MESSAGE "Erro: O item não foi encontrado no banco de dados para exclusão. CodPedido: " + STRING(bpedidos.Codpedido) + " CodItem: " + STRING(ttItens.CodItem)
                VIEW-AS ALERT-BOX ERROR.
        END.
        
        RUN piCarregaItens(bpedidos.Codpedido).
        RUN AtualizaValorTotalPedido(bpedidos.Codpedido).
    END.
END.

ON CHOOSE OF bt-rel DO:
    DEFINE VARIABLE cArq AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iTotalPedidos AS INTEGER NO-UNDO.
    
    ASSIGN cArq = SESSION:TEMP-DIRECTORY + "relatorio_pedidos.txt".
    
    OUTPUT TO VALUE(cArq) PAGE-SIZE 60 PAGED.
    
    PUT UNFORMATTED
        "RELATÓRIO DE PEDIDOS" SKIP
        "Data: " + STRING(TODAY, "99/99/9999") SKIP
        FILL("=", 100) SKIP(2).
    
    FOR EACH bpedidos NO-LOCK BY bpedidos.CodPedido:
        FIND FIRST bcliente WHERE bcliente.CodCliente = bpedidos.CodCliente NO-LOCK NO-ERROR.
        FIND FIRST bcidade WHERE bcidade.CodCidade = bcliente.CodCidade NO-LOCK NO-ERROR.
        
        PUT UNFORMATTED
            FILL("-", 100) SKIP
            "Pedido nº: " STRING(bpedidos.CodPedido, "9999") SPACE(5)
            "Data: " STRING(bpedidos.DatPedido, "99/99/9999") SKIP
            "Cliente: " STRING(bcliente.CodCliente, "9999") + " - " + TRIM(bcliente.NomCliente) SKIP
            "Endereço: " TRIM(bcliente.Endereco) + " - " +
            (IF AVAILABLE bcidade THEN TRIM(bcidade.NomCidade) + " - " + bcidade.CodUF ELSE "?") SKIP
            "Observação: " TRIM(bpedidos.Observacao) SKIP(1).
        
        PUT UNFORMATTED
            " Cod Produto Quantidade Valor Total" SKIP
            " ---- ---------------------------- ---------- ------------" SKIP.
        
        DEFINE VARIABLE iTotal AS DECIMAL NO-UNDO.
        ASSIGN iTotal = 0.
        
        FOR EACH bitem WHERE bitem.CodPedido = bpedidos.CodPedido:
            FIND FIRST bprod WHERE bprod.CodProduto = bitem.CodProduto NO-LOCK NO-ERROR.
            
            PUT UNFORMATTED
                " " STRING(bitem.CodItem, "9999") SPACE
                TRIM(bprod.NomProduto) FORMAT "x(28)" SPACE(2)
                STRING(bitem.NumQuantidade, "->>>>>9") FORMAT "x(10)" SPACE(3)
                STRING(bitem.ValTotal, "->>>>>>9.99") FORMAT "x(12)" SKIP.
            
            iTotal = iTotal + bitem.ValTotal.
        END.
        
        PUT UNFORMATTED
            SKIP
            FILL("-", 100) SKIP
            " Total do Pedido: " STRING(iTotal, "->>>>>>9.99") SKIP(2).
        
        iTotalPedidos = iTotalPedidos + 1.
    END.
    
    IF iTotalPedidos = 0 THEN
        PUT UNFORMATTED "Nenhum pedido encontrado." SKIP(2).
    
    OUTPUT CLOSE.
    OS-COMMAND NO-WAIT VALUE(cArq).
END.

RUN piOpenQuery.
RUN piHabilitaBotoes(TRUE).
IF AVAILABLE bpedidos THEN
    RUN piCarregaItens(bpedidos.Codpedido).
ELSE
    RUN piCarregaItens(0).

APPLY "choose" TO bt-pri.
VIEW FRAME f-ped.
WAIT-FOR WINDOW-CLOSE OF FRAME f-ped.

PROCEDURE piMostra:
    IF AVAILABLE bpedidos THEN DO:
        FIND FIRST bcliente WHERE bcliente.Codcliente = bpedidos.Codcliente NO-LOCK NO-ERROR.
        FIND FIRST bcidade WHERE bcidade.CodCidade = bcliente.CodCidade NO-LOCK NO-ERROR.
        
        DISPLAY
            bpedidos.Codpedido
            bpedidos.DatPedido
            bpedidos.Codcliente
            bcliente.Nomcliente
            bcliente.Endereco
            bcliente.CodCidade
            bcidade.NomCidade
            bpedidos.Observacao
            bpedidos.ValPedido
        WITH FRAME f-ped.
        
        RUN piCarregaItens(bpedidos.Codpedido).
    END.
    ELSE
        CLEAR FRAME f-ped.
END PROCEDURE.

PROCEDURE piCarregaItens:
    DEFINE INPUT PARAMETER piCodPedido AS INTEGER NO-UNDO.
    
    EMPTY TEMP-TABLE ttItens.
    ASSIGN iSeqItem = 0.
    
    FOR EACH bitem WHERE bitem.CodPedido = piCodPedido,
        EACH bprod WHERE bprod.CodProduto = bitem.CodProduto NO-LOCK:
        
        CREATE ttItens.
        ASSIGN
            iSeqItem = iSeqItem + 1
            ttItens.SeqItem = iSeqItem
            ttItens.CodItem = bitem.CodItem
            ttItens.CodProduto = bprod.CodProduto
            ttItens.NomProduto = bprod.NomProduto
            ttItens.NumQuantidade = bitem.NumQuantidade
            ttItens.ValProduto = bprod.ValProduto
            ttItens.ValTotal = bitem.ValTotal.
    END.
    
    CLOSE QUERY qttItens.
    OPEN QUERY qttItens FOR EACH ttItens.
    ENABLE br-itens WITH FRAME f-ped.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRow AS ROWID NO-UNDO.
    
    IF AVAILABLE bpedidos THEN
        rRow = ROWID(bpedidos).
    
    OPEN QUERY qpedidos FOR EACH bpedidos.
    REPOSITION qpedidos TO ROWID rRow NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    
    DO WITH FRAME f-ped:
        ASSIGN
            bt-pri:SENSITIVE = pEnable
            bt-ant:SENSITIVE = pEnable
            bt-prox:SENSITIVE = pEnable
            bt-ult:SENSITIVE = pEnable
            bt-add:SENSITIVE = pEnable
            bt-mod:SENSITIVE = pEnable
            bt-del:SENSITIVE = pEnable
            bt-exp:SENSITIVE = pEnable
            bt-rel:SENSITIVE = pEnable
            bt-sair:SENSITIVE = pEnable
            bt-additem:SENSITIVE = pEnable
            bt-moditem:SENSITIVE = pEnable
            bt-delitem:SENSITIVE = pEnable
            bt-save:SENSITIVE = NOT pEnable
            bt-canc:SENSITIVE = NOT pEnable.
    END.
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.
    
    DO WITH FRAME f-ped:
        ASSIGN
            bpedidos.Codcliente:SENSITIVE = pEnable
            bpedidos.DatPedido:SENSITIVE = pEnable
            bpedidos.Observacao:SENSITIVE = pEnable.
    END.
END PROCEDURE.

PROCEDURE AtualizaValorTotalPedido:
    DEFINE INPUT PARAMETER piCodPedido AS INTEGER NO-UNDO.
    DEFINE VARIABLE dTotal AS DECIMAL NO-UNDO.
    
    ASSIGN dTotal = 0.
    
    FOR EACH bitem WHERE bitem.CodPedido = piCodPedido:
        dTotal = dTotal + bitem.ValTotal.
    END.
    
    FIND bpedidos EXCLUSIVE-LOCK WHERE bpedidos.Codpedido = piCodPedido NO-ERROR.
    IF AVAILABLE bpedidos THEN DO:
        bpedidos.ValPedido = dTotal.
        DISPLAY bpedidos.ValPedido WITH FRAME f-ped.
    END.
END PROCEDURE.