# This toolchain is gcc 5.2.0 on uClibc-ng 1.0.6

GNU_TARGET_NAME = mipsel-linux
EXACT_TARGET_NAME = mipsel-buildroot-linux-uclibc

LIBC_STYLE=uclibc
TARGET_ARCH=mipsel
TARGET_OS=linux-uclibc

LIBSTDC++_VERSION=6.0.21

LIBC-DEV_IPK_VERSION=1

GETTEXT_NLS=enable
#NO_BUILTIN_MATH=true
IPV6=yes

CROSS_CONFIGURATION_GCC_VERSION=5.2.0
CROSS_CONFIGURATION_UCLIBC_VERSION=1.0.6

ifeq ($(HOST_MACHINE),mips)

HOSTCC = $(TARGET_CC)
GNU_HOST_NAME = $(GNU_TARGET_NAME)
TARGET_CROSS = /opt/bin/
TARGET_LIBDIR = /opt/lib
TARGET_INCDIR = /opt/include
TARGET_LDFLAGS =
TARGET_CUSTOM_FLAGS=
TARGET_CFLAGS= $(TARGET_OPTIMIZATION) $(TARGET_DEBUGGING) $(TARGET_CUSTOM_FLAGS)

toolchain:

else

HOSTCC = gcc
GNU_HOST_NAME = $(HOST_MACHINE)-pc-linux-gnu
CROSS_CONFIGURATION_GCC=gcc-$(CROSS_CONFIGURATION_GCC_VERSION)
CROSS_CONFIGURATION_UCLIBC=uclibc-$(CROSS_CONFIGURATION_UCLIBC_VERSION)
CROSS_CONFIGURATION=$(CROSS_CONFIGURATION_GCC)-$(CROSS_CONFIGURATION_UCLIBC)
TARGET_CROSS_BUILD_DIR = $(BASE_DIR)/toolchain/buildroot-2015.08
TARGET_CROSS_TOP = $(BASE_DIR)/toolchain/buildroot-mipsel-linux-2.6.36-uclibc-ng-5.2.0
TARGET_CROSS = $(TARGET_CROSS_TOP)/bin/mipsel-buildroot-linux-uclibc-
TARGET_LIBDIR = $(TARGET_CROSS_TOP)/mipsel-buildroot-linux-uclibc/sysroot/usr/lib
TARGET_INCDIR = $(TARGET_CROSS_TOP)/mipsel-buildroot-linux-uclibc/sysroot/usr/include

#	to make feed firmware-independent, we make
#	all packages dependent on uclibc-opt by hacking ipkg-build from ipkg-utils,
#	and add following ld flag to hardcode /opt/lib/ld-uClibc.so.0
#	into executables instead of firmware's /lib/ld-uClibc.so.0
TARGET_LDFLAGS = -Wl,--dynamic-linker=/opt/lib/ld-uClibc.so.0

TARGET_CUSTOM_FLAGS= -pipe
TARGET_CFLAGS=$(TARGET_OPTIMIZATION) $(TARGET_DEBUGGING) $(TARGET_CUSTOM_FLAGS)

TOOLCHAIN_SITE=http://buildroot.uclibc.org/downloads
TOOLCHAIN_SOURCE=buildroot-2015.08.tar.bz2

UCLIBC-OPT_VERSION = 1.0.6
UCLIBC-OPT_IPK_VERSION = 1
LIBNSL_IPK_VERSION = 1
UCLIBC-OPT_LIBS_SOURCE_DIR = $(TARGET_CROSS_TOP)/mipsel-buildroot-linux-uclibc/sysroot/lib

BUILDROOT-MIPSEL-NG_SOURCE_DIR=$(SOURCE_DIR)/buildroot-mipsel-ng

BUILDROOT-MIPSEL-NG_PATCHES=$(BUILDROOT-MIPSEL-NG_SOURCE_DIR)/uclibc-ng-1.0.6.patch

toolchain: $(TARGET_CROSS_TOP)/.built

toolchain-configure: $(TARGET_CROSS_TOP)/.configured

