#Include 'Protheus.ch'
/*/{Protheus.doc} FSFAT003
Rotina de análise de crédito.
Permite avaliar o crédito do cliente a partir do grupo ecnômico e liberar o crédito
Executado do MATA410 - Ações relacionadas - Ou seja, posicionado no pedido
@author Fabio Branis
@since 18/12/2014
@version 1.0
/*/
User Function FSFAT003()
	
	Local lProc		:= .T. //Controle de processamento
	Local cNumPed	:= "" //Cnpj do cliente a avaliar o crédito
	
	//Autoloader
	while lProc
		lProc := indexRot() //indexRot é o root da aplicação - Controler principal
	enddo
	
Return

Static Function indexRot(cNumPed)
/*/{Protheus.doc} indexRot
Controller principal da rotina
@author Fabio
@since 18/12/2014
@version 1.0
@param ${param}, ${param_type}, ${param_descr}
@return lRet, Status de processamento - Retorna se deve continuar processando
/*/	
	Local lRet		:= .F.
	Local aCabecPed	:= {} //Dados de cabeçalho
	Local aDadosCli	:= {} //Array com os dados do cliente
	Local aDadoCons	:= {} //Dados dos pedidos consignados
	Local aDadoGrpE	:= {} //Dados do grupo econômico -
	Local aDadoFina	:= {} //Dados financeiros do cliente
	
	aDadosCli := retDadosCl(SC5->C5_CLIENTE, SC5->C5_LOJACLI)
	aDadoGrpE := retDadoGrpE(SC5->C5_CLIENTE, SC5->C5_LOJACLI)

return lRet

Static Function retDadosCl(cCodCli,cLojCli)
/*/{Protheus.doc} retDadosCl
Função que retorna um array com os dados do cliente
Estrutura do array:
[1]=Nome do cliente 
[2]=Cnpj do cliente
[3]=Crédito do cliente
[4]=Saldo de duplicatas do cliente
[5]=Saldo Limite de Crédito do cliente
[6]=Saldo de Pedidos do cliente
[7]=Vencimento do limite de crédito
@author Fabio Branis
@since 18/12/2014
@version 1.0
@param cCodCli, String, Código do cliente
@param cLojCli, String, Loja do cliente
@return aRet, Array de retorno com os dados
/*/
	Local aRet		:= {}
	Local nCreGrp	:= 0
	Local nSldCre	:= 0
	Local aArea		:= getArea()
	Local aAreaSA1	:= SA1->(getArea())
	
	//Busco os registros que precisam ser processados
	SA1->(dbsetorder(1))
	if SA1->(dbseek(xFilial("SA1")+cCodCli+cLojCli))

		//Grupo econômico para buscar o crédito do cliente
		SZ1->(dbsetorder(2))
		if SZ1->(dbseek(xFilial("SZ1")+cCodCli+cLojCli))
		
			//Teste de controle de crédito - 1=Grupo 2=Individual
			if SA1->A1_ANGRU == "1"
				//Controla por grupo
				SZ0->(dbsetorder(1))
				if SZ0->(dbseek(xFilial("SZ0")+SZ1->Z1_CODGRP))
					nCreGrp := SZ0->Z0_VALOR
				endif
			else
				//Controle individual
				nCreGrp := SZ1->Z1_VALOR
			endif
		endif
		nSldCre := nCreGrp - SA1->A1_SALDUPM //Obtendo o saldo do crédito do cliente
		
		//Alimento o array de retorno
		aadd(aRet,SA1->A1_NOME)
		aadd(aRet,SA1->A1_CGC)
		aadd(aRet,nCreGrp)
		aadd(aRet,SA1->A1_SALDUPM)
		aadd(aRet,nSldCre)
		aadd(aRet,SA1->A1_VACUM)
		aadd(aRet,SA1->A1_VENCLC) //Vencimento do crédito - Pego da SA1
		
	endif
	
	restArea(aArea)
	restArea(aAreaSA1)
	
return aRet

