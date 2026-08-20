#  mpiCheckPhaseHook {#setup-hook-mpi-check}


This hook can be used to set up a check phase that
requires running an MPI application. It detects the
present MPI implementation type and exports
the necessary environment variables to use
`mpirun` and `mpiexec` in a Nix sandbox.


Example:

```nix
{ mpiCheckPhaseHook, mpi, ... }:
{
  # ...

  nativeCheckInputs = [
    openssh
    mpiCheckPhaseHook
  ];
}
```

