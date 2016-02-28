#Requires -Version 4.0
<#
.SYNOPSIS
    Creates a bootable, sysprepped VHDX from a Windows installation medium (iso).

.DESCRIPTION
    Creates a bootable, sysprepped VHDX from a Windows installation medium.
    If a specific edition is requested, it is this edition that will be extracted from the iso.
    If a core/gui and standard/datacenter is requested, the corresponding edition is used from the following list:
    - Windows Server 2012 R2 SERVERSTANDARDCORE
    - Windows Server 2012 R2 SERVERSTANDARD
    - Windows Server 2012 R2 SERVERDATACENTERCORE
    - Windows Server 2012 R2 SERVERDATACENTER
    - Windows Server 2016 Technical Preview 4 SERVERSTANDARDCORE
    - Windows Server 2016 Technical Preview 4 SERVERSTANDARD
    - Windows Server 2016 Technical Preview 4 SERVERDATACENTERCORE
    - Windows Server 2016 Technical Preview 4 SERVERDATACENTER

.NOTES
    Copyright (c) 2016 Jeroen Swart. All rights reserved.
#>

function New-LabOSImage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'Edition')]
        [string]$Edition,

        [Parameter(Mandatory = $true, ParameterSetName = 'TypeCoreStandard')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TypeCoreDataCenter')]
        [switch]$Core,
        [Parameter(Mandatory = $true, ParameterSetName = 'TypeGuiStandard')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TypeGuiDataCenter')]
        [switch]$Gui,

        [Parameter(Mandatory = $true, ParameterSetName = 'TypeCoreStandard')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TypeGuiStandard')]
        [switch]$Standard,
        [Parameter(Mandatory = $true, ParameterSetName = 'TypeCoreDataCenter')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TypeGuiDataCenter')]
        [switch]$DataCenter,

        [Parameter()]
        [ValidateRange(10GB, 64TB)]
        [UInt64]$DiskSizeBytes = 32GB,

        [Parameter(Mandatory = $true)]
        [string]$ImagePath,
        [switch]$Force,
        [switch]$WhatIf
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw 'The provided path to the installation medium does not exist.'
    }

    if ((Test-Path -Path $ImagePath -PathType Leaf) -and -not $Force.IsPresent) {
        Write-Host 'image already exists; if you want to recreate the image, use -Force' -ForegroundColor Yellow
        return
    }
        
    if (-not $Edition) {
        Write-Verbose 'Edition not provided; determining edition from parameters.'
        if (-not $Core -and -not $Gui) {
            Write-Verbose 'Core or Gui not provided; using default.'
            $Core = $true
        }
        if (-not $Standard -and -not $DataCenter) {
            Write-Verbose 'Standard or DataCenter not provided; using default.'
            $Standard = $true
        }
        Write-Verbose "Selected '$(if ($Core) { 'Core' } else { 'Gui' })' edition."
        Write-Verbose "Selected '$(if ($Standard) { 'Standard' } else { 'DataCenter' })' edition."

        $fileName = Split-Path -Path $Path -Leaf
        if ($fileName-match 'en_windows_server_2012_r2') {
            Write-Verbose "Recognized iso-file as 'Windows Server 2012 R2'"
            $Edition = 'Windows Server 2012 R2'
        }
        elseif ($fileName-match 'windows_server_2016_technical_preview_4') {
            Write-Verbose "Recognized iso-file as 'Windows Server 2016 Technical Preview 4'"
            $Edition = 'Windows Server 2016 Technical Preview 4'
        }
        else {
            throw "Unable to determine Windows version from filename '$fileName'."
        }

        if ($Core -and $Standard) {
            $Edition += ' SERVERSTANDARDCORE'
        }
        elseif ($Core -and $DataCenter) {
            $Edition += ' SERVERDATACENTERCORE'
        }
        elseif ($Gui -and $Standard) {
            $Edition += ' SERVERSTANDARD'
        }
        elseif ($Gui -and $DataCenter) {
            $Edition += ' SERVERDATACENTER'
        }
    }
    Write-Verbose "Edition '$Edition' selected."

    if (Test-Path -Path $ImagePath -PathType Leaf) {
        Write-Verbose "Removing existing image at '$ImagePath'."
        if (-not $WhatIf.IsPresent) {
            Remove-Item -Path $ImagePath -Force -Confirm:$false
        }
    }
    $imageFolder = Split-Path -Path $ImagePath
    if (-not (Test-Path -Path $imageFolder -PathType Container)) {
        Write-Verbose "Creating image-location at '$imageFolder'."
        if (-not $WhatIf.IsPresent) {
            New-Item -Path (Split-Path -Path $ImagePath) -ItemType Directory -ErrorAction Stop | Out-Null
        }
    }

    Write-Host 'Creating image.'
    if (-not $WhatIf.IsPresent) {
        Convert-WindowsImage `
        -SourcePath $Path `
        -Edition $Edition `
        -VHDPath $ImagePath `
        -VHDFormat VHDX `
        -VHDPartitionStyle GPT `
        -SizeBytes $DiskSizeBytes
    }

    Write-Host 'Done.'
}
