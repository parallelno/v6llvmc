$c = Get-Content tests\features\75\mir_all.txt
$currentPass = "?"
$count = 0
for ($i = 0; $i -lt $c.Count; $i++) {
  if ($c[$i] -match "IR Dump After (.+) \*\*\*") { $currentPass = $matches[1] }
  if ($c[$i] -match "Machine code for function lxi_lo_used") {
    $count++
    if ($count -ge 108) {
      Write-Host "==== #$count pass='$currentPass' (line $i) ===="
      $endIdx = [Math]::Min($i + 22, $c.Count - 1)
      $c[$i..$endIdx]
    }
  }
}
