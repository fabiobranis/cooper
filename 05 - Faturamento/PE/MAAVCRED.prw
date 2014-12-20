#Include 'Protheus.ch'
/*/{Protheus.doc} MAAVCRED
Ponto de entrada que permite customizar por completo a regra de aprovação de pedidos de venda
@author Fabio Branis
@since 18/12/2014
@version 1.0
@param paramixb[1], String, Código do cliente
@param paramixb[2], String, Código da loja
@param paramixb[3], Float, Valor submetido a aprovação - item do pedido
@param paramixb[4], Integer, Moeda referente aos valores 
@param paramixb[8], Boolean, Verifica se considera os pedidos acumulados
@return xRet, Pode ser lógico para aprovar ou cacter para definir qual o código de bloqueio
@example
(examples)
@see (links_or_references)
/*/
User Function MAAVCRED()

	Local cCodClGrp		:= paramixb[1] //Código do cliente
	Local cLjGrp		:= paramixb[2] //Código da loja
	Local nValAprv		:= paramixb[3] //Valor submetido a aprovação - item do pedido
	Local nMoedAprv		:= paramixb[4] //Moeda referente aos valores
	Local lPedAcum		:= paramixb[5] //Verifica se considera os pedidos acumulados
	Local xRetApr
	
	do case
	//Horizon ou Cooper
	case SM0->M0_CODIGO == "20" .or. SM0->M0_CODIGO == "30"
		xRetApr := aprvPedGr(cCodClGrp,cLjGrp,nValAprv,nMoedAprv,lPedAcum,0)// Projeto do grupo econômico - Submeto o pedido à aprovação
	endcase

Return xRetApr
 
Static Function aprvPedGr(cCodClGrp,cLjGrp,nValAprv,nMoedAprv,lPedido,nVlrCred,aEmpenho)
/*/{Protheus.doc} aprvPedGr
Função que testa se o pedido pode ser aprovado, de acordo com as regras dos grupos ecnômicos
@author Fabio
@since 18/12/2014
@version 1.0
@param cCodClGrp, String, Código do cliente
@param cLjGrp, String, Código da loja
@param nValAprv, Float, Valor submetido a aprovação - item do pedido
@param nMoedAprv, Integer, Moeda referente aos valores 
@param lPedAcum, Boolean, Verifica se considera os pedidos acumulados
@param nVlrCred, Float, Valor de crédito - Mantido por compatibilidade
@return lRet, Define se aprovou o pedido - por item
/*/	
	Local xRet
	Local aArea    := GetArea()
	Local aAreaSA1 := SA1->(GetArea())
	Local aAreaSE1 := SE1->(GetArea())
	Local aStruSA1 := {}
	Local cTipoLim := SuperGetMv("MV_CREDCLI")
	Local cQuery   := ""
	Local cAliasSE1:= "SE1"
	Local cAliasSA1:= "SA1"
	Local cAliasQry:= ""
	Local nLimCred := 0
	Local nLimCredFin := 0
	Local nVlrReal 	:= xMoeda(nValAprv,nMoedAprv,1,dDataBase,2)
	Local nVlrFin  	:= 0
	Local nVlrPed  	:= nVlrReal
	Local nLiminCr 	:= SuperGetMv("MV_LIMINCR")  //Limite Minimo de Credito
	Local nPerMax  	:= SuperGetMv("MV_PERMAX")   //Percentual Maximo comprometido com o Limite de Credito
	Local nFaixaA  	:= SuperGetMv("MV_PEDIDOA")  //Limite de Credito para a Faixa A
	Local nFaixaB  	:= SuperGetMv("MV_PEDIDOB")  //Limite de Credito para a Faixa B
	Local nFaixaC  	:= SuperGetMv("MV_PEDIDOC")  //Limite de Credito para a Faixa C
	Local nNumDias 	:= 0
	Local nRegEmp  	:= 0
	Local nMCusto  	:= 0
	Local nX       	:= 0
	Local lQuery   	:= .F.
	Local cSepNeg   := If("|"$MV_CRNEG,"|",",")
	Local cSepProv  := If("|"$MVPROVIS,"|",",")
	Local cSepRec   := If("|"$MVRECANT,"|",",")
	Local lRetorno	:= .T.
	Local cCodigo	:= ""
	Local lPedido	:= .T.
	Local nLimGrp	:= retCredGrp(cCodClGrp,cLjGrp) //Retorno o valor do crédito do grupo econômico

	DEFAULT nVlrCred := 0
	
	//Avaliação de risco de cliente
	If ( MsSeek(xFilial("SA1")+cCodClGrp+cLjGrp) )
		If ( SA1->A1_RISCO == "A" )
			lRetorno := .T.
		EndIf
		If ( SA1->A1_RISCO == "E" .And. nVlrCred<=0)
			lRetorno := .F.
			cCodigo  := "01" // Limite de Credito
		EndIf
		If ( SA1->A1_RISCO == "Z" .And. nVlrCred<=0)
			SerSolLbCR()
			lRetorno := .F.
			cCodigo  := "01" // Limite de Credito
		Else
			If SerSolLbCR()
				cCodigo  := "04" //Vencimento do Limite de Credito
				lRetorno := .F.
			EndIf
		EndIf

		//Aqui e avaliado o Vencimento do Limite de Credito do Cliente            ³
		
		If ( !Empty(SA1->A1_VENCLC) .And. SA1->A1_VENCLC < dDataBase ) .And. nVlrCred <= 0
			cCodigo  := "04" //Vencimento do Limite de Credito
			lRetorno := .F.
		EndIf
		If ( SA1->A1_RISCO <> "A" .And. !(SA1->A1_RISCO $ "E,Z" .And. nVlrCred<=0) .And. lRetorno)
			
			//Aqui e verificado o Limite de Credito do Cliente + Loja
			//O Limite de Credito sempre esta na Moeda MV_MCUSTO, mas os calculos sao 
			//em na moeda corrente.
			nMCusto	 := IIf(SA1->A1_MOEDALC > 0,SA1->A1_MOEDALC,Val(SuperGetMv("MV_MCUSTO")))
			nVlrCred := xMoeda(nVlrCred,nMoedAprv,1,dDataBase,2)
			If SA1->A1_RISCO$"E,Z"
				nLimCred := 0
			Else
				nLimCred := xMoeda(nLimGrp,nMCusto,1,dDataBase,2) //Limite de crédito pelo grupo econômico
			EndIf
			
			//Verifica se o Valor nao é maior que o Limite de Credito
			If ( lPedido )
				If nVlrCred < nVlrReal
					nVlrReal += SA1->A1_SALDUP + xMoeda(SA1->A1_SALPEDL,nMCusto,1,dDatabase,2)
				Else
					nVlrReal -= nVlrCred
					nLimCred -= SA1->A1_SALDUP + xMoeda(SA1->A1_SALPEDL,nMCusto,1,dDatabase,2)
				EndIf
				If ( aEmpenho <> Nil ) .And. ( !Empty(aEmpenho) )
					nRegEmp  := aScan(aEmpenho[1],{|x| x[1]==SA1->(RecNo())})
					If ( nRegEmp <> 0 )
						nVlrReal += xMoeda(aEmpenho[1][nRegEmp][2],nMCusto,1,dDatabase,2)
					EndIf
				EndIf
			EndIf
			If ( nVlrReal > nLimCred .And. nVlrReal > 0)
				cCodigo  := "01" // Limite de Credito
				lRetorno := .F.
			EndIf
			
			//Controle de limite de credito secundario - Verificar se será usado com o Leandro
