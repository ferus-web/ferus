import urlly, os

let x = paramStr(1)
let y = parseURL(x)

echo "Scheme: " & y.scheme
echo "Username: " & y.username
echo "Password: " & y.password
echo "Hostname: " & y.hostname
echo "Port: " & y.port
echo "Authority: " & y.authority
echo "Paths: " & y.paths
echo "Search: " & y.search
echo "Fragment: " & y.fragment
