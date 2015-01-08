#Include 'Protheus.ch'

/*/{Protheus.doc} FSFIN001
Rotina de geração do boleto Bradesco
@author Fabio Branis
@since 08/01/2015
@version 1.0
@param lAutom, boolean, Indica se é chamada de menu ou automática
@example
A rotina pode ser chamada do menu ou de um ponto de entrada.
Sendo chamada por um ponto de entrada, o parâmetro lAutom deve ser sempre .T. para alimentar os mv_par da rotina
/*/
User Function FSFIN001(lAutom)
	
	Local cPerg 		:= "FSFIN001"
	Local lProc			:= .T.
	Local lSucess		:= .T.
	Private cErroMsg	:= ""
	Private cHlpErro	:= ""
	Default lAutom 		:= .F.
	
	//Controller de processamento automático
	if lAutom
		montaParam()
	else
		ajustaSx1(cPerg)
		lProc := pergunte(cPerg,.T.)
	endif
	
	//Controller de processamento para a rotina
	if lProc
		lSucess := fin001Proc(lAutom)
	endif
	
	//Apresento a mensagem de status
	if lSucess
	else
		help('',1,cHlpErro,"",cErroMsg,1,0)//Disparo help se der problema com os parâmetros
	endif
	
Return

Static Function fin001Proc(lAutom)
/*/{Protheus.doc} fin001Proc
Controller principal da rotina
@author Fabio Branis
@since 08/01/2015
@version 1.0
@param lAutom, boolean, Define o comportamento da rotina com relação aos dados
@return lRet, Status da rotina
/*/
	
	Local cAliBol	:= iif(lAutom,"SE1",getNextAlias())
	Local aStruQry	:= SE1->(dbstruct())
	Local lRet		:= .T.
	Local aDadosTit	:= {}
	Local nb		:= 0
	
	//Para processamento de menu
	if !lAutom
		lRet := recDados(cAliBol,aStruQry)//Faço a query e alimento a tabela temporária
	endif
	
	if lRet
		aDadosTit := cntrlBol(cAliBol,lAutom)
		for nb := 0 to len(aDadosTit)
			imprBol(aDadosTit[nb])
		next
	else
		//Para o caso de não haver dados
		cHlpErro := "SEMDADOS"
		cErroMsg := "Os parâmetros selecionados não retornaram dados."
	endif
	
return

Static Function cntrlBol(cAliBol,lAutom)
/*/{Protheus.doc} cntrlBol
Controla a função que alimenta o array com os boletos
@author Fabio Branis
@since 08/01/2015
@version 1.0
@param cAliBol, String, Nome do alias da tabela temporária ou SE1
@param lAutom, boolean, Define o comportamento da rotina com relação aos dados
@return aBoleto, array com os dados dos boletos
/*/
	Local aBoleto	:= {}
	
	if !lAutom
		(cAliBol)->(dbgotop())
		while (cAliBol)->(!(eof()))
			aadd(aBoleto,dadosBol(cAliBol))
			(cAliBol)->(dbskip())
		enddo
	else
		aadd(aBoleto,alimenta(cAliBol))
	endif
	
return aBoleto

Static Function dadosBol()
	Local aBoleto 	:= {}
return aBoleto

