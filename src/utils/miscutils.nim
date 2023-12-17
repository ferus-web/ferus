proc truncate*(s: string, limit: int): string =
  var x = ""
  for y in 0..s.len:
    if y < limit:
      x = x & s[y]
  
  x & "..."
