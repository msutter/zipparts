function New-ZipPartsFromFile
{
  <#
  .Synopsis
  Generates a part zips of the given file
  .Description
  Generates a part zips of the given file
  .Parameter FilePath
  The Path of the File to be zipped (in multiple parts)
  .Parameter OutputPath
  The Output Directory of the generated zip file(s)
  .Parameter MaxOutputSegmentSize
  The maximum size of an output segment, when saving a split Zip file.
  .Example
  New-ZipPartsFromFile -FilePath .\Git-1.9.5-preview20141217.exe -Verbose -MaxOutputSegmentSize 5242880
  .Example
  $result = New-ZipPartsFromFile -FilePath .\Git-1.9.5-preview20141217.exe -Verbose -MaxOutputSegmentSize 5242880
  $result.ZipPartFilesCount
  4
  #>

  Param(
    [Parameter(Mandatory=$True)]
    [string]$FilePath,

    [Parameter(Mandatory=$False)]
    [string]$OutputPath = (Get-Item $FilePath).BaseName,

    [Parameter(Mandatory=$False)]
    [string]$ZipOutBaseName = (Get-Item $FilePath).BaseName,

    [Parameter(Mandatory=$False)]
    [string]$ZipExtractBasePath = '.\',

    [Parameter(Mandatory=$False)]
    [int]$MaxOutputSegmentSize = 524288000 #500M
  )

  $ErrorActionPreference = "Stop"

  Write-Verbose "PWD: ${PWD}"

  if ([System.IO.Path]::IsPathRooted($FilePath)) {
    $AbsFilePath = $FilePath
  } else {
    $AbsFilePath = (Join-Path $PWD $FilePath) -replace '\\\.\\', '\'
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

  Write-Verbose "AbsOutputPath: ${AbsOutputPath}"
  Write-Verbose "ZipOutBaseName: ${ZipOutBaseName}"
  Write-Verbose "AbsFilePath: ${AbsFilePath}"

  # Proceed the zipping
  [System.Reflection.Assembly]::UnsafeLoadFrom($DotNetZipDllPath) | Write-Verbose
  $zipfile = new-object Ionic.Zip.ZipFile
  $zipfile.UseZip64WhenSaving = [Ionic.Zip.Zip64Option]::Always
  $zipfile.MaxOutputSegmentSize = $MaxOutputSegmentSize
  $zipfile.AddFile($AbsFilePath, $ZipExtractBasePath ) | Write-Verbose
  $zipfile.Save("${AbsOutputPath}\${ZipOutBaseName}.zip") | Write-Verbose
  $zipfile.Dispose() | Out-Null

  # Get zip files objects
  Write-Verbose "Sort and count files in ${AbsOutputPath}"
  $ZipPartFiles = Get-ChildItem $AbsOutputPath | Sort-Object extension

  # Main zip file
  $MainZipPartFile = $ZipPartFiles | Where-Object { $_.Extension -eq '.zip' }

  # Sub zip file
  $SubZipPartFiles = $ZipPartFiles | Where-Object { $_.Extension -ne '.zip' }

  # Count
  $ZipPartFilesCount = $ZipPartFiles.count
  Write-Verbose "Generated ${ZipPartFilesCount} part zip files"

  # Zipped Filename
  $ZippedFile = (Get-Item $FilePath).name

  # Compute a result object
  $ZipResultProperties = @{
    'ZippedFile'           = $ZippedFile;
    'ZipExtractBasePath'   = $ZipExtractBasePath;
    'MainZipPartFile'      = $MainZipPartFile;
    'SubZipPartFiles'      = $SubZipPartFiles;
    'MaxOutputSegmentSize' = $MaxOutputSegmentSize;
    'ZipPartFilesCount'    = $ZipPartFilesCount;
    'ZipPartFiles'         = $ZipPartFiles;
    'AbsOutputPath'        = $AbsOutputPath;
  }

  $ZipResult = New-Object -TypeName PSObject -Prop $ZipResultProperties
  return $ZipResult

}