Static Function recDados(cTabBol,aEstrut)
/*/{Protheus.doc} recDados
Monta a query, executa e alimenta o arquivo temporário
@author Fabio
@since 08/01/2015
@version 1.0
@param cTabBol, String, Alias da tabela temporária
@param aEstrut, Array ,Array com os campos a selecionar
/*/
	Local cQuery	:= ""
	Local nI		:= 0
	Local nReg		:= 0
	Local lRet		:= .T.
	
	cQuery := "SELECT  "
	
	//Alimento a projeção da consulta com os campos da SE1			
	for nI:=1 to len(aEstrut)
		cQuery += aEstrut[nI][1]+","
	next nI
			
	cQuery += " SE1.R_E_C_N_O_  AS NREG "
	cQuery += " FROM "+	RetSqlName("SE1") + " SE1 "
	cQuery += " WHERE E1_NUM   >= '" 	+ mv_par03 		+ "' And E1_NUM     <= '" 	+ mv_par04 + "'  "
	cQuery += " AND E1_PARCELA >= '" 	+ mv_par05 		+ "' And E1_PARCELA <= '"	+ mv_par06 + "'  "
	cQuery += " AND E1_CLIENTE >= '" 	+ mv_par11 		+ "' And E1_CLIENTE <= '"	+ mv_par12 + "' "
	cQuery += " AND E1_EMISSAO >= '" 	+ dtos(mv_par17)	+ "' And E1_EMISSAO <= '"	+ dtos(mv_par18) + "' "
	cQuery += " AND E1_VENCTO  >= '" 	+ dtos(mv_par15)	+ "' And E1_VENCTO  <= '" 	+ dtos(mv_par16) + "' "
	cQuery += " AND E1_LOJA    >= '"	+ mv_par13			+ "' And E1_LOJA    <= '"	+ mv_par14 + "' "
	If mv_par22 == 2 //Nao gera bordero
		cQuery += " AND E1_NUMBOR  >= '"	+ mv_par19			+ "' And E1_NUMBOR  <= '"	+ mv_par20 + "' "
		If !Empty(mv_par07)
			cQuery += " AND E1_PORTADO = '" + mv_par07 + "' "
		Endif
	Else
		cQuery += " AND E1_NUMBCO = '' AND E1_NUMBOR = '' " //Se gera bordero, somente selecionara os titulos sem boleto
	Endif
	cQuery += " AND E1_FILIAL = '"		+ xFilial("SE1")	+ "' And E1_SALDO > 0  "
	cQuery += " AND SUBSTRING(E1_TIPO,3,1) != '-' "
	cQuery += " AND D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY E1_PORTADO, E1_CLIENTE, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_EMISSAO "
	
	if select(cTabBol) <> 0
		(cTabBol)->(dbclosearea())
	endif
	
	dbusearea(.T.,"TOPCONN",tcgenqry(,,cQuery),cTabBol,.F.,.T.) //Executo a query
	
	count to nReg //Armazeno a quantidade de registros recuperada
	procRegua(nReg) 
	//Testo para dar o retorno
	if nReg <= 0
		lRet := .F.
	endif
return lRet

