#INCLUDE "RWMAKE.CH"        
#INCLUDE "TOPCONN.CH"
/*/{Protheus.doc} FSFIN001
Rotina de gração de boletos para a empresa Cooper
@author Fabio Branis
@since 08/01/2015
@version 1.0
@param aBoletos, Array, Vem preenchido através de pontos de entrada com boletos pré selecionados
/*/
User Function FSFIN001(aBoletos)

	Local   nOpc 		:= 1
	Local	nX			:= 0
	Local	nJ			:= 0
	Local	aCabec		:= {}
	Local   aMarked 	:= {}
	Local   cDesc 		:= "Este programa imprime os boletos de"+chr(13)+"cobranca bancaria de acordo com"+chr(13)+"os parametros informados"
	Local 	cQuery		:= ""
	Local	_lInverte	:= .F.
	Local	_cMarca		:= GetMark()  
	Local 	_oDlg       
	Local	oMark          
	Local	oBrowse    
	Local	oImgMark
	Local	oImgDMark

	Private BB			:= .F.
	Private BRADESCO	:= .F.
	Private ITAU		:= .F.
	Private	aTitulos	:= {}   
	Private cLocPagto	:= ""
	Private Exec    	:= .F.  
	Private lMarcar		:= .T.
	Private cIndexName 	:= ''
	Private cIndexKey  	:= ''
	Private cFilter    	:= ''
	Private cPerg		:= "FSFIN001"
	Private cAliasSE1 
	Private lAutoExec   
	
	Private _MV_PAR01
	Private _MV_PAR02
	Private _MV_PAR03
	Private _MV_PAR04
	Private _MV_PAR05
	Private _MV_PAR06
	Private _MV_PAR07
	Private _MV_PAR08
	Private _MV_PAR09
	Private _MV_PAR10
	Private _MV_PAR11
	Private _MV_PAR12
	Private _MV_PAR13
	Private _MV_PAR14
	Private _MV_PAR15
	Private _MV_PAR16
	Private _MV_PAR17
	Private _MV_PAR18
	Private _MV_PAR19
	Private _MV_PAR20
	Private _MV_PAR21
	Private _MV_PAR22
	Private _MV_PAR23
	Private _MV_PAR24
	Private _MV_PAR25
	Private _MV_PAR26
	Private _MV_PAR27
	
	aBoletos := IIF(aBoletos==Nil,{},aBoletos)  
	
	lAutoExec := Len(aBoletos) > 0     
			
	dbSelectArea("SE1")
	
	If !lAutoExec
	
		ValidPerg()
			
		If !Pergunte (cPerg,.T.)
			Return
		EndIf
		
		//Configura os parametros
		_MV_PAR01 := MV_PAR01 //Do Prefixo:
		_MV_PAR02 := MV_PAR02 //Ate o Prefixo:
		_MV_PAR03 := MV_PAR03 //Do Titulo:
		_MV_PAR04 := MV_PAR04 //Ate o Titulo:
		_MV_PAR05 := MV_PAR05 //Da Parcela:
		_MV_PAR06 := MV_PAR06 //Ate a Parcela:
		_MV_PAR07 := MV_PAR07 //Do Banco:
		_MV_PAR08 := MV_PAR08 //Agencia:
		_MV_PAR09 := MV_PAR09 //Conta:
		_MV_PAR10 := MV_PAR10 //SubConta:
		_MV_PAR11 := MV_PAR11 //Do Cliente:
		_MV_PAR12 := MV_PAR12 //Ate o Cliente:
		_MV_PAR13 := MV_PAR13 //Da Loja:
		_MV_PAR14 := MV_PAR14 //Ate a Loja:
		_MV_PAR15 := MV_PAR15 //Da Data de Vencimento:
		_MV_PAR16 := MV_PAR16 //Ate a Data de Vencimento:
		_MV_PAR17 := MV_PAR17 //Da Data Emissão:
		_MV_PAR18 := MV_PAR18 //Ate a Data de Emissão:
		_MV_PAR19 := MV_PAR19 //Do bordero:
		_MV_PAR20 := MV_PAR20 //Ate o Bordero:
		_MV_PAR21 := MV_PAR21 //Selecionar Títulos:
		_MV_PAR22 := MV_PAR22 //Gerar Bordero

		If Empty(MV_PAR04) .Or. Empty(MV_PAR06) .Or. Empty(MV_PAR12) .Or. Empty(MV_PAR18) .Or. Empty(MV_PAR16) .Or. Empty(MV_PAR14) .Or. Empty(MV_PAR20)
			VerParam("Você deve selecionar um intervalo de valores em todos os parâmetros!")
			Return
		EndIf

		nOpc := Aviso("Impressao do Boleto Laser",cDesc,{"Ok","Cancelar"})
	Else
		//COnfigura os parametros
		_MV_PAR21 := 1
		_MV_PAR22 := 1 //Gerar Bordero

		//Dados do Banco		
		_MV_PAR07 := MV_PAR01
		_MV_PAR08 := MV_PAR02
		_MV_PAR09 := MV_PAR03
		_MV_PAR10 := MV_PAR04
		
	EndIf

	If nOpc == 1
	 
		dbSelectArea("SE1")
		aStruTRB := dbStruct()
		
		If !lAutoExec
		
			cQuery := "SELECT  "
				
			For nI:=1 To Len(aStruTRB)
				cQuery += aStruTRB[nI][1]+","
			Next nI
			
			cQuery += " SE1.R_E_C_N_O_  AS NREG "
			cQuery += " FROM "+	RetSqlName("SE1") + " SE1 "
			cQuery += " WHERE E1_NUM   >= '" 	+ _MV_PAR03 		+ "' And E1_NUM     <= '" 	+ _MV_PAR04 + "'  " 
			cQuery += " AND E1_PARCELA >= '" 	+ _MV_PAR05 		+ "' And E1_PARCELA <= '"	+ _MV_PAR06 + "'  " 
			cQuery += " AND E1_CLIENTE >= '" 	+ _MV_PAR11 		+ "' And E1_CLIENTE <= '"	+ _MV_PAR12 + "' " 
			cQuery += " AND E1_EMISSAO >= '" 	+ DTOS(_MV_PAR17)	+ "' And E1_EMISSAO <= '"	+ DTOS(_MV_PAR18) + "' " 
			cQuery += " AND E1_VENCTO  >= '" 	+ DTOS(_MV_PAR15)	+ "' And E1_VENCTO  <= '" 	+ DTOS(_MV_PAR16) + "' "
			cQuery += " AND E1_LOJA    >= '"	+ _MV_PAR13			+ "' And E1_LOJA    <= '"	+ _MV_PAR14 + "' "
			If _MV_PAR22 == 2 //Nao gera bordero
				cQuery += " AND E1_NUMBOR  >= '"	+ _MV_PAR19			+ "' And E1_NUMBOR  <= '"	+ _MV_PAR20 + "' "
				If !Empty(_MV_PAR07)
					cQuery += " AND E1_PORTADO = '" + _MV_PAR07 + "' "
				Endif
			Else
				cQuery += " AND E1_NUMBCO = '' AND E1_NUMBOR = '' " //Se gera bordero, somente selecionara os titulos sem boleto
			Endif
			cQuery += " AND E1_FILIAL = '"		+ xFilial("SE1")	+ "' And E1_SALDO > 0  " 
			cQuery += " AND SUBSTRING(E1_TIPO,3,1) != '-' "  
			cQuery += " AND D_E_L_E_T_ = ' ' "
		    cQuery += " ORDER BY E1_PORTADO, E1_CLIENTE, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_EMISSAO "
	   EndIf
	
		If Select("TRB1") <> 0
			dbSelectArea("TRB1")
			dbCloseArea()
		EndIf
		
		cAliasSE1 := "TRB1"
		cNomeArq:=CriaTrab( aStruTRB, .T. )
		dbUseArea(.T.,__LocalDriver,cNomeArq,cAliasSE1,.T.,.F.)
		
		If !lAutoExec                                        
			MsAguarde({|| SqlToTrb(cQuery, aStruTRB, cAliasSE1 )},OemToAnsi("Executando Query..."))
		Else                         
			//Criado no ponto de entrada M460NOTA
			For nX:=1 To Len(aBoletos)
				RecLock(cAliasSE1, .T.)
					For nJ:=1 To Len(aBoletos[nX])
						aDados := aBoletos[nX][nJ]
						&(cAliasSE1+"->"+aDados[1]) := aDados[2]        
				   	Next
				MsUnlock()             
			Next
		EndIf
		
		DbSelectArea(cAliasSE1)
		DbGoTOp()
	
		If _mv_par21 == 1
			    
		    dbSelectArea(cAliasSe1)
		    dbGoTop()       
		    
		    While !EoF()
		        aTemp := {}
		        AADD(aTemp, !lMarcar)    
		        AADD(aTemp, (cAliasSe1)->E1_PREFIXO)    
		        AADD(aTemp, (cAliasSe1)->E1_NUM)      
		        AADD(aTemp, (cAliasSe1)->E1_PARCELA)  
		        AADD(aTemp, (cAliasSe1)->E1_TIPO)    
		        AADD(aTemp, (cAliasSe1)->E1_EMISSAO)  
		        AADD(aTemp, (cAliasSe1)->E1_VENCTO)    
		        AADD(aTemp, Transform((cAliasSe1)->E1_SALDO,x3Picture("E1_SALDO")))    
		        	
		        //Caso seja execucao automatica, deve verificar a condicao de pagamento
				If lAutoExec
			        AADD(aTitulos, aTemp)                                
		        Else                                             
		        	//Nao deve verificar porque no financeiro tem o esquema de agrupamento de NF
		        	AADD(aTitulos, aTemp)
		        EndIf
		        
		        (cAliasSe1)->(DbSkip())
		    EndDo     
		    
		    If Len(aTitulos) == 0
		    	Alert("Não foram encontrados títulos com os parametros informados!") 
		    	DbSelectArea("SE1") 
				RetIndex("SE1")
				FErase(cIndexName+OrdBagExt())        
				Return
		    EndIf  
		    			
			AADD(aCabec, "")
			AADD(aCabec, "Prefixo")
			AADD(aCabec, "Documento")
			AADD(aCabec, "Parcela")
			AADD(aCabec, "Tipo")
			AADD(aCabec, "Emissao")
			AADD(aCabec, "Vencimento")
			AADD(aCabec, "Valor")
		
			@ 001,001 TO 400,700 DIALOG _oDlg TITLE "Seleção de Titulos" 
			
			oImgMark 	:= LoadBitmap(GetResources(),'LBTIK')
			oImgDMark	:= LoadBitmap(GetResources(),'LBNO')  
			
			oBrowse:= TCBROWSE():New(001,001,350,170,,aCabec,{},_oDlg,,,,,{||},,_oDlg:oFont,,,,,.F.,,.T.,,.F.,,,)
			
			oBrowse:SetArray(aTitulos)
			oBrowse:lAdjustColSize 	:= .T.
			oBrowse:bLDblClick		:= {|nRow, nCol| aTitulos[oBrowse:nAt,01] := !aTitulos[oBrowse:nAt,01]}
			oBrowse:bChange			:= {||SetFocus(oBrowse:hWnd)} 
			oBrowse:bHeaderClick	:= {|nRow, nCol| If(nCol == 1,(lMarcacao(),oBrowse:Refresh()),Nil) }
			oBrowse:nAt				:= 1
			oBrowse:bLine 			:= {||{ If(	aTitulos[oBrowse:nAt,01],oImgMark,oImgDMark),;
												aTitulos[oBrowse:nAt,02],;
												aTitulos[oBrowse:nAt,03],;
												aTitulos[oBrowse:nAT,04],;
												aTitulos[oBrowse:nAT,05],;
												aTitulos[oBrowse:nAT,06],;
												aTitulos[oBrowse:nAT,07],;
												aTitulos[oBrowse:nAT,08]}}
		    
	    
			@ 180,280 BMPBUTTON TYPE 01 ACTION (Exec := .T.,Close(_oDlg))
			@ 180,310 BMPBUTTON TYPE 02 ACTION (Exec := .F.,Close(_oDlg))
			ACTIVATE DIALOG _oDlg CENTERED
		EndIf
	EndIf
	
	//Execucao automatica
	If _mv_par21 == 2
		Exec := .T.
	EndIf
	
	For nX:=1 To Len(aTitulos)
		AADD(aMarked,IIF(_mv_par21 == 2,.T.,aTitulos[nX][1]))
	Next
	
	If Exec
		Processa({|lEnd| MontaRel(aMarked)}) 
	Endif
	
	DbSelectArea("SE1") 
	RetIndex("SE1")
	FErase(cIndexName+OrdBagExt())
	
