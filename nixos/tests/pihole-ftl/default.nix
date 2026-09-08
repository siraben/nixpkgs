{ runTest }:

{
  basic = runTest ./basic.nix;
  dnsmasq = runTest ./dnsmasq.nix;
  lists = runTest ./lists.nix;
}
