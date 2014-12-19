#INCLUDE "RWMAKE.CH"
/*
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FSFAT001   | Desenvolvedor  | Leandro (SOLUTII) | Data  | 15/11/2014    |
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Cadastro de grupo economico											  |
+-----------+-------------------------------------------------------------------------+
| Modulos   |                                                                         |
+-----------+-------------------------------------------------------------------------+
| Processos |                                                                         |
+-----------+-------------------------------------------------------------------------+
|                  Modificacoes desde a construcao inicial                            |
+----------+-------------+------------------------------------------------------------+
| DATA     | PROGRAMADOR | MOTIVO                                                     |
+----------+-------------+------------------------------------------------------------+
|          |             |                                                            |
+----------+-------------+------------------------------------------------------------+
*/
User Function FSFAT001()
	Private cCadastro	:= OemToAnsi("Grupo Econômico")
	Private aRotina		:= {{"Pesquisar"	,"AxPesqui"	,0,1},;
							{"Visualizar"	,"U_fCadGRP",0,2},;
							{"Incluir"		,"U_fCadGRP",0,3},;
							{"Alterar"		,"U_fCadGRP",0,4},;
							{"Excluir"		,"U_fCadGRP",0,5}}
	
	mBrowse(6,8,22,71,"SZ0")
Return()

User Function fCadGRP(cAlias,nRecno,nOpc)
/*********************************************************************************************
* Tela de cadastro
*
**/                         
	Local lRet
	SetPrvt("NOPCE,NOPCG,NUSADO,AHEADER")
	SetPrvt("ACOLS,_NI,CTITULO,CALIASENCHOICE,CALIASGETD,CLINOK")
	SetPrvt("CTUDOK,CFIELDOK,ACPOENCHOICE")

	nOpcE:= nOpc
	nOpcG:= nOpc

	RegToMemory("SZ0",(nOpc==3))                   
	If (nOpc==3)
		M->Z0_CODIGO:= fUltCod("SZ0","Z0_CODIGO")
	EndIf

	nUsado:=0
	dbSelectArea("SX3")
	dbSetOrder(1)
	dbSeek("SZ1")
	aHeader:={}
	Do While (!Eof()) .And. (SX3->X3_Arquivo == "SZ1")
		If (AllTrim(SX3->X3_CAMPO) $ "Z1_CODCLI/Z1_LOJCLI/Z1_NOMCLI/Z1_VALOR")
			If X3Uso(SX3->X3_Usado) .And. (cNivel >= SX3->X3_Nivel)
				nUsado := nUsado+1
				Aadd(aHeader,{TRIM(x3_titulo),;
				x3_campo, ;
				x3_picture, ;
				x3_tamanho, ;
				x3_decimal,"AllwaysTrue()", ;
				x3_usado  ,;
				x3_tipo   ,;
				x3_arquivo,;
				x3_context})
			EndIf
		EndIf
				   
		dbSelectArea("SX3")
		dbSkip() 
	EndDo
	
	If (nOpc==3)
		aCols:={Array(nUsado+1)}
		aCols[1,nUsado+1]:=.F.
		For _ni:=1 to nUsado
			aCols[1,_ni]:= CriaVar(aHeader[_ni,2])
		Next
	Else
		aCols:={}
		dbSelectArea("SZ1")
		dbSetOrder(1)
		dbSeek(xFilial("SZ1")+M->Z0_CODIGO)
		Do While !eof() .And. SZ1->Z1_FILIAL==M->Z0_FILIAL .And. SZ1->Z1_CODGRP==M->Z0_CODIGO
			AADD(aCols,Array(nUsado+1))   
			
			For _ni:=1 to nUsado                                        
				If (AllTrim(aHeader[_ni,2])!="Z1_NOMCLI")
					aCols[Len(aCols),_ni]:= FieldGet(FieldPos(aHeader[_ni,2]))
				Else                        
					aCols[Len(aCols),_ni]:= POSICIONE("SA1",1,XFILIAL("SA1")+SZ1->Z1_CODCLI,"A1_NOME")
				EndIf
			Next
			aCols[Len(aCols),nUsado+1]:= .F.//valida linha deletada
			
			dbSelectArea("SZ1")
			dbSkip()
		EndDo
	EndIf
	
	cAliasEnchoice := "SZ0"
	cAliasGetD     := "SZ1"
	cLinOk         := "U_fValVR(nOpcG)"
	cTudOk         := "AllwaysTrue()"
	cFieldOk       := "U_fDescr(nOpcG)"
	aCpoEnchoice   := {}
                                                                                     
	lRet:= Modelo3(cCadastro,cAliasEnchoice,cAliasGetD,aCpoEnchoice,cLinOk,cTudOk,nOpcE,nOpcG,cFieldOk)
	
	If lRet
		fGGRP(nOpc)
		ConfirmSx8()
	Else   
		RollBackSx8()
	EndIf
