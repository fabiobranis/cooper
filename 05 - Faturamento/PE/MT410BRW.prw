#Include 'Protheus.ch'
/*/{Protheus.doc} MT410BRW
Ponto de entrada para permitir a inclusão de funcionalidades no browse da rotina.
@author Fabio Branis
@since 19/12/2014
@version 1.0
/*/
User Function MT410BRW()
	
	do case
	//Horizon ou Cooper
	case SM0->M0_CODIGO == "20" .or. SM0->M0_CODIGO == "30"
		incRot()// Projeto do grupo econômico - Gravo os dados
	endcase
	
Return

Static Function incRot()
/*/{Protheus.doc} incRot
Inclui chamadas de rotinas no aRotina da função
@author Fabio Branis
@since 19/12/2014
@version 1.0
/*/
	aadd(aRotina,{"Aprovar Pedido","U_FSFAT003()",0,1}) //Adciono no a Rotina a chamada para a função para aprovação do pedido
return
