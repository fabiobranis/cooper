#Include 'Protheus.ch'
/*/{Protheus.doc} FSFAT004
Fun��o que faz o processo de adequa��o dos cadastros de clientes integrando as duas empresas que compartilham
dados.
Refaz os saldos com base nas informa��es das duas empresas.
@author Fabio Branis
@since 19/12/2014
@version 1.0
/*/
User Function FSFAT004()
	
	Local cPerg		:= "FSFAT004"
	Local lProc		:= .T.
	
	//Autoloader
	while lProc
		ajustaSx1(cPerg)
		lProc := indexRot(cPerg) //indexRot � o root da aplica��o - Controler principal
	enddo
	
Return

Static Function indexRot(cPerg)
/*/{Protheus.doc} indexRot
Controller principal da fun��o.
@author Fabio Branis
@since 19/12/2014
@version 1.0
@param cPerg, String, Grupo de perguntas
@return lRet, Defini��o de novo processamento
/*/
	Local lRet 			:= .F.
	Local aDadoAtual	:= {} //Dados da primeira emrpesa a ser processada
	Local aDadoOutr		:= {} //Dados da segunda empresa a ser processada
	Local aPar			:= {} //Par�metros para o execblock
	Local cCnpjCli		:= ""
	Local cCodEmpPr		:= iif(SM0->M0_CODIGO == "20","30","20")//Empresa n�o logada
	Private cAliasTemp	:= getNextAlias() //Private como dep�ncia da fun��o indexRot
	
	if pergunte(cPerg,.T.)

		if recDadosCli(mv_par01,mv_par02)
		
			(cAliTemp)->(dbgotop())
			while (cAliTemp)->(!(eof()))
			
				cCnpjCli := (cAliTemp)->A1_CGC
				
				//Par�metros para a empresa logada
				aPar := {"","",cCnpjCli}
				aDadoAtual := ExecBlock ("FSFAT002",.F.,.F.,aPar)//Recupero os dados da Empresa logada
				
				//Par�metros para a outra empresa 
				aPar := {cCodEmpPr,"01",cCnpjCli}
				aDadoOutr := ExecBlock ("FSFAT002",.F.,.F.,aPar) //Recupero os dados da outra empresa
				
				grvDados(cCnpjCli,aDadoAtual,aDadoOutr)
				
				(cAliTemp)->(dbskip())
			enddo
		
		else
			help('',1,"FSFAT002","Defina os par�metros corretamente",1,0)//Disparo help se der problema com os par�metros
		endif
		lRet := msgyesno("Deseja processar novamente?","[FSFAT004]")
	endif
	
	//Verifico se o alias n�o est� sendo usado
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
return lRet

