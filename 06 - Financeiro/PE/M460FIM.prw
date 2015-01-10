#Include 'Protheus.ch'

/*/{Protheus.doc} M460FIM
Ponto de entrada executado na preparacao do documento, com objetivo
de chamar outro ponto de entrada de impressao de boletos 
@author Fabio Branis
@since 10/01/2015
@version 1.0
/*/
User Function M460FIM()
	//Caso o fonte tenha sido chamado pelo pedido de venda
	If AllTrim(funname()) $ "MATA410/MATA461"
		U_M460NOTA()	
	EndIf
Return