Static Function retDadoCon(cCnpjCli)
/*/{Protheus.doc} retDadoCon
Função que retorna um array com os dados dos pedidos consignados
Estrutura do array:
[1]=Pedidos não faturados
[2]=Duplicatas a compensar
[3]=Saldo total dos pedidos
@author Fabio Branis
@since 18/12/2014
@version 1.0
@param cCnpjCli, String, Cnpj do cliente
@return aRet, Array de retorno com os dados
/*/
	Local aRet	:= {}
	
return aRet

Static Function retDadoGrpE(cCodCli,cLojCli)
/*/{Protheus.doc} retDadoGrpE
Função que retorna um array com os dados do grupo econômico que o cliente está incluído
Estrutura do array:
[1]=Crédito do grupo
[2]=Saldo das Duplicatas
[3]=Saldo Limite de crédito
[4]=Saldo dos Pedidos
@author Fabio Branis
@since 18/12/2014
@version 1.0
@param cCodCli, String, Código do cliente
@param cLojCli, String, Loja do cliente
@return aRet, Array de retorno com os dados
/*/
	Local aRet			:= {}
	Local nSldDplGrp	:= 0 //Saldo de duplicatas do grupo
	Local nSldPedGrp	:= 0 //Saldo dos pedidos do grupo
	
	//Busco o grupo pelo cliente
	SZ1->(dbsetorder(2))
	if SZ1->(dbseek(xFilial("SZ1")+cCodCli+cLojCli))
		
		//Busco o cabeçalho do grupo
		SZ0->(dbsetorder(1))
		if SZ0->(dbseek(xFilial("SZ0")+SZ1->Z1_CODGRP))
			
			//Retorno os valores que precisam ser processados
			nSldDplGrp := retSldGrp(SZ0->Z0_CODIGO)
			nSldPedGrp := retSldPed(SZ0->Z0_CODIGO)
			
			//Alimento o array de retorno
			aadd(aRet,SZ0->Z0_VALOR)
			aadd(aRet,nSldDplGrp)
			aadd(aRet,SZ0->Z0_VALOR - nSldDplGrp)
			aadd(aRet,nSldPedGrp)
		endif
	
	endif
	
return aRet

Static Function retSldGrp(cCodGrpEc)
/*/{Protheus.doc} retSldGrp
Função que retorna o saldo de duplicatas do grupo econômico
Depêndencia da função retDadoGrpE
@author Fabio Branis
@since 18/12/2014
@version 1.0
@param cCodGrpEc, String, Código do grupo econômico
@return nRet, Valor do saldo de duplicatas
/*/
	Local nRet		:= 0
	Local aAreaSZ1	:= SZ1->(getArea())
	Local aAreaSA1	:= SA1->(getArea())
	
	SA1->(dbsetorder(1))
	//Vou ao primeiro registro da tabela
	SZ1->(dbgotop())
	SZ1->(dbsetorder(1))
	if SZ1->(dbseek(xFilial("SZ1")+cCodGrpEc)) //Procuro pelo grupo nos itens
	
		while SZ1->(!(eof())) .and. cCodGrpEc == SZ1->Z1_CODGRP //Percorro os itens do grupo
			if SA1->(dbseek(xFilial("SA1")+SZ1->Z1_CODCLI+SZ1->Z1_LOJCLI)) //Procuro pelo cliente
				nRet += SA1->A1_SALDUP //Recupero do indicador do cadastro
			endif
			SZ1->(dbskip())
		enddo
	endif
	restArea(aAreaSZ1)
	restArea(aAreaSA1)
return nRet

