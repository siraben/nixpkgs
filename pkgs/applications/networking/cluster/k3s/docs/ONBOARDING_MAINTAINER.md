# Onboarding Maintainer

Anyone willing can become a maintainer; no prerequisite knowledge is required. Willingness to learn is enough.

A K3s maintainer maintains K3s's:

- [documentation](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/README.md)
- [issues](https://github.com/NixOS/nixpkgs/issues?q=is%3Aissue+is%3Aopen+k3s)
- [pull requests](https://github.com/NixOS/nixpkgs/pulls?q=is%3Aopen+is%3Apr+label%3A%226.topic%3A+k3s%22)
- [NixOS tests](https://github.com/NixOS/nixpkgs/tree/master/nixos/tests/rancher)
- [NixOS service module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/cluster/rancher)
- [update script](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/update-script.sh) (the process of updating)
- updates (the act of updating) and [r-ryantm bot logs](https://r.ryantm.com/log/k3s/)
- deprecations
- CVEs
- NixOS releases
- dependencies (runc, containerd, ipset)

Anything that is due, basically.

As a maintainer, feel free to improve anything and everything at your discretion, meaning at your pace and according to your capabilities and interests.

Only consensus is required to move any proposal forward. Consensus means the approval of others.

If you cause a regression (we've all been there), you are responsible for fixing it, but in case you can't fix it (it happens), feel free to ask for help. That's fine, just let us know.

To merge code, you need to be a committer, or use the merge-bot, but currently the merge-bot only works for packages located at `pkgs/by-name/`, which means, K3s still needs to be migrated there before you can use merge-bot for merging. As a non-committer, once you have approved a PR you need to forward the request to a committer. For deciding which committer, give preference initially to K3s committers, but any committer can commit. A committer usually has a green approval in PRs.

The current K3s committers are marcusramberg and Mic92.

@euank is often silent but still active and has always handled anything dreadful, internal parts of K3s/Kubernetes, or architectural issues. He initially packaged K3s for Nixpkgs; think of him as a last resort. When we fail to accomplish a fix, he comes to rescue us from ourselves.

@mic92 stepped up when @superherointj stepped down some time ago. As Mic92 has broad responsibilities in Nixpkgs (he is responsible for far too many things already: nixpkgs-review, sops-nix, release management, bot-whatever), we avoid giving him chore work for `nixos-unstable` and pick him as committer only as a last resort. As Mic92 runs K3s in a `nixos-stable` setting, he might help test stable backports.

When handling requests, follow the usual basics. When reviewing PRs and issues, be welcoming and helpful, provide hints whenever possible, try to move things forward, assume goodwill, ignore (do not react to) any negativity (since it spirals badly), and defer and resolve any severe disagreement in private. Even during disagreements, be thankful to people for their dedicated time, no matter what happens. In essence, when any unfortunate event occurs, **always put people over code**.

Dumbshit happens, and we make mistakes. CI, reviews, and fellow maintainers are there to nudge us in a better direction. There is no need to overthink interactions; if a problem occurs, we'll handle it.

We should optimize for maintainer satisfaction, because it is maintainers who make the service great. The best kind of win we have is when someone new steps up to become a maintainer. This increases our capacity for meaningful work and expands our knowledge pool.

Know that your participation matters most to us. We thank you for stepping up. It's good to have you here!

We welcome you and wish you the best in this new journey!

K3s Maintainers