Return Nil                   

//------------------------------------------------------------------------------------
// Inverte marcacao
//------------------------------------------------------------------------------------
Static Function lMarcacao()
	For nX:= 1 To Len(aTitulos)
		aTitulos[nX][1] := lMarcar
	Next
	lMarcar := !lMarcar
Return


Static Function MontaRel(aMarked)
/*/{Protheus.doc} MontaRel
Função que monta as informações que serão impressas no boleto.
Também persiste os dados das tabelas SEA e SEE referentes ao boleto e borderô
@author Fabio Branis
@since 08/01/2015
@version 1.0
@param aMarked, Array, Boletos Marcados para a Impressão
/*/
	Local oPrint                  
	Local aDatSacado     
	Local aBolText  
	Local lMark		:= .F.          
	Local CB_RN_NN  	:= {} 
	Local i        	:= 1 
	Local n 			:= 0
	Local nRec      := 0
	Local _nVlrAbat 	:= 0
	Local aBitmap   	:= {"" ,"\Bitmaps\Logo_Siga.bmp"}  //Logo da empresa                 
	Local aBMP		:= aBitMap                  
	Private aDadosEmp	:= {SM0->M0_NOMECOM                                                      	,; //Nome da Empresa
	                       AllTrim(SM0->M0_ENDCOB)                                          		,; //Endereço
	                       AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB 	,; //Complemento
	                       "CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             ,; //CEP
	                       "PABX/FAX: "+SM0->M0_TEL                                              ,; //Telefones
	                       "CNPJ: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+           	;
	                       Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+                    	;
	                       Subs(SM0->M0_CGC,13,2)                                             	,; //CGC
	                       "I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+      		;
	                       Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                      	}  //I.E
	
   
	Private aDadosTit                       
	Private aDadosBanco     
   
	DbSelectArea(cAliasSE1)
	dbGoTop()
	For nX:=1 To Len(aMarked)
		If !lMark
			lMark := aMarked[nX]
		EndIf
	Next
	If !lMark
		Alert("Você deve marcar ao menos um boleto para impressão!")
  		Return 		
	EndIf
   
	oPrint:= TMSPrinter():New( "Boleto Laser" )
	oPrint:Setup()
	oPrint:SetPortrait() 	// ou SetLandscape()
	oPrint:SetPaperSize(9)	// tamanho A4
	oPrint:StartPage()   	// Inicia uma nova página
               
   ProcRegua(nRec)
   
   Do While !EOF()    

	  If !aMarked[i]
		i++
		dbSkip()
		Loop
	  Endif

      //Posiciona o SA6 (Bancos)
      DbSelectArea("SA6")
      DbSetOrder(1)
      If !Empty((caliasSE1)->E1_AGEDEP) .And. _MV_PAR22 == 2
         DbSeek(xFilial("SA6")+(caliasSE1)->E1_PORTADO+(caliasSE1)->E1_AGEDEP+(caliasSE1)->E1_CONTA)  
      Else 
         DbSeek(xFilial("SA6")+_MV_PAR07+_MV_PAR08+_MV_PAR09)  
      Endif
      
      If Eof()
         MsgBox("Banco/Agência não Encontrado")
         Return()
      Endif
      
      SEA->(DbSetOrder(1))
      SEA->(DbSeek(xFilial("SEA")+(caliasSE1)->E1_NUMBOR+(caliasSE1)->E1_PREFIXO+(caliasSE1)->E1_NUM+(caliasSE1)->E1_PARCELA+(caliasSE1)->E1_TIPO))      
      //Posiciona o SEE (Parametros banco)
      DbSelectArea("SEE")
      DbSetOrder(1)
      If !Empty((caliasSE1)->E1_AGEDEP) .And. _MV_PAR22 == 2
         DbSeek(xFilial("SEE")+(caliasSE1)->(E1_PORTADO+E1_AGEDEP+E1_CONTA)+SEA->EA_SUBCTA)
      Else
         DbSeek(xFilial("SEE")+_MV_PAR07+_MV_PAR08+_MV_PAR09+_MV_PAR10)  
      Endif
      
      If Eof()
         MsgBox("Parametros Bancos Não Encontrado")
         Return()
      EndIf
      
      //Posiciona o SA1 (Cliente)
      DbSelectArea("SA1")
      DbSetOrder(1)
      DbSeek(xFilial("SA1")+(caliasSE1)->(E1_CLIENTE+E1_LOJA))
      
      If Len(Alltrim(SA1->A1_CGC))== 14
         cCpfCnpj:="CNPJ "+Transform(SA1->A1_CGC,"@R 99.999.999/9999-99")
      Else 
         cCpfCnpj:="CPF "+Transform(SA1->A1_CGC,"@R 999.999.999-99")
      Endif   
      
      DbSelectArea("SE1")
       
      aDadosBanco  := {SA6->A6_COD                                       ,;               //Numero do Banco
                       SA6->A6_NREDUZ                                       ,;               //Nome do Banco
                       Iif(SA6->A6_COD=="479",StrZero(Val(AllTrim(SA6->A6_AGENCIA)),7),SubStr(StrZero(Val(AllTrim(SA6->A6_AGENCIA)),4),1,4)+If(Empty(SA6->A6_DVAGE),"","-"+SA6->A6_DVAGE)),;   //Agência
                       Iif(SA6->A6_COD=="479",AllTrim(SEE->EE_CODEMP),AllTrim(SA6->A6_NUMCON)),;   //Conta Corrente
                       Iif(SA6->A6_COD=="479","",If(Empty(SA6->A6_DVCTA),"",SA6->A6_DVCTA))  ,;               //Dígito da conta corrente
                       AllTrim(SEE->EE_CARTEIR)+Iif(!Empty(AllTrim(SEE->EE_VARIACA)),"-"+SEE->EE_VARIACA,"") }                //Carteira

      aDatSacado   := {AllTrim(SA1->A1_NOME)+" - "+cCpfCnpj             ,;      //Razão Social 
                       AllTrim(SA1->A1_COD )                            ,;      //Código
                       If(!Empty(SA1->A1_ENDCOB),AllTrim(SA1->A1_ENDCOB)+" - "+SA1->A1_BAIRROC,AllTrim(SA1->A1_END)+"-"+SA1->A1_BAIRRO) ,;      //Endereço
                       If(!Empty(SA1->A1_MUNC), AllTrim(SA1->A1_MUNC ), AllTrim(SA1->A1_MUN )) ,;      //Cidade
                       If(!Empty(SA1->A1_ESTC), SA1->A1_ESTC, SA1->A1_EST) ,;      //Estado
                       If(!Empty(SA1->A1_CEPC), SA1->A1_CEPC, SA1->A1_CEP)  }       //CEP     
      
	_nSaldo := 0
	_nSaldo := (caliasSE1)->E1_SALDO+(caliasSE1)->E1_SDACRES-(caliasSE1)->E1_SDDECRE 
      _nSaldo -= SomaAbat((caliasSE1)->E1_PREFIXO,(caliasSE1)->E1_NUM,(caliasSE1)->E1_PARCELA,"R",1,,(caliasSE1)->E1_CLIENTE,(caliasSE1)->E1_LOJA)
      
      //Monta o Borderô
      If lAutoExec .Or. _MV_PAR22 == 1
			
		cAliasTmp 	:= Alias()
		cRecTmp		:= Recno()
		cBordero 	:= BuscaBorde()
			
		If Empty(cBordero)
			cBordero := GetMv("MV_NUMBORR",.F.)
			If Empty(cBordero)
				cBordero := "000001"
			Endif
			PutMv("MV_NUMBORR",Soma1(cBordero))
		Endif

		RecLock("SEA",.T.)
			SEA->EA_FILIAL		:= (caliasSE1)->E1_FILIAL	 
			SEA->EA_PREFIXO 	:= (caliasSE1)->E1_PREFIXO	 
			SEA->EA_NUM 		:= (caliasSE1)->E1_NUM		 
			SEA->EA_PARCELA 	:= (caliasSE1)->E1_PARCELA	 
			SEA->EA_PORTADO 	:= SA6->A6_COD	 
			SEA->EA_AGEDEP 		:= SA6->A6_AGENCIA	 
			SEA->EA_SUBCTA 		:= _MV_PAR10
			SEA->EA_DATABOR 	:= (dDataBase)				 
			SEA->EA_TIPO 		:= (caliasSE1)->E1_TIPO	 
			SEA->EA_LOJA 		:= (caliasSE1)->E1_LOJA	 
			SEA->EA_NUMCON 		:= SA6->A6_NUMCON	 
			SEA->EA_SALDO 		:= (caliasSE1)->E1_SALDO	 
			SEA->EA_FILORIG 	:= (caliasSE1)->E1_FILORIG	 
			SEA->EA_CART 		:= "R"	
			SEA->EA_NUMBOR 		:= cBordero
			SEA->EA_SITUACA		:= "1"
			SEA->EA_SITUANT     := "0"		
		SEA->(MsUnlock())
					
		DbSelectArea("SE1")
		DbSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
		
		RecLock("SE1",.F.)
		SE1->E1_NUMBOR	:= cBordero			 
		SE1->E1_MOVIMEN	:= dDataBase				 
		SE1->E1_DATABOR	:= dDataBase
		SE1->E1_SITUACA	:= "1"
		SE1->E1_PORTADO := SA6->A6_COD
		SE1->E1_AGEDEP  := SA6->A6_AGENCIA
		SE1->E1_CONTA   := SA6->A6_NUMCON
		SE1->(MsUnlock())

		DbCloseArea()
		
		DbSelectArea(cAliasTmp)
		DbGoTo(cRecTmp)
					
	EndIf
      
      //Tamanho do NOSSO NUMERO
      nTam_NN := If( SEE->EE_TAM_NN == 0 , 11 , SEE->EE_TAM_NN )

      //Define NOSSO NUMERO: Se o titulo já foi impresso, reaproveita, senao, busca do proximo numero gravada na tabela de parametros banco
      cNosso_Num := StrZero( Val( IIf( Empty((caliasSE1)->E1_NUMBCO) , SEE->EE_FAXATU , Substr((caliasSE1)->E1_NUMBCO,1,nTam_NN) ) ) , nTam_NN )
      
      If Val(cNosso_Num) == 0
      	cNosso_Num := StrZero( 1, nTam_NN )
      Endif

      If Empty( (caliasSE1)->E1_NUMBCO) //Titulo ainda nao impresso, calcula o proximo numero para o proximo boleto que será impresso futuramente
			DbSelectArea("SEE")
			RecLock("SEE",.f.)
			SEE->EE_FAXATU := StrZero( Val(cNosso_Num) + 1, nTam_NN )
	     	SEE->(MsUnlock())
	  Endif

      //montando codigo de barras 
      //Caso o titulo ja tenha sido impresso sera pego o nosso numero do campo E1_NUMBCO
      CB_RN_NN    := Ret_cBarra(	Substr(aDadosBanco[1],1,3)+"9",;
      								Subs(aDadosBanco[3],1,4),;
      								aDadosBanco[4],;
      								aDadosBanco[5],;
      								SubStr(aDadosBanco[6],1,2),;
      								AllTrim((caliasSE1)->E1_NUM)+AllTrim((caliasSE1)->E1_PARCELA),;
      								_nSaldo,;
      								(caliasSE1)->E1_VENCREA,;
      								SEE->EE_CODEMP,;
      								cNosso_Num,;
      								SEE->EE_CARTEIR)

      //aDadosTit    :=  {AllTrim((caliasSE1)->E1_NUM)+AllTrim((caliasSE1)->E1_PARCELA)  ,;             //Número do título
      aDadosTit    :=  {AllTrim((caliasSE1)->E1_NUM)  ,;             //Número do título
                       (caliasSE1)->E1_EMISSAO      ,;             //Data da emissão do título
                       MsDate()    ,;             //Data da emissão do boleto
                       (caliasSE1)->E1_VENCREA  ,;             //Data do vencimento
                       _nSaldo,;             //Valor do título
                       SubStr(CB_RN_NN[3],1,Len(CB_RN_NN[3])-1)+"-"+SubStr(CB_RN_NN[3],Len(CB_RN_NN[3]),1) ,; //Nosso número (Ver fórmula para calculo)
                       AllTrim((caliasSE1)->E1_TIPO)  ,;//TIPO DO TITULO
                       AllTrim((caliasSE1)->E1_PARCELA)} //PARCELA DO TITULO

      //Mensagens boleto
      aBolText  := 	{}
      //Mensagem de desconto
      If (caliasSE1)->E1_DESCFIN > 0
	      nValDesc := ((caliasSE1)->E1_DESCFIN * (caliasSE1)->E1_SALDO) / 100
	      cDesconto := "DESCONTO DE R$ "+Alltrim(TransForm(nValDesc,"@E 9999,999,999.99"))+" P/ PAGTO ATÉ O VENCIMENTO"
	      aAdd( aBolText , cDesconto )
      Endif
      //Mensagem de juros
      If (caliasSE1)->E1_VALJUR > 0
	      cJuros := "JUROS DE MORA POR DIA - R$ "+Alltrim(TransForm((caliasSE1)->E1_VALJUR,"@E 9999,999,999.99"))
	      aAdd( aBolText , cJuros )
	  ElseIf (caliasSE1)->E1_PORCJUR > 0
	  	  nValJuros := ((caliasSE1)->E1_PORCJUR * (caliasSE1)->E1_SALDO) / 100
	      cJuros    := "JUROS DE MORA POR DIA - R$ "+Alltrim(TransForm(nValJuros,"@E 9999,999,999.99"))
	      aAdd( aBolText , cJuros )
	  Endif
	  //Mensagem para protesto
	  If Alltrim(SEE->EE_DIASPRO) <> "00" .And. !Empty(SEE->EE_DIASPRO)
		  cProstesto := "Título sujeito a Protesto após "+SEE->EE_DIASPRO+" dias de vencimento."
		  aAdd( aBolText , cProstesto )
	  EndIf
      //Outras Mensagens de instrucao
      aAdd( aBolText , SEE->EE_MSG1 ) //Instrucao 1
      aAdd( aBolText , SEE->EE_MSG2 ) //Instrucao 2
      aAdd( aBolText , SEE->EE_MSG3 ) //Instrucao 3                        
	  
      cLocPagto := SEE->EE_LOCPAG //Local para pagamento
      cEspecieD := SEE->EE_ESPDOC //Especie Doc
      cAceite   := SEE->EE_ACEITE //Aceite
      BB		:= Substr(aDadosBanco[1],1,3) == "001"
      BRADESCO	:= Substr(aDadosBanco[1],1,3) == "237"
      ITAU 		:= Substr(aDadosBanco[1],1,3) $ "341/655"
      cValCIP   := SEE->EE_VALCIP 
      
      If Empty(AllTrim((caliasSE1)->E1_NUMBCO)) //AINDA NÃO FOI IMPRESSO O TITULO   
	     	SE1->(dbSetOrder(1))
			If SE1->(dbSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))
				RecLock("SE1",.F.)
				SE1->E1_OCORREN	:= "01" //Registro de Titulos  
				SE1->E1_INSTR1	:= "00" //05-Protestar no 5o. Dia Útil (1o. Intrs cod.)
				SE1->E1_INSTR2 	:= "00" //00-Ausencia de Instruções (2a. Intr. cod.)
				SE1->E1_NUMBCO 	:= CB_RN_NN[3] //Nosso numero com ou sem digito verificador (depende da configuracao do banco)
				SE1->E1_PORTADO	:= SA6->A6_COD
				SE1->(MsUnlock())
			EndIf
      Endif

      If aMarked[i]
         Impress(oPrint,aBMP,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)
         n := n + 1
      EndIf 
     
      DbSelectArea(cAliasSE1)  
      dbSkip()          
      IncProc()
      i++
   EndDo   
   
   oPrint:EndPage()     // Finaliza a página
   oPrint:Preview()     // Visualiza antes de imprimir

