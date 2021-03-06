# Copyright (c) 2016-2020 Franco Fichtner <franco@opnsense.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

LOCALBASE?=	/usr/local
PAGER?=		less

OPENSSL?=	${LOCALBASE}/bin/openssl

_FLAVOUR!=	if [ -f ${OPENSSL} ]; then ${OPENSSL} version; fi
FLAVOUR?=	${_FLAVOUR:[1]}

PKG!=		which pkg || echo true
GIT!=		which git || echo true
ARCH!=		uname -p

PLUGIN_ABI?=	20.1
PLUGIN_ARCH?=	${ARCH}
PLUGIN_FLAVOUR=	${FLAVOUR}

REPLACEMENTS=	PLUGIN_ABI \
		PLUGIN_ARCH \
		PLUGIN_FLAVOUR

SED_REPLACE=	# empty

.for REPLACEMENT in ${REPLACEMENTS}
SED_REPLACE+=	-e "s=%%${REPLACEMENT}%%=${${REPLACEMENT}}=g"
.endfor

ARGS=	diff mfc

# handle argument expansion for required targets
.for TARGET in ${.TARGETS}
_TARGET=		${TARGET:C/\-.*//}
.if ${_TARGET} != ${TARGET}
.for ARGUMENT in ${ARGS}
.if ${_TARGET} == ${ARGUMENT}
${_TARGET}_ARGS+=	${TARGET:C/^[^\-]*(\-|\$)//:S/,/ /g}
${TARGET}: ${_TARGET}
.endif
.endfor
${_TARGET}_ARG=		${${_TARGET}_ARGS:[0]}
.endif
.endfor

diff:
	@git diff --stat -p stable/${PLUGIN_ABI} ${.CURDIR}/${diff_ARGS:[1]}

mfc:
.for MFC in ${mfc_ARGS}
.if exists(${MFC})
	@git diff --stat -p stable/${PLUGIN_ABI} ${.CURDIR}/${MFC} > /tmp/mfc.diff
	@git checkout stable/${PLUGIN_ABI}
	@git apply /tmp/mfc.diff
	@git add ${.CURDIR}
	@if ! git diff --quiet HEAD; then \
		git commit -m "${MFC}: sync with master"; \
	fi
.else
	@git checkout stable/${PLUGIN_ABI}
	@git cherry-pick -x ${MFC}
.endif
	@git checkout master
.endfor
