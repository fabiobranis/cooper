#Include 'Protheus.ch'
/*/{Protheus.doc} MTVALAVC
Ponto de entrada executado pelo FATXFUN, neste ponto de entrada é recuperado o valor de crédito que o 
cliente possui para a crítica do mesmo no ato da liberação do pedido, por exemplo (MATA440).
Solutti/Sagaris
@author Fabio Nunes
@since 13/12/2014
@version 1.0
@param paramxib[1], String, Nome da função que foi chamada no íncio da Stack da thread corrente
@param paramxib[2], Float, Valor de crédito do cliente
@return nValCrAvc, Valor do crédito alterado
@see Em caso de dúvidas, fabiobranis@gmail.com - Sagaris Consultoria e Sistemas
/*/
User Function MTVALAVC()
	
	Local nValCrAvc	:= paramxib[2]
	
	do case
	//Horizon ou Cooper
	case SM0->M0_CODIGO == "20" .or. SM0->M0_CODIGO == "30" 
		//Busco o valor de acordo com o grupo econômico
		nValCrAvc := retValGrp()
	endcase

return nValCrAvc

Static Function retValGrp()
/*/{Protheus.doc} retValGrp
Função que retorna o valor de crédito do grupo econômico
@author Fabio Nunes
@since 13/12/2014
@version 1.0
@return nValGrpEc, Integer contendo o valor de crédito do cliente ou grupo econômico
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
	//Retorno o sistema para o status anterior, para não dar zebra no resto do processo
	restArea(aArea)
	restArea(aAreaSA1)
return nValGrpEc