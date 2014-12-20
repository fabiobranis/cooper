#Include 'Protheus.ch'
/*/{Protheus.doc} FSFAT004
Função que faz o processo de adequação dos cadastros de clientes integrando as duas empresas que compartilham
dados.
Refaz os saldos com base nas informações das duas empresas.
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
		lProc := indexRot(cPerg) //indexRot é o root da aplicação - Controler principal
	enddo
	
Return

Static Function indexRot(cPerg)
/*/{Protheus.doc} indexRot
Controller principal da função.
@author Fabio Branis
@since 19/12/2014
@version 1.0
@param cPerg, String, Grupo de perguntas
@return lRet, Definição de novo processamento
/*/
	Local lRet 			:= .F.
	Local aDadoAtual	:= {} //Dados da primeira emrpesa a ser processada
	Local aDadoOutr		:= {} //Dados da segunda empresa a ser processada
	Local aPar			:= {} //Parâmetros para o execblock
	Local cCnpjCli		:= ""
	Local cCodEmpPr		:= iif(SM0->M0_CODIGO == "20","30","20")//Empresa não logada
	Private cAliasTemp	:= getNextAlias() //Private como depência da função indexRot
	
	if pergunte(cPerg,.T.)

		if recDadosCli(mv_par01,mv_par02)
		
			(cAliTemp)->(dbgotop())
			while (cAliTemp)->(!(eof()))
			
				cCnpjCli := (cAliTemp)->A1_CGC
				
				//Parâmetros para a empresa logada
				aPar := {"","",cCnpjCli}
				aDadoAtual := ExecBlock ("FSFAT002",.F.,.F.,aPar)//Recupero os dados da Empresa logada
				
				//Parâmetros para a outra empresa 
				aPar := {cCodEmpPr,"01",cCnpjCli}
				aDadoOutr := ExecBlock ("FSFAT002",.F.,.F.,aPar) //Recupero os dados da outra empresa
				
				grvDados(cCnpjCli,aDadoAtual,aDadoOutr)
				
				(cAliTemp)->(dbskip())
			enddo
		
		else
			help('',1,"FSFAT002","Defina os parâmetros corretamente",1,0)//Disparo help se der problema com os parâmetros
		endif
		lRet := msgyesno("Deseja processar novamente?","[FSFAT004]")
	endif
	
	//Verifico se o alias não está sendo usado
	if select(cAliTemp) <> 0
		(cAliTemp)->(dbclosearea())
	endif
	
return lRet

Static Function grvDados(cCnpjCli,aDadoAtual,aDadoOutr)
/*/{Protheus.doc} grvDados
Função que grava as informações na tabela.
Camada de persitência de dados
@author Fabio Branis
@since 19/12/2014
@version 1.0
@param cCnpjCli, String, Cnpj do cliente
@param aDadoAtual, Array, Dados da empresa 1
@param aDadoOutr, Array, Dados da empresa 2
/*/
	//Variáveis do processo de faturamento
	Local dPrimCompr	:= ctod("") //Primeira compra
	Local dUltCompr		:= ctod("")//	Última Compra
	Local cUltEmpCpr	:= iif(SM0->M0_CODIGO == "20","COOPER","HORIZON") //Última empresa que foi feita a compra - rever lógica
	Local nMaiCompr		:= 0 //Maior compra
	Local nNumComprs	:= 0 //Número de compras do cliente
	Local nVacumPed		:= 0 //Valor acumulado dos pedidos
	Local cCnpjCli		:= 	"" //Cnpj Do cliente
	
	//Variáveis de controle financeiro
	Local nMsaldCli		:= 0 //Maior saldo do cliente
	Local nMedAtrCl		:= 0 //Média de atraso do cliente
	Local nSldTitCl		:= 0 //Saldo de títulos em aberto
	Local nNroPgCli		:= 0 //Número de pagamentos do cliente
	Local nAtrCli		:= 0 //Valor em atraso do cliente
	Local nMAtrCli		:= 0 //Maior atraso de título - Verificar se é em dias ou valores
	Local nMmaDupl		:= 0 //Valor da maior duplicata do cliente
	Local nSldDplC		:= 0 //Saldo das duplicatas em aberto do cliente
	Local nNroPgAt		:= 0 //Número de pagamentos feitos em atraso
	
	SA1->(dbsetorder(3))//Busco pelo cnpj
	if SA1->(dbseek(xFilial("SA1")+cCnpjCli))
	
		//Ajusto os valores de cadastro de cliente
		dPrimCompr 	:= retPrimCpr(aDadoAtual[1],aDadoOutr[1])//Verifico qual a menor data
		dUltCompr 	:= retUltCpr(aDadoAtual[14],aDadoOutr[14])//última compra
		nMaiCompr 	:= iif(aDadoAtual[2] > aDadoOutr[2],aDadoAtual[2],aDadoOutr[2])//Verifico a maior compra
		nNumComprs 	:= aDadoAtual[3]+aDadoOutr[3] //Somo o número de compras
		nVacumPed 	:= aDadoAtual[4]+aDadoOutr[4]//Somo os valores acumulados
	
		//Ajusto os valores do financeiro - Também é cadastro mas conceitualmente separado
		nMsaldCli	:= aDadoAtual[5]+aDadoOutr[5]//Somo o valor - O maior saldo devedor é a soma do maior das duas empresas
		nMedAtrCl	:= (aDadoAtual[6]+aDadoOutr[6])/2//Somo e divido por 2 para obter a média das duas empresas
	 	nSldTitCl	:= aDadoAtual[7]+aDadoOutr[7]//O saldo em aberto é a soma dos dois 
	 	nNroPgCli	:= aDadoAtual[8]+aDadoOutr[8]//O número de pagamentos é a soma das duas empresas
		nVlAtrCli	:= aDadoAtual[9]+aDadoOutr[9]//Valor em atraso é a soma das duas empresas 
		nMAtrCli	:= aDadoAtual[10]+aDadoOutr[10]//Maior atraso é o valor, então somo das duas empresas 
		nMmaDupl	:= iif(aDadoAtual[11] > aDadoOutr[11],aDadoAtual[11],aDadoOutr[11])//Comparo pra pegar o maior valor 
		nSldDplC	:= aDadoAtual[12]+aDadoOutr[12]//Saldo das duplicatas é a soma das duas empresas 
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
@param cCliDe, String, Código da faixa inicial de clientes
@param cCliAte, String,Código da faixa final de clientes
@return lRet, Se houver registros retorna .T.
/*/	
	Local cQuery	:= ""
	Local nReg		:= 0
	Local lRet		:= .T.
	
	//Recupero o Cnpj do cliente na base logada - Não filtro filial pois o cadastro é compartilhado
	cQuery := "	SELECT A1_CGC FROM "+RetSqlName("SA1")+" SA1 "
	cQuery += "		WHERE A1 COD BETWEEN '"+cCliDe+"' AND '"+cCliAte+"' "
	cQuery += "		AND SA1.D_E_L_E_T_ = '' "
	cQuery += "		ORDER BY A1_COD, A1_LOJA "
	
	//Verifico se o alias não está sendo usado
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
Função que retorna a primeira data de compra.
Foi concebida pois deve ser testada se as datas estão preenchidas
@author Fabio
@since 17/12/2014
@version 1.0
@param dData1, data, Primeira data
@param dData2, data, Segunda data
@return dDatRet, Menor data de compra
/*/
	Local dDatRet	:= ctod("")
	
	//Se nenhuma data está preenchida é porqu não houve compra
	if empty(dData1) .and. empty(dData2)
		dDatRet := ctod("")
	else
		if empty(dData1)
			dDatRet := dData2
		else
			if empty(dData2)
				dDatRet := dData1
			else
				dDatRet := iif(dData1 < dData2,dData1,dData2)//Se as duas datas estão preenchidas, então eu testo
			endif
		endif
	endif
	
return dDatRet

Static Function retUltCpr(dData1,dData2)
/*/{Protheus.doc} retUltCpr
Função que retorna a pultima data de compra.
Foi concebida pois deve ser testada se as datas estão preenchidas
@author Fabio
@since 17/12/2014
@version 1.0
@param dData1, data, Primeira data
@param dData2, data, Segunda data
@return dDatRet, Menor data de compra
/*/
	Local dDatRet	:= ctod("")
	
	//Se nenhuma data está preenchida é porque não houve compra compra
	if empty(dData1) .and. empty(dData2)
		dDatRet := ctod("")
	else
		if empty(dData1)
			dDatRet := dData2
		else
			if empty(dData2)
				dDatRet := dData1
			else
				dDatRet := iif(dData1 > dData2,dData1,dData2)//Se as duas datas estão preenchidas, então eu testo
			endif
		endif
	endif
	
return dDatRet
Static Function ajustaSx1(cPerg)
/*/{Protheus.doc} ajustaSx1
Função para gravar os dados no arquivo de perguntas da função
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
	PutSX1(cPerg,"02","Cliente até", "", "","mv_ch2","C",aTam[1],0,0,"G","","SA1", "","","mv_par02","", "", "","","","","","","","","","","","","","",aHelpPor,{},{},"" )
	
return