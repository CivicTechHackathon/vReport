﻿[T4Scaffolding.ControllerScaffolder("Controller with read/write action and views, using EF data access code", Description = "Adds an ASP.NET MVC controller with views and data access code", SupportsModelType = $true, SupportsDataContextType = $true, SupportsViewScaffolder = $true)][CmdletBinding()]
param(     
	[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string]$ControllerName,   
	[string]$ModelType,
	[string]$Project,
	[string]$CodeLanguage,
	[string]$DbContextType,
	[string]$Area,
	[string]$ViewScaffolder = "View",
	[alias("MasterPage")]$Layout,
	[alias("ContentPlaceholderIDs")][string[]]$SectionNames,
	[alias("PrimaryContentPlaceholderID")][string]$PrimarySectionName,
	[switch]$ReferenceScriptLibraries = $false,
	[switch]$Repository = $false,
	[switch]$NoChildItems = $false,
	[string[]]$TemplateFolders,
	[switch]$Force = $false,
	[string]$ForceMode
)

# Interpret the "Force" and "ForceMode" options
$overwriteController = $Force -and ((!$ForceMode) -or ($ForceMode -eq "ControllerOnly"))
$overwriteFilesExceptController = $Force -and ((!$ForceMode) -or ($ForceMode -eq "PreserveController"))
$Controller = $ControllerName
# If you haven't specified a model type, we'll guess from the controller name
if (!$ModelType) {
	if ($ControllerName.EndsWith("Controller", [StringComparison]::OrdinalIgnoreCase)) {
		# If you've given "PeopleController" as the full controller name, we're looking for a model called People or Person
		$ModelType = [System.Text.RegularExpressions.Regex]::Replace($ControllerName, "Controller$", "", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
		$foundModelType = Get-ProjectType $ModelType -Project $Project -ErrorAction SilentlyContinue
		if (!$foundModelType) {
			$ModelType = [string](Get-SingularizedWord $ModelType)
			$foundModelType = Get-ProjectType $ModelType -Project $Project -ErrorAction SilentlyContinue
		}
	} else {
		# If you've given "people" as the controller name, we're looking for a model called People or Person, and the controller will be PeopleController
		$ModelType = $ControllerName
		$foundModelType = Get-ProjectType $ModelType -Project $Project -ErrorAction SilentlyContinue
		if (!$foundModelType) {
			$ModelType = [string](Get-SingularizedWord $ModelType)
			$foundModelType = Get-ProjectType $ModelType -Project $Project -ErrorAction SilentlyContinue
		}
		if ($foundModelType) {
			$ControllerName = [string](Get-PluralizedWord $foundModelType.Name) + "Controller"
			
		}
	}
	if (!$foundModelType) { throw "Cannot find a model type corresponding to a controller called '$ControllerName'. Try supplying a -ModelType parameter value." }
} else {
	# If you have specified a model type
	$foundModelType = Get-ProjectType $ModelType -Project $Project
	if (!$foundModelType) { return }
	if (!$ControllerName.EndsWith("Controller", [StringComparison]::OrdinalIgnoreCase)) {
		$ControllerName = $ControllerName + "Controller"
	}
}

Write-Host "Scaffolding $ControllerName..."

if(!$DbContextType) { $DbContextType = [System.Text.RegularExpressions.Regex]::Replace((Get-Project $Project).Name, "[^a-zA-Z0-9]", "") + "Context" }
if (!$NoChildItems) {
	if ($Repository) {
		Scaffold Repository -ModelType $foundModelType.FullName -DbContextType $DbContextType -Area $Area -Project $Project -CodeLanguage $CodeLanguage -Force:$overwriteFilesExceptController
	} else {
		$dbContextScaffolderResult = Scaffold DbContext -ModelType $foundModelType.FullName -DbContextType $DbContextType -Area $Area -Project $Project -CodeLanguage $CodeLanguage
		$foundDbContextType = $dbContextScaffolderResult.DbContextType
		if (!$foundDbContextType) { return }
	}
}
if (!$foundDbContextType) { $foundDbContextType = Get-ProjectType $DbContextType -Project $Project }
if (!$foundDbContextType) { return }

$primaryKey = Get-PrimaryKey $foundModelType.FullName -Project $Project -ErrorIfNotFound
if (!$primaryKey) { return }

$outputPath = Join-Path Controllers $ControllerName
# We don't create areas here, so just ensure that if you specify one, it already exists
if ($Area) {
	$areaPath = Join-Path Areas $Area
	if (-not (Get-ProjectItem $areaPath -Project $Project)) {
		Write-Error "Cannot find area '$Area'. Make sure it exists already."
		return
	}
	$outputPath = Join-Path $areaPath $outputPath
}

# Prepare all the parameter values to pass to the template, then invoke the template with those values
$repositoryName = $foundModelType.Name + "Repository"
$defaultNamespace = (Get-Project $Project).Properties.Item("DefaultNamespace").Value
$modelTypeNamespace = [T4Scaffolding.Namespaces]::GetNamespace($foundModelType.FullName)
$controllerNamespace = [T4Scaffolding.Namespaces]::Normalize($defaultNamespace + "." + [System.IO.Path]::GetDirectoryName($outputPath).Replace([System.IO.Path]::DirectorySeparatorChar, "."))
$areaNamespace = if ($Area) { [T4Scaffolding.Namespaces]::Normalize($defaultNamespace + ".Areas.$Area") } else { $defaultNamespace }
$dbContextNamespace = $foundDbContextType.Namespace.FullName
$repositoriesNamespace = [T4Scaffolding.Namespaces]::Normalize($areaNamespace + ".Models")
$modelTypePluralized = Get-PluralizedWord $foundModelType.Name
$relatedEntities = [Array](Get-RelatedEntities $foundModelType.FullName -Project $project)

if (!$relatedEntities) { $relatedEntities = @() }

$templateName = "MVCController"
Add-ProjectItemViaTemplate $outputPath -Template $templateName -Model @{
	ControllerName = $ControllerName;
	ModelType = [MarshalByRefObject]$foundModelType; 
	PrimaryKey = [string]$primaryKey; 
	DefaultNamespace = $defaultNamespace; 
	AreaNamespace = $areaNamespace; 
	DbContextNamespace = $dbContextNamespace;
	RepositoriesNamespace = $repositoriesNamespace;
	ModelTypeNamespace = $modelTypeNamespace; 
	ControllerNamespace = $controllerNamespace; 
	DbContextType = [MarshalByRefObject]$foundDbContextType;
	Repository = $repositoryName; 
	ModelTypePluralized = [string]$modelTypePluralized; 
	RelatedEntities = $relatedEntities;
} -SuccessMessage "Added ASP .NET Mvc Controller {0}" -TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$overwriteController

# Api Controller
$finalPath = Join-Path Controllers Api
$finalPath = Join-Path $finalPath $ControllerName
# We don't create areas here, so just ensure that if you specify one, it already exists
if ($Area) {
	$areaPath = Join-Path Areas $Area
	if (-not (Get-ProjectItem $areaPath -Project $Project)) {
		Write-Error "Cannot find area '$Area'. Make sure it exists already."
		return
	}
	$finalPath = Join-Path $areaPath $finalPath
}

#$finalPath = [string](Get-PluralizedWord $foundModelType.Name) + "ApiController"
Add-ProjectItemViaTemplate $finalPath -Template "Controller" -Model @{ 
		Namespace = $defaultNamespace;  
		ApiControllerName = $controllerNamespace;
		ModelType = $ModelType; 
		ModelTypePluralized = [string]$modelTypePluralized; 
		DbContextType = $DbContextType;
		ViewDataType = [MarshalByRefObject]$foundModelType;
		RelatedEntities = $relatedEntities;
		PluralController = [string](Get-PluralizedWord $foundModelType.Name);
	} -SuccessMessage "Added WEB API controller at {0}" `
	-TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force



# Ensure we have a controller name, plus a model type if specified
if ($ModelType) {
	$foundModelType = Get-ProjectType $ModelType -Project $Project
	if (!$foundModelType) { return }
	$primaryKeyName = [string](Get-PrimaryKey $foundModelType.FullName -Project $Project)
}

# Decide where to put the output
$PluralController = [string](Get-PluralizedWord $Controller)
$outputFolderName = Join-Path Views $PluralController
if ($Area) {
	# We don't create areas here, so just ensure that if you specify one, it already exists
	$areaPath = Join-Path Areas $Area
	if (-not (Get-ProjectItem $areaPath -Project $Project)) {
		Write-Error "Cannot find area '$Area'. Make sure it exists already."
		return
	}
	$outputFolderName = Join-Path $areaPath $outputFolderName
}


if ($foundModelType) { $relatedEntities = [Array](Get-RelatedEntities $foundModelType.FullName -Project $project) }
if (!$relatedEntities) { $relatedEntities = @() }

# _CreateOrEdit Template
$ViewName = "_CreateOrEdit"
$outputPath = Join-Path $outputFolderName $ViewName

Add-ProjectItemViaTemplate $outputPath -Template "_CreateOrEdit" -Model @{
	IsContentPage = [bool]$Layout;
	Layout = $Layout;
	SectionNames = $SectionNames;
	PrimarySectionName = $PrimarySectionName;
	ReferenceScriptLibraries = $ReferenceScriptLibraries.ToBool();
	ViewName = $ViewName;
	PrimaryKeyName = $primaryKeyName;
	ViewDataType = [MarshalByRefObject]$foundModelType;
	ViewDataTypeName = $foundModelType.Name;
	RelatedEntities = $relatedEntities;
} -SuccessMessage "Added $ViewName view at '{0}'" -TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force

# Create Template
$ViewName = "Create"
$outputPath = Join-Path $outputFolderName $ViewName

Add-ProjectItemViaTemplate $outputPath -Template "Create" -Model @{
	IsContentPage = [bool]$Layout;
	Layout = $Layout;
	SectionNames = $SectionNames;
	PrimarySectionName = $PrimarySectionName;
	ReferenceScriptLibraries = $ReferenceScriptLibraries.ToBool();
	ViewName = $ViewName;
	PrimaryKeyName = $primaryKeyName;
	ViewDataType = [MarshalByRefObject]$foundModelType;
	ViewDataTypeName = $foundModelType.Name;
	RelatedEntities = $relatedEntities;
	Area = $Area;
} -SuccessMessage "Added $ViewName view at '{0}'" -TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force

# Edit Template
$ViewName = "Edit"
$outputPath = Join-Path $outputFolderName $ViewName

Add-ProjectItemViaTemplate $outputPath -Template "Edit" -Model @{
	IsContentPage = [bool]$Layout;
	Layout = $Layout;
	SectionNames = $SectionNames;
	PrimarySectionName = $PrimarySectionName;
	ReferenceScriptLibraries = $ReferenceScriptLibraries.ToBool();
	ViewName = $ViewName;
	PrimaryKeyName = $primaryKeyName;
	ViewDataType = [MarshalByRefObject]$foundModelType;
	ViewDataTypeName = $foundModelType.Name;
	RelatedEntities = $relatedEntities;
	Area = $Area;
} -SuccessMessage "Added $ViewName view at '{0}'" -TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force


# Index Template
$ViewName = "Index"
$outputPath = Join-Path $outputFolderName $ViewName

Add-ProjectItemViaTemplate $outputPath -Template "Index" -Model @{
	IsContentPage = [bool]$Layout;
	Layout = $Layout;
	SectionNames = $SectionNames;
	PrimarySectionName = $PrimarySectionName;
	ReferenceScriptLibraries = $ReferenceScriptLibraries.ToBool();
	ViewName = $ViewName;
	PrimaryKeyName = $primaryKeyName;
	PluralViewDataType = $modelTypePluralized;
	ViewDataType = [MarshalByRefObject]$foundModelType;
	ViewDataTypeName = $foundModelType.Name;
	RelatedEntities = $relatedEntities;
	Area = $Area;
} -SuccessMessage "Added $ViewName view at '{0}'" -TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force

# Detail Template

$ViewName = "Details"
$outputPath = Join-Path $outputFolderName $ViewName

Add-ProjectItemViaTemplate $outputPath -Template "Details" -Model @{
	IsContentPage = [bool]$Layout;
	Layout = $Layout;
	SectionNames = $SectionNames;
	PrimarySectionName = $PrimarySectionName;
	ReferenceScriptLibraries = $ReferenceScriptLibraries.ToBool();
	ViewName = $ViewName;
	PrimaryKeyName = $primaryKeyName;
	PluralViewDataType = $modelTypePluralized;
	ViewDataType = [MarshalByRefObject]$foundModelType;
	ViewDataTypeName = $foundModelType.Name;
	ChildViewDataType =	[MarshalByRefObject]$foundChildModelType;
	ChildViewDataTypeName = $foundChildModelType;
	RelatedEntities = $relatedEntities;
	Area = $Area;
} -SuccessMessage "Added $ViewName view at '{0}'" -TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force

# AngularController Template
$viewName = $Controller + "Controller"
$finalPath = "Scripts\app\" + $Area + "\" + $Controller + "Controller"
Add-ProjectItemViaTemplate $finalPath -Template "AngularJsController" -Model @{
	IsContentPage = [bool]$Layout;
	Layout = $Layout;
	SectionNames = $SectionNames;
	PrimarySectionName = $PrimarySectionName;
	ReferenceScriptLibraries = $ReferenceScriptLibraries.ToBool();
	ViewName = $ViewName;
	PrimaryKeyName = [string]$primaryKey;
	ViewDataType = [MarshalByRefObject]$foundModelType;
	ViewDataTypeName = $foundModelType.Name;
	PluralViewDataType = $modelTypePluralized;
	RelatedEntities = $relatedEntities;
	ParentDataType = (Get-PluralizedWord $foundModelType.Name);
	IndexPath = "/" + $Area + "/" + (Get-PluralizedWord $foundModelType.Name);
} -SuccessMessage "Added AngularJs Controller at {0}" `
	-TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force

