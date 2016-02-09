# Copyright 2005 The Android Open Source Project
#
# Android.mk for adb
#

LOCAL_PATH:= $(call my-dir)

ifeq ($(HOST_OS),windows)
  adb_host_clang := false  # libc++ for mingw not ready yet.
else
  adb_host_clang := true
endif

adb_version := $(shell git -C $(LOCAL_PATH) rev-parse --short=12 HEAD 2>/dev/null)-android

ADB_COMMON_CFLAGS := \
    -Wall -Werror \
    -Wno-unused-parameter \
    -DADB_REVISION='"$(adb_version)"' \

# libadb
# =========================================================

# Much of adb is duplicated in bootable/recovery/minadb and fastboot. Changes
# made to adb rarely get ported to the other two, so the trees have diverged a
# bit. We'd like to stop this because it is a maintenance nightmare, but the
# divergence makes this difficult to do all at once. For now, we will start
# small by moving common files into a static library. Hopefully some day we can
# get enough of adb in here that we no longer need minadb. https://b/17626262
LIBADB_SRC_FILES := \
    adb.cpp \
    adb_auth.cpp \
    adb_io.cpp \
    adb_listeners.cpp \
    adb_utils.cpp \
    sockets.cpp \
    transport.cpp \
    transport_local.cpp \
    transport_usb.cpp \

LIBADB_TEST_SRCS := \
    adb_io_test.cpp \
    adb_utils_test.cpp \
    transport_test.cpp \

LIBADB_CFLAGS := \
    $(ADB_COMMON_CFLAGS) \
    -Wno-missing-field-initializers \
    -fvisibility=hidden \

LIBADB_darwin_SRC_FILES := \
    fdevent.cpp \
    get_my_path_darwin.cpp \
    usb_osx.cpp \

LIBADB_linux_SRC_FILES := \
    fdevent.cpp \
    get_my_path_linux.cpp \
    usb_linux.cpp \

LIBADB_windows_SRC_FILES := \
    get_my_path_windows.cpp \
    sysdeps_win32.cpp \
    usb_windows.cpp \

include $(CLEAR_VARS)
LOCAL_CLANG := true
LOCAL_MODULE := libmrom_adbd
LOCAL_CFLAGS := $(LIBADB_CFLAGS) -DADB_HOST=0
LOCAL_SRC_FILES := \
    $(LIBADB_SRC_FILES) \
    adb_auth_client.cpp \
    fdevent.cpp \
    jdwp_service.cpp \
    qemu_tracing.cpp \
    usb_linux_client.cpp \

LOCAL_SHARED_LIBRARIES := libbase

include $(BUILD_STATIC_LIBRARY)

# adbd device daemon
# =========================================================

include $(CLEAR_VARS)

LOCAL_CLANG := true

LOCAL_SRC_FILES := \
    adb_main.cpp \
    services.cpp \
    file_sync_service.cpp \
    framebuffer_service.cpp \
    remount_service.cpp \
    set_verity_enable_state_service.cpp \

LOCAL_CFLAGS := \
    $(ADB_COMMON_CFLAGS) \
    -DADB_HOST=0 \
    -D_GNU_SOURCE \
    -Wno-deprecated-declarations \

LOCAL_CFLAGS += -DALLOW_ADBD_NO_AUTH=$(if $(filter userdebug eng,$(TARGET_BUILD_VARIANT)),1,0)

ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
LOCAL_CFLAGS += -DALLOW_ADBD_DISABLE_VERITY=1
LOCAL_CFLAGS += -DALLOW_ADBD_ROOT=1
endif

LOCAL_MODULE := mrom_adbd

LOCAL_FORCE_STATIC_EXECUTABLE := true
#LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT_SBIN)
#LOCAL_UNSTRIPPED_PATH := $(TARGET_ROOT_OUT_SBIN_UNSTRIPPED)
LOCAL_MODULE_PATH := $(TARGET_OUT_OPTIONAL_EXECUTABLES)
LOCAL_UNSTRIPPED_PATH := $(TARGET_OUT_EXECUTABLES_UNSTRIPPED)
LOCAL_C_INCLUDES += system/extras/ext4_utils

LOCAL_STATIC_LIBRARIES := \
    libmrom_adbd \
    libbase \
    libfs_mgr \
    liblog \
    libcutils \
    libc \
    libmincrypt \
    libselinux \
    libext4_utils_static \

include $(BUILD_EXECUTABLE)