Return nil

Static Function Impress(oPrint,aBitmap,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)
/*/{Protheus.doc} Impress
Função que imprime a página do boleto
@author Fabio Branis
@since 08/01/2015
@version 1.0
@param oPrint,Object, Objeto de Impressão
@param aBitmap, Array, Contém as imagens a imprimir
@param aDadosEmp, Array, Contém os dados da empresa a imprimir
@param aDadosTit, Array, Contém os dados dos títulos a imprimir
@param aDadosBanco, Array, Contém os dados do banco a imprimir
@param aDatSacado, Array, Contém os dados do sacado/cliente a imprimir
@param aBolText, Array, Contém os textos do boleto a imprimir, definidos pelo usuário no cadastro de parâmetros bancos
@param CB_RN_NN, Array, Contém os dados de código de barras, linha digitável e nosso número
@param cLocPagto, String, Local de pagamento
@param cValCIP, String, CIP
@param cEspecieD, String, Espécie do documento
@param cAceite, Strin, Aceite
/*/
	Local oFont8,nBol
	Local oFont10
	Local oFont16
	Local oFont16n     
	Local oFont20
	Local oFont24
	Local i := 0
	Local aCoords1 := {150,1900,250,2300}   // FICHA DO SACADO
	Local aCoords2 := {420,1900,490,2300}   // FICHA DO SACADO
	Local aCoords3 := {1270,1900,1370,2300} // FICHA DO CAIXA
	Local aCoords4 := {1540,1900,1610,2300} // FICHA DO CAIXA
	Local aCoords5 := {2390,1900,2490,2300} // FICHA DE COMPENSACAO
	Local aCoords6 := {2660,1900,2730,2300} // FICHA DE COMPENSACAO
	Local oBrush
	
	//Parâmetros de TFont.New()
	//1.Nome da Fonte (Windows)
	//3.Tamanho em Pixels
	//5.Bold (T/F)
	oFont8  	:= TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont09 	:= TFont():New("Arial",9,9,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10 	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10n 	:= TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14		:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14n	:= TFont():New("Arial",9,13,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont16 	:= TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n	:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont20		:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont24 	:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)
	
	oBrush := TBrush():New("",4)
	
	oPrint:StartPage()   // Inicia uma nova página
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ficha do Caixa                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oPrint:Line (150,100,150,2300)   
	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		oPrint:SayBitMap(84-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
	Else
		oPrint:Say  (84,100,aDadosBanco[2],oFont16 )  //Nome Banco
	Endif
	oPrint:Say  (84,1850,"Comprovante de Entrega"                              ,oFont10)

	oPrint:Line (250,100,250,1300 )
	oPrint:Line (350,100,350,1300 )
	oPrint:Line (420,100,420,2300 )
	oPrint:Line (490,100,490,2300 )

	oPrint:Line (350,400,420,400)
	oPrint:Line (420,500,490,500)
	oPrint:Line (350,725,420,725)
	oPrint:Line (350,850,420,850)

	oPrint:Line (150,1300,490,1300 )
	oPrint:Line (150,2300,490,2300 )
	oPrint:Say  (150,1310 ,"MOTIVOS DE NÃO ENTREGA (para uso do entregador)"                             ,oFont8) 
	oPrint:Say  (200,1310 ,"|   | Mudou-se"                             ,oFont8) 
	oPrint:Say  (270,1310 ,"|   | Recusado"                             ,oFont8) 
	oPrint:Say  (340,1310 ,"|   | Desconhecido"                             ,oFont8) 

	oPrint:Say  (200,1580 ,"|   | Ausente"                             ,oFont8) 
	oPrint:Say  (270,1580 ,"|   | Não Procurado"                             ,oFont8) 
	oPrint:Say  (340,1580 ,"|   | Endereço insuficiente"                             ,oFont8) 

	oPrint:Say  (200,1930 ,"|   | Não existe o Número"                             ,oFont8) 
	oPrint:Say  (270,1930 ,"|   | Falecido"                             ,oFont8) 
	oPrint:Say  (340,1930 ,"|   | Outros(anotar no verso)"                             ,oFont8) 

	oPrint:Say  (420,1310 ,"Recebi(emos) o bloqueto"                             ,oFont8) 
	oPrint:Say  (450,1310 ,"com os dados ao lado."                             ,oFont8) 
	oPrint:Line (420,1700,490,1700)
	oPrint:Say  (420,1705 ,"Data"                             ,oFont8) 
	oPrint:Line (420,1900,490,1900)
	oPrint:Say  (420,1905 ,"Assinatura"                             ,oFont8) 

	oPrint:Say  (150,100 ,"Cedente"            	,oFont8)
	oPrint:Say  (150,300 ,aDadosEmp[6]         	,oFont10n) 
	oPrint:Say  (185,100 ,AllTrim(aDadosEmp[1])	,oFont10)
	oPrint:Say  (220,100 ,aDadosEmp[2]+", "+aDadosEmp[3] ,oFont8)
	
	cIndTmp := At("-",aDatSacado[1])
	cCGCTmp := SubStr(aDatSacado[1], At("-", aDatSacado[1])+2, Len(aDatSacado[1]))
	cSacado := SubStr(aDatSacado[1],1, At("-", aDatSacado[1])-2)

	oPrint:Say  (250,100 ,"Sacado"   	,oFont8) 
	oPrint:Say  (250,300 ,cCGCTmp		,oFont10n)
	oPrint:Say  (290,100 ,cSacado    	,oFont10)

	oPrint:Say  (350,100 ,"Data do Vencimento"                              ,oFont8)  
	oPrint:Say  (380,100 ,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10) 

	oPrint:Say  (350,405 ,"Nro.Documento"                                  ,oFont8) 
	oPrint:Say  (380,435 ,aDadosTit[1]+aDadosTit[8]                         ,oFont10)

	oPrint:Say  (350,730,"Moeda"                                   ,oFont8)
	oPrint:Say  (380,755,GetMv("MV_SIMB1")                         ,oFont10)

	oPrint:Say  (350,855,"Valor/Quantidade"                               ,oFont8) 
	oPrint:Say  (380,865,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

	oPrint:Say  (420,100 ,"Agencia/Cod. Cedente"                           ,oFont8)      
	oPrint:Say  (450,100,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10)

	oPrint:Say  (420,505,"Nosso Número"                                   ,oFont8)   	
	If BRADESCO
		oPrint:Say  (450,520,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)        ,oFont10)
	ElseIf BB
		nPosRat := RAT("-",aDadosTit[6])
		If nPosRat > 0
			oPrint:Say  (450,520,Substr(aDadosTit[6],1,nPosRat-1),oFont10)
		Else
			oPrint:Say  (450,520,aDadosTit[6],oFont10)
		Endif
	ElseIf ITAU
		oPrint:Say  (450,520,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6])-2)        ,oFont10)
	Else
		oPrint:Say  (450,520,substr(aDadosTit[6],1,len(aDadosTit[6])-2)        ,oFont10)
	EndIf

	For i := 100 to 2300 step 50
	   oPrint:Line( 520, i, 520, i+30)
	Next i

	For i := 100 to 2300 step 50
	   oPrint:Line( 1080, i, 1080, i+30)
	Next i

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ficha do Sacado                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	oPrint:Line (1270,100,1270,2300)   
	oPrint:Line (1270,650,1170,650 )
	oPrint:Line (1270,900,1170,900 ) 
	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		oPrint:SayBitMap(1204-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
	Else
		oPrint:Say  (1204,100,aDadosBanco[2],oFont16 ) //Nome Banco (ou imagem)
	Endif
	If BRADESCO
		oPrint:Say  (1182,680,aDadosBanco[1]+"-2",oFont20 ) 
	Else
		oPrint:Say  (1182,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 ) 
	EndIf
	
	oPrint:Line (1370,100,1370,2300 )
	oPrint:Line (1470,100,1470,2300 )
	oPrint:Line (1540,100,1540,2300 )
	oPrint:Line (1610,100,1610,2300 )
	
	oPrint:Line (1470,500,1610,500)
	oPrint:Line (1540,750,1610,750) 
	oPrint:Line (1470,1000,1610,1000)
	oPrint:Line (1470,1350,1540,1350)
	oPrint:Line (1470,1550,1610,1550)
	
	oPrint:Say  (1270,100 ,"Local de Pagamento"                             ,oFont8) 
	oPrint:Say  (1310,100 ,cLocPagto        ,oFont10)
	
	oPrint:Say  (1270,1910,"Vencimento"                                     ,oFont8)
	oPrint:Say  (1310,2010,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10)
	 
	oPrint:Say  (1370,100 ,"Cedente"                                        ,oFont8) 
	oPrint:Say  (1405,100 ,AllTrim(aDadosEmp[1])+" - "+aDadosEmp[6]                                     ,oFont10)
	oPrint:Say  (1440,100 ,aDadosEmp[2]+", "+aDadosEmp[3] ,oFont8)
	
	oPrint:Say  (1370,1910,"Agência/Código Cedente"                         ,oFont8) 
	oPrint:Say  (1410,2010,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10)
	
	oPrint:Say  (1470,100 ,"Data do Documento"                              ,oFont8)  
	oPrint:Say  (1500,100 ,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4),oFont10) 
	
	oPrint:Say  (1470,505 ,"Nro.Documento"                                  ,oFont8) 
	oPrint:Say  (1500,535 ,aDadosTit[1]+aDadosTit[8]                  ,oFont10)
	
	oPrint:Say  (1470,1005,"Espécie Doc."                                   ,oFont8)
	oPrint:Say  (1500,1105,cEspecieD                                       ,oFont10)
	
	oPrint:Say  (1470,1355,"Aceite"                                         ,oFont8) 
	oPrint:Say  (1500,1455,cAceite                                          ,oFont10)
	
	oPrint:Say  (1470,1555,"Data do Processamento"                          ,oFont8) 
	oPrint:Say  (1500,1655,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4)                               ,oFont10)

	oPrint:Say  (1470,1910,"Nosso Número"                                   ,oFont8)  	
	If BRADESCO
		//oPrint:Say  (1470,1910,"Cart / Nosso Número"                                   ,oFont8)   
		oPrint:Say  (1500,1930,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)       ,oFont10)
	ElseIf BB
		nPosRat := RAT("-",aDadosTit[6])
		If nPosRat > 0
			oPrint:Say  (1500,1930,Substr(aDadosTit[6],1,nPosRat-1),oFont10)
		Else
			oPrint:Say  (1500,1930,aDadosTit[6],oFont10)
		Endif
	ElseIf ITAU
		oPrint:Say  (1500,1930,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6])-2)        ,oFont10)  
	Else
		oPrint:Say  (1500,1930,substr(aDadosTit[6],1,len(aDadosTit[6])-2)        ,oFont10)
	EndIf
	
	oPrint:Say  (1540,100 ,"Uso do Banco"                                   ,oFont8)
	
	If !Empty(cValCIP)
		oPrint:Line(1540,405,1610,405)
		oPrint:Say(1540,410,"CIP")
		oPrint:Say(1570,435,cValCIP,oFont10)
	EndIf        
	
	oPrint:Say  (1540,505 ,"Carteira"                                       ,oFont8)     
	oPrint:Say  (1570,555 ,aDadosBanco[6]                                   ,oFont10)     
	
	oPrint:Say  (1540,755 ,"Espécie"                                        ,oFont8)   
	oPrint:Say  (1570,805 ,GetMv("MV_SIMB1")                                ,oFont10)  
	
	oPrint:Say  (1540,1005,"Quantidade"                                     ,oFont8) 
	oPrint:Say  (1540,1555,"Valor"                                          ,oFont8)            
	
	oPrint:Say  (1540,1910,"(=)Valor do Documento"                          ,oFont8) 
	oPrint:Say  (1570,2010,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)
	
	oPrint:Say  (1610,100 ,"Instruções/Texto de responsabilidade do cedente",oFont8)
	For nBol := 1 To 6
		If Len(aBolText) >= nBol
			oPrint:Say  (1630+(40*nBol),100 ,aBolText[nBol],oFont09)
		Endif
	Next nBol
	
	oPrint:Say  (1610,1910,"(-)Desconto/Abatimento"                         ,oFont8) 
	oPrint:Say  (1680,1910,"(-)Outras Deduções"                             ,oFont8)
	oPrint:Say  (1750,1910,"(+)Mora/Multa"                                  ,oFont8)
	oPrint:Say  (1820,1910,"(+)Outros Acréscimos"                           ,oFont8)
	oPrint:Say  (1890,1910,"(=)Valor Cobrado"                               ,oFont8)
	
	oPrint:Say  (1960 ,100 ,"Sacado:"                                         ,oFont8) 
	oPrint:Say  (1988 ,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             ,oFont8)
	oPrint:Say  (2030 ,210 ,aDatSacado[3]                                    ,oFont8)
	oPrint:Say  (2070 ,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5] ,oFont8)
	
	oPrint:Say  (1925,100 ,"Sacador/Avalista"                               ,oFont8)   
	oPrint:Say  (2110,1500,"Autenticação Mecânica "                        ,oFont8)  
	oPrint:Say  (1204,1850,"Recibo do Sacado"                              ,oFont10)
	
	oPrint:Line (1270,1900,1960,1900 )
	oPrint:Line (1680,1900,1680,2300 )
	oPrint:Line (1750,1900,1750,2300 )
	oPrint:Line (1820,1900,1820,2300 )
	oPrint:Line (1890,1900,1890,2300 )  
	oPrint:Line (1960,100 ,1960,2300 )
	
	oPrint:Line (2105,100,2105,2300  )     
	
	For i := 100 to 2300 step 50
	   oPrint:Line( 2270, i, 2270, i+30)
	Next i                                                                   
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ficha de Compensacao                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	oPrint:Line (2390,100,2390,2300)   
	oPrint:Line (2390,650,2290,650 )
	oPrint:Line (2390,900,2290,900 )

	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		oPrint:SayBitMap(2324-30,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
	Else	 
		oPrint:Say  (2324,100,aDadosBanco[2],oFont16 )  //Nome do Banco
	Endif
	
	If BRADESCO
		oPrint:Say  (2302,680,aDadosBanco[1]+"-2",oFont20 ) 
	Else
		oPrint:Say  (2302,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 ) 
	EndIf
	oPrint:Say  (2324,920,CB_RN_NN[2],oFont14n) //linha digitavel
	
	oPrint:Line (2490,100,2490,2300 )
	oPrint:Line (2590,100,2590,2300 )
	oPrint:Line (2660,100,2660,2300 )
	oPrint:Line (2730,100,2730,2300 )
	
	oPrint:Line (2590,500,2730,500)
	oPrint:Line (2660,750,2730,750)
	oPrint:Line (2590,1000,2730,1000)
	oPrint:Line (2590,1350,2660,1350)
	oPrint:Line (2590,1550,2730,1550)
	
	oPrint:Say  (2390,100 ,"Local de Pagamento"                             ,oFont8) 
	oPrint:Say  (2430,100 ,cLocPagto        ,oFont10)
	
	oPrint:Say  (2390,1910,"Vencimento"                                     ,oFont8)
	oPrint:Say  (2430,2010,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10)
	 
	oPrint:Say  (2490,100 ,"Cedente"                                        ,oFont8) 
	oPrint:Say  (2525,100 ,AllTrim(aDadosEmp[1])+" - "+aDadosEmp[6]                                     ,oFont10)
	oPrint:Say  (2560,100 ,aDadosEmp[2]+", "+aDadosEmp[3] ,oFont8)
	
	oPrint:Say  (2490,1910,"Agência/Código Cedente"                         ,oFont8) 
	oPrint:Say  (2530,2010,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10)
	
	oPrint:Say  (2590,100 ,"Data do Documento"                              ,oFont8)  
	oPrint:Say  (2620,100 ,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4),oFont10) 
	
	oPrint:Say  (2590,505 ,"Nro.Documento"                                  ,oFont8) 
	oPrint:Say  (2620,535 ,aDadosTit[1]+aDadosTit[8]                  ,oFont10)
	
	oPrint:Say  (2590,1005,"Espécie Doc."                                   ,oFont8)
	oPrint:Say  (2620,1105,cEspecieD                                        ,oFont10)
	
	oPrint:Say  (2590,1355,"Aceite"                                         ,oFont8) 
	oPrint:Say  (2620,1455,cAceite                                          ,oFont10)
	
	oPrint:Say  (2590,1555,"Data do Processamento"                          ,oFont8) 
	oPrint:Say  (2620,1655,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4)                               ,oFont10)

	oPrint:Say  (2590,1910,"Nosso Número"                                   ,oFont8)   	
	If BRADESCO
		oPrint:Say  (2620,1930,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)        ,oFont10)
	ElseIf BB
		nPosRat := RAT("-",aDadosTit[6])
		If nPosRat > 0
			oPrint:Say  (2620,1930,Substr(aDadosTit[6],1,nPosRat-1),oFont10)
		Else
			oPrint:Say  (2620,1930,aDadosTit[6],oFont10)
		Endif
	ElseIf ITAU
		oPrint:Say  (2620,1930,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6])-2)        ,oFont10)  
	Else
		oPrint:Say  (2620,1930,substr(aDadosTit[6],1,len(aDadosTit[6])-2)        ,oFont10)
	EndIf
	
	oPrint:Say  (2660,100 ,"Uso do Banco"                                   ,oFont8)
	
	If !Empty(cValCIP)
		oPrint:Line(2660,405,2730,405)
		oPrint:Say(2660,410,"CIP")
		oPrint:Say(2690,435,cValCIP,oFont10)
	EndIf        
	
	oPrint:Say  (2660,505 ,"Carteira"                                       ,oFont8)     
	oPrint:Say  (2690,555 ,aDadosBanco[6]                                   ,oFont10)     
	
	oPrint:Say  (2660,755 ,"Espécie"                                        ,oFont8)   
	oPrint:Say  (2690,805 ,GetMv("MV_SIMB1")                                ,oFont10)  
	
	oPrint:Say  (2660,1005,"Quantidade"                                     ,oFont8) 
	oPrint:Say  (2660,1555,"Valor"                                          ,oFont8)            
	
	oPrint:Say  (2660,1910,"(=)Valor do Documento"                          ,oFont8) 
	oPrint:Say  (2690,2010,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)
	
	oPrint:Say  (2730,100 ,"Instruções/Texto de responsabilidade do cedente",oFont8)     
	For nBol := 1 To 6
		If Len(aBolText) >= nBol
			oPrint:Say  (2750+(40*nBol),100 ,aBolText[nBol],oFont09)
		Endif
	Next nBol

	oPrint:Say  (2730,1910,"(-)Desconto/Abatimento"                         	,oFont8) 
	oPrint:Say  (2800,1910,"(-)Outras Deduções"                             	,oFont8)
	oPrint:Say  (2870,1910,"(+)Mora/Multa"                                 	,oFont8)
	oPrint:Say  (2940,1910,"(+)Outros Acréscimos"                           	,oFont8)
	oPrint:Say  (3010,1910,"(=)Valor Cobrado"                               	,oFont8)
	
	oPrint:Say  (3080,100 ,"Sacado"                                        	,oFont8) 
	oPrint:Say  (3108,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             	,oFont8)
	oPrint:Say  (3148,210 ,aDatSacado[3]                                   	,oFont8)
	oPrint:Say  (3188,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]	,oFont8)
	
	oPrint:Say  (3228,100 ,"Sacador/Avalista"                               	,oFont8)   
	oPrint:Say  (3270,1500,"Autenticação Mecânica -"                        	,oFont8)  
	oPrint:Say  (3270,1850,"Ficha de Compensação"                           	,oFont10)
	
	
	oPrint:Line(2390,1900,3080,1900)
	oPrint:Line(2800,1900,2800,2300)
	oPrint:Line(2870,1900,2870,2300)
	oPrint:Line(2940,1900,2940,2300)
	oPrint:Line(3010,1900,3010,2300)  
	oPrint:Line(3080,100 ,3080,2300)
	
	oPrint:Line (3265,100,3265,2300)     
	MSBAR("INT25"  ,27.9,1.3,CB_RN_NN[1],oPrint,.F.,,,0.025,1.3,,,,.F.)   
	
	/*
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
	±±³Parametros³ 01 cTypeBar String com o tipo do codigo de barras          ³±±
	±±³          ³             "EAN13","EAN8","UPCA" ,"SUP5"   ,"CODE128"     ³±±
	±±³          ³             "INT25","MAT25,"IND25","CODABAR" ,"CODE3_9"    ³±±
	±±³          ³ 02 nRow     Numero da Linha em centimentros                ³±±
	±±³          ³ 03 nCol     Numero da coluna em centimentros               ³±±
	±±³          ³ 04 cCode    String com o conteudo do codigo                ³±±
	±±³          ³ 05 oPr      Objeto Printer                                 ³±±
	±±³          ³ 06 lcheck   Se calcula o digito de controle                ³±±
	±±³          ³ 07 Cor      Numero  da Cor, utilize a "common.ch"          ³±±
	±±³          ³ 08 lHort    Se imprime na Horizontal                       ³±±
	±±³          ³ 09 nWidth   Numero do Tamanho da barra em centimetros      ³±±
	±±³          ³ 10 nHeigth  Numero da Altura da barra em milimetros        ³±±
	±±³          ³ 11 lBanner  Se imprime o linha em baixo do codigo          ³±±
	±±³          ³ 12 cFont    String com o tipo de fonte                     ³±±
	±±³          ³ 13 cMode    String com o modo do codigo de barras CODE128  ³±±
	±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
	*/
	      
	oPrint:EndPage() // Finaliza a pagina
		
