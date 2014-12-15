#Include 'Protheus.ch'
/*/{Protheus.doc} MTVALAVC
Ponto de entrada executado pelo FATXFUN, neste ponto de entrada � recuperado o valor de cr�dito que o 
cliente possui para a cr�tica do mesmo no ato da libera��o do pedido, por exemplo (MATA440).
Solutti/Sagaris
@author Fabio Nunes
@since 13/12/2014
@version 1.0
@param paramxib[1], String, Nome da fun��o que foi chamada no �ncio da Stack da thread corrente
@param paramxib[2], Float, Valor de cr�dito do cliente
@return nValCrAvc, Valor do cr�dito alterado
@see Em caso de d�vidas, fabiobranis@gmail.com - Sagaris Consultoria e Sistemas
/*/
User Function MTVALAVC()
	
	Local nValCrAvc	:= paramxib[2]
	
	do case
	//Horizon ou Cooper
	case SM0->M0_CODIGO == "20" .or. SM0->M0_CODIGO == "30" 
		//Busco o valor de acordo com o grupo econ�mico
		nValCrAvc := retValGrp()
	endcase

return nValCrAvc

Static Function retValGrp()
/*/{Protheus.doc} retValGrp
Fun��o que retorna o valor de cr�dito do grupo econ�mico
@author Fabio Nunes
@since 13/12/2014
@version 1.0
@return nValGrpEc, Integer contendo o valor de cr�dito do cliente ou grupo econ�mico
/*/
	Local nValGrpEc	:= 0
	//Salvo a tabela e registro posicionado tanto para a tabela posicionada quanto para a SA1 onde farei um dbseek()
	Local aArea		:= GetArea()
	Local aAreaSA1	:= SA1->(GetArea())

	SA1->(dbsetorder(1))
	if SA1->(dbseek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJA))
		
		SZ0->(dbsetorder(1))
		
	else
	endif
	//Retorno o sistema para o status anterior, para n�o dar zebra no resto do processo
	restArea(aArea)
	restArea(aAreaSA1)
return nValGrpEc