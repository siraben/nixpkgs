## azurite: use JavaScript TypeScript compiler on 32-bit

### Description of changes

Azurite 3.37.0 builds with TypeScript 7's native compiler. Its npm package does
not provide a linux-ia32 binary, so the build fails with:

```
Unable to resolve @typescript/typescript-linux-ia32
```

On 32-bit build platforms, use the JavaScript TypeScript 6.0.3 compiler already
included in the upstream lockfile for tooling support. No dependency or hash
changes are needed. Keep the native compiler on 64-bit build platforms.

### Validation

- Baseline i686 build reproduced the missing compiler failure.
- Patched i686 build compiles successfully using `typescript/bin/tsc`.
- x86_64 build succeeds using the original `typescript-for-build/bin/tsc`.
- Both installed `azurite --version` commands print `3.37.0`.
- Full service integration and Xfce ISO validation are still pending.

```sh
nix-build . -A azurite --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A azurite --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
