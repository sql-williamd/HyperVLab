
# TODO: set desktop-iamge
#       http://powershell.com/cs/blogs/tips/archive/2014/01/10/change-desktop-wallpaper.aspx

$setupFolder = $PSScriptRoot
$logFilePath = Join-Path $setupFolder log.txt

function Write-Log {
    param (
        [string]$Level,
        [string]$Message
    )

    $timestamp = [System.DateTime]::Now.TimeOfDay.ToString()

    # FATAL, ERROR, WARNING, INFO, DEBUG, TRACE
    if (!$Level) {
        $Level = "INFO"    
    }
    $formattedMessage = "$timestamp - $($Level.PadLeft(8)) - $Message"

    switch ($level) {
        "FATAL"   { Write-Host $formattedMessage -ForegroundColor White -BackgroundColor Red }
        "ERROR"   { Write-Host $formattedMessage -ForegroundColor White -BackgroundColor Red }
        "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "INFO"    { Write-Host $formattedMessage -ForegroundColor White }
        "DEBUG"   { Write-Host $formattedMessage -ForegroundColor Cyan }
        "TRACE"   { Write-Host $formattedMessage -ForegroundColor Gray }
        default   { Write-Host $formattedMessage -ForegroundColor White }
    }

    if ($logFilePath) {
        Add-content $logFilePath -value $formattedMessage
    }
}

function Convert-PSObjectToHashtable {
    param (
        [Parameter(  
             Position = 0,   
             Mandatory = $true,   
             ValueFromPipeline = $true,  
             ValueFromPipelineByPropertyName = $true  
         )]
        [object]$InputObject
    )

    if (-not $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $output = @(
            foreach ($item in $InputObject) {
                Convert-PSObjectToHashtable $item
            }
        )

        Write-Output -NoEnumerate $output
    }
    elseif ($InputObject -is [psobject]) {
        $output = @{}
        $InputObject | Get-Member -MemberType *Property | % { 
            $output.($_.name) = Convert-PSObjectToHashtable $InputObject.($_.name)
        } 
        $output
    }
    else {
        $InputObject
    }
}

function Get-AvailableDriveLetter {
    param(
       [parameter(Mandatory=$False)]
       [Switch]
       $ReturnFirstLetterOnly
   )
 
   $volumeList = Get-Volume
   # Get all available drive letters, and store in a temporary variable.
   $usedDriveLetters = @(Get-Volume | % { "$([char]$_.DriveLetter)"}) + @(Get-WmiObject -Class Win32_MappedLogicalDisk| %{$([char]$_.DeviceID.Trim(':'))})
   $tempDriveLetters = @(Compare-Object -DifferenceObject $usedDriveLetters -ReferenceObject $( 67..90 | % { "$([char]$_)" } ) | ? { $_.SideIndicator -eq '<=' } | % { $_.InputObject })
 
   # For completeness, sort the output alphabetically
   $availableDriveLetter = ($tempDriveLetters | Sort-Object)
   if ($ReturnFirstLetterOnly -eq $true)
   {
      $tempDriveLetters[0]
   }
   else
   {
      $tempDriveLetters
   }
}