Return()

Static Function fGGRP(nTipo)
/******************************************************************
* Funcao para gravar
* 
***/
	Local nInd := 0
	Local nPosCli:= Ascan(aHeader, {|x| Upper(Alltrim(x[2])) == "Z1_CODCLI"})
	Local nPosVal:= Ascan(aHeader, {|x| Upper(Alltrim(x[2])) == "Z1_VALOR"})
	Local nPosLoj:= Ascan(aHeader, {|x| Upper(Alltrim(x[2])) == "Z1_LOJCLI"})

	//ENCHOICE
	If (nTipo==3 .or. nTipo==4)
		//Grava enchoice
		dbSelectArea("SZ0")
		dbSetOrder(1)
		If dbSeek(xFilial("SZ0")+M->Z0_CODIGO)
			RecLock("SZ0",.F.)
		Else
			RecLock("SZ0",.T.)
		EndIf
		
		Replace SZ0->Z0_Filial  With  xFilial("SZ5"),;
				SZ0->Z0_CODIGO	With  M->Z0_CODIGO,;
				SZ0->Z0_NOME	With  M->Z0_NOME,;
				SZ0->Z0_VALOR	With  M->Z0_VALOR
		MsUnLock()
	ElseIf (nTipo==5)
		dbSelectArea("SZ0")   
		dbSetOrder(1)
		If dbSeek(xFilial("SZ0")+M->Z0_CODIGO)
			If RecLock("SZ0",.F.)
				dbDelete()
				MsUnLock()
			EndIf
		EndIf
	EndIf
	//FIM - ENCHOICE

	//GETDADOS	
	If (nTipo==3 .or. nTipo==4)
		//SEMPRE DELETA TUDO E RECRIAR COM NOVO CODIGO
		dbSelectArea("SZ1")
		dbsetorder(1)
		If dbSeek(xFilial("SZ1")+M->Z0_CODIGO)
			Do While !SZ1->(Eof()) .And. (SZ1->Z1_FILIAL==M->Z0_FILIAL) .And. (SZ1->Z1_CODGRP==M->Z0_CODIGO)
				If RecLock("SZ1",.F.)
					dbdelete()
					MsUnlock()                                             
				EndIf                                                      
				
				SZ1->(dbSkip())
			EndDo
		EndIf
		//FIM - SEMPRE DELETA TUDO E RECRIAR COM NOVO CODIGO
		
		//Grava Dados
		For nInd := 1 To Len(aCols)
			If (!aCols[nInd,nUsado + 1])
				If RecLock("SZ1",.T.)
					Replace SZ1->Z1_Filial  With xFilial("SZ1"),;
							SZ1->Z1_CODIGO	With fUltCod("SZ1","Z1_CODIGO"),;
							SZ1->Z1_CODGRP 	With M->Z0_CODIGO,;
							SZ1->Z1_CODCLI	With aCols[nInd,nPosCli],;
							SZ1->Z1_LOJCLI	With aCols[nInd,nPosLoj],;
							SZ1->Z1_VALOR	With aCols[nInd,nPosVal]
					MsUnLock()
				EndIf
			EndIf
		Next
	EndIf
	//FIM - GETDADOS	
Return()

User Function fDescr(nTipo)
/******************************************************************
* Retorna a descricao dos itens nos getdados
*
***/                  
	Local nDescCli	:= ""
	Local lOk		:= .T.
	                              
	If (nTipo==3 .or. nTipo==4)
		If (Type("M->Z1_CODCLI")!="U")
			nDescCli:= Ascan(aHeader, {|x| Upper(Alltrim(x[2])) == "Z1_NOMCLI"})
			If (AllTrim(M->Z1_CODCLI)!="")
				aCols[N][nDescCli]:= POSICIONE("SA1",1,xFilial("SA1")+M->Z1_CODCLI,"A1_NOME")
				lOk:= (AllTrim(aCols[N][nDescCli])!="")
			EndIf
		EndIf
	EndIf
	
	If !lOk
		MSGBox(OemToAnsi("Código não encontrado na base!"),OemToAnsi("Atenção!!!"),"INFO")        
	EndIf
