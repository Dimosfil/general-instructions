param(
    [string]$SystemOutputPath = "tools/project-memory/system-preferences.json",
    [string]$GitOutputPath = "tools/project-memory/git-preferences.json",
    [string]$Selection = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$available = @("English", "Russian", "Spanish", "German", "French")
$languageAliases = @{
    "english" = "English"
    "en" = "English"
    "russian" = "Russian"
    "ru" = "Russian"
    "spanish" = "Spanish"
    "es" = "Spanish"
    "german" = "German"
    "de" = "German"
    "french" = "French"
    "fr" = "French"
}
$languageAliases[(-join ((0x0430,0x043D,0x0433,0x043B,0x0438,0x0439,0x0441,0x043A,0x0438,0x0439) | ForEach-Object { [char]$_ }))] = "English"
$languageAliases[(-join ((0x0440,0x0443,0x0441,0x0441,0x043A,0x0438,0x0439) | ForEach-Object { [char]$_ }))] = "Russian"
$languageAliases[(-join ((0x0438,0x0441,0x043F,0x0430,0x043D,0x0441,0x043A,0x0438,0x0439) | ForEach-Object { [char]$_ }))] = "Spanish"
$languageAliases[(-join ((0x043D,0x0435,0x043C,0x0435,0x0446,0x043A,0x0438,0x0439) | ForEach-Object { [char]$_ }))] = "German"
$languageAliases[(-join ((0x0444,0x0440,0x0430,0x043D,0x0446,0x0443,0x0437,0x0441,0x043A,0x0438,0x0439) | ForEach-Object { [char]$_ }))] = "French"

$defaultSelected = @("English")
if (Test-Path -LiteralPath $SystemOutputPath) {
    try {
        $existing = Get-Content -LiteralPath $SystemOutputPath -Raw | ConvertFrom-Json
        if ($existing.agent_response_language.languages) {
            $existingLanguages = @($existing.agent_response_language.languages | ForEach-Object { [string]$_ })
            $defaultSelected = @($existingLanguages | Where-Object { $available -contains $_ } | Select-Object -Unique)
        }
        elseif ($existing.agent_response_language.mode -eq "fixed" -and $existing.agent_response_language.language) {
            $existingLanguage = [string]$existing.agent_response_language.language
            if ($available -contains $existingLanguage) {
                $defaultSelected = @($existingLanguage)
            }
        }
        if ($defaultSelected.Count -eq 0) {
            $defaultSelected = @("English")
        }
    }
    catch {
        Write-Host "Could not read existing system preferences; using defaults."
    }
}

Write-Host "Select project languages in priority order for agent communication, agent-created tasks, plans, checklists, and commits."
Write-Host "Enter numbers or names in order, for example: 2 1"
Write-Host ""

for ($i = 0; $i -lt $available.Count; $i++) {
    $language = $available[$i]
    $checked = if ($defaultSelected -contains $language) { "[x]" } else { "[ ]" }
    Write-Host ("{0} {1}. {2}" -f $checked, ($i + 1), $language)
}

Write-Host ""
if ([string]::IsNullOrWhiteSpace($Selection)) {
    $inputText = Read-Host "Selection"
}
else {
    $inputText = $Selection
}

$selected = $defaultSelected
if (-not [string]::IsNullOrWhiteSpace($inputText)) {
    $normalizedInput = $inputText.ToLowerInvariant() -replace "[^\p{L}0-9]+", " "
    $selected = foreach ($part in ($normalizedInput -split "\s+")) {
        $trimmed = $part.Trim()
        if ($trimmed -match "^[0-9]+$") {
            $index = [int]$trimmed - 1
            if ($index -ge 0 -and $index -lt $available.Count) {
                $available[$index]
            }
        }
        elseif ($languageAliases.ContainsKey($trimmed)) {
            $languageAliases[$trimmed]
        }
    }
}

$selected = @($selected | Where-Object { $_ } | Select-Object -Unique)
if ($selected.Count -eq 0) {
    $selected = @("English")
}

$systemConfig = [ordered]@{
    agent_response_language = [ordered]@{
        mode = "fixed"
        language = $selected[0]
        languages = $selected
        available = $available
        applies_to = @(
            "progress_updates",
            "final_answers",
            "clarifying_questions",
            "user_facing_explanations",
            "agent_created_task_titles",
            "agent_created_task_descriptions",
            "task_manager_updates",
            "plans",
            "checklists"
        )
        exceptions = @(
            "existing_task_text",
            "code",
            "commands",
            "logs",
            "quoted_text",
            "user_requested_language"
        )
    }
}

$additional = @($selected | Select-Object -Skip 1)

$gitConfig = [ordered]@{
    commit_message_languages = [ordered]@{
        primary = $selected[0]
        additional = $additional
        available = $available
        format = "selected_order"
    }
}

foreach ($path in @($SystemOutputPath, $GitOutputPath)) {
    $directory = Split-Path -Parent $path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
}

$systemConfig | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $SystemOutputPath -Encoding UTF8
$gitConfig | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $GitOutputPath -Encoding UTF8

Write-Host ""
Write-Host "Saved project language preferences."
Write-Host ("Project language order: {0}" -f ($selected -join ", "))
Write-Host ("Git commit primary language: {0}" -f $selected[0])
if ($additional.Count -gt 0) {
    Write-Host ("Git commit additional languages: {0}" -f ($additional -join ", "))
}
else {
    Write-Host "Git commit additional languages: none"
}
