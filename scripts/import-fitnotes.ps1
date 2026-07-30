param(
    [Parameter(Mandatory)] [string] $CsvPath,
    [switch] $Apply
)

$ErrorActionPreference = 'Stop'

function Stable-Guid([string] $Value) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Value)) }
    finally { $sha.Dispose() }
    $bytes = [byte[]]::new(16)
    [Array]::Copy($hash, $bytes, 16)
    return [Guid]::new($bytes)
}

function Sql-Text([AllowNull()] [string] $Value) {
    if ($null -eq $Value -or $Value.Length -eq 0) { return 'NULL' }
    return "'" + $Value.Replace("'", "''") + "'"
}

function Sql-Number([AllowNull()] [string] $Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return 'NULL' }
    return ([decimal]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture)).ToString([Globalization.CultureInfo]::InvariantCulture)
}

function Equipment-For([string] $Name) {
    if ($Name -match 'Cable|Pulldown|Pull Down|Push Down|Crossover|Zig Hail') { return 'Cable' }
    if ($Name -match 'Dumbbell') { return 'Dumbbell' }
    if ($Name -match 'Barbell|EZ-Bar|French Press|Deadlift|Squat') { return 'Barbell' }
    if ($Name -match 'Machine|Pec Deck|Pec Dec|Hack|Belt|Leg Press|Leg Extension|Leg Curl|Pullover|Abductor|Adductor|Hip Thrust|Rear Kick|Abdominal') { return 'Machine' }
    if ($Name -match 'Pull Up|Dips|Hyperextension|Roman Chair|Crunch') { return 'Bodyweight' }
    return 'Other'
}

$rows = Import-Csv -LiteralPath $CsvPath
$dates = @($rows.Date | Sort-Object -Unique)
$exerciseNames = @($rows.Exercise | Sort-Object -Unique)

[PSCustomObject]@{
    Rows = $rows.Count
    Workouts = $dates.Count
    Exercises = $exerciseNames.Count
    FirstDate = $dates[0]
    LastDate = $dates[-1]
    Mode = if ($Apply) { 'apply' } else { 'dry-run' }
} | Format-List

if (-not $Apply) { return }

$envValues = @{}
Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\.env') | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') { $envValues[$matches[1].Trim()] = $matches[2].Trim() }
}
$loginBody = @{
    userName = $envValues.TRAINING_ADMIN_USERNAME
    password = $envValues.TRAINING_ADMIN_PASSWORD
} | ConvertTo-Json
$token = Invoke-RestMethod -Uri 'http://127.0.0.1:8181/api/v1/auth/login' -Method Post -ContentType 'application/json' -Body $loginBody
$export = Invoke-RestMethod -Uri 'http://127.0.0.1:8181/api/v1/export' -Headers @{ Authorization = "Bearer $($token.accessToken)" }
$ownerId = [Guid]$export.profile.id

$knownExercises = @{}
foreach ($exercise in $export.exercises) { $knownExercises[$exercise.name.ToLowerInvariant()] = [Guid]$exercise.id }
$canonical = @{
    'Flat Barbell Bench Press' = 'Bench Press'
    'Barbell Squat' = 'Squat'
    'Zig Hail' = 'Cable Lateral Raise'
    'Reverse Pec Dec' = 'Reverse Pec Deck'
    'Canle Extension' = 'Cable Extension'
}

$sql = [Collections.Generic.List[string]]::new()
$sql.Add('\set ON_ERROR_STOP on')
$sql.Add('BEGIN;')