/*			If SA1->A1_RISCO $ "E,Z"
				nLimCredFin	:= xMoeda(SA1->A1_LCFIN,nMCusto,1,dDataBase,MsDecimais(1))
			Else
				nLimCredFin := 0
			EndIf
			If ( aEmpenho <> Nil ) .And. ( !Empty(aEmpenho) )
				nRegEmp  := aScan(aEmpenho[1],{|x| x[1]==SA1->(RecNo())})
				If ( nRegEmp <> 0 )
					nLimCredFin -= aEmpenho[1][nRegEmp][3]
				EndIf
			EndIf
			If SA1->A1_SALFIN > nLimCredFin .And. SA1->A1_LCFIN > 0
				cCodigo 	:= "01" // Limite de Credito
				lRetorno := .F.
			EndIf*/
		EndIf
	EndIf
	
	/*
	O retorno da função funciona da seguinte forma.
	Se eu tenho como retorno .T. então sempre vai retornar lógico.
	Se o retorno for .F. eu vejo se o código de retorno é 01, se for o sistema atribui automáticamente o retorno
	Se não for 01 eu retorno o código, pois o sistema vai atribuir .F. no retorno e marcar o código que eu enviei daqui
	*/
	if lRetorno
		xRet := lRetorno
	else
		if cCodigo <> "01"
			xRet := cCodigo
		else
			xRet := lRetorno
		endif
	endif
	
	RestArea(aAreaSA1)
	RestArea(aAreaSE1)
	RestArea(aArea)
return xRet

Static Function retCredGrp(cCodClGrp,cLjGrp)
	Local nRet	:= 0
	
	Local aAreaSA1	:= SA1->(getArea())
	SA1->(dbsetorder(1))
	if SA1->(dbseek(xFilial("SA1")+cCodClGrp+cLjGrp))
	
	//Busco o grupo pelo cliente
		SZ1->(dbsetorder(2))
		if SZ1->(dbseek(xFilial("SZ1")+cCodClGrp+cLjGrp))
		
			//Teste de controle de crédito - 1=Grupo 2=Individual
			if SA1->A1_ANGRU == "1"
				//Controla por grupo
				SZ0->(dbsetorder(1))
				if SZ0->(dbseek(xFilial("SZ0")+SZ1->Z1_CODGRP))
					nRet := SZ0->Z0_VALOR
				endif
			else
				//Controle individual
				nRet := SZ1->Z1_VALOR
			endif
	
		endif
	endif
	restArea(aAreaSA1)
return nRet