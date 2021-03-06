#
# Module manifest for module 'HyperVLabClient'
#

@{
 
# Author of this module
Author = 'Jeroen Swart'

# Script module or binary module file associated with this manifest.
RootModule = 'HyperVLabClient.psm1'

# Version number of this module.
ModuleVersion = '1.0.0.0'

# ID used to uniquely identify this module
GUID = '933289ca-e093-4d98-8f5c-7002dc9910f6'

# Company or vendor of this module
CompanyName = 'www.codeblack.nl'

# Copyright statement for this module
Copyright = '(c) Jeroen Swart 2016. All rights reserved.'

# Description of the functionality provided by this module
Description = 'CredentialManagement provides functions for managing credentials in Windows.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
#RequiredModules = @(@{ModuleName='PowerShellGet'; ModuleVersion='1.0.0.1'; Guid='1d73a601-4a6c-43c5-ba3f-619b18bbb404'})
#RequiredModules = 'PowerShellGet'

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
#TypesToProcess = @('ScriptAnalyzer.types.ps1xml')

# Format files (.ps1xml) to be loaded when importing this module
#FormatsToProcess = @('ScriptAnalyzer.format.ps1xml')

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = @(
    'Initialize-LabVM',
    'Install-LabVMTfsAgent',
    'Uninstall-LabVMTfsAgent'
)

# Cmdlets to export from this module
#CmdletsToExport = @('Get-LabVM','New-LabVM')
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
PrivateData = @{
    PSData = @{
#        ProjectUri = 'https://github.com/CodeblackNL/CredentialManagement'
#        LicenseUri = 'https://github.com/CodeblackNL/CredentialManagement/blob/master/LICENSE'
#        Tags = 'credential','credentials','Credential Manager'
#        IconUri = ''
#        ReleaseNotes = ''
#        ExternalModuleDependencies = @(@{ModuleName='PowerShellGet'; ModuleVersion='1.0.0.1'; Guid='1d73a601-4a6c-43c5-ba3f-619b18bbb404'})
#        ExternalModuleDependencies = 'PowerShellGet'
    }
}

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''
}
