# Project name and programming language
project('com.github.avojak.iridium', 'vala', 'c')

# Include the translations module
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

subdir('src')
subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