Static Function ajustaSx1(cPerg)
/*/{Protheus.doc} ajustaSx1
Função para montar o arquivo de perguntas da rotina
@author Fabio Branis
@since 08/01/2015
@version 1.0
@param $cPerg, String, Nome do grupo de perguntas
/*/
	Local aTam		:= {}
	Local aHelpPor	:= {}
	
	aadd(aHelpPor,"Defina a faixa de prefixos a considerar")
	aadd(aHelpPor,"na rotina")
	aTam :=tamSx3("E1_PREFIXO")
	PutSx1(cPerg,"01","Do Prefixo:"				,"","","mv_ch1" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par01",""  				,"","","",""   			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"02","Ate o Prefixo:"			,"","","mv_ch2" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par02",""  				,"","","",""   			,"","","","","","","","","","","",aHelpPor)
	
	aHelpPor := {}
	aadd(aHelpPor,"Defina a faixa de títulos a considerar")
	aadd(aHelpPor,"na rotina")
	aTam :=tamSx3("E1_NUM")
	PutSx1(cPerg,"03","Do Titulo:"				,"","","mv_ch3" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par03",""				,"","","",""   			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"04","Ate o Titulo:"			,"","","mv_ch4" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par04",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	
	aHelpPor := {}
	aadd(aHelpPor,"Defina a faixa de parcelas a considerar")
	aadd(aHelpPor,"na rotina")
	aTam :=tamSx3("E1_PARCELA")
	PutSx1(cPerg,"05","Da Parcela:"				,"","","mv_ch5" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par05",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"06","Ate a Parcela:"			,"","","mv_ch6" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par06",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	
	aHelpPor := {}
	aadd(aHelpPor,"Escolha o código do banco")
	aTam :=tamSx3("EE_CODIGO")
	PutSx1(cPerg,"07","Do Banco:"				,"","","mv_ch7" ,"C",aTam[1],0,0,"G","","SA6"	,"","","mv_par07",""   				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	
	aHelpPor := {}
	aadd(aHelpPor,"Escolha a agência")
	aTam :=tamSx3("EE_AGENCIA")
	PutSx1(cPerg,"08","Agencia:"				,"","","mv_ch8" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par08",""   				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	
	aHelpPor := {}
	aadd(aHelpPor,"Escolha a conta")
	aTam :=tamSx3("EE_CONTA")
	PutSx1(cPerg,"09","Conta:"					,"","","mv_ch9" ,"C",aTam[1],0,0,"G","",""		,"","","mv_par09",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	
	aHelpPor := {}
	aadd(aHelpPor,"Escolha a subconta onde os parâmetros")
	aadd(aHelpPor,"para impressão de boletos estejam")
	aadd(aHelpPor,"configurados")
	aTam :=tamSx3("EE_SUBCTA")
	PutSx1(cPerg,"10","SubConta:" 				,"","","mv_ch10","C",aTam[1],0,0,"G","",""		,"","","mv_par10",""  				,"","","","" 			,"","","","","","","","","","","",aHelpPor)

	aHelpPor := {}
	aadd(aHelpPor,"Defina a faixa de clientes")
	aadd(aHelpPor,"para a rotina")
	aTam :=tamSx3("A1_COD")
	PutSx1(cPerg,"11","Do Cliente:"				,"","","mv_ch11","C",aTam[1],0,0,"G","","SA1"	,"","","mv_par11",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"12","Ate o Cliente:"			,"","","mv_ch12","C",aTam[1],0,0,"G","","SA1"	,"","","mv_par12",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)

	aHelpPor := {}
	aadd(aHelpPor,"Defina a faixa de loja de clientes")
	aadd(aHelpPor,"para a rotina")
	aTam :=tamSx3("A1_LOJA")
	PutSx1(cPerg,"13","Da Loja:"				,"","","mv_ch13","C",aTam[1],0,0,"G","",""		,"","","mv_par13",""   				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"14","Ate a Loja:"				,"","","mv_ch14","C",aTam[1],0,0,"G","",""		,"","","mv_par14",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)

	aHelpPor := {}
	aadd(aHelpPor,"Defina a abrangência de vencimento")
	aadd(aHelpPor,"para a rotina")
	aTam :=tamSx3("E1_VENCTO")
	PutSx1(cPerg,"15","Da Dt. Venc.:"			,"","","mv_ch15","D",aTam[1],0,0,"G","",""		,"","","mv_par15",""  				,"","","",""  			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"16","Ate a Dt. Venc:"			,"","","mv_ch16","D",aTam[1],0,0,"G","",""		,"","","mv_par16",""  				,"","","",""   			,"","","","","","","","","","","",aHelpPor)

	aHelpPor := {}
	aadd(aHelpPor,"Defina a abrangência de emissão")
	aadd(aHelpPor,"para a rotina")
	aTam :=tamSx3("E1_VENCTO")
	PutSx1(cPerg,"17","Da Dt. Emissao:"			,"","","mv_ch17","D",aTam[1],0,0,"G","",""		,"","","mv_par17",""   				,"","","",""   			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"18","Ate a Dt. Emis:"			,"","","mv_ch18","D",aTam[1],0,0,"G","",""		,"","","mv_par18",""   				,"","","",""   			,"","","","","","","","","","","",aHelpPor)

	aHelpPor := {}
	aadd(aHelpPor,"Defina a faixa de borderôs de títulos")
	aadd(aHelpPor,"para a rotina, caso haja borderôs")
	aTam :=tamSx3("E1_NUMBOR")
	PutSx1(cPerg,"19","Do bordero:"				,"","","mv_ch19","C",aTam[1],0,0,"G","",""		,"","","mv_par19",""				,"","","",""   			,"","","","","","","","","","","",aHelpPor)
	PutSx1(cPerg,"20","Ate o Bordero:"			,"","","mv_ch20","C",aTam[1],0,0,"G","",""		,"","","mv_par20",""				,"","","",""			,"","","","","","","","","","","",aHelpPor)

	aHelpPor := {}
	aadd(aHelpPor,"Selecione sim se você quer um browse")
	aadd(aHelpPor,"para selecionar títulos específicos")
	aadd(aHelpPor,"filtrados nos parâmetroa dessa rotina")
	PutSx1(cPerg,"21","Selecionar titulos:"		,"","","mv_ch21","N",01,0,0,"C","",""		,"","","mv_par21","Sim"				,"","","","Não"			,"","","","","","","","","","","",aHelpPor)

	aHelpPor := {}
	aadd(aHelpPor,"Selecione sim se você deseja que")
	aadd(aHelpPor,"o borderô seja gerao pela rotina")
	aadd(aHelpPor,"Será baseada na numeração do MV_NUMBORR")
	PutSx1(cPerg,"22","Gerar Bordero:"			,"","","mv_ch22","N",01,0,0,"C","",""		,"","","mv_par22","Sim"				,"","","","Não"			,"","","","","","","","","","","",aHelpPor)

return