Return Nil

Static Function Modulo10(cData)
/*/{Protheus.doc} Modulo10
Função que faz o cálculo de módulo 10
@author Fabio Branis
@since 09/01/2015
@version 1.0
@param cData, String, Dados de entrada para o cálculo - Números em formato de string
@return D, Variável com o resultado produzido pelo cálculo
/*/	
	Local L,D,P	:= 0
	Local B    	:= .F.
	
   L := Len(cData)
   B := .T.
   D := 0
   
   While L > 0 
      P := Val(SubStr(cData, L, 1))
      If (B) 
         P := P * 2
         If P > 9 
            P := P - 9
         End
      End
      D := D + P
      L := L - 1
      B := !B
   End
   
   D := 10 - (Mod(D,10))
   
   If D = 10
      D := 0
   End
   
Return(D)

Static Function Modulo11(cData,cBanc)
/*/{Protheus.doc} Modulo11
Função que faz o cálculo de módulo 11
@author Fabio Branis
@since 09/01/2015
@version 1.0
@param cData, String, Dados de entrada para o cálculo - Números em formato de string
@param cBanc, String, Especifica o banco
@return D, Variável com o resultado produzido pelo cálculo
/*/		
	Local L, D, P := 0
	  
	If cBanc == "001" //Banco do Brasil
	   L := Len(cdata)
	   D := 0
	   P := 10
	   While L > 0 
	      P := P - 1
	      D := D + (Val(SubStr(cData, L, 1)) * P)
	      If P = 2 
	         P := 10
	      End
	      L := L - 1
	   End
	   D := mod(D,11)
	   If D == 10
	      D := "X"
	   Else
	      D := AllTrim(Str(D))
	   End           
	ElseIf cBanc == "237" //Bradesco
	
	    nSoma1 := val(subs("09",01,1))    *2
	    nSoma2 := val(subs("09",02,1))    *7
	    nSoma3 := val(subs(cData,01,1))   *6
	    nSoma4 := val(subs(cData,02,1))   *5
	    nSoma5 := val(subs(cData,03,1))   *4
	    nSoma6 := val(subs(cData,04,1))   *3
	    nSoma7 := val(subs(cData,05,1))   *2
	    nSoma8 := val(subs(cData,06,1))   *7
	    nSoma9 := val(subs(cData,07,1))   *6
	    nSomaA := val(subs(cData,08,1))   *5
	    nSomaB := val(subs(cData,09,1))   *4
	    nSomaC := val(subs(cData,10,1))   *3
	    nSomaD := val(subs(cData,11,1))   *2
	        
	    cDigito := mod(nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8+nSoma9+nSomaA+nSomaB+nSomaC+nSomaD,11)
	    
	    D := iif(cDigito == 1, "P", iif(cDigito == 0 , "0", strzero(11-cDigito,1)))
    
    
   ElseIf cBanc $ "341/422/655" //ITAU ou SAFRA ou VOTORANTIM
   
		nCnt	:= 0
		cDigito:= 0
		nSoma	:= 0
		nBase	:= 0
		aPeso	:= {9,8,7,6,5,4,3,2}; 
		
		nBase := Len(aPeso)+1
		
		FOR nCnt := Len(cData) TO 1 STEP -1
			nBase := IF(--nBase = 0,Len(aPeso),nBase)
			nSoma += Val(SUBS(cData,nCnt,01)) * aPeso[nBase]
		NEXT
		
		cDigito := 11 - (nSoma % 11)  

		DO CASE
			CASE cDigito = 0
				cDigito := "1"
			CASE cDigito > 9
				cDigito := "1"
			CASE cBanc == "422" //Se banco SAFRA
				cDigito := "0"
			OTHERWISE
				cDigito := STR( cDigito, 1, 0 )
		ENDCASE
        
		D := cDigito
      
	ElseIf cBanc == "479"
	   L := Len(cdata)
	   D := 0
	   P := 1
	   While L > 0 
	      P := P + 1
	      D := D + (Val(SubStr(cData, L, 1)) * P)
	      If P = 9 
	         P := 1
	      End
	      L := L - 1
	   End
	   D := Mod(D*10,11)
	   If D == 10
	      D := 0
	   End
	   D := AllTrim(Str(D))
	Else
	   L := Len(cdata)
	   D := 0
	   P := 1
	   While L > 0 
	      P := P + 1
	      D := D + (Val(SubStr(cData, L, 1)) * P)
	      If P = 9 
	         P := 1
	      End
	      L := L - 1
	   End
	   D := 11 - (mod(D,11))
	   If (D == 10 .Or. D == 11)
	      D := 1
	   End
	   D := AllTrim(Str(D))
	Endif
	   
