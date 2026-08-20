= Adding plugin, theme or language =

To extend the `wordpressPackages` set, add a new line to the corresponding JSON
file with the codename of the package:

- `wordpress-languages.json` for language packs
- `wordpress-themes.json` for themes
- `wordpress-plugins.json` for plugins

The codename is the last part of the URL of the plugin or theme page, for
example `cookie-notice` in the URL
`https://wordpress.org/plugins/cookie-notice/` or `twentytwenty` in
`https://wordpress.org/themes/twentytwenty/`.

In case of language packages, the name consists of country and language codes.
For example, `de_DE` uses the language code `de` (German) and the country code `DE` (Germany).
For available translations and language codes, see the [upstream translation repository](https://translate.wordpress.org).

To regenerate the Nixpkgs `wordpressPackages` set, run:

```
./generate.sh
```

After that, you can commit and submit the changes.

= Usage with the WordPress module =

The plugins will be available in the namespace `wordpressPackages.plugins`.
Using them together with the WordPress module could look like this:

```nix
{
  services.wordpress = {
    sites."blog.${config.networking.domain}" = {
      plugins = with pkgs.wordpressPackages.plugins; [
        anti-spam-bee
        code-syntax-block
        cookie-notice
        lightbox-with-photoswipe
        wp-gdpr-compliance
      ];
    };
  };
}
```

The same scheme applies to `themes` and `languages`.
