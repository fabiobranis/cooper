#Include 'Protheus.ch'
#Include "colors.ch"

/*/{Protheus.doc} F060VLOK
Ponto de entrada executado apos confirmar bordero, com objetivo de
selecionar a sub-conta. 
@author Fabio
@since 10/01/2015
@version 1.0
@return .T., Retorno padrão da rotina
/*/
User Function F060VLOK()
	Local aArea  := GetArea()
	Local aAreaEE:= SEE->(GetArea())
	Local cBanco := PARAMIXB[2] //Banco
	Local cAgenc := PARAMIXB[3] //Agencia
	Local cConta := PARAMIXB[4] //Conta
	Local oDlg,oBoxPv,aCBoxPv,cSubConta
	Local nOpca := 0

	Public _cSub_SEE := Space(3)

	aCBoxPv := {}

	//Procuro a subconta 
	dbSelectArea("SEE")
	dbSetOrder(1)
	dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta)
	While !Eof() .and. SEE->(EE_FILIAL+EE_CODIGO+EE_AGENCIA+EE_CONTA) == xFilial("SEE")+cBanco+cAgenc+cConta
		If !Empty(SEE->EE_SUBCTA)
			aAdd(aCBoxPv,SEE->EE_SUBCTA)
		Endif
		dbSelectArea("SEE")
		dbSkip()
	End
	
	//Browse para confirmar a subconta
	If Len(aCBoxPv) > 1
		cSubConta := aCBoxPv[1]
		DEFINE MSDIALOG oDlg TITLE "Selecionar a sub-conta utilizada no borderô:" From 9,0 To 15,60 OF oMainWnd
	
		@ 005, 002 Say "Banco "	 SIZE 40, 7 OF oDlg PIXEL
		@ 005, 035 MSGET cBanco  Picture "@!" F3 "SA6" SIZE 40,8 OF oDlg PIXEL HASBUTTON When .F.
		@ 005, 082 Say "Agência" SIZE 40, 7 OF oDlg PIXEL
		@ 005, 107 MSGET cAgenc	 Picture "@!" SIZE 40,8 OF oDlg PIXEL When .F.
		@ 005, 164 Say "Conta"   SIZE 40, 7 OF oDlg PIXEL
		@ 005, 184 MSGET cConta	 Picture "@!" SIZE 40,8 OF oDlg PIXEL When .F.
	
		@ 020, 002 Say "Sub-Conta "	SIZE 40, 7 OF oDlg PIXEL COLOR CLR_HBLUE
		@ 020, 035 combobox oBoxPv var cSubConta items aCBoxPv size 70,08 of oDlg pixel
	
		DEFINE SBUTTON FROM 020,170  TYPE 1 ACTION (nOpca := 1,oDlg:End()) ENABLE OF oDlg
		DEFINE SBUTTON FROM 020,200  TYPE 2 ACTION oDlg:End() ENABLE OF oDlg
	
		ACTIVATE MSDIALOG oDlg CENTERED
	
		IF nOpca == 0
			RestArea(aAreaEE)
			RestArea(aArea)
			Return .F.
		Endif
		_cSub_SEE := cSubConta
	
	ElseIf Len(aCBoxPv) == 1
		_cSub_SEE := aCBoxPv[1]
	Endif

	RestArea(aAreaEE)
	RestArea(aArea)

Return .T.