Return(D)   


//Retorna os strings para inpressão do Boleto
//CB = String para o cód.barras, RN = String com o número digitável
//Cobrança não identificada, número do boleto = Título + Parcela
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,cCarBank)
/*/{Protheus.doc} Ret_cBarra
Função que retorna os dados de código de barras, linha digitável, nosso número com dv
@author Fabio
@since 09/01/2015
@version 1.0
@param cBanco, String, Código do banco
@param cAgencia, Strin, Código da Agência
@param cConta, String, Código da Conta
@param cDacCC, String, Dígito da conta
@param cCarteira, String, Carteira de cobrança BRADESCO
@param cNroDoc, String, Número do documento
@param nValor, Float, Valor do documento
@param dvencimento, Date, Vencimento do documento
@param cConvenio, String, Convênio
@param cSequencial, String, Sequencial Nosso número
@param cCarBank, String, Carteira BB
@return aRet, Array com os dados descritos no ínicio da documentação, na mesma ordem da descrição
@example
(examples)
@see (links_or_references)
/*/	
	Local cCodEmp 		:= StrZero(Val(SubStr(cConvenio,1,7)),7)
	Local cNumSeq 		:= strzero(val(cSequencial),nTam_NN)
	Local bldocnufinal 	:= strzero(val(cNroDoc),9)
	Local blvalorfinal 	:= strzero(int(nValor*100),10)
	Local cNNumSDig 	:= cCpoLivre := cCBSemDig := cCodBarra := cNNum := cFatVenc := ''
	Local cDvn          := " "

	//Fator Vencimento - POSICAO DE 06 A 09	
	cFatVenc := STRZERO(dvencimento - CtoD("07/10/1997"),4)
	
	//Prefixo Nosso Numero
	//Nosso Numero
	cNNum := cNumSeq

	//Campo Livre (Definir campo livre com cada banco)
	If Substr(cBanco,1,3) == "001" //BB
		cCpoLivre := StrZero(0,6) + cCodEmp + cNumSeq + PadR(cCarBank,2) //cCarBank -> Carteira
		//6 + 7 + 10 + 2
	ElseIf Substr(cBanco,1,3) == "237" //BRADESCO
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		cCpoLivre := StrZero(Val(cAgencia),4) + cCarteira + cNumSeq + StrZero(Val(cConta),7) + "0"
		//4 + 2 + 11 + 8
	ElseIf SubStr(cBanco,1,3) $ "341/655" //ITAU ou VOTORANTIM
		cDvn := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)+cCarBank+cNumSeq))
		cDvC := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)))
		cCpoLivre := Alltrim(cCarBank) + cNumSeq + cDvn + strzero(val(cAgencia),4)+AllTrim(cConta)+cDvC+"000"
		//2 + 8 + 1 + 4 + 10
	ElseIf SubStr(cBanco,1,3) == "422" //SAFRA
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		cCpoLivre := "7" + PadL( Strzero(Val(cAgencia),4)+AllTrim(cConta) , 14 ) + cNumSeq + cDvn + "2"
		cCpoLivre := StrTran(cCpoLivre," ","0")
		//1 + 14 + 8 + 2
	Else
		cCpoLivre := ""
	Endif
	
	//Dados para Calcular o Dig Verificador Geral
	cCBSemDig := cBanco + cFatVenc + blvalorfinal + cCpoLivre
	
	//Codigo de Barras Completo
	cCodBarra := cBanco +  Modulo11(cCBSemDig,"SEM_BANCO") + cFatVenc + blvalorfinal + cCpoLivre
	//4 + 1 + 4 + 10 + 6 + 7 + 10 + 2
	
	//Digito Verificador do Primeiro Campo                  
	cPrCpo := cBanco + SubStr(cCodBarra,20,5)
	cDvPrCpo := AllTrim(Str(Modulo10(cPrCpo)))
	
	//Digito Verificador do Segundo Campo
	cSgCpo := SubStr(cCodBarra,25,10)
	cDvSgCpo := AllTrim(Str(Modulo10(cSgCpo)))
	
	//Digito Verificador do Terceiro Campo
	cTrCpo := SubStr(cCodBarra,35,10)
	cDvTrCpo := AllTrim(Str(Modulo10(cTrCpo)))
	
	//Digito Verificador Geral
	cDvGeral := SubStr(cCodBarra,5,1)
	
	//Linha Digitavel
	cLindig := SubStr(cPrCpo,1,5) + "." + SubStr(cPrCpo,6,4) + cDvPrCpo + " "   //primeiro campo
	cLinDig += SubStr(cSgCpo,1,5) + "." + SubStr(cSgCpo,6,5) + cDvSgCpo + " "   //segundo campo
	cLinDig += SubStr(cTrCpo,1,5) + "." + SubStr(cTrCpo,6,5) + cDvTrCpo + " "   //terceiro campo
	cLinDig += " " + cDvGeral              //dig verificador geral
	cLinDig += "  " + SubStr(cCodBarra,6,4)+SubStr(cCodBarra,10,10)  // fator de vencimento e valor nominal do titulo
	
