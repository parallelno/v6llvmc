$c = Get-Content tests\features\75\mir_all.txt
$state = "?"
$currentPass = "?"
for ($i = 0; $i -lt $c.Count; $i++) {
  if ($c[$i] -match "IR Dump After (.+) \*\*\*") { $currentPass = $matches[1] }
  if ($c[$i] -match "Machine code for function lxi_lo_used") {
    $endIdx = [Math]::Min($i + 40, $c.Count - 1)
    $block = ($c[$i..$endIdx] -join "`n")
    $newState = "?"
    if ($block -match "(?ms)SHLD.*?\n\s+\`$a = MVIr -1\b") { $newState = "FOLDED" }
    elseif ($block -match "(?ms)SHLD.*?\n\s+\`$a = MOVrr \`$e") { $newState = "UNFOLDED" }
    if ($newState -ne $state) {
      Write-Host "Line $i pass='$currentPass' state=$newState"
      $state = $newState
    }
  }
}
