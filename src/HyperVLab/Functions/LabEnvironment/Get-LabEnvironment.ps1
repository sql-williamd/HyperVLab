#Requires -Version 5.0

function Get-LabEnvironment {
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'EnvironmentName')]
        [string[]]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentPath')]
        [string[]]$Path
    )

    $filePaths = @()
    if ($($PSCmdlet.ParameterSetName) -eq 'EnvironmentName') {
        $environmentsFilePath = Join-Path -Path $script:configurationPath -ChildPath 'environments.json'
        if (Test-Path -Path $environmentsFilePath -PathType Leaf) {
            $environments = Get-Content -Path $environmentsFilePath -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
            foreach ($environmentName in $environments.Keys) {
                if (-not $Name -or $Name -contains $environmentName) {
                    $filePaths += $environments.$environmentName
                }                
            }
        }
    }
    else {
        foreach ($p in $Path) {
            $filePaths += $p
        }
    }

    foreach ($filePath in $filePaths) {
        $environmentFilePath = $filePath
        Write-Verbose "Processing path '$environmentFilePath'"

        if (Test-Path -Path $environmentFilePath -PathType Container) {
            Write-Verbose "path '$environmentFilePath' is folder, assuming filename is missing"
            $environmentFilePath = Join-Path -Path $environmentFilePath -ChildPath 'environment.json'
        }

        if (Test-Path -Path $environmentFilePath -PathType Leaf) {
            Write-Verbose "file '$environmentFilePath' found"
            $environmentContent = Get-Content -Path $environmentFilePath -Raw

            $tokensFilePath = [System.IO.Path]::GetFullPath((Join-Path -Path (Split-Path -Path $environmentFilePath -Parent) -ChildPath 'tokens.json'))
            if (Test-Path -Path $tokensFilePath -PathType Leaf) {
                $tokens = Get-Content -Path $tokensFilePath -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
                foreach ($key in $tokens.Keys) {
                    try {
                        $environmentContent = $environmentContent.Replace("{$key}", ($tokens.$key))
                    }
                    catch {
                        Write-Warning -Message "Error replacing token '$key'."
                    }
                }
            }

            $environment = Convert-FromJsonObject -InputObject ($environmentContent | ConvertFrom-Json) -TypeName 'LabEnvironment'
            if (-not $Name -or $Name -contains $environment.Name) {
                $environment.Path = $environmentFilePath

                Write-Output $environment
            }
        }
    }
}


