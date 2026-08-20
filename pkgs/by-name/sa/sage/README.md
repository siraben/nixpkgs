# Sage on NixOS

Sage is a pretty complex package that depends on many other complex packages and patches some of those. As a result, the Sage Nix package is also quite complex.

Don't feel discouraged from fixing, simplifying, or improving things, though. The individual files have comments explaining their purpose. The most important ones are `default.nix`, which links everything together; `sage-src.nix`, which adds patches; and `sagelib.nix`, which builds the actual Sage package.

## The Sage build is broken

First, you should find out which change to Nixpkgs is at fault (if you don't already know). You can use `git bisect` for that (see the man page).

If the build broke as a result of a package update, try these solutions in order:

- Search the [Sage GitHub repository](https://github.com/sagemath/sage) for keywords like "Upgrade <package>". Maybe somebody has already proposed a patch that fixes the issue. You can then add a `fetchpatch` to `sage-src.nix`.

- Check whether [Gentoo](https://github.com/cschwan/sage-on-gentoo/tree/master/sci-mathematics/sage), [Debian](https://salsa.debian.org/science-team/sagemath/tree/master/debian), or [Arch Linux](https://git.archlinux.org/svntogit/community.git/tree/trunk?h=packages/sagemath) has already solved the problem. You can then add a `fetchpatch` to `sage-src.nix`. If applicable, you should also propose the patch upstream.

- Fix the problem yourself. First, clone the SageMath source and then check out the Sage version you want to patch:

```
[user@localhost ~]$ git clone https://github.com/sagemath/sage.git
[user@localhost ~]$ cd sage
[user@localhost sage]$ git checkout 9.8 # substitute the relevant version here
```

Then make the needed changes and generate a patch with `git diff`:

```
[user@localhost ~]$ <make changes>
[user@localhost ~]$ git diff -u > /path/to/nixpkgs/pkgs/by-name/sa/sage/patches/name-of-patch.patch
```

Now just add the patch to `sage-src.nix` and test your changes. If they fix the problem, submit a PR upstream (refer to Sage's [Developer's Guide](http://doc.sagemath.org/html/en/developer/index.html) for further details).

- Pin the package version in `default.nix` and add a note that explains why that is necessary.

## I want to update Sage

You'll need to change the `version` field in `sage-src.nix`. Afterwards, just try to build and let Nix tell you which patches no longer apply (hopefully because they were adopted upstream). Remove those.

Hopefully the build will succeed now. If it doesn't and the problem is obvious, fix it as described in [The Sage build is broken](#the-sage-build-is-broken).
If the problem is not obvious, you can try to first update Sage to an intermediate version (remember that you can also set the `version` field to any Git revision of Sage) and locate the Sage commit that introduced the issue. You can even use `git bisect` for that (it will only be a bit tricky to keep track of which patches to apply). Hopefully, after that, the issue will be obvious.

## Well, that didn't help!

If you couldn't fix the problem, create a GitHub issue on the Nixpkgs repository and ping the Sage maintainers (as listed in the Sage package).
Describe what you did and why it didn't work. Afterwards, it would be great if you could help the next person by improving this documentation!
