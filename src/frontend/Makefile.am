# Copyright 2021-2025 MarcosHCK
# This file is part of abaco.
#
# abaco is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# abaco is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with abaco. If not, see <http://www.gnu.org/licenses/>.
#

VOID=

#
# Binaries and libraries
# - declare
#

bin_PROGRAMS=\
  abaco \
  $(VOID)

#
# Binaries and libraries
# - sources
#

abaco_SOURCES=\
  main.vala \
  $(VOID)
abaco_CFLAGS=\
  $(GIO_CFLAGS) \
  $(GLIB_CFLAGS) \
  $(GOBJECT_CFLAGS) \
  $(LLVM_CFLAGS) \
  -I../backend/ \
  $(VOID)
abaco_LDFLAGS=\
  $(GIO_LIBS) \
  $(GLIB_LIBS) \
  $(GOBJECT_LIBS) \
  $(LLVM_LIBS) \
  ../backend/libabaco.la \
  $(VOID)

#
# Vala
#

AM_VALAFLAGS=\
  --vapidir=../backend/ \
	--vapi-comments \
	--hide-internal \
	--abi-stability \
  --pkg libabaco \
	-D DEBUG=${DEBUG} \
	-D DEVELOPER=${DEVELOPER} \
	$(VOID)
