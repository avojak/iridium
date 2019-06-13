icon_sizes = ['16', '24', '32', '48', '64', '128']

# Install the icons
foreach i : icon_sizes
    install_data(
        join_paths('assets', 'icons', i + 'x' + i, meson.project_name() + '.internet-chat-new.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'actions')
    )
    install_data(
        join_paths('assets', 'icons', i + 'x' + i, meson.project_name() + '.internet-chat-new.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'actions')
    )
    install_data(
        join_paths('assets', 'icons', i + 'x' + i, meson.project_name() + '.network-server-new.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'actions')
    )
    install_data(
        join_paths('assets', 'icons', i + 'x' + i, meson.project_name() + '.network-server-new.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'actions')
    )
    install_data(
        join_paths('assets', 'icons', i + 'x' + i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
        rename: meson.project_name() + '.svg'
    )
    install_data(
        join_paths('assets', 'icons', i + 'x' + i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
        rename: meson.project_name() + '.svg'
    )
endforeach

# Install the settings schema
install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

# Translate and install our .desktop file so the Applications Menu will see it
i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

# Translate and install our .appdata.xml file so AppCenter will see it
i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)