Static Function grvDados(cCnpjCli,aDadoAtual,aDadoOutr)
/*/{Protheus.doc} grvDados
Fun��o que grava as informa��es na tabela.
Camada de persit�ncia de dados
@author Fabio Branis
@since 19/12/2014
@version 1.0
@param cCnpjCli, String, Cnpj do cliente
@param aDadoAtual, Array, Dados da empresa 1
@param aDadoOutr, Array, Dados da empresa 2
/*/
	//Vari�veis do processo de faturamento
	Local dPrimCompr	:= ctod("") //Primeira compra
	Local dUltCompr		:= ctod("")//	�ltima Compra
	Local cUltEmpCpr	:= iif(SM0->M0_CODIGO == "20","COOPER","HORIZON") //�ltima empresa que foi feita a compra - rever l�gica
	Local nMaiCompr		:= 0 //Maior compra
	Local nNumComprs	:= 0 //N�mero de compras do cliente
	Local nVacumPed		:= 0 //Valor acumulado dos pedidos
	Local cCnpjCli		:= 	"" //Cnpj Do cliente
	
	//Vari�veis de controle financeiro
	Local nMsaldCli		:= 0 //Maior saldo do cliente
	Local nMedAtrCl		:= 0 //M�dia de atraso do cliente
	Local nSldTitCl		:= 0 //Saldo de t�tulos em aberto
	Local nNroPgCli		:= 0 //N�mero de pagamentos do cliente
	Local nAtrCli		:= 0 //Valor em atraso do cliente
	Local nMAtrCli		:= 0 //Maior atraso de t�tulo - Verificar se � em dias ou valores
	Local nMmaDupl		:= 0 //Valor da maior duplicata do cliente
	Local nSldDplC		:= 0 //Saldo das duplicatas em aberto do cliente
	Local nNroPgAt		:= 0 //N�mero de pagamentos feitos em atraso
	
	SA1->(dbsetorder(3))//Busco pelo cnpj
	if SA1->(dbseek(xFilial("SA1")+cCnpjCli))
	
		//Ajusto os valores de cadastro de cliente
		dPrimCompr 	:= retPrimCpr(aDadoAtual[1],aDadoOutr[1])//Verifico qual a menor data
		dUltCompr 	:= retUltCpr(aDadoAtual[14],aDadoOutr[14])//�ltima compra
		nMaiCompr 	:= iif(aDadoAtual[2] > aDadoOutr[2],aDadoAtual[2],aDadoOutr[2])//Verifico a maior compra
		nNumComprs 	:= aDadoAtual[3]+aDadoOutr[3] //Somo o n�mero de compras
		nVacumPed 	:= aDadoAtual[4]+aDadoOutr[4]//Somo os valores acumulados
	
		//Ajusto os valores do financeiro - Tamb�m � cadastro mas conceitualmente separado
		nMsaldCli	:= aDadoAtual[5]+aDadoOutr[5]//Somo o valor - O maior saldo devedor � a soma do maior das duas empresas
		nMedAtrCl	:= (aDadoAtual[6]+aDadoOutr[6])/2//Somo e divido por 2 para obter a m�dia das duas empresas
	 	nSldTitCl	:= aDadoAtual[7]+aDadoOutr[7]//O saldo em aberto � a soma dos dois 
	 	nNroPgCli	:= aDadoAtual[8]+aDadoOutr[8]//O n�mero de pagamentos � a soma das duas empresas
		nVlAtrCli	:= aDadoAtual[9]+aDadoOutr[9]//Valor em atraso � a soma das duas empresas 
		nMAtrCli	:= aDadoAtual[10]+aDadoOutr[10]//Maior atraso � o valor, ent�o somo das duas empresas 
		nMmaDupl	:= iif(aDadoAtual[11] > aDadoOutr[11],aDadoAtual[11],aDadoOutr[11])//Comparo pra pegar o maior valor 
		nSldDplC	:= aDadoAtual[12]+aDadoOutr[12]//Saldo das duplicatas � a soma das duas empresas 
		nNroPgAt	:= aDadoAtual[13]+aDadoOutr[13]//Somo o valor dos pagamentos em atraso
		
		//Gravo os dados na tabela SA1
		if reckLock("SA1",.F.)
			//Relativo ao processo de faturamento
			SA1->A1_PRICOM 	:= dPrimCompr
			SA1->A1_ULTCOM 	:= dUltCompr
			SA1->A1_ULTCEM 	:= cUltEmpCpr
			SA1->A1_MCOMPRA := nMaiCompr
			SA1->A1_NROCOM	:= nNumComprs
			SA1->A1_VACUM	:= nVacumPed
			
			//Relativo ao financeiro
			SA1->A1_MSALDO 	:= nMsaldCli
			SA1->A1_METR 	:= nMedAtrCl
			SA1->A1_SALDUP 	:= nSldTitCl
			SA1->A1_NROPAG 	:= nNroPgCli
			SA1->A1_ATR 	:= nVlAtrCli
			SA1->A1_MATR 	:= nMAtrCli
			SA1->A1_MAIDUPL := nMmaDupl
			SA1->A1_SALDUPM := nSldDplC
			SA1->A1_PAGATR 	:= nNroPgAt
			
			msUnlock("SA1")
		endif
		
	endif
	
return

