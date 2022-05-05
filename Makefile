SHELL := /bin/bash

APP_ID := com.github.avojak.iridium

ELEMENTARY_FLATPAK_REMOTE_URL  := https://flatpak.elementary.io/repo.flatpakrepo
ELEMENTARY_FLATPAK_REMOTE_NAME := appcenter
ELEMENTARY_PLATFORM_VERSION    := 7

# FLATHUB_FLATPAK_REMOTE_URL  := https://flathub.org/repo/flathub.flatpakrepo
# FLATHUB_FLATPAK_REMOTE_NAME := flathub
# FLATHUB_PLATFORM_VERSION    := 42

BUILD_DIR        := build
NINJA_BUILD_FILE := $(BUILD_DIR)/build.ninja

FLATPAK_BUILDER_FLAGS := --user --install --force-clean
ifdef OFFLINE_BUILD
FLATPAK_BUILDER_FLAGS += --disable-download
endif

# Check for executables which are assumed to already be present on the system
EXECUTABLES = flatpak flatpak-builder
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

.DEFAULT_GOAL := flatpak

.PHONY: all
all: translations flatpak

.PHONY: flatpak-init
flatpak-init:
	flatpak remote-add --if-not-exists --system $(ELEMENTARY_FLATPAK_REMOTE_NAME) $(ELEMENTARY_FLATPAK_REMOTE_URL)
	flatpak install -y --user $(ELEMENTARY_FLATPAK_REMOTE_NAME) io.elementary.Platform//$(ELEMENTARY_PLATFORM_VERSION) 
	flatpak install -y --user $(ELEMENTARY_FLATPAK_REMOTE_NAME) io.elementary.Sdk//$(ELEMENTARY_PLATFORM_VERSION)

.PHONY: init
init: flatpak-init

.PHONY: flatpak
flatpak:
	flatpak-builder build $(APP_ID).yml $(FLATPAK_BUILDER_FLAGS)

# .PHONY: flathub-init
# flathub-init:
# 	flatpak remote-add --if-not-exists --system $(FLATHUB_FLATPAK_REMOTE_NAME) $(FLATHUB_FLATPAK_REMOTE_URL)
# 	flatpak install -y --user $(FLATHUB_FLATPAK_REMOTE_NAME) org.gnome.Platform//$(FLATHUB_PLATFORM_VERSION)
# 	flatpak install -y --user $(FLATHUB_FLATPAK_REMOTE_NAME) org.gnome.Sdk//$(FLATHUB_PLATFORM_VERSION)

# .PHONY: flathub
# flathub:
# 	flatpak-builder build flathub/$(APP_ID).yml --user --install --force-clean

.PHONY: lint
lint:
	io.elementary.vala-lint ./src

$(NINJA_BUILD_FILE):
	meson build --prefix=/user

.PHONY: translations
translations: $(NINJA_BUILD_FILE)
	ninja -C build $(APP_ID)-pot
	ninja -C build $(APP_ID)-update-po

.PHONY: clean
clean:
	rm -rf ./.flatpak-builder/
	rm -rf ./build/
	rm -rf ./builddir/