$(DL_DIR)/$(TOOLCHAIN_SOURCE):
	$(WGET) -P $(@D) $(TOOLCHAIN_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

$(TARGET_CROSS_TOP)/.configured: $(DL_DIR)/$(TOOLCHAIN_SOURCE) #$(OPTWARE_TOP)/platforms/toolchain-$(OPTWARE_TARGET).mk
	rm -rf $(TARGET_CROSS_TOP) $(TARGET_CROSS_BUILD_DIR)
	mkdir -p $(TARGET_CROSS_TOP)/mipsel-buildroot-linux-uclibc/sysroot
	tar -xjvf $(DL_DIR)/$(TOOLCHAIN_SOURCE) -C $(BASE_DIR)/toolchain
	if test -n "$(BUILDROOT-MIPSEL-NG_PATCHES)" ; \
		then cat $(BUILDROOT-MIPSEL-NG_PATCHES) | \
		patch -bd $(TARGET_CROSS_BUILD_DIR) -p1 ; \
	fi
	sed 's|^BR2_DL_DIR=.*|BR2_DL_DIR="$(DL_DIR)"|' $(BUILDROOT-MIPSEL-NG_SOURCE_DIR)/config > $(TARGET_CROSS_BUILD_DIR)/.config
	sed -i.orig -e '/^RUNTIME_PREFIX=\|^DEVEL_PREFIX=/s|=.*|="/opt/"|' $(TARGET_CROSS_BUILD_DIR)/package/uclibc/uClibc-ng.config
#	cp -f $(BUILDROOT-MIPSEL-NG_SOURCE_DIR)/gcc-5.2.0-patches/*.patch $(TARGET_CROSS_BUILD_DIR)/package/gcc/5.2.0/
#	cp -f $(BUILDROOT-MIPSEL-NG_SOURCE_DIR)/uClibc-0.9.33-patches/*.patch $(TARGET_CROSS_BUILD_DIR)/package/uclibc/0.9.33.2/
	touch $@

$(TARGET_CROSS_TOP)/.built: $(TARGET_CROSS_TOP)/.configured
	rm -f $@
	$(MAKE) STAGING_DIR=$(TARGET_CROSS_TOP)/mipsel-buildroot-linux-uclibc/sysroot -C $(TARGET_CROSS_BUILD_DIR)
	cp -af $(TARGET_CROSS_BUILD_DIR)/output/host/usr/* $(TARGET_CROSS_TOP)/
	cp -f $(UCLIBC-OPT_LIBS_SOURCE_DIR)/libnsl-$(CROSS_CONFIGURATION_UCLIBC_VERSION).so $(TARGET_LIBDIR)/
	cp -f $(TARGET_CROSS_TOP)/lib/gcc/mipsel-buildroot-linux-uclibc/5.2.0/*.a $(UCLIBC-OPT_LIBS_SOURCE_DIR)/
	touch $@

GCC_TARGET_NAME := mipsel-buildroot-linux-uclibc

GCC_CPPFLAGS := -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64

GCC_EXTRA_CONF_ENV := ac_cv_lbl_unaligned_fail=yes ac_cv_func_mmap_fixed_mapped=yes ac_cv_func_memcmp_working=yes ac_cv_have_decl_malloc=yes gl_cv_func_malloc_0_nonnull=yes ac_cv_func_malloc_0_nonnull=yes ac_cv_func_calloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes lt_cv_sys_lib_search_path_spec="" ac_cv_c_bigendian=no

NATIVE_GCC_EXTRA_CONFIG_ARGS=--with-gxx-include-dir=/opt/include/c++/5.2.0 --disable-__cxa_atexit --with-gnu-ld --disable-libssp --enable-target-optspace --disable-libsanitizer --enable-tls --disable-libmudflap --enable-threads --without-isl --without-cloog --with-float=soft --disable-decimal-float --with-arch=mips32r2 --with-abi=32 --enable-shared --disable-libgomp --with-gmp=$(STAGING_PREFIX) --with-mpfr=$(STAGING_PREFIX) --with-mpc=$(STAGING_PREFIX) --with-default-libstdcxx-abi=gcc4-compatible --with-system-zlib

NATIVE_GCC_ADDITIONAL_DEPS=zlib

NATIVE_GCC_ADDITIONAL_STAGE=zlib-stage

endif