Return({cCodBarra,cLinDig,cNNum+PadR(cDvn,1)})

Static Function ValidPerg()
/*/{Protheus.doc} ValidPerg
Função que alimenta o grupo de perguntas da rotina
@author Fabio
@since 10/01/2015
@version 1.0
//*/	
	PutSx1(cPerg,"01","Do Prefixo:"				,"","","mv_ch1" ,"C",03,0,0,"G","",""		,"","","mv_par01",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"02","Ate o Prefixo:"			,"","","mv_ch2" ,"C",03,0,0,"G","",""		,"","","mv_par02",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"03","Do Titulo:"				,"","","mv_ch3" ,"C",07,0,0,"G","",""		,"","","mv_par03",""				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"04","Ate o Titulo:"			,"","","mv_ch4" ,"C",07,0,0,"G","",""		,"","","mv_par04",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"05","Da Parcela:"				,"","","mv_ch5" ,"C",02,0,0,"G","",""		,"","","mv_par05",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"06","Ate a Parcela:"			,"","","mv_ch6" ,"C",02,0,0,"G","",""		,"","","mv_par06",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"07","Do Banco:"				,"","","mv_ch7" ,"C",03,0,0,"G","","SA6"	,"","","mv_par07",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"08","Agencia:"				,"","","mv_ch8" ,"C",05,0,0,"G","",""		,"","","mv_par08",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"09","Conta:"					,"","","mv_ch9" ,"C",10,0,0,"G","",""		,"","","mv_par09",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"10","SubConta:" 				,"","","mv_ch10","C",03,0,0,"G","",""		,"","","mv_par10",""  				,"","","","" 			,"","","","","","","","","","","")
	PutSx1(cPerg,"11","Do Cliente:"				,"","","mv_ch11","C",06,0,0,"G","","SA1"	,"","","mv_par11",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"12","Ate o Cliente:"			,"","","mv_ch12","C",06,0,0,"G","","SA1"	,"","","mv_par12",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"13","Da Loja:"				,"","","mv_ch13","C",02,0,0,"G","",""		,"","","mv_par13",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"14","Ate a Loja:"				,"","","mv_ch14","C",02,0,0,"G","",""		,"","","mv_par14",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"15","Da Dt. Venc.:"			,"","","mv_ch15","D",08,0,0,"G","",""		,"","","mv_par15",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"16","Ate a Dt. Venc:"			,"","","mv_ch16","D",08,0,0,"G","",""		,"","","mv_par16",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"17","Da Dt. Emissao:"			,"","","mv_ch17","D",08,0,0,"G","",""		,"","","mv_par17",""   				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"18","Ate a Dt. Emis:"			,"","","mv_ch18","D",08,0,0,"G","",""		,"","","mv_par18",""   				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"19","Do bordero:"				,"","","mv_ch19","C",06,0,0,"G","",""		,"","","mv_par19",""				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"20","Ate o Bordero:"			,"","","mv_ch20","C",06,0,0,"G","",""		,"","","mv_par20",""				,"","","",""			,"","","","","","","","","","","")
	PutSx1(cPerg,"21","Selecionar titulos:"		,"","","mv_ch21","N",01,0,0,"C","",""		,"","","mv_par21","Sim"				,"","","","Não"			,"","","","","","","","","","","")
	PutSx1(cPerg,"22","Gerar Bordero:"			,"","","mv_ch22","N",01,0,0,"C","",""		,"","","mv_par22","Sim"				,"","","","Não"			,"","","","","","","","","","","")
