# PowerShell script to pack and push a .NET Core class library to NuGet
# Prerequisites: .NET Core SDK

function Update-MinorVersion {
    param (
        [string]$csprojRelativePath
    )

    # Get the full csproj path
    $csprojPath = Join-Path -Path $PSScriptRoot -ChildPath $csprojRelativePath

    # Load the .csproj XML
    $csprojXml = [xml](Get-Content $csprojPath)

    # Get the version number
    $versionNode = $csprojXml.SelectSingleNode("/Project/PropertyGroup/Version")

    # Check if the version exists
    if ($versionNode -eq $null) {
        Write-Error "Version not found in $csprojPath"
        return
    }

    # Split the version number into its parts
    $versionParts = $versionNode.'#text'.Split('.')

    # Check if the version number is valid
    if ($versionParts.Length -ne 3) {
        Write-Error "Version $($versionNode.'#text') is not a valid version number"
        return
    }

    # Increment the minor version number
    $versionParts[2] = [int]$versionParts[2] + 1

    # Build the new version number
    $newVersion = $versionParts -join '.'

    # Update the version number in the .csproj XML
    $versionNode.'#text' = $newVersion

    # Save the .csproj XML with the original formatting
    $csprojXml.Save($csprojPath)

    Write-Output "Updated version number to $newVersion"
}

# Get the version number from the .csproj file
function Get-Version {
    param (
        [string]$csprojPath
    )

    # Load the .csproj XML
    $csprojXml = [xml](Get-Content $csprojPath)

    # Get the version number
    $version = $csprojXml.Project.PropertyGroup.Version

    # Check if the version exists
    if ($version -eq $null) {
        Write-Error "Version not found in $csprojPath"
        return
    }

    return $version
}

# Get the PackageId from the .csproj file
function Get-PackageId {
    param (
        [string]$csprojPath
    )

    # Load the .csproj XML
    $csprojXml = [xml](Get-Content $csprojPath)

    # Get the PackageId
    $packageId = $csprojXml.Project.PropertyGroup.PackageId

    # Check if the PackageId exists
    if ($packageId -eq $null) {
        Write-Error "PackageId not found in $csprojPath"
        return
    }

    return $packageId
}

# Get the NuGet API key from the environment variables
$nugetApiKey = [System.Environment]::GetEnvironmentVariable("NUGET_API_KEY", "User")

# Check if the NuGet API key exists
if ($nugetApiKey -eq $null -or $nugetApiKey -eq "") {
    Write-Error "The NuGet API key is not set in the environment variables (NUGET_API_KEY). Please set it and try again."
    exit 1
}

# Path to the project file (.csproj)
$projectFilePath = ".\heapzilla-common.csproj"

# Update the minor version number, incrementing it by 1
Update-MinorVersion $projectFilePath

# Get the updated version number from the .csproj file
$version = Get-Version $projectFilePath

# Get the PackageId from the .csproj file
$packageId = Get-PackageId $projectFilePath

# Pack the project into a NuGet package with the current date and time as the version number
dotnet pack $projectFilePath --configuration Release --output .\nuget

# The name of the .nupkg file
$nugetPackageFilePath = ".\nuget\$packageId.$version.nupkg"

# Push the NuGet package to NuGet
dotnet nuget push $nugetPackageFilePath --api-key $nugetApiKey --source https://api.nuget.org/v3/index.json
