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
	Local cCnpjCli	:= posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_CGC")
	Local nVlTotPed	:= 0
	
	nVlTotPed	:= retTotPed(SC5->C5_NUM) 
	aDadosCli 	:= retDadosCl(SC5->C5_CLIENTE, SC5->C5_LOJACLI)
	aDadoGrpE 	:= retDadoGrpE(SC5->C5_CLIENTE, SC5->C5_LOJACLI)
	aDadoCons 	:= retDadoCon(cCnpjCli)
	
	if interfAprv(aDadosCli,aDadoGrpE,aDadoCons,nVlTotPed)//Interface com o usuário
		processAprv()//Processamento
	endif
	
return lRet

Static Function interfAprv(aDadosCli,aDadoGrpE,aDadoCons,nVlTotPed)
/*/{Protheus.doc} interfAprv
Interface com o cliente, camada de apresentação de dados View
@author Fabio
@since 19/12/2014
@version 1.0
@param aDadosCli, Array, Array com os dados do cliente conforme documentado na função que preenche
@param aDadoGrpE, Array, Array com os dados do grupo econômico conforme documentado na função que preenche
@param aDadoCons, Array, Array com os dados dos podidos consignados do cliente conforme documentado na função que preenche
@return lRet, Status se deve liberar ou não os pedidos
/*/
	
	Local lRet		:= .F.
	Local aJanela	:= msAdvSize(.T.,.F.,)
	Local aInfo		:= {aJanela[1],aJanela[2],aJanela[3],aJanela[4],3,3}
	Local nTopDlg	:= aJanela[7]
	Local nLeftDlg	:= aJanela[2]
	Local nBotDlg	:= aJanela[6]
	Local nRightDlg	:= aJanela[5]
	Local aButDlg	:= {}
	
	//Painel Superior
	Local cCliNom	:= aDadosCli[1]
	Local cGrpEcon	:= alltrim(aDadoGrpE[6])+" | "+alltrim(aDadoGrpE[5])
	Local nValTotP	:= round(nVlTotPed,2)
	
	//Painel de cliente
	Local nCreCli	:= aDadosCli[3]
	Local nSldDupl	:= aDadosCli[4]
	Local nSldLim	:= aDadosCli[5]
	Local nSldPed	:= aDadosCli[6]
	Local dVencCre	:= aDadosCli[7]
	
	//Painel de grupo
	Local nCreGrp	:= aDadoGrpE[1]
	Local nSldDplGr	:= aDadoGrpE[2]
	Local nSldLimGr	:= aDadoGrpE[3]
	Local nSldPedGr	:= aDadoGrpE[4]
	
	//Painel dos Pedidos Consignados
	Local nNotFat	:= aDadoCons[1]
	Local nCompens	:= aDadoCons[2]
	Local nSldCon	:= aDadoCons[3]
	
	//Painel financeiro do cliente
	Local nTitPr	:= aDadosCli[8]
	Local nMaiorAtr	:= aDadosCli[9]
	Local nVlrAtr	:= aDadosCli[10]

	Private oDlgAprv, oPnlSup, oPnlCli, oPnlPedm, oPnlGrp, oPnlDado, oBtnOk, oBtnCanc
	Private oSayNomCli, oGetNomGli, oSayGrEcon, oGetGrpEcon, oSayVlrPed, oGetVlrPed //Painel Superior 
	Private oSayCreCl, oGetCreCli, oSayDupC, oGetDupC, oSaySldCr, oGetSldCr, oSaySalPe, oGetSalPe, oSayVncL, oGetVncL //Dados do cliente
	Private oSayCreGr, oGetCreGr, oSaySldDpG, oGetSldDpG, oSaySldLmG,oGetSldLmG, oSaySldPed, oGetSldPed //Dados do grupo
	Private oSayNaoFat, oGetNaoFat, oSayCompen, oGetCompen, oSaySldCo, oGetSldCo //Pedidos Consignados
	Private oSayTitPr, oGetTitPr,oSayMaior, oGetMaior, oSayVlrAtr, oGetVlrAtr //Dados Financeiro
	
	//Janela Principal
	oDlgAprv	:= MsDialog():New(nTopDlg+10,nLeftDlg+300,nBotDlg-10,nRightDlg-300,"[FSFAT003] Aprovação de Crédito de Pedidos de Vendas",,,.F.,,,,,,.T.,,,.T.)
	
	//Painel superior
	oPnlSup		:= TPanel():New(10,10,"Dados Gerais",oDlgAprv,,.F.,.F.,,,330,60,.T.,.F.)
	oSayNomCli	:= TSay():New(15,3,{||"Cliente:"}, oPnlSup,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetNomGli	:= TGet():New(12,55,{|u|iif(pcount()>0,cCliNom:= u,cCliNom)},oPnlSup,150,009,"@!",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"cCliNom",,,,.F.,.T.,.F.,,,)
	oSayGrEcon	:= TSay():New(30,3,{||"Grupo Econômico:"}, oPnlSup,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetGrpEcon	:= TGet():New(27,55,{|u|iif(pcount()>0,cGrpEcon:= u,cGrpEcon)},oPnlSup,150,009,"@!",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"cGrpEcon",,,,.F.,.T.,.F.,,,)
	oSayVlrPed	:= TSay():New(45,3,{||"Valor do Pedido:"}, oPnlSup,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetVlrPed	:= TGet():New(42,55,{|u|iif(pcount()>0,nValTotP:= u,nValTotP)},oPnlSup,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nValTotP",,,,.F.,.T.,.F.,,,)
	
	//Painel com os dados do cliente
	oPnlCli		:= TPanel():New(80,10,"Dados do Cliente",oDlgAprv,,.F.,.F.,,,150,90,.T.,.F.)
	oSayCreCl	:= TSay():New(15,3,{||"Crédito do Cliente:"}, oPnlCli,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetCreCli	:= TGet():New(12,55,{|u|iif(pcount()>0,nCreCli:= u,nCreCli)},oPnlCli,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nCreCli",,,,.F.,.T.,.F.,,,)
	oSayDupC	:= TSay():New(30,3,{||"Saldo Duplicatas:"}, oPnlCli,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetDupC	:= TGet():New(27,55,{|u|iif(pcount()>0,nSldDupl:= u,nSldDupl)},oPnlCli,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nSldDupl",,,,.F.,.T.,.F.,,,)
	oSaySldCr	:= TSay():New(45,3,{||"Saldo Lim Credito:"}, oPnlCli,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetSldCr	:= TGet():New(42,55,{|u|iif(pcount()>0,nSldLim:= u,nSldLim)},oPnlCli,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nSldLim",,,,.F.,.T.,.F.,,,)
	oSaySalPe	:= TSay():New(60,3,{||"Saldo Pedidos:"}, oPnlCli,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetSalPe	:= TGet():New(57,55,{|u|iif(pcount()>0,nSldPed:= u,nSldPed)},oPnlCli,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nSldPed",,,,.F.,.T.,.F.,,,)
	oSayVncL	:= TSay():New(75,3,{||"Venc Credito"}, oPnlCli,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetVncL	:= TGet():New(72,55,{|u|iif(pcount()>0,dVencCre:= u,dVencCre)},oPnlCli,60,009,"",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"dVencCre",,,,.F.,.T.,.F.,,,)
	
	//Painel com os dados de pedidos consignados
	oPnlPedm 	:= TPanel():New(180,10,"Pedidos Consignados - Cliente",oDlgAprv,,.F.,.F.,,,150,60,.T.,.F.)
	oSayNaoFat	:= TSay():New(15,3,{||"Não Faturados:"}, oPnlPedm,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetNaoFat	:= TGet():New(12,55,{|u|iif(pcount()>0,nNotFat:= u,nNotFat)},oPnlPedm,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nNotFat",,,,.F.,.T.,.F.,,,)
	oSayCompen	:= TSay():New(30,3,{||"Valor a Compensar:"}, oPnlPedm,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetCompen	:= TGet():New(27,55,{|u|iif(pcount()>0,nCompens:= u,nCompens)},oPnlPedm,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nCompens",,,,.F.,.T.,.F.,,,)
	oSaySldCo	:= TSay():New(45,3,{||"Saldo Total:"}, oPnlPedm,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetSldCo	:= TGet():New(42,55,{|u|iif(pcount()>0,nSldCon:= u,nSldCon)},oPnlPedm,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nSldCon",,,,.F.,.T.,.F.,,,)
	
	//Painel com os dados do grupo econômico
	oPnlGrp 	:= TPanel():New(80,180,"Dados do Grupo",oDlgAprv,,.F.,.F.,,,150,90,.T.,.F.)
	oSayCreGr	:= TSay():New(15,3,{||"Crédito do Grupo:"}, oPnlGrp,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetCreGr	:= TGet():New(12,55,{|u|iif(pcount()>0,nCreGrp:= u,nCreGrp)},oPnlGrp,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nCreGrp",,,,.F.,.T.,.F.,,,)
	oSaySldDpG	:= TSay():New(30,3,{||"Saldo Duplicatas:"}, oPnlGrp,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetSldDpG	:= TGet():New(27,55,{|u|iif(pcount()>0,nSldDplGr:= u,nSldDplGr)},oPnlGrp,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nSldDplGr",,,,.F.,.T.,.F.,,,)
	oSaySldLmG	:= TSay():New(45,3,{||"Saldo Lim Credito:"}, oPnlGrp,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetSldLmG	:= TGet():New(42,55,{|u|iif(pcount()>0,nSldLimGr:= u,nSldLimGr)},oPnlGrp,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nSldLimGr",,,,.F.,.T.,.F.,,,)
	oSaySldPed	:= TSay():New(60,3,{||"Saldo Pedidos:"}, oPnlGrp,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetSldPed	:= TGet():New(57,55,{|u|iif(pcount()>0,nSldPedGr:= u,nSldPedGr)},oPnlGrp,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nSldPedGr",,,,.F.,.T.,.F.,,,)
	
	//Painel com os dados financeiros
	oPnlDado	:= TPanel():New(180,180,"Dados Financeiros - Cliente",oDlgAprv,,.F.,.F.,,,150,60,.T.,.F.)
	oSayTitPr	:= TSay():New(15,3,{||"Títulos Protestados:"}, oPnlDado,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetTitPr	:= TGet():New(12,55,{|u|iif(pcount()>0,nTitPr:= u,nTitPr)},oPnlDado,60,009,"@E 9999",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nTitPr",,,,.F.,.T.,.F.,,,)
	oSayMaior	:= TSay():New(30,3,{||"Maior Atraso:"}, oPnlDado,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetMaior	:= TGet():New(27,55,{|u|iif(pcount()>0,nMaiorAtr:= u,nMaiorAtr)},oPnlDado,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nMaiorAtr",,,,.F.,.T.,.F.,,,)
	oSayVlrAtr	:= TSay():New(45,3,{||"Valor Atrasado Atual:"}, oPnlDado,"",,,,,.T.,,,50,009,,,,,,.F.)
	oGetVlrAtr	:= TGet():New(42,55,{|u|iif(pcount()>0,nVlrAtr:= u,nVlrAtr)},oPnlDado,60,009,"@E 9,999,999,999.99",{||},,,,,,.T.,,,{||},,,{||},.T.,.F.,,"nVlrAtr",,,,.F.,.T.,.F.,,,)
	
	oBtnOk 		:=  TButton():New(250,180,"Liberar",oDlgAprv,{||lRet := .T.,oDlgAprv:end()},30,15,,,,.T.,,,,{||},,)
	oBtnCanc 	:=  TButton():New(250,230,"Cancelar",oDlgAprv,{||lRet := .F.,oDlgAprv:end()},30,15,,,,.T.,,,,{||},,)  
	
	oDlgAprv:Activate(,,,.T.)
	
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
[8]=Número de títulos protestados
[9]=Maior atraso de título
[10] = Valor atrasado
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
		nTitProt := retNumProt(SA1->A1_CGC)//Obtendo o número de títulos protestados
		
		//Alimento o array de retorno
		aadd(aRet,SA1->A1_NOME)
		aadd(aRet,SA1->A1_CGC)
		aadd(aRet,nCreGrp)
		aadd(aRet,SA1->A1_SALDUPM)
		aadd(aRet,nSldCre)
		aadd(aRet,SA1->A1_VACUM)
		aadd(aRet,SA1->A1_VENCLC) //Vencimento do crédito - Pego da SA1
		aadd(aRet,nTitProt)//Número de títulos protestatos
		aadd(aRet,SA1->A1_MATR) //Maior atraso de título A1_ATR
		aadd(aRet,SA1->A1_ATR) //Valor atrasado
		
	endif
	
	restArea(aArea)
	restArea(aAreaSA1)
	
return aRet
//início das dependências da função retDadosCl
Static Function retNumProt(cCnpjCli)
/*/{Protheus.doc} retNumProt
Função que retorna o número de protestos do clientes
@author Fabio
@since 19/12/2014
@version 1.0
@param cCnpjCli, String, Cnpj do cliente
@return nRet, Número de protestos
/*/	
	Local nRet		:= 0
	Local cQuery	:= ""
	Local cAliTemp	:= getNextAlias()
	
	cQuery := " SELECT COUNT(E1_NUM) AS NUMTIT FROM SE1200 SE1 "
	cQuery += "		INNER JOIN SA1200 SA1 "
	cQuery += "	ON A1_COD = E1_CLIENTE "
	cQuery += "	AND A1_LOJA = E1_LOJA "
	cQuery += "	AND A1_CGC = '' "
	cQuery += "	AND SA1.D_E_L_E_T_ = '' "
	cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	cQuery += " AND E1_TIPO = 'NF' "
	cQuery += " AND E1_SITUACA = 'F' "	
	
	//Verifico a área
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nRet += (cAliTemp)->NUMTIT //Protestos da cooper
	
	//Fecho porque vou usar de novo
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
	//Horizon
	cQuery := " SELECT COUNT(E1_NUM) AS NUMTIT FROM SE1300 SE1 "
	cQuery += "		INNER JOIN SA1300 SA1 "
	cQuery += "	ON A1_COD = E1_CLIENTE "
	cQuery += "	AND A1_LOJA = E1_LOJA "
	cQuery += "	AND A1_CGC = '' "
	cQuery += "	AND SA1.D_E_L_E_T_ = '' "
	cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	cQuery += " AND E1_TIPO = 'NF' "
	cQuery += " AND E1_SITUACA = 'F' "	
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nRet += (cAliTemp)->NUMTIT //Protestos da Horizon
	
	//Fecho porque vou usar de novo
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
return nRet
//Fim das dependências da função retDadosCl

Static Function retDadoGrpE(cCodCli,cLojCli)
/*/{Protheus.doc} retDadoGrpE
Função que retorna um array com os dados do grupo econômico que o cliente está incluído
Estrutura do array:
[1]=Crédito do grupo
[2]=Saldo das Duplicatas
[3]=Saldo Limite de crédito
[4]=Saldo dos Pedidos
[5]=Nome do Grupo
[6]=Código do grupo
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
			aadd(aRet,SZ0->Z0_NOME)
			aadd(aRet,SZ0->Z0_CODIGO)
		endif
	
	endif
	
return aRet

//Ínico das depências da função retDadoGrpE()
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
	cQuery := "	SELECT SUM(C6_PRCVEN*C6_QTDVEN) AS VALOR_PED FROM SC6200 SC6 "
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
	cQuery := "	SELECT SUM(C6_PRCVEN*C6_QTDVEN) AS VALOR_PED FROM SC6300 SC6 "
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

//Fim das dependências da função retDadoGrpE()

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
	Local aRet		:= {}
	Local nPedNtf	:= 0
	Local aDadosPed	:= {}
	
	nDplComp := retDpComp(cCnpjCli)//Retorno o valor das duplicatas a compensar
	aDadosPed := retPedCon(cCnpjCli)//Retorna dos dados dos pedidos consignados
	
	//Alimento o array conforme posições na tela
	aadd(aRet,aDadosPed[1])
	aadd(aRet,nDplComp)
	aadd(aRet,aDadosPed[2])
	
return aRet

//Início das depências da função retDadoCon
Static Function retDpComp(cCnpjCli)
/*/{Protheus.doc} retDpComp
Função que retorna as NCC a compensar dos clientes.
Para os casos de pedidos consignados.
@author Fabio Branis
@since 19/12/2014
@version 1.0
@param cCnpjCli, String, Cnpj do cliente
@return nRet, Valor somado das NCC das duas empresas para o cliente
@example
(examples)
@see (links_or_references)
/*/
	Local nRet		:= 0
	Local cQuery	:= ""
	Local cAliTemp	:= getNextAlias()
	
	//Cooper
	cQuery := " SELECT  SUM(E1_SALDO) AS SALDO_NCC FROM SE1200 SE1 "
	cQuery += " 	INNER JOIN SA1200 SA1 "
	cQuery += "			ON A1_COD = E1_CLIENTE "
	cQuery += "			AND A1_LOJA = E1_LOJA "
    cQuery += "    		AND A1_CGC = '"+cCnpjCli+"' "
	cQuery += "			AND SA1.D_E_L_E_T_ = '' "
	cQuery += "		WHERE SE1.D_E_L_E_T_ = '' "
    cQuery += "			AND E1_TIPO = 'NCC' "
    
    //Verifico a disponibilidade da tabela
    if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
    
    dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nRet += (cAliTemp)->SALDO_NCC //NCC da cooper
	
	//Fecho a tabela
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
    
    //Horizon
	cQuery := " SELECT  SUM(E1_SALDO) AS SALDO_NCC FROM SE1300 SE1 "
	cQuery += " 	INNER JOIN SA1300 SA1 "
	cQuery += "			ON A1_COD = E1_CLIENTE "
	cQuery += "			AND A1_LOJA = E1_LOJA "
    cQuery += "    		AND A1_CGC = '"+cCnpjCli+"' "
	cQuery += "			AND SA1.D_E_L_E_T_ = '' "
	cQuery += "		WHERE SE1.D_E_L_E_T_ = '' "
    cQuery += "			AND E1_TIPO = 'NCC' "
                         
    dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nRet += (cAliTemp)->SALDO_NCC //NCC da horizon
	
	//Fecho a tabela
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
return nRet

Static Function retPedCon(cCnpjCli)
/*/{Protheus.doc} retPedCon
Função para retornar os pedidos consignados.
Estrutura do array
[1] - Pedidos não faturados
[2] - Saldo total dos pedidos
@author Fabio
@since 19/12/2014
@version 1.0
@param cCnpjCli, String, Cnpj do cliente
@return aRet, Array com os dados
/*/
	Local aRet		:= {}
	Local cQuery	:= ""
	Local cAliTemp	:= getNextAlias()
	Local nValNotFa	:= 0
	Local nValTotPe	:= 0	
	
	//Cooper
	cQuery := " SELECT " 
	cQuery += " 		SUM( CASE WHEN C5_LIBEROK = '' AND C5_NOTA = ''	AND C5_BLQ = '' THEN C6_PRCVEN*C6_QTDVEN END) AS VAL_NOT_FAT,
	cQuery += "			SUM (C6_PRCVEN*C6_QTDVEN) AS VAL_TOT_PED "
	cQuery += "	FROM SC6200 SC6, SC5200 SC5, SA1200 SA1 "
	cQuery += "	WHERE SC6.D_E_L_E_T_ = '' "
	cQuery += "		AND C5_NUM = C6_NUM "
	cQuery += "		AND C5_FILIAL = C6_FILIAL "
	cQuery += "		AND C5_CLIENTE = C6_CLI "
	cQuery += "		AND C5_LOJACLI = C6_LOJA " 
	cQuery += "		AND C6_TPCOM = '2' " //2 No caso será consignado
	cQuery += " 	AND A1_COD = C5_CLIENTE "
	cQuery += " 	AND A1_LOJA = C5_LOJACLI "
	cQuery += " 	AND A1_CGC = '"+cCnpjCli+"' "
	cQuery += " 	AND SA1.D_E_L_E_T_ = '' "
	cQuery += " 	AND SC5.D_E_L_E_T_ = '' "
	
	//Verifico o alias
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nValNotFa += (cAliTemp)->VAL_NOT_FAT //Valores não faturados da Cooper
	nValTotPe += (cAliTemp)->VAL_TOT_PED //Valor total dos pedidos
	
	//Fecho a tabela
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
	//Horizon
	cQuery := " SELECT " 
	cQuery += " 		SUM( CASE WHEN C5_LIBEROK = '' AND C5_NOTA = ''	AND C5_BLQ = '' THEN C6_PRCVEN*C6_QTDVEN END) AS VAL_NOT_FAT,
	cQuery += "			SUM (C6_PRCVEN*C6_QTDVEN) AS VAL_TOT_PED "
	cQuery += "	FROM SC6300 SC6, SC5300 SC5, SA1300 SA1 "
	cQuery += "	WHERE SC6.D_E_L_E_T_ = '' "
	cQuery += "		AND C5_NUM = C6_NUM "
	cQuery += "		AND C5_FILIAL = C6_FILIAL "
	cQuery += "		AND C5_CLIENTE = C6_CLI "
	cQuery += "		AND C5_LOJACLI = C6_LOJA " 
	cQuery += "		AND C6_TPCOM = '2' " //2 No caso será consignado
	cQuery += " 	AND A1_COD = C5_CLIENTE "
	cQuery += " 	AND A1_LOJA = C5_LOJACLI "
	cQuery += " 	AND A1_CGC = '"+cCnpjCli+"' "
	cQuery += " 	AND SA1.D_E_L_E_T_ = '' "
	cQuery += " 	AND SC5.D_E_L_E_T_ = '' "
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	(cAliTemp)->(dbgotop())//Posiciono no primeiro registro
	nValNotFa += (cAliTemp)->VAL_NOT_FAT //Valores não faturados da Cooper
	nValTotPe += (cAliTemp)->VAL_TOT_PED //Valor total dos pedidos
	
	//Fecho a tabela
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
	//Alimento o array
	aadd(aRet,nValNotFa)
	aadd(aRet,nValTotPe)
	
return aRet
//Fim das dependências da função retDadoCon

Static Function retTotPed(cNumPed)
/*/{Protheus.doc} retTotPed
Retorna o valor total do pedido de vendas
@author Fabio Branis
@since 19/12/2014
@version 1.0
@param cNumPed,String,Número do Pedido
@return nRet, Valor total do pedido
/*/
	Local aAreaSC6	:= SC6->(getArea())
	Local nRet		:= 0
	
	SC6->(dbsetorder(1))
	if SC6->(dbseek(xFilial("SC6")+cNumPed))
		while SC6->(!(eof())) .and. SC6->C6_NUM == cNumPed
			nRet += SC6->C6_PRCVEN*SC6->C6_QTDVEN
			SC6->(dbskip())
		enddo
	endif
	restArea(aAreaSC6)
	
return nRet