Static Function retSldPed(cCodGrpEc)
/*/{Protheus.doc} retSldGrp
Função que retorna o saldo de pedidos em aberto do grupo econômico
Depêndencia da função retDadoGrpE
@author Fabio Branis
@since 18/12/2014
@version 1.0
@param cCodGrpEc, String, Código do grupo econômico
@return nRet, Valor do saldo de duplicatas
/*/
	Local nRet		:= 0
	Local cQuery	:= ""
	Local cAliTemp	:= getNextAlias()
	Local cCliCnpj	:= ""
	Local cClause	:= ""
	Local nContW	:= 0
		
	//Query para a cooper - Não filtro filial - Empresa chumbada
	cQuery := "	SELECT SUM(C6_PRCVEN*C6_QTDLIB) AS VALOR_PED FROM SC6200 SC6 "
	cQuery += " INNER JOIN SZ1200 SZ1 "
	cQuery += "		ON Z1_CODCLI = C6_CLI "
	cQuery += "			AND Z1_LOJCLI = C6_LOJA " 
	cQuery += "			AND Z1_CODGRP = '"+cCodGrpEc+"' "
	cQuery += "			AND SZ1.D_E_L_E_T_ = '' "
	cQuery += "	INNER JOIN SA1200 SA1 "
	cQuery += "		ON A1_COD = Z1_CODCLI "
	cQuery += "			AND A1_LOJA = Z1_LOJCLI "
	cQuery += "			AND SA1.D_E_L_E_T_ = '' "
	cQuery += " INNER JOIN SC5200 SC5 "
	cQuery += "		ON C5_CLIENTE = A1_COD "
	cQuery += "			AND C5_LOJACLI = A1_LOJA "
	cQuery += "			AND C5_NUM = C6_NUM "
	cQuery += "			AND C5_LIBEROK = '' "
	cQuery += "			AND C5_NOTA = '' "
	cQuery += "			AND C5_BLQ = '' "
	cQuery += "			AND SC5.D_E_L_E_T_ = '' "
	cQuery += " WHERE SC6.D_E_L_E_T_ = '' "
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nRet := (cAliTemp)->VALOR_PED //Vendas da cooper
	
	//Fecho porque vou usar de novo
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
	//Busco o cliente pelo cpf/cnpj pois o código na outra base não é o mesmo
	cQuery := " SELECT A1_CGC FROM SA1200 SA1 "
	cQuery += " INNER JOIN SZ1200 SZ1 "
	cQuery += "		ON Z1_CODCLI = A1_COD "
	cQuery += "		AND Z1_LOJCLI = A1_LOJA "
	cQuery += "		AND Z1_CODGRP = '"+cCodGrpEc+"' "
	cQuery += " WHERE SA1.D_E_L_E_T_ = '' "
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	
	//Monto a string de pesquisa
	while (cAliTemp)->(!(eof()))
		cCliCnpj	+= "'"+(cAliTemp)->A1_CGC+"'"
		nContW++
		(cAliTemp)->(dbskip())
	enddo
	
	//Define se será IN ou = na busca
	if nContW > 1
		cCliCnpj := strtran(cCliCnpj,"''","','") //coloco vírgula para separar
		cClause := " A1_CGC IN ("+cCliCnpj+")"
	else
		cClause := " A1_CGC = "+cCliCnpj
	endif
	
	//Fecho porque vou usar de novo
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
	//Query para a horizon - Não filtro filial - Empresa chumbada
	cQuery := "	SELECT SUM(C6_PRCVEN*C6_QTDLIB) AS VALOR_PED FROM SC6300 SC6 "
	cQuery += "	INNER JOIN SA1200 SA1 "
	cQuery += "		ON A1_COD = C6_CLI "
	cQuery += "			AND A1_LOJA = C6_LOJA "
	cQuery += "			AND "+cClause //Pesquisa pelo Cnpj/Cpf
	cQuery += "			AND SA1.D_E_L_E_T_ = '' "
	cQuery += " INNER JOIN SC5300 SC5 "
	cQuery += "		ON C5_CLIENTE = A1_COD "
	cQuery += "			AND C5_LOJACLI = A1_LOJA "
	cQuery += "			AND C5_NUM = C6_NUM "
	cQuery += "			AND C5_LIBEROK = '' "
	cQuery += "			AND C5_NOTA = '' "
	cQuery += "			AND C5_BLQ = '' "
	cQuery += "			AND SC5.D_E_L_E_T_ = '' "
	cQuery += " WHERE SC6.D_E_L_E_T_ = '' "
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nRet += (cAliTemp)->VALOR_PED //Vendas da cooper
	
	//Fecho a tabela
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
return nRet