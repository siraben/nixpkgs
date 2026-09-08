#include <gtk/gtk.h>

int main(int argc, char **argv) {
  if (argc != 3) {
    g_printerr("usage: %s PACKAGE HICOLOR_THEME\n", argv[0]);
    return 2;
  }

  g_autofree gchar *desktop_file = g_build_filename(
      argv[1], "share", "applications", "wootility.desktop", NULL);
  g_autoptr(GKeyFile) desktop = g_key_file_new();
  g_autoptr(GError) error = NULL;
  if (!g_key_file_load_from_file(desktop, desktop_file, G_KEY_FILE_NONE,
                                 &error)) {
    g_printerr("cannot load %s: %s\n", desktop_file, error->message);
    return 1;
  }

  g_autofree gchar *icon_name =
      g_key_file_get_string(desktop, "Desktop Entry", "Icon", &error);
  if (icon_name == NULL) {
    g_printerr("cannot read Icon from %s: %s\n", desktop_file, error->message);
    return 1;
  }

  g_autofree gchar *package_icons =
      g_build_filename(argv[1], "share", "icons", NULL);
  g_autofree gchar *hicolor_icons =
      g_build_filename(argv[2], "share", "icons", NULL);
  /* GtkIconTheme search roots correspond to $XDG_DATA_DIRS/icons. */
  const gchar *search_path[] = {package_icons, hicolor_icons};
  g_autoptr(GtkIconTheme) theme = gtk_icon_theme_new();
  gtk_icon_theme_set_search_path(theme, search_path, G_N_ELEMENTS(search_path));
  gtk_icon_theme_set_custom_theme(theme, "hicolor");

  g_autoptr(GtkIconInfo) icon = gtk_icon_theme_lookup_icon(
      theme, icon_name, 512, GTK_ICON_LOOKUP_FORCE_SIZE);
  if (icon == NULL) {
    g_printerr("cannot resolve icon %s from %s\n", icon_name, desktop_file);
    return 1;
  }

  g_autofree gchar *expected =
      g_strdup_printf("%s/%s.png", package_icons, icon_name);
  const gchar *actual = gtk_icon_info_get_filename(icon);
  if (g_strcmp0(actual, expected) != 0) {
    g_printerr("resolved %s to %s instead of %s\n", icon_name, actual,
               expected);
    return 1;
  }

  g_print("resolved %s to %s\n", icon_name, actual);
  return 0;
}
