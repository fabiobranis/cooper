#Include 'Protheus.ch'
/*/{Protheus.doc} M460FIM
Ponto de entrada executado pelo MATA460, neste ponto de entrada é permitido customizar a rotina de 
emissão de notas fiscais de saída. 
Solutti
@author Fabio Branis
@since 15/12/2014
@version 1.0
@see Em caso de dúvidas, fabiobranis@gmail.com - Sagaris Consultoria e Sistemas
/*/
User Function M460FIM()
	
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
	//Variáveis do processo de faturamento
	Local dPrimCompr	:= ctod("") //Primeira compra
	Local dUltCompr		:= dDatabase //	Última Compra
	Local cUltEmpCpr	:= iif(SM0->M0_CODIGO == "20","COOPER","HORIZON") //Última empresa que foi feita a compra
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
	
	//Controle de processamento
	Local aAreaSA1		:= SA1->(getArea())
	Local aAreaSE1		:= SE1->(getArea())
	Local aAreaSC5		:= SC5->(getArea())
	Local aAreaSF2		:= SF2->(getArea())
	Local aArea			:= getArea()
	Local aPar			:= {}
	Local cCodEmpPr		:= iif(cEmpLog == "20","30","20")
	
	Local aDadoAtual	:= {} //Array que receberá o retorno do processamento da empresa logada - Dados do cliente
	Local aDadoOutr		:= {}//Array que receberá o retorno do processamento da outra empresa não logada - Dados do cliente
	Local cCodCliCh 	:= ""
	Local cLojCliCh 	:= ""
	
	SA1->(dbsetorder(1))
	if SA1->(dbseek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
		
		cCodCliCh := SA1->A1_COD
		cLojCliCh := SA1->A1_LOJA
		
		//Parâmetros para a empresa logada
		aPar := {"","",cCodCliCh,cLojCliCh}
		aDadoAtual := ExecBlock ("FSFAT002",.F.,.F.,aPar)//Recupero os dados da Empresa logada
		
		//Parâmetros para a outra empresa 
		aPar := {cCodEmpPr,"01",cCodCliCh,cLojCliCh}
		aDadoOutr := ExecBlock ("FSFAT002",.F.,.F.,aPar) //Recupero os dados da outra empresa
		
		
		//Ajusto os valores de cadastro de cliente
		dPrimCompr 	:= retPrimCpr(aDadoAtual[1],aDadoOutr[1])//Verifico qual a menor data
		nMaiCompr 	:= iif(aDadoAtual[2] > aDadoOutr[2],aDadoAtual[2],aDadoOutr[2])//Verifico a maior compra
		nNumComprs 	:= aDadoAtual[3]+aDadoOutr[3] //Somo o número de compras
		nVacumPed 	:= aDadoAtual[4]+aDadoOutr[4]//Somo os valores acumulados
	
		//Ajusto os valores do financeiro - Também é cadastro mas conceitualmente separado
		nMsaldCli	:= iif(SA1->A1_MSALDO > aDadoAtual[5]+aDadoOutr[5],SA1->A1_MSALDO,aDadoAtual[5]+aDadoOutr[5])//Comparo a soma com o que está gravado pra pegar o maior
		nMedAtrCl	:= retMedAtr(aDadoAtual[6],aDadoOutr[6])//(aDadoAtual[6]+aDadoOutr[6])/2//Somo e divido por 2 para obter a média das duas empresas
	 	nSldTitCl	:= aDadoAtual[7]+aDadoOutr[7]//O saldo em aberto é a soma dos dois 
	 	nNroPgCli	:= aDadoAtual[8]+aDadoOutr[8]//O número de pagamentos é a soma das duas empresas
		nVlAtrCli	:= aDadoAtual[9]+aDadoOutr[9]//Valor em atraso é a soma das duas empresas 
		nMAtrCli	:= aDadoAtual[10]+aDadoOutr[10]//Maior atraso é o valor, então somo das duas empresas 
		nMmaDupl	:= iif(aDadoAtual[11] > aDadoOutr[11],aDadoAtual[11],aDadoOutr[11])//Comparo pra pegar o maior valor 
		nSldDplC	:= aDadoAtual[12]+aDadoOutr[12]//Saldo das duplicatas é a soma das duas empresas 
		nNroPgAt	:= aDadoAtual[13]+aDadoOutr[13]//Somo o valor dos pagamentos em atraso
	
		//Gravo os dados na tabela SA1
		if recLock("SA1",.F.)
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
	restArea(aAreaSA1)
	restArea(aAreaSE1)
	restArea(aAreaSC5)
	restArea(aAreaSF2)
	restArea(aArea)
	
return

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
	
	//Se nenhuma data está preenchida é porque é a primeira compra
	if empty(dData1) .and. empty(dData2)
		dDatRet := dDataBase
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

Static Function retMedAtr(nMed1,nMed2)
/*/{Protheus.doc} retMedAtr
Retorna a média de atraso de pagamentos com base no cálculo das duas empresas
@author Fabio Branis
@since 21/12/2014
@version 1.0
@param nMed1, float, Média da empresa 1
@param nMed2, float, Média da empresa 2
@return nRet, Média Calculada
/*/
	Local nRet	:= 0
	
	do case
	case nMed1 <> 0 .and. nMed2 <> 0
		nRet := (nMed1 + nMed2) / 2
	case nMed1 <> 0 .and. nMed2 == 0
		nRet := nMed1
	case nMed1 == 0 .and. nMed2 <> 0
		nRet := nMed2
	endcase
	
return nRet