#Include 'Protheus.ch'

/*/{Protheus.doc} SF2460I
Ponto de entrada executado apos a geracao da nota fiscal, obtendo
a lista de titulos a receber para geracao dos boletos.
@author Fabio Branis
@since 10/01/2015
@version 1.0
/*/
User Function SF2460I()

	Public _aS_F_2_
	
	//Controlo se a variável já foi criada
	If ValType(_aS_F_2_) == "U"
		_aS_F_2_ := {}
	EndIf
	
	AADD(_aS_F_2_,{SF2->F2_PREFIXO,SF2->F2_DUPL})

Return