Return

Static Function VerParam(mensagem)
/*/{Protheus.doc} VerParam
Função que dá a mensagem de validação dos parâmetros e retorna a rotina
@author Fabio
@since 10/01/2015
@version 1.0
@param mensagem, String, Mensagem
/*/
	Alert(mensagem)
	U_BOLETOACTVS()
Return

Static Function BuscaBorde()  
/*/{Protheus.doc} BuscaBorde
Busca um bordero com a data atual que não tenha sido transferido
@author Fabio Branis
@since 08/01/2015
@version 1.0
@return cRet, Número do borderô
/*/
	Local cRet	:= ""
	Local cQuery:= ""
	Local Temp
	Local cIniBord := "A00001"
	
	cQuery += "Select EA_NUMBOR From "	+ RetSqlName("SEA")	+ " As SEA "
	cQuery += "Where SEA.EA_AGEDEP = '"	+ _MV_PAR08 		+ "' " 
	cQuery += "And SEA.EA_NUMCON = '" 	+ _MV_PAR09 		+ "' " 
	cQuery += "And SEA.EA_PORTADO = '" 	+ _MV_PAR07 		+ "' "
	cQuery += "And SEA.EA_SUBCTA = '" 	+ _MV_PAR10 		+ "' "
	cQuery += "And SEA.EA_FILIAL = '" 	+ xFilial("SEA") 	+ "' "
	cQuery += "And SEA.EA_DATABOR = '" 	+ dToS(dDataBase) 	+ "' "
	cQuery += "And SEA.EA_TRANSF = '' "
	cQuery += "And SEA.EA_CART = 'R' "
   //	cQuery += "And SEA.EA_NUMBOR >= '"+cIniBord+"' "
	cQuery += "And SEA.D_E_L_E_T_ = '' " 

	TCQUERY cQuery NEW ALIAS (Temp:=GetNextAlias())
	
	While (Temp)->(!EoF())
		cRet := (Temp)->EA_NUMBOR
		(Temp)->(DbSkip())
	EndDo
	
	(Temp)->(DbCloseArea())
	
Return cRet