Static Function recDadosCli(cCliDe,cCliAte)
/*/{Protheus.doc} recDadosCli
(long_description)
@author Fabio
@since 19/12/2014
@version 1.0
@param cCliDe, String, C�digo da faixa inicial de clientes
@param cCliAte, String,C�digo da faixa final de clientes
@return lRet, Se houver registros retorna .T.
/*/	
	Local cQuery	:= ""
	Local nReg		:= 0
	Local lRet		:= .T.
	
	//Recupero o Cnpj do cliente na base logada - N�o filtro filial pois o cadastro � compartilhado
	cQuery := "	SELECT A1_CGC FROM "+RetSqlName("SA1")+" SA1 "
	cQuery += "		WHERE A1 COD BETWEEN '"+cCliDe+"' AND '"+cCliAte+"' "
	cQuery += "		AND SA1.D_E_L_E_T_ = '' "
	cQuery += "		ORDER BY A1_COD, A1_LOJA "
	
	//Verifico se o alias n�o est� sendo usado
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cAliTemp,.F.,.T.) //Executo a query
	
	nReg := (cAliTemp)->(reccount()) //Armazeno a quantidade de registros recuperada
	 
	//Testo para dar o retorno
	if nReg <= 0
		lRet := .F.
	endif
	
return lRet

Static Function retPrimCpr(dData1,dData2)
/*/{Protheus.doc} retPrimCpr
Fun��o que retorna a primeira data de compra.
Foi concebida pois deve ser testada se as datas est�o preenchidas
@author Fabio
@since 17/12/2014
@version 1.0
@param dData1, data, Primeira data
@param dData2, data, Segunda data
@return dDatRet, Menor data de compra
/*/
	Local dDatRet	:= ctod("")
	
	//Se nenhuma data est� preenchida � porqu n�o houve compra
	if empty(dData1) .and. empty(dData2)
		dDatRet := ctod("")
	else
		if empty(dData1)
			dDatRet := dData2
		else
			if empty(dData2)
				dDatRet := dData1
			else
				dDatRet := iif(dData1 < dData2,dData1,dData2)//Se as duas datas est�o preenchidas, ent�o eu testo
			endif
		endif
	endif
	
return dDatRet

Static Function retUltCpr(dData1,dData2)
/*/{Protheus.doc} retUltCpr
Fun��o que retorna a pultima data de compra.
Foi concebida pois deve ser testada se as datas est�o preenchidas
@author Fabio
@since 17/12/2014
@version 1.0
@param dData1, data, Primeira data
@param dData2, data, Segunda data
@return dDatRet, Menor data de compra
/*/
	Local dDatRet	:= ctod("")
	
	//Se nenhuma data est� preenchida � porque n�o houve compra compra
	if empty(dData1) .and. empty(dData2)
		dDatRet := ctod("")
	else
		if empty(dData1)
			dDatRet := dData2
		else
			if empty(dData2)
				dDatRet := dData1
			else
				dDatRet := iif(dData1 > dData2,dData1,dData2)//Se as duas datas est�o preenchidas, ent�o eu testo
			endif
		endif
	endif
	
return dDatRet
Static Function ajustaSx1(cPerg)
/*/{Protheus.doc} ajustaSx1
Fun��o para gravar os dados no arquivo de perguntas da fun��o
@author Fabio Branis
@since 19/12/2014
@version 1.0
@param cPerg, String, Grupo de perguntas do arquivo SX1
/*/
	
	Local aHelpPor	:= {}
	Local aTam		:= tamSx3("A1_COD")
	
	aadd(aHelpPor,"Informe o cliente incial.")
	PutSX1(cPerg,"01","Cliente de", "", "","mv_ch1","C",aTam[1],0,0,"G","","SA1", "","","mv_par01","", "", "","","","","","","","","","","","","","",aHelpPor,{},{},"" )
	
	aHelpPor := {}
	aadd(aHelpPor,"Informe o cliente final.")
	PutSX1(cPerg,"02","Cliente at�", "", "","mv_ch2","C",aTam[1],0,0,"G","","SA1", "","","mv_par02","", "", "","","","","","","","","","","","","","",aHelpPor,{},{},"" )
	
return