# get notepad process
$notepad = Get-Process notepad -ErrorAction SilentlyContinue
if ($notepad) {
  # try gracefully first
  $notepad.CloseMainWindow()
  # kill after five seconds
  Sleep 5
  if (!$notepad.HasExited) {
    $notepad | Stop-Process -Force
  }
}
Remove-Variable notepad