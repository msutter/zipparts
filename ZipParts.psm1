$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

# Load all functions
"$moduleRoot\Functions\*.ps1" |
Resolve-Path |
Where-Object -FilterScript {
    -not ($_.ProviderPath.Contains('.Tests.'))
} |
ForEach-Object -Process {
    . $_.ProviderPath
}

# Export Functions
Export-ModuleMember -Function *
