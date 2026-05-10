# `pkgsBootstrappedOpenjdk` — full-source Java bootstrap

Ports the Wolfi/Chainguard full-source Java bootstrap chain into
nixpkgs. The terminal target is a runnable
`pkgsBootstrappedOpenjdk.openjdk24`, produced solely from C/C++
source plus three pure-Java JARs, with no Temurin/Adoptium binary
tarball seed.

The chain stands beside the existing `openjdk{8,11,17,21,25}`
packages; it does not replace them.

## Stage chain

```
gcc6-with-gcj  →  fastjar  →  java-gcj-compat  →  openjdk7-icedtea
                                                         ↓
                                                  openjdk8-icedtea
                                                         ↓
                                                  openjdk9 → 10 → ... → 24
```

`gcc6-with-gcj` is the last GCC release that ships the gcj front-end
(removed in GCC 7); we use it to AOT-compile the Eclipse Compiler for
Java (ECJ) into a native `javac`, which drives IcedTea 2.x's OpenJDK 7
bootstrap. JDKs 9 and 10 are built interpreter-only because gcc-15
miscompiles their JIT; their launchers are wrapped to default to
`-Xint` so downstream stages see clean output.

## Trust contract

The chain admits **three pure-Java artifacts as source**. They contain
no native code — pure Java bytecode that runs on any JVM — so the
chain is "binary toolchain free" in the sense that matters for
reproducibility against a hostile compiler chain.

| Artifact | URL | Purpose |
|---|---|---|
| `ecj-4.9.jar` | `https://sourceware.org/pub/java/ecj-4.9.jar` | Eclipse Compiler for Java 4.9; AOT-compiled into `javac` by gcc-6's gcj. |
| `apache-ant-1.9.16-bin.tar.gz` | `https://dlcdn.apache.org/ant/binaries/apache-ant-1.9.16-bin.tar.gz` | Apache Ant 1.9.16; required by IcedTea 2.x's build system. |
| `rhino-1.7.7.2.jar` | `https://github.com/mozilla/rhino/releases/download/Rhino1_7_7_2_Release/rhino-1.7.7.2.jar` | Mozilla Rhino JS engine; required by IcedTea 2.x's `--with-rhino`. |

## Security caveat

Intermediate JDKs (`openjdk7-icedtea`, `openjdk8-icedtea`,
`openjdk{9..23}`) are **bootstrap artifacts only**. They lack security
backports and must not be shipped as runtime JDKs. Only
`pkgsBootstrappedOpenjdk.openjdk24` is intended for end-user use.

## Cost

- Build time: ~10–14 hours wall on a 16-core box, dominated by
  `openjdk7-icedtea` (~6–10 hours; gij interprets the IcedTea
  boot phase).
- Closure: ~5 GB of bootstrap-stage outputs to reach the final
  `openjdk24` artifact.

## References

- Chainguard blog: <https://www.chainguard.dev/unchained/fully-bootstrapping-java-from-source-in-wolfi>
- Bootstrappable.org Java page: <https://bootstrappable.org/projects/java.html>
- Wolfi recipes (pinned): <https://github.com/wolfi-dev/os/tree/725a9ef89febcd2abd3223750893582f11fe8169>
