# Project name and programming language
project('com.github.avojak.iridium', 'vala', 'c')

# Include the translations module
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    join_paths('src', 'Application.vala'),
    join_paths('src', 'MainWindow.vala'),
    join_paths('src', 'Layouts', 'MainLayout.vala'),
    join_paths('src', 'Services', 'ServerConnection.vala'),
    join_paths('src', 'Services', 'ServerConnectionDetails.vala'),
    join_paths('src', 'Services', 'ServerConnectionHandler.vala'),
    join_paths('src', 'Views', 'ChatView.vala'),
    join_paths('src', 'Views', 'Welcome.vala'),
    join_paths('src', 'Widgets', 'ChannelJoinDialog.vala'),
    join_paths('src', 'Widgets', 'HeaderBar.vala'),
    join_paths('src', 'Widgets', 'ServerConnectionDialog.vala'),
    join_paths('src', 'Widgets', 'SidePanel.vala'),
    join_paths('src', 'Widgets', 'ServerPanelRow.vala'),
    dependencies: [
        dependency('gtk+-3.0', version: '>= 3.6.0'),
        dependency('gee-0.8', version: '>= 0.8.5'),
        dependency('glib-2.0', version: '>= 2.30.0'),
        dependency('granite', version: '>= 0.5.1')
    ],
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
