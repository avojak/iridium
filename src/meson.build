conf_data = configuration_data()
conf_data.set('APP_ID', application_id)
conf_data.set('APP_NAME', application_name)
conf_data.set('VERSION', meson.project_version())

config_header = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

iridium_files = files(
    join_paths('Application.vala'),
    join_paths('MainWindow.vala'),
    join_paths('Layouts', 'MainLayout.vala'),
    join_paths('Models', 'AuthenticationMethod.vala'),
    join_paths('Models', 'RichText.vala'),
    join_paths('Models', 'ChannelErrorMessageText.vala'),
    join_paths('Models', 'InvalidCertificatePolicy.vala'),
    join_paths('Models', 'PrivateMessageText.vala'),
    join_paths('Models', 'SelfPrivateMessageText.vala'),
    join_paths('Models', 'OthersPrivateMessageText.vala'),
    join_paths('Models', 'ServerErrorMessageText.vala'),
    join_paths('Models', 'ServerIdentity.vala'),
    join_paths('Models', 'ServerMessageText.vala'),
    join_paths('Services', 'CertificateManager.vala'),
    join_paths('Services', 'Message.vala'),
    join_paths('Services', 'MessageCommands.vala'),
    join_paths('Services', 'NumericCodes.vala'),
    join_paths('Services', 'ServerConnection.vala'),
    join_paths('Services', 'ServerConnectionDAO.vala'),
    join_paths('Services', 'ServerConnectionDetails.vala'),
    join_paths('Services', 'ServerConnectionHandler.vala'),
    join_paths('Services', 'Channel.vala'),
    join_paths('Services', 'SecretManager.vala'),
    join_paths('Services', 'Server.vala'),
    join_paths('Services', 'SQLClient.vala'),
    join_paths('Views', 'ChatView.vala'),
    join_paths('Views', 'ChannelChatView.vala'),
    join_paths('Views', 'PrivateMessageChatView.vala'),
    join_paths('Views', 'ServerChatView.vala'),
    join_paths('Views', 'Welcome.vala'),
    join_paths('Widgets', 'CertificateWarningDialog.vala'),
    join_paths('Widgets', 'ChannelJoinDialog.vala'),
    join_paths('Widgets', 'ChannelTopicEditDialog.vala'),
    join_paths('Widgets', 'HeaderBar.vala'),
    join_paths('Widgets', 'ManageConnectionsDialog.vala'),
    join_paths('Widgets', 'NetworkInfoBar.vala'),
    join_paths('Widgets', 'PreferencesDialog.vala'),
    join_paths('Widgets', 'ServerConnectionDialog.vala'),
    join_paths('Widgets', 'StatusBar.vala'),
    join_paths('Widgets', 'SidePanel', 'Panel.vala'),
    join_paths('Widgets', 'SidePanel', 'Row.vala'),
    join_paths('Widgets', 'SidePanel', 'ServerRow.vala'),
    join_paths('Widgets', 'SidePanel', 'ChannelRow.vala'),
    join_paths('Widgets', 'SidePanel', 'PrivateMessageRow.vala'),
    join_paths('Widgets', 'UsersPopover', 'ChannelUsersPopover.vala'),
    join_paths('Widgets', 'UsersPopover', 'UserListBoxRow.vala')
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    application_id,
    iridium_files,
    config_header,
    css_gresource,
    dependencies: [
        dependency('gtk+-3.0', version: '>= 3.6.4'),
        dependency('gee-0.8', version: '>= 0.8.5'),
        dependency('glib-2.0', version: '>= 2.30.0'),
        dependency('granite', version: '>= 0.5.1'),
        dependency('libsecret-1', version: '>= 0.18.6'),
        dependency('sqlite3', version: '>= 3.22.0')
    ],
    vala_args: vala_args,
    install: true
)
