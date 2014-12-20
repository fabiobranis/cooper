#Include 'Protheus.ch'
/*/{Protheus.doc} FSFAT002
Programa que retorna os indicadores atualizados do cliente.
@author Fabio Branis
@since 16/12/2014
@version 1.0
@param paramixb[1], String, Empresa que vai ser processada
@param paramixb[2], String, Filial que vai ser processada
@param paramixb[3], String, Cnpj do cliente
@return aDadosCli, Array contendo os dados do cliente
/*/
User Function FSFAT002()
	
	Local aDadosCli		:= {}
	Local nMaiorVDA		:= 0
	Local cCliCod		:= ""
	Local cLojCod		:= ""
	Local cCliente		:= ""
	Local nMoeda		:= Int(Val(GetMv("MV_MCUSTO")))
	Local nMaiorVDAaux 	:= 0
	Local nMSaldo		:= 0
	Local nMoedaF		:= 0
	Local nTaxaM		:= 0
	Local cChaveSe1		:= ""
	Local cFilBusca		:= ""
	Local nSaldoTit		:= 0
	Local dPricom		:= ctod("")
	Local dUltCom		:= ctod("")
	Local nVacumPed		:= 0
	Local lE1MsFil
	Local cFilSF2  		:= ""
	Local nValForte		:= 0
	Local nMaiorDupl	:= 0
	Local nNumPgt		:= 0
	Local nPgtAtr		:= 0
	Local nValAtr		:= 0
	Local nRoCom		:= 0
	Local cNumPedVen	:= ""
	Local nMatrTit		:= 0
	Local nMedAtr		:= 0
	Local nSldAberto	:= 0
	
	Local cCnpjCli		:= paramixb[3]
	Local lJobEmp		:= iif(empty(paramixb[1]),.F.,.T.)
	Local cNumEmp		:= paramixb[1]
	Local cNumFil		:= paramixb[2]
	Local cEmprBkp		:= SM0->M0_CODIGO
	Local cAliSA1		:= iif(lJobEmp,"SA1AUX","SA1")//Já que o empchangetable não funciona, fazemos funcionar de alguma forma
	
	//Verificos se é para trocar de empresa
	if lJobEmp

     	dbUseArea(.T., "TOPCONN", "SA1"+alltrim(cNumEmp)+"0",cAliSA1,.T.,.F.)//Abro a SA1 separado, pois a função de mudança não funcionou pra ela
     	//Defino os três primeiros índices para a tabela SA1
     	dbsetindex("SA1"+alltrim(cNumEmp)+"01")
     	dbsetindex("SA1"+alltrim(cNumEmp)+"02")
     	dbsetindex("SA1"+alltrim(cNumEmp)+"03") 
     	
     	//Abro a tabela referente à outra empresa
     	EmpChangeTable("SE1",cNumEmp,cEmprBkp,2 ) 
     	EmpChangeTable("SF2",cNumEmp,cEmprBkp,2 ) 
	endif
	
	lE1MsFil 		:= SE1->(FieldPos("E1_MSFIL") > 0)
	cFilSF2  		:= xFilial("SF2")
	
	//Posiciono no cliente tanto a tabela SA1 quanto SE1
	dbSelectArea("SE1")
	dbSetOrder(2)
	(cAliSA1)->(dbsetorder(3))
	if (cAliSA1)->(dbseek(xFilial("SA1")+cCnpjCli))
		cCliCod	:= (cAliSA1)->A1_COD
		cLojCod	:= (cAliSA1)->A1_LOJA
		MsSeek(xFilial("SE1")+(cAliSA1)->A1_COD+(cAliSA1)->A1_LOJA,.T.)
	endif
		
	nMaiorVDA := 0
		
	While !Eof().And.(SE1->E1_CLIENTE >= cCliCod .And. SE1->E1_CLIENTE <= cCliCod) .and. (SE1->E1_LOJA >= cLojCod .and. SE1->E1_LOJA <= cLojCod)

		If SE1->E1_CLIENTE >= cCliCod .And. SE1->E1_CLIENTE <= cCliCod

			//
			//Atualiza Saldo do Cliente
			//
				
			dbSelectArea(cAliSA1)
			dbsetorder(1)
			If !Empty(xFilial("SA1")) .and. !Empty(xFilial("SE1"))
				cFilBusca := SE1->E1_FILIAL		// Ambos exclusivos, neste caso
																// a filial serah 1 para 1
			Else
				cFilBusca := xFilial("SA1")		// filial do cliente ((cAliSA1))
			Endif

			//
			//Monta a chave de busca para o (cAliSA1)
			//			
			cChaveSe1 := cFilBusca + SE1->E1_CLIENTE+ SE1->E1_LOJA
							
			dbSelectArea( "SA1" )
			If (dbSeek( cChaveSe1 ) )
				If !((cAliSA1)->(A1_FILIAL+A1_COD+A1_LOJA) ==  cCliente)
					cCliente     := (cAliSA1)->(A1_FILIAL+A1_COD+A1_LOJA)
					nMaiorVDA    := 0
					nMaiorVDAaux := 0
					nMSaldo      := 0
				EndIf
				nMoedaF		:= If((cAliSA1)->A1_MOEDALC > 0,(cAliSA1)->A1_MOEDALC,nMoeda)
				nTaxaM:=Round(SE1->E1_VLCRUZ/SE1->E1_VALOR,3)
				If SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG+"/"+MVABATIM+"/"+MVIRABT+"/"+MVFUABT+"/"+MVINABT+"/"+MVISABT+"/"+MVPIABT+"/"+MVCFABT
					AtuSalDup("-",SE1->E1_SALDO,SE1->E1_MOEDA,SE1->E1_TIPO,Iif(nTaxaM==1,Nil,nTaxaM),SE1->E1_EMISSAO)
				Else
					nSaldoTit := SE1->E1_SALDO
					nSaldoTit := Iif(nSaldoTit < 0, 0, nSaldoTit)
					IF !(SE1->E1_TIPO $ MVPROVIS)
						AtuSalDup("+",nSaldoTit,SE1->E1_MOEDA,SE1->E1_TIPO,Iif(nTaxaM==1,Nil,nTaxaM),SE1->E1_EMISSAO)
					Endif
					
					//Primeira compra
					dPricom  := Iif(SE1->E1_EMISSAO<A1_PRICOM.or.Empty(A1_PRICOM),SE1->E1_EMISSAO,A1_PRICOM)
					//Última compra
					dUltCom  := Iif(A1_ULTCOM<SE1->E1_EMISSAO,SE1->E1_EMISSAO,A1_ULTCOM)
					
					//Valor acumulado dos pedidos
					IF Year(SE1->E1_EMISSAO) == Year(dDataBase) .And. AllTrim(Upper(SE1->E1_ORIGEM))<>"FINA280"
						nVacumPed += xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,nMoedaF,SE1->E1_EMISSAO)
					Endif
	
					IF !(SE1->E1_TIPO $ MVPROVIS)
						    						    
						If AllTrim(Upper(SE1->E1_ORIGEM)) == "MATA460"
							SF2->(dbSetOrder(2))
							cFilSF2 := If (lE1Msfil .and. !Empty(xFilial("SF2")),SE1->E1_MSFIL,xFilial("SF2"))
							If !SF2->( MsSeek(cFilSF2+SE1->(E1_CLIENTE+E1_LOJA+E1_NUM+E1_PREFIXO)))
									// Se nao encontrou a nota, procura pela serie da nota ao inves do prefixo (MV_1DUPREF customizado)
								SF2->( MsSeek(cFilSF2+SE1->(E1_CLIENTE+E1_LOJA+E1_NUM+E1_SERIE)))
							Endif
							If SF2->(!EoF())
								nMaiorVDAaux := xMoeda(SF2->F2_VALFAT,SE1->E1_MOEDA,nMoedaF,SE1->E1_EMISSAO)
								If nMaiorVDA < nMaiorVDAaux
									nMaiorVDA := nMaiorVDAaux
								Endif
							Endif
						Else
							nMaiorVDA := xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,nMoedaF,SE1->E1_EMISSAO) //Maior venda
						Endif
						    
						nValForte := xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,nMoedaF,SE1->E1_EMISSAO)
						//Maior duplicata
						if nValForte > (cAliSA1)->A1_MAIDUPL //refaz dados historicos
							nMaiorDupl := nValForte
						else
							nMaiorDupl := (cAliSA1)->A1_MAIDUPL
						endif
						
						//
						//Atualiza Atrasos/Pagamentos em Atraso do Cliente
						//
						aBaixas:=Baixas(SE1->E1_NATUREZ,SE1->E1_PREFIXO,SE1->E1_NUM,;
							SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_MOEDA,"R",SE1->E1_CLIENTE,;
							dDataBase,SE1->E1_LOJA,SE1->E1_FILIAL)
	
						If (Empty(SE1->E1_FATURA) .Or. Substr(SE1->E1_FATURA,1,6) = "NOTFAT") .And.;
								STR(SE1->E1_SALDO,17,2) != STR(SE1->E1_VALOR,17,2)
							nNumPgt += aBaixas[11] //Número total de pagamentos
						Endif
						If SE1->E1_SALDO == 0
							If (Empty(SE1->E1_FATURA) .Or. Substr(SE1->E1_FATURA,1,6) = "NOTFAT")
								If (SE1->E1_BAIXA - SE1->E1_VENCREA) > 0
									nPgtAtr += SE1->E1_VALLIQ //Pagamentos feitos com atraso
								Endif
							Endif
						Else
							If SE1->E1_VENCREA < dDatabase
								nValAtr += SE1->E1_SALDO //Pagamentos em atraso
							Endif
						Endif
							
						//
						//Atualiza Dados Historicos
						//
				
						//A1_MSALDO - Maior saldo de duplicatas do Cliente
						//A1_METR - Media de atrasos do Cliente
						//A1_MATR - Maior atraso do Cliente
	  					
	  					//Maior compra			  							
						If nMaiorVDA < (cAliSA1)->A1_MCOMPRA
							nMaiorVDA := (cAliSA1)->A1_MCOMPRA
						Endif
	  						 		  						 	
							// Nao incrementa faturas a receber (FINA280)
						If AllTrim(Upper(SE1->E1_ORIGEM)) <> "FINA280"
							If !Empty(SE1->E1_PEDIDO)
								// Se existe pedido de vendas, somente incrementa se for um pedido diferente do titulo anterior
								If cNumPedVen != SE1->E1_PEDIDO
									nRoCom += 1//(cAliSA1)->A1_NROCOM  += 1
								EndIf
							Else
			  						 	// Se nao existe pedido, entao incrementa como titulo normal do Financeiro
								nRoCom += 1//(cAliSA1)->A1_NROCOM  += 1
							EndIf
						EndIf

						If SE1->E1_SALDO > 0
							nMSaldo += xMoeda(SE1->E1_SALDO,SE1->E1_MOEDA,nMoedaF,SE1->E1_EMISSAO) //Maior Saldo
							nSldAberto += xMoeda(SE1->E1_SALDO,SE1->E1_MOEDA,nMoedaF,SE1->E1_EMISSAO)//Saldo em aberto
						EndIf
						
						//Maior saldo devedor
						If (cAliSA1)->A1_SALDUPM > (cAliSA1)->A1_MSALDO
							nMSaldo := (cAliSA1)->A1_SALDUPM
						Else
							If nMSaldo < (cAliSA1)->A1_MSALDO
								nMSaldo := (cAliSA1)->A1_MSALDO
							EndIf
						EndIf
								
						IF Empty(SE1->E1_FATURA) .Or. Substr(SE1->E1_FATURA,1,6) = "NOTFAT"
							If (SE1->E1_BAIXA - SE1->E1_VENCREA) > (cAliSA1)->A1_MATR
								nMatrTit := SE1->E1_BAIXA - SE1->E1_VENCREA //Maior atraso
							EndIf
							If !Empty(SE1->E1_BAIXA)
								nMedAtr := ((cAliSA1)->A1_METR * (nNumPgt-1) + (SE1->E1_BAIXA - SE1->E1_VENCREA))/ nNumPgt //Média de atraso
							Endif
						Endif
					Endif
				
					//
					//Funcao para ajustar os campos do (cAliSA1) para vendas
					//Que possuem Administradora Financeira e         
					//Apenas para o modulo SIGALOJA                   
					//
					//F410AjusLj(nMaiorVDA,cNumPedVen,nMoedaF)
				Endif
			Endif
		Endif
		cNumPedVen := SE1->E1_PEDIDO
		dbSelectArea( "SE1" )
		dbSkip()
	Enddo
	
	//Alimento o array de retorno
	aadd(aDadosCli,dPricom)
	aadd(aDadosCli,nMaiorVDA)
	aadd(aDadosCli,nRoCom)
	aadd(aDadosCli,nVacumPed)
	aadd(aDadosCli,nMSaldo)
	aadd(aDadosCli,nMedAtr)
	aadd(aDadosCli,nSldAberto)
	aadd(aDadosCli,nNumPgt)
	aadd(aDadosCli,nValAtr)
	aadd(aDadosCli,nMatrTit)
	aadd(aDadosCli,nMaiorDupl)
	aadd(aDadosCli,nSldAberto)
	aadd(aDadosCli,nPgtAtr)
	aadd(aDadosCli,dUltCom)
	
	//Se for mudança de empresa volto tudo ao normal
	if lJobEmp
		
		dbclosearea(cAliSA1)//Fecho a tabela
		//Volto ao estado original
     	EmpChangeTable("SE1",cEmprBkp,cNumEmp,2 ) 
     	EmpChangeTable("SF2",cEmprBkp,cNumEmp,2 ) 
	endif
	
Return aDadosCli
