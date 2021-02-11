<#
: IIS Security ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
: Verifica desvios de seguranca nos site/app com o utilitario appcmd.exe
:   - DirectoryBrowse
#>
Import-Module WebAdministration

# === LISTA DE DIRETORIOS E SUB-DIRETORIOS FISICOS ==================================
$WebSites=(Get-Website).Name    #Lista de sites. Ex: SiteAlpha
foreach ($WebSite_Name in $WebSites) {  #Lista de HomeDirectory. Ex: D:\WebSites\wwwAlpha
    $WebSite_Name_PhysicalPaths=(Get-WebSite -Name $WebSite_Name).PhysicalPath.Replace("%SystemDrive%",$env:SystemDrive)
    $WebSite_Name_PhysicalPathSubPath=$WebSite_Name_PhysicalPathSubPath+$WebSite_Name_PhysicalPaths_URL
    foreach ($WebSite_Name_PhysicalPath in $WebSite_Name_PhysicalPaths) {
        $WebSite_Name_PhysicalPathSubPath=$WebSite_Name_PhysicalPathSubPath+$WebSite_Name_PhysicalPath+"`n"
        foreach ($WebSite_Name_PhysicalSubPath in $WebSite_Name_PhysicalPath) {
            $WebSite_Name_PhysicalSubPaths=(Get-ChildItem -Path $WebSite_Name_PhysicalSubPath -Directory -Recurse).FullName
            $resultPhy=$resultPhy+$WebSite_Name+"`n"
            foreach ($line in $WebSite_Name_PhysicalSubPaths) {
                [string]$line = $line #(converte formato de variavel para aceitar o metodo Replace)
                $resultPhy=$resultPhy+$WebSite_Name+$line.Substring(($WebSite_Name_PhysicalSubPath).Length).Replace("\","/") +"`n"
            }
        }
    }
}

# === LISTA DE DIRETORIOS VIRTUAIS ==================================================
$WebSites=(Get-Website).Name    #Lista de sites. Ex: SiteAlpha
foreach ($WebSite_Name in $WebSites) {  #Lista de diretorios virtuais. Ex: /Vendas
    $WebSite_Name_VDirPath=(Get-WebVirtualDirectory -Site $WebSite_Name).Path
    foreach ($line in $WebSite_Name_VDirPath) {
        $WebSite_Name_App_URL = $WebSite_Name+$line
        $resultVir = $resultVir+$WebSite_Name_App_URL+"`n"
    }
}

# === LISTA DE APLICACOES ===========================================================
$WebSites=(Get-Website).Name    #Lista de sites. Ex: SiteAlpha
foreach ($WebSite_Name in $WebSites) {  #Lista de aplicacoes. Ex: /Relatorios
    $WebSite_Name_AppPath=(Get-WebApplication -Site $WebSite_Name).Path
    foreach ($line in $WebSite_Name_AppPath) {
        $WebSite_Name_App_URL = $WebSite_Name+$line
        $resultApp = $resultApp+$WebSite_Name_App_URL+"`n"
    }
}

$resultURL = $resultPhy+$resultVir+$resultApp           # Concatena todas as listas
$resultURL = $resultURL -Split "`n"                     # Cria um array da string, separado por CR/LF
$resultURL = $resultURL | Sort-Object -Unique           # Exclui URLs duplicadas
$resultURL = $resultURL | Where-Object {$_ -ne ""}      # Exclui linhas em branco
$resultURL
Write-Host "======================================================================"

# === VERIFICA STATUS DA PROPRIEDADE DIRECTORY_BROWSE ===============================
$qntTest = ($resultURL | Measure-Object -Line).Lines    # Quantidade de testes que serao feitos
foreach ($item in $resultURL) {

    $itemchar = """$item"""
    $resultCMD = cmd /c "C:\Windows\System32\inetsrv\appcmd.exe list config $itemchar -section:directoryBrowse"
    $resultCMDstatus = (([string]$resultCMD).Split('"'))[1]
    Write-Host "-" $item " ---> " $resultCMDstatus
    if ($resultCMDstatus -like "true") {
        $DirectoryBrowseEnabledURL = $DirectoryBrowseEnabledURL + $item + "`n"
    }
}

# === REPORT TEXTO ==================================================================
$DirectoryBrowseEnabledURL = $DirectoryBrowseEnabledURL -Split "`n"     # Cria um array da string, separado por CR/LF
$DirectoryBrowseEnabledURL = $DirectoryBrowseEnabledURL | Where-Object {$_ -ne ""}    # Exclui linhas em branco
$qntDirectoryBrowseEnabledURL = ($DirectoryBrowseEnabledURL | Measure-Object -Line).Lines
if ($qntDirectoryBrowseEnabledURL -ne 0) {
    Write-Host "--> $env:COMPUTERNAME - Foram testadas $qntTest URLs. A propriedade DirectoryBrowse esta HABILITADA em:"
    $DirectoryBrowseEnabledURL
} else {
    Write-Host "--- $env:COMPUTERNAME - Foram testadas $qntTest URLs. A propriedade DirectoryBrowse esta DESABILITADA em todas."

}
Write-Host "-------------------------------------------------------------------------------------------------------"
#EOF