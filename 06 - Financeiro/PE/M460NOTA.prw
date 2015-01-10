#Include 'Protheus.ch'

/*/{Protheus.doc} M460NOTA
Ponto de entrada 'M460NOTA', executado ao final do processamento de
todas as notas fiscais selecionadas na markbrowse.
Alimenta os parâmetros dos boletos e chama o programa de impressão de boletos
@author Fabio Branis
@since 10/01/2015
@version 1.0
/*/      
User Function M460NOTA()

	Local aBoletos	:= {}
	Local aDBF2		:= {}   
	Local aSE1		:= {}
	Local nI 		:= 0
	Local nX 		:= 0   
	
	Public _aS_F_2_      
	
	//Parâmetro que controla a impressão a partir das notas fiscais
	If SuperGetMV("MV_XBOLNF",.F.,"N") <> "S"
		Return NIL
	Endif
	
	//Verifica se já houve preenchimento da variável pública das notas
	If ValType(_aS_F_2_) == "U"
		_aS_F_2_ := {}
	EndIf
                                 	
	DbSelectArea("SE1")
	aDBF2 := dbStruct()
	
	//Percorro as notas fiscais
	For nX := 1 To Len(_aS_F_2_)

		DbSelectArea("SE1")
		DbSetOrder(1)	
		
		If DbSeek(xFilial("SE1")+_aS_F_2_[nX][1]+_aS_F_2_[nX][2])
			While !EoF() .And. SE1->E1_NUM == _aS_F_2_[nX][2] .And. SE1->E1_PREFIXO == _aS_F_2_[nX][1];
			 .And. SE1->E1_FILIAL == xFilial("SE1")                                                
			 
			 	aSE1 := {}
			 	
			 	//Adiciono aos valor ao array auxiliar dos boletos
				For nI := 1 To Len(aDBF2)    
		 			AADD(aSe1, {aDBF2[nI][1], &("SE1->"+(aDBF2[nI][1]))})
				Next
				
				//Adciono valor ao array dos boletos
				AADD(aBoletos, aSE1)
				
				DbSelectArea("SE1")
				DbSkip()
			EndDo
		EndIf
	
	Next
	
	//Se houver boletos e o usuário optar por gerar
	If Len(aBoletos) > 0 .And. MsgYesNo("Deseja gerar boleto?")
		//Filtro Tela de Faturamento
		cPerg2	:= "FSFIN201"
		PutSx1(cPerg2,"01","Do Banco:"				,"","","mv_ch1" ,"C",03,0,0,"G","","SA6"	,"","","mv_par01",""   				,"","","",""  			,"","","","","","","","","","","")
		PutSx1(cPerg2,"02","Agencia:"				,"","","mv_ch2" ,"C",05,0,0,"G","",""		,"","","mv_par02",""   				,"","","",""  			,"","","","","","","","","","","")
		PutSx1(cPerg2,"03","Conta:"					,"","","mv_ch3" ,"C",10,0,0,"G","",""		,"","","mv_par03",""  				,"","","",""  			,"","","","","","","","","","","")
		PutSx1(cPerg2,"04","SubConta:" 				,"","","mv_ch4" ,"C",03,0,0,"G","","SEESUB"		,"","","mv_par04",""  				,"","","","" 			,"","","","","","","","","","","")
		If Pergunte(cPerg2,.T.,"Boleto")
			U_FSFIN001(aBoletos)//Chamo a rotina de impressão
		EndIf

	EndIf
	
	_aS_F_2_ := {}
Return