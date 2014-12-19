#Include 'Protheus.ch'
/*/{Protheus.doc} SACI008
Ponto de entrada executado pelo FINA070, neste ponto de entrada é permitido customizar a rotina de 
baixas do contas a receber. 
Solutti
@author Fabio Branis
@since 17/12/2014
@version 1.0
/*/
User Function SACI008()

	do case
	//Horizon ou Cooper
	case SM0->M0_CODIGO == "20" .or. SM0->M0_CODIGO == "30"
		grvDadoGrp(SM0->M0_CODIGO)// Projeto do grupo econômico - Gravo os dados
	endcase
	
Return

Static Function grvDadoGrp(cEmpLog)
/*/{Protheus.doc} grvDadoGrp
Função que faz a interface e persiste os dados das empresas no cadastro de clientes Cooper/Horizon
@author Fabio Branis
@since 15/12/2014
@version 1.0
/*/	
	
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
	
	//Controle de processamento
	Local aAreaSA1		:= SA1->(getArea())
	Local aAreaSE1		:= SE1->(getArea())
	Local aAreaSF2		:= SF2->(getArea())
	Local aArea			:= getArea()
	Local aPar			:= {}
	Local cCodEmpPr		:= iif(cEmpLog == "20","30","20")
	
	Local aDadoAtual	:= {} //Array que receberá o retorno do processamento da empresa logada - Dados do cliente
	Local aDadoOutr		:= {}//Array que receberá o retorno do processamento da outra empresa não logada - Dados do cliente
	
	SA1->(dbsetorder(1))
	if SA1->(dbseek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
		
		cCnpjCli := SA1->A1_CGC//Recupero o cnpj
		
		//Parâmetros para a empresa logada
		aPar := {"","",cCnpjCli}
		aDadoAtual := ExecBlock ("FSFAT002",.F.,.F.,aPar)//Recupero os dados da Empresa logada
		
		//Parâmetros para a outra empresa 
		aPar := {cCodEmpPr,"01",cCnpjCli}
		aDadoOutr := ExecBlock ("FSFAT002",.F.,.F.,aPar) //Recupero os dados da outra empresa
		
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
	restArea(aAreaSA1)
	restArea(aAreaSE1)
	restArea(aAreaSF2)
	restArea(aArea)
	
return