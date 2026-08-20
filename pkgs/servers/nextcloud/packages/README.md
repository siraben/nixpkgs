## Updating apps

To regenerate the Nixpkgs `nextcloudPackages` set, run:

```
./generate.sh
```

After that, you can commit and submit the changes in a pull request.

## Adding apps

**Before adding an app and making a pull request to Nixpkgs, please first update as described above in a separate commit.**

To extend the `nextcloudPackages` set, add a new line to the corresponding JSON
file with the ID of the app:

- `nextcloud-apps.json` for apps

The app must be available in the official
[Nextcloud app store](https://apps.nextcloud.com).
The ID corresponds to the last part of the app URL,
for example `breezedark` for the app with the URL
`https://apps.nextcloud.com/apps/breezedark`.

Then regenerate the Nixpkgs `nextcloudPackages` set by running:

```
./generate.sh
```

**Make sure that in this update, only the app added to `nextcloud-apps.json` gets updated.**

After that, you can commit and submit the changes in a pull request.

## Usage with the Nextcloud module

The apps will be available in the namespace `nextcloud31Packages.apps` (and for older versions of Nextcloud similarly).
Using them together with the Nextcloud module could look like this:

```
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "localhost";
    config.adminpassFile = "${pkgs.writeText "adminpass" "hunter2"}";
    extraApps = with pkgs.nextcloud31Packages.apps; {
      inherit mail calendar contacts;
    };
    extraAppsEnable = true;
  };
}
```

Adapt the version number in the Nextcloud package and nextcloudPackages set
according to the Nextcloud version you wish to use. There are several supported
stable Nextcloud versions available in the repository.
