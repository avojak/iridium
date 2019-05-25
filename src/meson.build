conf_data = configuration_data()
conf_data.set('PROJECT_NAME', 'Iridium')
conf_data.set('VERSION', meson.project_version())

config_header = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    join_paths('Application.vala'),
    join_paths('MainWindow.vala'),
    join_paths('Layouts', 'MainLayout.vala'),
    join_paths('Models', 'RichText.vala'),
    join_paths('Models', 'ChannelErrorMessageText.vala'),
    join_paths('Models', 'PrivMessageText.vala'),
    join_paths('Models', 'SelfPrivMessageText.vala'),
    join_paths('Models', 'OthersPrivMessageText.vala'),
    join_paths('Models', 'ServerErrorMessageText.vala'),
    join_paths('Models', 'ServerMessageText.vala'),
    join_paths('Services', 'Message.vala'),
    join_paths('Services', 'MessageCommands.vala'),
    join_paths('Services', 'NumericCodes.vala'),
    join_paths('Services', 'ServerConnection.vala'),
    join_paths('Services', 'ServerConnectionDetails.vala'),
    join_paths('Services', 'ServerConnectionHandler.vala'),
    join_paths('Services', 'Settings.vala'),
    join_paths('Views', 'ChatView.vala'),
    join_paths('Views', 'ChannelChatView.vala'),
    join_paths('Views', 'ServerChatView.vala'),
    join_paths('Views', 'Welcome.vala'),
    join_paths('Widgets', 'ChannelJoinDialog.vala'),
    join_paths('Widgets', 'HeaderBar.vala'),
    join_paths('Widgets', 'ServerConnectionDialog.vala'),
    join_paths('Widgets', 'SidePanel', 'Panel.vala'),
    join_paths('Widgets', 'SidePanel', 'Row.vala'),
    join_paths('Widgets', 'SidePanel', 'ServerRow.vala'),
    join_paths('Widgets', 'SidePanel', 'ChannelRow.vala'),
    config_header,
    dependencies: [
        dependency('gtk+-3.0', version: '>= 3.6.4'),
        dependency('gee-0.8', version: '>= 0.8.5'),
        dependency('glib-2.0', version: '>= 2.30.0'),
        dependency('granite', version: '>= 0.5.1')
    ],
    install: true
)
