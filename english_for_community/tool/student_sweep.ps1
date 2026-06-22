# Mechanical token sweep for student mobile scope (Phase 2).
$dirs = @(
  "lib/feature/home", "lib/feature/student", "lib/feature/listening",
  "lib/feature/listening_comp", "lib/feature/reading", "lib/feature/speaking",
  "lib/feature/writing", "lib/feature/vocabulary", "lib/feature/profile", "lib/feature/progress"
)
$radiusMap = @{
  '2'='AppRadius.xs'; '3'='AppRadius.xs'; '4'='AppRadius.xs'
  '6'='AppRadius.chip'; '7'='AppRadius.chip'
  '8'='AppRadius.input'; '9'='AppRadius.input'
  '10'='AppRadius.card'; '12'='AppRadius.card'
  '14'='AppRadius.sheet'; '16'='AppRadius.sheet'; '18'='AppRadius.sheet'
  '20'='AppRadius.lg'; '22'='AppRadius.lg'
  '999'='AppRadius.pill'
}
$durationMap = @{
  '90'='AppMotion.micro'; '120'='AppMotion.fast'; '180'='AppMotion.base'
  '200'='AppMotion.base'; '220'='AppMotion.page'; '300'='AppMotion.base'
  '350'='AppMotion.debounce'; '500'='AppMotion.enter'; '900'='AppMotion.pulse'
}
foreach ($d in $dirs) {
  Get-ChildItem -Path $d -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $orig = $c
    foreach ($k in $radiusMap.Keys) {
      $v = $radiusMap[$k]
      $c = $c -replace "BorderRadius\.circular\($k\)", "BorderRadius.circular($v)"
      $c = $c -replace "Radius\.circular\($k\)", "Radius.circular($v)"
    }
    foreach ($k in $durationMap.Keys) {
      $v = $durationMap[$k]
      $c = $c -replace "Duration\(milliseconds:\s*$k\)", $v
    }
    if ($c -ne $orig) {
      if ($c -notmatch "core/theme/app_spacing.dart" -and $c -match 'AppRadius\.') {
        $c = "import 'package:english_for_community/core/theme/app_spacing.dart';`n" + $c
      }
      if ($c -notmatch "core/theme/app_motion.dart" -and $c -match 'AppMotion\.(micro|fast|base|page|debounce|enter|pulse)') {
        $c = "import 'package:english_for_community/core/theme/app_motion.dart';`n" + $c
      }
      Set-Content $_.FullName -Value $c -NoNewline
      Write-Host "Updated $($_.FullName)"
    }
  }
}
