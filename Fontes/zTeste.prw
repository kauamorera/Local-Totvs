//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} zTeste
Função de Teste
@type user function
@author Atilio
@since 20/03/2025
@version 1.0
@example
u_zTeste()
/*/

User Function zTeste()
	Local aArea := FWGetArea()
	Local cNome := ""

	//Vamos mostrar um prompt pro usuário informar o nome
	cNome := FWInputBox("Digite um nome:")

	//Exibindo um resultado
	FWAlertInfo("Usuário digitou: " + cNome, "Mensagem")

	FWRestArea(aArea)
Return
