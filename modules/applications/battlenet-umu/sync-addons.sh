declared_addon_var="${1^^}_ADDONS"
declared_addon_dir_var="${1^^}_ADDON_DIR"

mkdir -p "$BNET_PREFIX/drive_c/${!declared_addon_dir_var}"

installed_addons=$(instawow -p "$1" list)

# Empty lists must produce no iterations.
mapfile -t to_add < <(comm -13 <(sort <<< "${installed_addons,,}" | grep .) <(sort <<< "${!declared_addon_var,,}" | grep .))
mapfile -t to_remove < <(comm -23 <(sort <<< "${installed_addons,,}" | grep .) <(sort <<< "${!declared_addon_var,,}" | grep .))

echo "Removing addons:"
for addon in "${to_remove[@]}"; do
  instawow -p "$1" remove "$addon"
done

echo "Installing addons:"
for addon in "${to_add[@]}"; do
  instawow -p "$1" install "$addon"
done
