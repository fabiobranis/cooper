#Include 'Protheus.ch'
/*/{Protheus.doc} MS520DEL
Ponto de entrada executado pelo MATA521, neste ponto de entrada é permitido customizar a rotina de 
exclusão de notas fiscais de saída. 
Solutti
@author Fabio Branis
@since 17/12/2014
@version 1.0
/*/
User Function MS520DEL()

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
		
		
		//Ajusto os valores de cadastro de cliente
		dPrimCompr 	:= retPrimCpr(aDadoAtual[1],aDadoOutr[1])//Verifico qual a menor data
		nMaiCompr 	:= iif(aDadoAtual[2] > aDadoOutr[2],aDadoAtual[2],aDadoOutr[2])//Verifico a maior compra
		nNumComprs 	:= aDadoAtual[3]+aDadoOutr[3] //Somo o número de compras
		nVacumPed 	:= aDadoAtual[4]+aDadoOutr[4]//Somo os valores acumulados
	
	
		//Gravo os dados na tabela SA1
		if reckLock("SA1",.F.)
			//Relativo ao processo de faturamento
			SA1->A1_PRICOM 	:= dPrimCompr
			SA1->A1_ULTCOM 	:= dUltCompr
			SA1->A1_ULTCEM 	:= cUltEmpCpr
			SA1->A1_MCOMPRA := nMaiCompr
			SA1->A1_NROCOM	:= nNumComprs
			SA1->A1_VACUM	:= nVacumPed
			
			msUnlock("SA1")
		endif
	
	endif
	restArea(aAreaSA1)
	restArea(aAreaSE1)
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
