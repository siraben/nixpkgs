set -e
echo "downloading $out from $url"
$curl/bin/curl -4 --fail --location --max-redirs 20 "$url" > "$out"