try {
    Write-Log "INFO" "Starting setup-complete script in '$setupFolder'"
    Write-Log "INFO" "Running as '$($env:USERNAME)'"

    #######################################
    # Initialize PowerShell environment
    #######################################
    Write-Log "INFO" "Setting execution policy"
    Set-ExecutionPolicy Unrestricted -Force
    Write-Log "INFO" "Finished setting execution policy"

    #######################################
    # Enable PS-Remoting
    #######################################
    Write-Log "INFO" "Enabling PowerShell remoting"
    Enable-PSRemoting -Force -Confirm:$false
    Set-Item WSMan:\localhost\Client\TrustedHosts * -Force
    Restart-Service winrm
    Write-Log "INFO" "Finished enabling PowerShell remoting"

    #######################################
    # Enable CredSSP
    #######################################
    Write-Log "INFO" "Enabling CredSSP authentication"
    Enable-WSManCredSSP -Role Server -Force | Out-Null
    Enable-WSManCredSSP -Role Client -DelegateComputer * -Force | Out-Null
    Write-Log "INFO" "Finished enabling CredSSP authentication"

    #######################################
    # Load configuration
    #######################################
    Write-Log "INFO" "Loading configuration"
    $configuration = Get-content -Path "$setupFolder\configuration.json" | ConvertFrom-Json
    #$configuration.NetworkAdapters = $configuration.NetworkAdapters.value
    Write-Log "INFO" "Finished loading configuration"

    #######################################
    # Extra disk
    #######################################
    Write-Log "INFO" "Checking offline disk(s)"
	$offlineDisks = Get-Disk | Where { $_.OperationalStatus -eq "Offline" }
	if ($offlineDisks) {
	    Write-Log "INFO" "Processing $($offlineDisks.Length) disks"
		foreach ($offlineDisk in $offlineDisks) {
			Write-Log "INFO" "Bringing disk '$($offlineDisk.Model)' ($($offlineDisk.Size)) online"
			Set-Disk -Number $offlineDisk.Number -IsOffline $false
			Write-Log "INFO" "Disk is online"

			if (!(Get-Partition -DiskNumber $offlineDisk.Number -ErrorAction SilentlyContinue)) {
				Write-Log "INFO" "Creating partition"
                $driveLetter = Get-AvailableDriveLetter -ReturnFirstLetterOnly
				$offlineDisk | Initialize-Disk -PartitionStyle GPT
				$offlineDisk | New-Partition -UseMaximumSize -DriveLetter $driveLetter
				$offlineDisk | Get-Partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel Data -Confirm:$false
				Write-Log "INFO" "Partition created ($($driveLetter):)"
			}
 		}
	}
	else {
		Write-Log "INFO" "No offline disk(s)"
	}
    
    #######################################
    # Shares
    #######################################
    Write-Log "INFO" "Creating profile-script for share(s)"
	if ($Configuration.Host -and $Configuration.Host.Shares) {
	    Write-Log "INFO" "Processing $(@($Configuration.Host.Shares).Length) shares"
		foreach ($share in $Configuration.Host.Shares) {
            $sharePath = "\\$($Configuration.Host.Name)\$($share.Name)"
            Write-Log "INFO" "Adding share '$($share.Name)' at '$sharePath'"
            $userName = "$($Configuration.Host.Name)\$($share.UserName)"
            $securePassword = ConvertTo-SecureString -String $($share.Password) -AsPlainText -Force            $credential = New-Object -TypeName PSCredential -ArgumentList $userName,$securePassword            New-PSDrive -PSProvider FileSystem -Name $($share.DriveLetter) -Root $sharePath -Persist -Credential $credential -Scope Global | Out-Null
$profileScript += @"                if (-not (Get-PSDrive -PSProvider FileSystem |? { `$_.Name -eq '$($share.DriveLetter)' })) {
    `$userName = "$($Configuration.Host.Name)\$($share.UserName)"
    `$securePassword = ConvertTo-SecureString -String $($share.Password) -AsPlainText -Force    `$credential = New-Object -TypeName PSCredential -ArgumentList `$userName,`$securePassword    New-PSDrive -PSProvider FileSystem -Name '$($share.DriveLetter)' -Root '$sharePath' -Persist -Credential `$credential -Scope Global | Out-Null
}
"@
            Write-Log "INFO" "Share '$($share.Name)' added"
 		}
        $profileScriptPath = "$pshome\profile.ps1"
        $profileScript | Out-File $profileScriptPath
        Write-Log "INFO" "Finished creating profile-script"
        Set-PSSessionConfiguration -Name 'microsoft.powershell' -StartupScript $profileScriptPath
        Write-Log "INFO" "Finished registering profile-script"
        Get-PSDrive | Select * | Out-File 'C:\Setup\drives.txt'
	}
	else {
		Write-Log "INFO" "No shares"
	}

    #######################################
    # Update LocalConfigurationManager
    #######################################
    Write-Log "INFO" "Updating LocalConfigurationManager configuration"
    configuration VMMetaConfig {
        node localhost {
            LocalConfigurationManager {
                RebootNodeIfNeeded = $true
            }
        }
    }

    VMMetaConfig -OutputPath $setupFolder\VMMetaConfig | Out-Null
    Set-DscLocalConfigurationManager -Path $setupFolder\VMMetaConfig -Verbose -ComputerName localhost
    Write-Log "INFO" "Finished updating LocalConfigurationManager configuration"

    #######################################
    # Configure PowerShellGet & Chocolatey
    #######################################
    # NOTE: registering a repository somehow fails when run after setup completes; it does work when running it manually afterwards
    if (Get-Command Register-PSRepository) {
        Write-Log "INFO" "Registering the package-source"
        $repositoryName = 'HyperVLab'
        $repositoryPath = Join-Path $setupFolder 'Repository'
        if (-not (Test-Path $repositoryPath -PathType Container)) {
            New-Item -Path $repositoryPath -Force -Confirm:$false
        }
        $repository = Get-PackageSource |? { $_.Name -eq $repositoryName }
        if ($repository) {
            Unregister-PackageSource -Name $repositoryName
        }
        Register-PackageSource -Name $repositoryName -Location $repositoryPath -ProviderName PowerShellGet -Trusted
        Write-Log "INFO" "Finished registering the package-source"
        Get-PackageSource | Select * | Out-File 'C:\Setup\packagesources.txt'

        <#
        Write-Log "INFO" "Starting installation of modules"

        if (Test-Path "$setupFolder\Modules") {
            $repositoryName = 'LocalModules'
            # add local repository
            Write-Log "INFO" "Add local repository '$setupFolder\Modules'"
            Register-PSRepository -Name $repositoryName -SourceLocation "$setupFolder\Modules" -InstallationPolicy Trusted -Verbose
        }
        else {
            Write-Log "INFO" "No modules, skipping installation of packages"
            # TODO: if internet available, install packages from the PowerShell-gallery
        }
    
        if ($repositoryName) {
            Write-Log "INFO" "Installing modules"
            Install-Module xComputerManagement -Scope AllUsers -Repository $repositoryName -Force
            Install-Module xNetworking -Scope AllUsers -Repository $repositoryName -Force
        }

        Write-Log "INFO" "Finished installation of modules"
        #>
    }
    else {
        Write-Log "INFO" "PowerShellGet not available, skipping installation of modules"
    }#>

    # add chocolatey package-source
    # Register-PackageSource -Name chocolatey -Location http://chocolatey.org/api/v2 -Provider PowerShellGet -Trusted -Verbose

    #######################################
    # Apply configuration
    #######################################
    Write-Log "INFO" "Start applying configuration"
    Write-Log "INFO" "Preparing configuration for DSC"
    $configuration `
        | Add-Member -MemberType NoteProperty -Name NodeName -Value 'localhost' -PassThru `
        | Add-Member -MemberType NoteProperty -Name PSDscAllowPlainTextPassword -Value $true

    $configurationData = @{
        AllNodes = @(
            (Convert-PSObjectToHashtable $configuration)
        )
    }
    Write-Log "INFO" "Loading configuration"
    . "$setupFolder\LabEnvironment.ps1"
    Write-Log "INFO" "Generating configuration"
    LabConfiguration -ConfigurationData $configurationData -OutputPath "$setupFolder\LabEnvironment" | Out-Null
    Write-Log "INFO" "Starting configuration"
    Start-DscConfiguration –Path $setupFolder\LabEnvironment –Wait -Force –Verbose | Out-Null
    Write-Log "INFO" "Finished applying configuration"

    Write-Log "INFO" "Finished setup-complete script"
}
catch {
    Write-Log "ERROR" $_
}