Return(lOk)

User Function fValVR(nTipo)
/******************************************************************
* Funcao para validacao do Valor do credito por cliente
*
***/
	Local lOk		:= .T.                                                                                                           
	Local lOKCLI	:= .T.
	Local nInd 
	Local nPosVR	:= Ascan(aHeader, {|x| Upper(Alltrim(x[2])) == "Z1_VALOR"})
	Local nPosCLI	:= Ascan(aHeader, {|x| Upper(Alltrim(x[2])) == "Z1_CODCLI"})
	Local nTot1		:= 0
	Local nTot2		:= 0
	Local cQuery

	If (nTipo==3 .or. nTipo==4)
		nTot1:= M->Z0_VALOR
		If !aCols[N][Len(aHeader)+1]
			For nInd:= 1 To Len(aCols)
				If !aCols[nInd][Len(aHeader)+1]
					If (nInd!=N)
						If (aCols[N][nPosCLI]==aCols[nInd][nPosCLI]) //SE O CLIENTE JÁ ESTIVER NO GRUPO NÃO PERMITE CADASTRAR NOVAMENTE  
							MSGBox(OemToAnsi("O cliente "+AllTrim(aCols[N][nPosCLI])+" já foi incluído na linha "+AllTrim(Str(nInd))+"!"),OemToAnsi("Atenção!!!"),"INFO")        
							lOKCLI:= .F.
						EndIf
					EndIf
					nTot2+= aCols[N][nPosVR]
				EndIf
			Next nInd
		EndIf

		If lOKCLI		
			cQuery:= "SELECT Z1_CODGRP,Z1_CODCLI FROM "+RetSqlName("SZ1")
			cQuery+= " WHERE D_E_L_E_T_<>'*'"
			cQuery+= "   AND Z1_FILIAL='"+xFilial("SZ1")+"'"
			cQuery+= "   AND Z1_CODGRP<>'"+M->Z0_CODIGO+"'"
			cQuery+= "   AND Z1_CODCLI='"+aCols[N][nPosCLI]+"'"
			dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "QSZ1", .F., .T.)
			dbSelectArea("QSZ1")
			QSZ1->(dbGoTop())
			If (AllTrim(QSZ1->Z1_CODCLI)!="")
				MSGBox(OemToAnsi("O cliente "+AllTrim(aCols[N][nPosCLI])+" já foi incluído no grupo "+AllTrim(QSZ1->Z1_CODGRP)+"!"),OemToAnsi("Atenção!!!"),"INFO")        
				lOKCLI:= .F.
			EndIf
			dbSelectArea("QSZ1")
			QSZ1->(dbCloseArea())
		EndIf
	EndIf
	
	If (nTot2>nTot1)
		MSGBox(OemToAnsi("O somatório dos valores dos créditos dos clientes está maior que o valor total do crédito do grupo!"),OemToAnsi("Atenção!!!"),"INFO")        
	EndIf
	
	lOk:= ((nTot2<=nTot1) .And. lOKCLI)
Return(lOk)

Static Function fUltCod(cTab,cCampo1)
/*******************************************************************************
* Funcao para buscar o ultimo codigo
*
**/
	Local aArea	:= GetArea()
	Local cQuery:= ""
	Local cAlTab:= "Q"+AllTrim(cTab)
	Local cCod	:= ""
	                                        
	cQuery:= " SELECT "+AllTrim(cCampo1)+" FROM "+RetSqlName(cTab)+" WHERE D_E_L_E_T_=' ' ORDER BY "+AllTrim(cCampo1)+" DESC"
	
	cQuery:= ChangeQuery(cQuery)	     
	//memowrite("C:\cquery.sql",cquery) 
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlTab,.F.,.T.)
	
	dbselectarea(cAlTab)
	(cAlTab)->(dbGoTop())
	If (AllTrim((cAlTab)->(&(cCampo1)))!="") //SE NAO HOUVER REGISTRO NA TABELA DEVE RETORNAR O CODIGO 1
		cCod:= StrZero( (Val((cAlTab)->(&(cCampo1)))+1), TamSX3(cCampo1)[1] )
	Else
		cCod:= StrZero(1, TamSX3(cCampo1)[1])
	EndIf
	dbselectarea(cAlTab)
	(cAlTab)->(dbCloseArea())
		
	RestArea(aArea)
Return(cCod)