$exerciseIds = @{}
foreach ($sourceName in $exerciseNames) {
    $name = if ($canonical.ContainsKey($sourceName)) { $canonical[$sourceName] } else { $sourceName }
    $key = $name.ToLowerInvariant()
    $id = if ($knownExercises.ContainsKey($key)) { $knownExercises[$key] } else { Stable-Guid "fitnotes:exercise:$name" }
    $exerciseIds[$sourceName] = $id
    $category = ($rows | Where-Object Exercise -eq $sourceName | Select-Object -First 1).Category
    $sql.Add(('INSERT INTO training."Exercises" ("Id","Name","Description","MuscleGroup","Equipment","IsArchived","CreatedAt","UpdatedAt","OwnerId") VALUES ({0},{1},NULL,{2},{3},FALSE,NOW(),NOW(),{4}) ON CONFLICT ("Id") DO NOTHING;' -f (Sql-Text $id), (Sql-Text $name), (Sql-Text $category), (Sql-Text (Equipment-For $sourceName)), (Sql-Text $ownerId)))
}

foreach ($date in $dates) {
    $dayRows = @($rows | Where-Object Date -eq $date)
    $workoutId = Stable-Guid "fitnotes:workout:$($ownerId):$date"
    $timestamp = "$date`T12:00:00Z"
    $categories = @($dayRows.Category | Select-Object -Unique)
    $name = if ($categories.Count -gt 0) { $categories -join ' + ' } else { 'Workout' }
    $marker = "FitNotes import: $date"
    $sql.Add(('INSERT INTO training."Workouts" ("Id","Name","ScheduledAt","StartedAt","CompletedAt","Status","Notes","CreatedAt","UpdatedAt","Version","OwnerId") VALUES ({0},{1},{2},{2},{2},2,{3},{2},{2},1,{4}) ON CONFLICT ("Id") DO NOTHING;' -f (Sql-Text $workoutId), (Sql-Text $name), (Sql-Text $timestamp), (Sql-Text $marker), (Sql-Text $ownerId)))

    $order = 0
    foreach ($sourceName in @($dayRows.Exercise | Select-Object -Unique)) {
        $order++
        $workoutExerciseId = Stable-Guid "fitnotes:workout-exercise:$($ownerId):$date`:$sourceName"
        $exerciseId = $exerciseIds[$sourceName]
        $sql.Add(('INSERT INTO training."WorkoutExercises" ("Id","WorkoutId","ExerciseId","Order","Notes","RestSeconds","WeightMultiplier") VALUES ({0},{1},{2},{3},NULL,90,1) ON CONFLICT ("Id") DO NOTHING;' -f (Sql-Text $workoutExerciseId), (Sql-Text $workoutId), (Sql-Text $exerciseId), $order))

        $setOrder = 0
        foreach ($set in @($dayRows | Where-Object Exercise -eq $sourceName)) {
            $setOrder++
            $setId = Stable-Guid "fitnotes:set:$($ownerId):$date`:$sourceName`:$setOrder"
            $weight = Sql-Number $set.'Weight (kg)'
            $reps = if ([string]::IsNullOrWhiteSpace($set.Reps)) { 'NULL' } else { [int]$set.Reps }
            $notes = Sql-Text $set.Notes
            $sql.Add(('INSERT INTO training."SetEntries" ("Id","WorkoutExerciseId","Order","Status","PlannedWeightKg","PlannedReps","PlannedRpe","ActualWeightKg","ActualReps","ActualRpe","IsWarmup","CompletedAt","Notes","UpdatedAt","Version") VALUES ({0},{1},{2},1,NULL,NULL,NULL,{3},{4},NULL,FALSE,{5},{6},{5},1) ON CONFLICT ("Id") DO NOTHING;' -f (Sql-Text $setId), (Sql-Text $workoutExerciseId), $setOrder, $weight, $reps, (Sql-Text $timestamp), $notes))
        }
    }
}

$sql.Add('COMMIT;')
$start = [Diagnostics.ProcessStartInfo]::new('docker', 'exec -i trainingapp-db-1 psql -U training -d training')
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.UseShellExecute = $false
$process = [Diagnostics.Process]::Start($start)
foreach ($line in $sql) { $process.StandardInput.WriteLine($line) }
$process.StandardInput.Close()
$stdout = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw "FitNotes import failed: $stderr" }
Write-Output "FitNotes import committed: $($dates.Count) workouts, $($rows.Count) sets."
