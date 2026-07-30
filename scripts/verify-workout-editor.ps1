$ErrorActionPreference = 'Stop'
$baseUrl = 'http://127.0.0.1:8181/api/v1'
$envValues = @{}
Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\.env') | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') { $envValues[$matches[1].Trim()] = $matches[2].Trim() }
}
$login = @{ userName = $envValues.TRAINING_ADMIN_USERNAME; password = $envValues.TRAINING_ADMIN_PASSWORD } | ConvertTo-Json
$tokens = Invoke-RestMethod "$baseUrl/auth/login" -Method Post -ContentType 'application/json' -Body $login
$headers = @{ Authorization = "Bearer $($tokens.accessToken)" }
$workout = $null

function Send([string] $Path, [string] $Method, $Body = $null) {
    $arguments = @{ Uri = "$baseUrl/$Path"; Method = $Method; Headers = $headers }
    if ($null -ne $Body) { $arguments.ContentType = 'application/json'; $arguments.Body = ($Body | ConvertTo-Json -Depth 8) }
    Invoke-RestMethod @arguments
}

try {
    $bootstrap = Send 'bootstrap' 'GET'
    $choices = @($bootstrap.exercises | Select-Object -First 2)
    if ($choices.Count -lt 2) { throw 'Two exercises are required for the editor smoke test.' }
    $workout = Send 'workouts/' 'POST' @{ name = 'Workout editor verification'; scheduledAt = [DateTimeOffset]::UtcNow.AddHours(1).ToString('o'); notes = 'automatic smoke test' }
    $exercise = Send "workouts/$($workout.id)/exercises" 'POST' @{ exerciseId = $choices[0].id; order = 1; notes = ''; restSeconds = 90; weightMultiplier = 1 }
    1..2 | ForEach-Object { Send "workouts/$($workout.id)/exercises/$($exercise.id)/sets" 'POST' @{ order = $_; plannedWeightKg = 50; plannedReps = 8; isWarmup = $false } | Out-Null }
    $before = Send "workouts/$($workout.id)" 'GET'
    $setIds = @($before.exercises[0].sets.id)
    Send "workouts/$($workout.id)/exercises/$($exercise.id)" 'PUT' @{ exerciseId = $choices[1].id; order = 1; notes = ''; restSeconds = 90; weightMultiplier = 1 } | Out-Null
    $afterReplace = Send "workouts/$($workout.id)" 'GET'
    if ($afterReplace.exercises[0].exerciseId -ne $choices[1].id) { throw 'Exercise replacement was not persisted.' }
    if (Compare-Object $setIds @($afterReplace.exercises[0].sets.id)) { throw 'Exercise replacement changed the existing sets.' }
    Send "workouts/$($workout.id)/sets/$($setIds[-1])" 'DELETE' | Out-Null
    $afterDelete = Send "workouts/$($workout.id)" 'GET'
    if ($afterDelete.exercises[0].sets.Count -ne 1) { throw 'Set count did not decrease.' }
    Write-Output 'Workout editor verification passed: replacement preserved sets and set count changed.'
}
finally {
    if ($null -ne $workout) {
        $sql = "DELETE FROM training.`"Workouts`" WHERE `"Id`" = '$($workout.id)' AND `"OwnerId`" = '$($tokens.user.id)' AND `"Name`" = 'Workout editor verification';"
        $start = [Diagnostics.ProcessStartInfo]::new('docker', 'exec -i trainingapp-db-1 psql -U training -d training')
        $start.RedirectStandardInput = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true; $start.UseShellExecute = $false
        $process = [Diagnostics.Process]::Start($start)
        $process.StandardInput.WriteLine($sql); $process.StandardInput.Close()
        $null = $process.StandardOutput.ReadToEnd(); $errorOutput = $process.StandardError.ReadToEnd(); $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw $errorOutput }
    }
}
