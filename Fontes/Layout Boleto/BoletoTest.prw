#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} TstBol
Funcao de teste para homologacao do layout Santander (033) seguindo o padrao grafico e dimensional do BV.
@type function
@version 1.0
@author Kaua.Baldin
@since 06/17/2026
@return variant, Retorna vazio
/*/
User Function TstBol()
	Local oPrint
	Local aDadosEmp, aDadosTit, aDadosBanco, aDatSacado, aBolText, aCB_RN_NN
	Local cNossoNum, cCodBar, cLinDig
	Local dirprt := "C:\TEMP\"

	// Prepara o ambiente para testes diretos via IDE (Evita erros de CACESSO e FWMSPrinter)
	RPCSetEnv("01", "01")

	// 1. Dados da Empresa Beneficiaria (Dados fixos para evitar erro de Alias SM0 no teste)
	aDadosEmp := {"GUERRA IMPLEMENTOS RODOVIARIOS S/A",;
		"RODOVIA BR 282, SN KM 499",;
		"SALA 02, JOAO WINCKLER, SC",;
		"CEP: 89820-000",;
		"PABX/FAX: (49) 3000-0000",;
		"CNPJ: 31.008.318/0001-42",;
		"I.E.: 123456789" }

	// 2. Parametros do Banco (Santander 033)
	// [1]CodBanco [2]NomeBanco [3]Agencia [4]Conta [5]DV [6]Carteira [7]Convenio
	aDadosBanco := {"033", "Banco Santander", "3471", "0000481", "2", "101", "6953808"}

	// 3. Dados do Sacado (Exemplo extraido do layout padrao)
	aDatSacado := {"SERAGLIO COMERCIO DE PECAS LTDA (CLI237-01)",;
		"CLI237-01",;
		"RODOVIA BR 282, SN KM 499-SALA 02-JOAO WINCKLER",;
		"XANXERE",;
		"SC",;
		"89820-000",;
		"12.546.569/0001-36",;
		"J"}

	// 4. Textos de Instrucoes de Cobranca
	aBolText := {"APOS O VENCIMENTO COBRAR MORA DE R$....... ",;
		"PROTESTAR APOS 05 DIAS CORRIDOS DO VENCIMENTO ",;
		"AO DIA",;
		"APOS O VENCIMENTO COBRAR MULTA DE R$......."}

	// 5. Geracao Numerica Baseada no Manual Santander e Fontes de Integracao
	cNossoNum := CalcNossoNum033("0002454") // 7 posicoes sequenciais de teste
	cCodBar   := CodBar033(1500.50, Date() + 15, cNossoNum, aDadosBanco[7])
	cLinDig   := LinDig033(cCodBar)

	aCB_RN_NN := {cCodBar, cLinDig, cNossoNum}

	// 6. Estrutura de Dados do Titulo
	// [1]NumDoc [2]Emissao [3]Processamento [4]Vencimento [5]Valor [6]NossoNumero [7]Prefixo [8]EspecieDoc
	aDadosTit := {"00002454", Date(), Date(), Date() + 15, 1500.50, cNossoNum, "BOL", "DM"}

	// 7. Inicializacao do Objeto Grafico FWMSPrinter voltado para o Client (VM local)
	oPrint := FWMSPrinter():New("Boleto_Santander_Teste", 6, .T., dirprt, .F.)
	oPrint:SetPortrait()
	oPrint:SetPaperSize(9)
	oPrint:cPathPDF := dirprt
	oPrint:lServer  := .F.

	// 8. Execucao da Montagem Visual Grafica
	ImpressSant(oPrint, aDadosEmp, aDadosTit, aDadosBanco, aDatSacado, aBolText, aCB_RN_NN)

	oPrint:Preview()

	// Encerra a sessao de teste
	RPCClearEnv()
Return


/*/{Protheus.doc} CalcNossoNum033
Calcula o Nosso Numero Santander com 7 posicoes base + 1 DV em Modulo 11.
@type function
@version 1.0
@author Kaua.Baldin
@since 06/17/2026
@param cNumSeq, character, Sequencial base para o nosso numero (7 posicoes)
@return variant, String contendo o nosso numero com o digito verificador
/*/
Static Function CalcNossoNum033(cNumSeq)
	Local cBaseNum := PadL(AllTrim(cNumSeq), 7, "0")
	Local nSoma    := 0
	Local nResto   := 0
	Local cDV      := ""
	Local nFator   := 2
	Local nI

	For nI := 7 To 1 Step -1
		nSoma += Val(SubStr(cBaseNum, nI, 1)) * nFator
		nFator++
		If nFator > 9
			nFator := 2
		EndIf
	Next

	nResto := Mod(nSoma, 11)

	If nResto == 0 .Or. nResto == 10
		cDV := "0"
	ElseIf nResto == 1
		cDV := "1"
	Else
		cDV := cValToChar(11 - nResto)
	EndIf

Return cBaseNum + cDV


/*/{Protheus.doc} CodBar033
Monta a string de 44 posicoes do Codigo de Barras do Santander.
@type function
@version 1.0
@author Kaua.Baldin
@since 06/17/2026
@param nValor, numeric, Valor do titulo
@param dVencto, date, Data de vencimento do titulo
@param cNossoNum, character, Nosso numero do titulo com DV
@param cConvenio, character, Codigo do convenio/beneficiario no banco
@return variant, Retorna a string do codigo de barras
/*/
Static Function CodBar033(nValor, dVencto, cNossoNum, cConvenio)
	Local cFatorVct   := StrZero(dVencto - sToD("19971007"), 4)
	Local cValTit     := StrZero(nValor * 100, 10)
	Local cCampoLivre := "9" + PadL(AllTrim(cConvenio), 7, "0") + "00000" + PadL(AllTrim(cNossoNum), 8, "0") + "0101"
	Local cCodBar     := "033" + "9" + "0" + cFatorVct + cValTit + cCampoLivre
	Local nSoma := 0, nPeso := 2, nI, nResto, cDV

	For nI := 44 To 1 Step -1
		If nI != 5
			nSoma += Val(SubStr(cCodBar, nI, 1)) * nPeso
			nPeso++
			If nPeso > 9
				nPeso := 2
			EndIf
		EndIf
	Next
	nSoma  := nSoma * 10
	nResto := Mod(nSoma, 11)

	If nResto == 0 .Or. nResto == 1 .Or. nResto == 10
		cDV := "1"
	Else
		cDV := cValToChar(nResto)
	EndIf

	cCodBar := SubStr(cCodBar, 1, 4) + cDV + SubStr(cCodBar, 6)
Return cCodBar


/*/{Protheus.doc} LinDig033
Gera a Representacao Numerica (Linha Digitavel) baseada no Codigo de Barras.
@type function
@version 1.0
@author Kaua.Baldin
@since 06/17/2026
@param cCodBar, character, String do codigo de barras gerado
@return variant, Retorna a linha digitavel formatada
/*/
Static Function LinDig033(cCodBar)
	Local cCampo1, cCampo2, cCampo3, cCampo4, cCampo5, cRet

	cCampo1 := SubStr(cCodBar, 1, 4) + SubStr(cCodBar, 20, 5)
	cCampo1 += DvMod10Sant(cCampo1)

	cCampo2 := SubStr(cCodBar, 25, 10)
	cCampo2 += DvMod10Sant(cCampo2)

	cCampo3 := SubStr(cCodBar, 35, 10)
	cCampo3 += DvMod10Sant(cCampo3)

	cCampo4 := SubStr(cCodBar, 5, 1)
	cCampo5 := SubStr(cCodBar, 6, 14)

	cRet := Transform(cCampo1 + cCampo2 + cCampo3 + cCampo4 + cCampo5, "@R 99999.99999 99999.999999 99999.999999 9 99999999999999")
Return cRet


/*/{Protheus.doc} DvMod10Sant
Calcula o digito verificador de amarracao dos blocos da linha digitavel.
@type function
@version 1.0
@author Kaua.Baldin
@since 06/17/2026
@param cCampo, character, Bloco da linha digitavel
@return variant, Retorna o digito verificador em Modulo 10
/*/
Static Function DvMod10Sant(cCampo)
	Local nSoma := 0, nPeso := 2, nMult, nI, nResto

	For nI := Len(cCampo) To 1 Step -1
		nMult := Val(SubStr(cCampo, nI, 1)) * nPeso
		If nMult > 9
			nMult := Val(SubStr(StrZero(nMult, 2), 1, 1)) + Val(SubStr(StrZero(nMult, 2), 2, 1))
		EndIf
		nSoma += nMult
		nPeso := IIf(nPeso == 2, 1, 2)
	Next
	nResto := Mod(nSoma, 10)
Return IIf(nResto == 0, "0", cValToChar(10 - nResto))


/*/{Protheus.doc} ImpressSant
Geracao do layout visual grafico espelhando a cubagem e posicionamento do BV.
@type function
@version 1.0
@author Kaua.Baldin
@since 06/17/2026
@param oPrn, object, Objeto FWMSPrinter
@param aDadosEmp, array, Dados da empresa cedente
@param aDadosTit, array, Dados do titulo
@param aDadosBanco, array, Dados do banco
@param aDatSacado, array, Dados do sacado
@param aBolText, array, Textos de instrucao
@param aCB_RN_NN, array, Array com as rotinas de numero e cod de barras
@return variant, Retorna vazio
/*/
Static Function ImpressSant(oPrn, aDadosEmp, aDadosTit, aDadosBanco, aDatSacado, aBolText, aCB_RN_NN)
	Local oFont8   := TFont():New("Arial",9,8,.T.,.F.,5,.T.,5,.T.,.F.)
	Local oFont11c := TFont():New("Courier New",9,11,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont11  := TFont():New("Arial",9,11,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont9   := TFont():New("Arial",9,8,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont10  := TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont14  := TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont20  := TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont21  := TFont():New("Arial",9,21,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont16n := TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	Local oFont15  := TFont():New("Arial",9,15,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont15n := TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
	Local oFont14n := TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
	Local oFont24  := TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

	Local nI      := 0
	Local cString := ""
	Local nCol    := 0
	Local cNroDoc := aDadosBanco[6] + "/" + aCB_RN_NN[3]

	// Coordenadas herdadas e estaveis do layout original da empresa
	Local nRow1 := 0,   nRol1 := -25
	Local nRow2 := 0,   nRol2 := -27
	Local nRow3 := -50, nRol3 := -85

	oPrn:StartPage()

	//========================================================================
	// PRIMEIRA PARTE - COMPROVANTE DE ENTREGA (CANHOTO SUPERIOR)
	//========================================================================
	oPrn:Line (nRol1+0150,500,nRol1+0070, 500)
	oPrn:Line (nRol1+0150,710,nRol1+0070, 710)

	oPrn:Say  (nRow1+0084,100,"Banco Santander",oFont14 )
	oPrn:Say  (nRow1+0075,513,"033-7",oFont21 )

	oPrn:Say  (nRow1+0084,1900,"Comprovante de Entrega",oFont10)
	oPrn:Line (nRol1+0150,100,nRol1+0150,2300)

	oPrn:Say  (nRow1+0150,100 ,"Cedente",oFont8)
	oPrn:Say  (nRow1+0200,100 ,aDadosEmp[1],oFont10)

	oPrn:Say  (nRow1+0150,1060,"Convenio do beneficiario",oFont8)
	oPrn:Say  (nRow1+0200,1060,aDadosBanco[7],oFont10)

	oPrn:Say  (nRow1+0150,1510,"Nro.Documento",oFont8)
	oPrn:Say  (nRow1+0200,1510,aDadosTit[7]+aDadosTit[1],oFont10)

	oPrn:Say  (nRow1+0250,100 ,"Sacado",oFont8)
	oPrn:Say  (nRow1+0300,100 ,aDatSacado[1],oFont9)

	oPrn:Say  (nRow1+0250,1060,"Vencimento",oFont8)
	oPrn:Say  (nRow1+0300,1080,StrZero(Day(aDadosTit[4]),2) +"/"+ StrZero(Month(aDadosTit[4]),2) +"/"+ Right(Str(Year(aDadosTit[4])),4),oFont10)

	oPrn:Say  (nRow1+0250,1510,"Valor do Documento",oFont8)
	oPrn:Say  (nRow1+0300,1550,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

	oPrn:Say  (nRow1+0400,0100,"Recebi(emos) o bloqueto/titulo com as caracteristicas acima.",oFont10)
	oPrn:Say  (nRow1+0350,1060,"Data",oFont8)
	oPrn:Say  (nRow1+0350,1410,"Assinatura",oFont8)
	oPrn:Say  (nRow1+0450,1060,"Data",oFont8)
	oPrn:Say  (nRow1+0450,1410,"Entregador",oFont8)

	oPrn:Line (nRol1+0250, 100,nRol1+0250,1900 )
	oPrn:Line (nRol1+0350, 100,nRol1+0350,1900 )
	oPrn:Line (nRol1+0450,1050,nRol1+0450,1900 )
	oPrn:Line (nRol1+0550, 100,nRol1+0550,2300 )

	oPrn:Line (nRol1+0550,1050,nRol1+0150,1050 )
	oPrn:Line (nRol1+0550,1400,nRol1+0350,1400 )
	oPrn:Line (nRol1+0350,1500,nRol1+0150,1500 )
	oPrn:Line (nRol1+0550,1900,nRol1+0150,1900 )

	oPrn:Say  (nRow1+0165,1910,"(  )Mudou-se"                               ,oFont8)
	oPrn:Say  (nRow1+0205,1910,"(  )Ausente"                                ,oFont8)
	oPrn:Say  (nRow1+0245,1910,"(  )Nao existe n. indicado"                 ,oFont8)
	oPrn:Say  (nRow1+0285,1910,"(  )Recusado"                               ,oFont8)
	oPrn:Say  (nRow1+0325,1910,"(  )Nao procurado"                          ,oFont8)
	oPrn:Say  (nRow1+0365,1910,"(  )Endereco insuficiente"                  ,oFont8)
	oPrn:Say  (nRow1+0405,1910,"(  )Desconhecido"                           ,oFont8)
	oPrn:Say  (nRow1+0445,1910,"(  )Falecido"                               ,oFont8)
	oPrn:Say  (nRow1+0485,1910,"(  )Outros(anotar no verso)"                ,oFont8)

	//========================================================================
	// SEGUNDA PARTE - RECIBO DO SACADO (COMPROVANTE DO CLIENTE)
	//========================================================================
	oPrn:Line (nRol2+0710,100,nRol2+0710,2300)
	oPrn:Line (nRol2+0710,500,nRol2+0630, 500)
	oPrn:Line (nRol2+0710,710,nRol2+0630, 710)

	oPrn:Say  (nRow2+0644,100,"Banco Santander",oFont14 )
	oPrn:Say  (nRow2+0635,513,"033-7",oFont21 )
	oPrn:Say  (nRow2+0644,1800,"Recibo do Sacado",oFont10)

	oPrn:Line (nRol2+0810,100,nRol2+0810,2300 )
	oPrn:Line (nRol2+0910,100,nRol2+0910,2300 )
	oPrn:Line (nRol2+0980,100,nRol2+0980,2300 )
	oPrn:Line (nRol2+1050,100,nRol2+1050,2300 )

	oPrn:Line (nRol2+0910,500,nRol2+1050,500)
	oPrn:Line (nRol2+0980,750,nRol2+1050,750)
	oPrn:Line (nRol2+0910,1000,nRol2+1050,1000)
	oPrn:Line (nRol2+0910,1300,nRol2+0980,1300)
	oPrn:Line (nRol2+0910,1480,nRol2+1050,1480)

	oPrn:Say  (nRow2+0710,100 ,"Local de Pagamento",oFont8)
	oPrn:Say  (nRow2+0725,400 ,"ATE O VENCIMENTO PAGUE PREFERENCIALMENTE NO SANTANDER",oFont10)
	oPrn:Say  (nRow2+0765,400 ,"APOS O VENCIMENTO PAGUE SOMENTE NO SANTANDER",oFont10)

	oPrn:Say  (nRow2+0710,1810,"Vencimento",oFont8)
	cString := StrZero(Day(aDadosTit[4]),2) +"/"+ StrZero(Month(aDadosTit[4]),2) +"/"+ Right(Str(Year(aDadosTit[4])),4)
	nCol    := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow2+0750,nCol,cString,oFont11c)

	oPrn:Say  (nRow2+0810,100 ,"Cedente",oFont8)
	oPrn:Say  (nRow2+0850,100 ,aDadosEmp[1]+"                  - "+aDadosEmp[6] ,oFont10)

	oPrn:Say  (nRow2+0810,1810,"Convenio beneficiario",oFont8)
	cString := Alltrim(aDadosBanco[3]+"/"+aDadosBanco[4])
	nCol    := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow2+0850,nCol,aDadosBanco[7],oFont11c)

	oPrn:Say  (nRow2+0910,100 ,"Data do Documento",oFont8)
	oPrn:Say  (nRow2+0940,100, DToC(aDadosTit[2]),oFont10)

	oPrn:Say  (nRow2+0910,505 ,"Nro.Documento",oFont8)
	oPrn:Say  (nRow2+0940,605 ,aDadosTit[7]+aDadosTit[1],oFont10)

	oPrn:Say  (nRow2+0910,1005,"Especie Doc.",oFont8)
	oPrn:Say  (nRow2+0940,1050,aDadosTit[8],oFont10)

	oPrn:Say  (nRow2+0910,1305,"Aceite",oFont8)
	oPrn:Say  (nRow2+0940,1400,"N",oFont10)

	oPrn:Say  (nRow2+0910,1485,"Data do Processamento",oFont8)
	oPrn:Say  (nRow2+0940,1550,StrZero(Day(aDadosTit[3]),2) +"/"+ StrZero(Month(aDadosTit[3]),2) +"/"+ Right(Str(Year(aDadosTit[3])),4),oFont10)

	oPrn:Say  (nRow2+0910,1810,"Nosso Numero",oFont8)
	cString := cNroDoc
	nCol    := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow2+0940,nCol,cNroDoc,oFont11c)

	oPrn:Say  (nRow2+0980,100 ,"Uso do Banco",oFont8)
	oPrn:Say  (nRow2+0980,505 ,"Carteira",oFont8)
	oPrn:Say  (nRow2+1010,555 ,aDadosBanco[6],oFont10)
	oPrn:Say  (nRow2+0980,755 ,"Especie",oFont8)
	oPrn:Say  (nRow2+1010,805 ,"R$",oFont10)
	oPrn:Say  (nRow2+0980,1005,"Quantidade",oFont8)
	oPrn:Say  (nRow2+0980,1485,"Valor",oFont8)

	oPrn:Say  (nRow2+0980,1810,"Valor do Documento",oFont8)
	cString := Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99"))
	nCol    := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow2+1010,nCol,cString  ,oFont11c)

	oPrn:Say  (nRow2+1050,100 ,"Instrucoes (Todas informacoes deste bloqueto sao de exclusiva responsabilidade do cedente)",oFont8)
	oPrn:Say  (nRow2+1100,100 ,aBolText[4]+" "+AllTrim(Transform((aDadosTit[5]*0.02),"@E 99,999.99")),oFont10)
	oPrn:Say  (nRow2+1150,100 ,aBolText[1]+" "+AllTrim(Transform(((aDadosTit[5]*(2/30))/100),"@E 99,999.99"))+" AO DIA",oFont10)
	oPrn:Say  (nRow2+1200,100 ,aBolText[2],oFont10)

	oPrn:Say  (nRow2+1050,1810,"(-)Desconto/Abatimento",oFont8)
	oPrn:Say  (nRow2+1120,1810,"(-)Outras Deducoes",oFont8)
	oPrn:Say  (nRow2+1190,1810,"(+)Mora/Multa",oFont8)
	oPrn:Say  (nRow2+1260,1810,"(+)Outros Acrescimos",oFont8)
	oPrn:Say  (nRow2+1330,1810,"(=)Valor Cobrado",oFont8)

	oPrn:Say  (nRow2+1350,100," APOS VCTO ACESSE WWW.SANTANDER.COM.BR/BOLETOS PARA ATUALIZAR SEU BOLETO",oFont10)

	oPrn:Say  (nRow2+1400,100 ,"Sacado",oFont8)
	oPrn:Say  (nRow2+1430,400 ,aDatSacado[1]+" ("+aDatSacado[2]+")",oFont10)
	oPrn:Say  (nRow2+1483,400 ,aDatSacado[3],oFont10)
	oPrn:Say  (nRow2+1536,400 ,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10)

	If aDatSacado[8] == "J"
		oPrn:Say  (nRow2+1589,400 ,"CNPJ: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10)
	Else
		oPrn:Say  (nRow2+1589,400 ,"CPF: "+TRANSFORM(aDatSacado[7],"@R 999.999.999-99"),oFont10)
	EndIf

	oPrn:Say  (nRow2+1589,1850,cNroDoc,oFont10)

	oPrn:Say  (nRow2+1605,100 ,"Sacador/Avalista",oFont8)
	oPrn:Say  (nRow2+1645,1500,"Autenticacao Mecanica",oFont8)

	oPrn:Line (nRol2+0710,1800,nRol2+1400,1800 )
	oPrn:Line (nRol2+1120,1800,nRol2+1120,2300 )
	oPrn:Line (nRol2+1190,1800,nRol2+1190,2300 )
	oPrn:Line (nRol2+1260,1800,nRol2+1260,2300 )
	oPrn:Line (nRol2+1330,1800,nRol2+1330,2300 )
	oPrn:Line (nRol2+1400,100 ,nRol2+1400,2300 )
	oPrn:Line (nRol2+1640,100 ,nRol2+1640,2300 )

	//========================================================================
	// TERCEIRA PARTE - FICHA DE COMPENSACAO (FICHA DE BANCO INFERIOR)
	//========================================================================
	For nI := 100 to 2300 step 50
		oPrn:Line(nRol3+1880, nI, nRol3+1880, nI+30)
	Next nI

	oPrn:Line (nRol3+2000,100,nRol3+2000,2300)
	oPrn:Line (nRol3+2000,500,nRol3+1920, 500)
	oPrn:Line (nRol3+2000,710,nRol3+1920, 710)

	oPrn:Say  (nRow3+1934,100,"Banco Santander",oFont14 )
	oPrn:Say  (nRow3+1925,513,"033-7",oFont21 )
	oPrn:Say  (nRow3+1934,755,aCB_RN_NN[2],oFont15n)

	oPrn:Line (nRol3+2100,100,nRol3+2100,2300 )
	oPrn:Line (nRol3+2200,100,nRol3+2200,2300 )
	oPrn:Line (nRol3+2270,100,nRol3+2270,2300 )
	oPrn:Line (nRol3+2340,100,nRol3+2340,2300 )

	oPrn:Line (nRol3+2200,500 ,nRol3+2340,500 )
	oPrn:Line (nRol3+2270,750 ,nRol3+2340,750 )
	oPrn:Line (nRol3+2200,1000,nRol3+2340,1000)
	oPrn:Line (nRol3+2200,1300,nRol3+2270,1300)
	oPrn:Line (nRol3+2200,1480,nRol3+2340,1480)

	oPrn:Say  (nRow3+2000,100 ,"Local de Pagamento",oFont8)
	oPrn:Say  (nRow3+2015,400 ,"ATE O VENCIMENTO PAGUE PREFERENCIALMENTE NO SANTANDER",oFont10)
	oPrn:Say  (nRow3+2055,400 ,"APOS O VENCIMENTO PAGUE SOMENTE NO SANTANDER",oFont10)

	oPrn:Say  (nRow3+2000,1810,"Vencimento",oFont8)
	cString := StrZero(Day(aDadosTit[4]),2) +"/"+ StrZero(Month(aDadosTit[4]),2) +"/"+ Right(Str(Year(aDadosTit[4])),4)
	nCol     := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow3+2040,nCol,cString,oFont11c)

	oPrn:Say  (nRow3+2100,100 ,"Cedente",oFont8)
	oPrn:Say  (nRow3+2140,100 ,aDadosEmp[1]+"                  - "+aDadosEmp[6] ,oFont10)

	oPrn:Say  (nRow3+2100,1810,"Convenio beneficiario",oFont8)
	cString := Alltrim(aDadosBanco[3]+"/"+aDadosBanco[4])
	nCol   := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow3+2140,nCol,aDadosBanco[7] ,oFont11c)

	oPrn:Say (nRow3+2200,100 ,"Data do Documento",oFont8)
	oPrn:Say (nRow3+2230,100, DToC(aDadosTit[2]), oFont10)

	oPrn:Say (nRow3+2200,505 ,"Nro.Documento",oFont8)
	oPrn:Say (nRow3+2230,605 ,aDadosTit[7]+aDadosTit[1],oFont10)

	oPrn:Say (nRow3+2200,1005,"Especie Doc.",oFont8)
	oPrn:Say (nRow3+2230,1050,aDadosTit[8],oFont10)

	oPrn:Say (nRow3+2200,1305,"Aceite",oFont8)
	oPrn:Say (nRow3+2230,1400,"N",oFont10)

	oPrn:Say  (nRow3+2200,1485,"Data do Processamento",oFont8)
	oPrn:Say  (nRow3+2230,1550,StrZero(Day(aDadosTit[3]),2) +"/"+ StrZero(Month(aDadosTit[3]),2) +"/"+ Right(Str(Year(aDadosTit[3])),4),oFont10)

	oPrn:Say  (nRow3+2200,1810,"Nosso Numero",oFont8)
	cString := cNroDoc
	nCol := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow3+2230,nCol,cNroDoc,oFont11c)

	oPrn:Say  (nRow3+2270,100 ,"Uso do Banco",oFont8)
	oPrn:Say  (nRow3+2270,505 ,"Carteira",oFont8)
	oPrn:Say  (nRow3+2300,555 ,aDadosBanco[6],oFont10)
	oPrn:Say  (nRow3+2270,755 ,"Especie",oFont8)
	oPrn:Say  (nRow3+2300,805 ,"R$",oFont10)
	oPrn:Say  (nRow3+2270,1005,"Quantidade",oFont8)
	oPrn:Say  (nRow3+2270,1485,"Valor",oFont8)

	oPrn:Say  (nRow3+2270,1810,"Valor do Documento",oFont8)
	cString := Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99"))
	nCol   := 1810+(374-(len(cString)*22))
	oPrn:Say  (nRow3+2300,nCol,cString,oFont11c)

	oPrn:Say  (nRow3+2340,100 ,"Instrucoes (Todas informacoes deste bloqueto sao de exclusiva responsabilidade do cedente)",oFont8)
	oPrn:Say  (nRow3+2390,100 ,aBolText[4]+" "+AllTrim(Transform((aDadosTit[5]*0.02),"@E 99,999.99")),oFont10)
	oPrn:Say  (nRow3+2440,100 ,aBolText[1]+" "+AllTrim(Transform(((aDadosTit[5]*(2/30))/100),"@E 99,999.99"))+" AO DIA",oFont10)
	oPrn:Say  (nRow3+2490,100 ,aBolText[2],oFont10)

	oPrn:Say  (nRow3+2340,1810,"(-)Desconto/Abatimento",oFont8)
	oPrn:Say  (nRow3+2410,1810,"(-)Outras Deducoes",oFont8)
	oPrn:Say  (nRow3+2480,1810,"(+)Mora/Multa",oFont8)
	oPrn:Say  (nRow3+2550,1810,"(+)Outros Acrescimos",oFont8)
	oPrn:Say  (nRow3+2620,1810,"(=)Valor Cobrado",oFont8)

	oPrn:Say  (nRow3+2640,100,"APOS VCTO ACESSE WWW.SANTANDER.COM.BR/BOLETOS PARA ATUALIZAR SEU BOLETO",oFont10)

	oPrn:Say  (nRow3+2690,100 ,"Sacado",oFont8)
	oPrn:Say  (nRow3+2700,400 ,aDatSacado[1]+" ("+aDatSacado[2]+")",oFont10)

	If aDatSacado[8] == "J"
		oPrn:Say  (nRow3+2700,1750,"CNPJ: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10)
	Else
		oPrn:Say  (nRow3+2700,1750,"CPF: "+TRANSFORM(aDatSacado[7],"@R 999.999.999-99"),oFont10)
	EndIf

	oPrn:Say  (nRow3+2753,400 ,aDatSacado[3],oFont10)
	oPrn:Say  (nRow3+2806,400 ,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10)
	oPrn:Say  (nRow3+2806,1750,cNroDoc,oFont10)

	oPrn:Say  (nRow3+2815,100 ,"Sacador/Avalista",oFont8)
	oPrn:Say  (nRow3+2855,1500,"Autenticacao Mecanica - Ficha de Compensacao",oFont8)

	oPrn:Line (nRol3+2000,1800,nRol3+2690,1800 )
	oPrn:Line (nRol3+2410,1800,nRol3+2410,2300 )
	oPrn:Line (nRol3+2480,1800,nRol3+2480,2300 )
	oPrn:Line (nRol3+2550,1800,nRol3+2550,2300 )
	oPrn:Line (nRol3+2620,1800,nRol3+2620,2300 )
	oPrn:Line (nRol3+2690,100 ,nRol3+2690,2300 )
	oPrn:Line (nRol3+2850,100 ,nRol3+2850,2300 )

	// Renderizacao do Codigo de Barras Intercalado 2 de 5
	oPrn:FwMsBar("INT25",67,1,aCB_RN_NN[1],oPrn,.F.,Nil,Nil,0.017,0.8,Nil,Nil,"A",.F.)

	oPrn:EndPage()
Return Nil
