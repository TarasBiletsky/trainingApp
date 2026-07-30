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
    $firstSet = $afterReplace.exercises[0].sets[0]
    Send "workouts/$($workout.id)/sets/$($firstSet.id)/complete" 'POST' @{ order=$firstSet.order; actualWeightKg=50; actualReps=8; isWarmup=$false; version=$firstSet.version; completedAt=[DateTimeOffset]::UtcNow.ToString('o') } | Out-Null
    $afterFirstSet = Send "workouts/$($workout.id)" 'GET'
    if ($afterFirstSet.status -ne 'InProgress') { throw 'Completing the first set did not start the workout.' }
    $secondSet = $afterFirstSet.exercises[0].sets[1]
    Send "workouts/$($workout.id)/sets/$($secondSet.id)/complete" 'POST' @{ order=$secondSet.order; actualWeightKg=50; actualReps=8; isWarmup=$false; version=$secondSet.version; completedAt=[DateTimeOffset]::UtcNow.ToString('o') } | Out-Null
    $afterLastSet = Send "workouts/$($workout.id)" 'GET'
    if ($afterLastSet.status -ne 'Completed') { throw 'Completing the last set did not finish the workout.' }
    $secondSet = $afterLastSet.exercises[0].sets[1]
    Send "workouts/$($workout.id)/sets/$($secondSet.id)/uncomplete" 'POST' @{ order=$secondSet.order; actualWeightKg=50; actualReps=8; isWarmup=$false; version=$secondSet.version } | Out-Null
    $afterUndo = Send "workouts/$($workout.id)" 'GET'
    if ($afterUndo.status -ne 'InProgress' -or $afterUndo.exercises[0].sets[1].status -ne 'Planned') { throw 'Undoing a set did not reopen the workout.' }
    Send "workouts/$($workout.id)/sets/$($setIds[-1])" 'DELETE' | Out-Null
    $afterDelete = Send "workouts/$($workout.id)" 'GET'
    if ($afterDelete.exercises[0].sets.Count -ne 1) { throw 'Set count did not decrease.' }
    Send "workouts/$($workout.id)/exercises/$($exercise.id)" 'DELETE' | Out-Null
    $afterExerciseDelete = Send "workouts/$($workout.id)" 'GET'
    if ($afterExerciseDelete.exercises.Count -ne 0) { throw 'Exercise was not deleted.' }
    Write-Output 'Workout editor verification passed: editing, automatic lifecycle, undo, and deletion succeeded.'
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
