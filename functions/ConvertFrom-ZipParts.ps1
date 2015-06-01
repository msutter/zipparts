function ConvertFrom-ZipParts
{
  <#
  .Synopsis
  Unzip part zips to folder
  .Description
  Unzip part zips to folder
  .Parameter ZipPath
  The Input Directory of the zip file(s)
  .Parameter OutputPath
  The Output Directory to unzip to
  #>

  Param(
    [Parameter(Mandatory=$True)]
    [string]$ZipPath,

    [Parameter(Mandatory=$False)]
    [string]$OutputPath = (Get-Location)
  )

  $ErrorActionPreference = "Stop"

  Write-Verbose "PWD: ${PWD}"

  if ([System.IO.Path]::IsPathRooted($ZipPath)) {
    $AbsZipPath = $ZipPath
  } else {
    $AbsZipPath = (Join-Path $PWD $ZipPath) -replace '\\\.\\', '\'
  }

  if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $AbsOutputPath = $OutputPath
  } else {
    $AbsOutputPath = (Join-Path $PWD $OutputPath) -replace '\\\.\\', '\'
  }

  $FunctionsPath    = $PSScriptRoot
  Write-Verbose "FunctionsPath: ${FunctionsPath}"

  $PsModulePath     = Split-Path  -Parent $FunctionsPath
  Write-Verbose "PsModulePath: ${PsModulePath}"

  $DotNetZipDllPath = Join-Path $PsModulePath "assemblies\DotNetZip.1.9.3\lib\net20\Ionic.Zip.dll"
  Write-Verbose "DotNetZipDllPath: ${DotNetZipDllPath}"

  Write-Verbose "load dll at ${DotNetZipDllPath}"

  if(!(Test-Path -Path $AbsOutputPath)){
    New-Item -ItemType directory -Path $AbsOutputPath | Out-Null
    Write-Verbose "Output Directory '${AbsOutputPath}' created."
  }

  Write-Verbose "AbsZipPath: ${AbsZipPath}"
  Write-Verbose "AbsOutputPath: ${AbsOutputPath}"


  # Proceed the zipping
  [System.Reflection.Assembly]::UnsafeLoadFrom($DotNetZipDllPath) | Write-Verbose
  $zipfile = [Ionic.Zip.ZipFile]::Read($AbsZipPath)
  $zipfile | % { $_.Extract($AbsOutputPath) }
  $zipfile.Dispose()

}