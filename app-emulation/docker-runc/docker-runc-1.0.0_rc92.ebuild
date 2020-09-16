# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# Flatcar: Based on docker-runc-1.0.0_rc4_p20180122.ebuild from commit
# 95c9943bd856cea19a2b9f8aef56928742c6d7e5 in Gentoo repo (see
# https://gitweb.gentoo.org/repo/gentoo.git/plain/app-emulation/docker-runc/docker-runc-1.0.0_rc4_p20180122.ebuild?id=95c9943bd856cea19a2b9f8aef56928742c6d7e5)

EAPI=6

GITHUB_URI="github.com/opencontainers/runc"
COREOS_GO_PACKAGE="${GITHUB_URI}"
COREOS_GO_VERSION="go1.15"
# the commit of runc that docker uses.
# see https://github.com/docker/docker-ce/blob/v19.03.13/components/engine/hack/dockerfile/install/runc.installer#L4
# Update the patch number when this commit is changed (i.e. the _p in the ebuild).
# The patch version is arbitrarily the number of commits since the tag version
# specified in the ebuild name. For example:
# $ git log --oneline v1.0.0-rc92..${COMMIT_ID} | wc -l
COMMIT_ID="3d68c79de7184b0eba97946d4f478736f46bf207"

inherit eutils flag-o-matic coreos-go vcs-snapshot

SRC_URI="https://${GITHUB_URI}/archive/${COMMIT_ID}.tar.gz -> ${P}.tar.gz"
KEYWORDS="amd64 arm64"

DESCRIPTION="runc container cli tools (docker fork)"
HOMEPAGE="http://runc.io"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="ambient apparmor hardened +seccomp selinux"

RDEPEND="
	apparmor? ( sys-libs/libapparmor )
	seccomp? ( sys-libs/libseccomp )
	!app-emulation/runc
"

S=${WORKDIR}/${P}/src/${COREOS_GO_PACKAGE}

RESTRICT="test"

src_unpack() {
	mkdir -p "${S}"
	tar --strip-components=1 -C "${S}" -xf "${DISTDIR}/${A}"
}

PATCHES=(
	"${FILESDIR}/0001-Delay-unshare-of-clone-newipc-for-selinux.patch"
	"${FILESDIR}/0001-temporarily-disable-selinux.GetEnabled-error-checks.patch"
)

src_compile() {
	# Taken from app-emulation/docker-1.7.0-r1
	export CGO_CFLAGS="-I${ROOT}/usr/include"
	export CGO_LDFLAGS="$(usex hardened '-fno-PIC ' '')
		-L${ROOT}/usr/$(get_libdir)"

	# build up optional flags
	local options=(
		$(usex ambient 'ambient' '')
		$(usex apparmor 'apparmor' '')
		$(usex seccomp 'seccomp' '')
		$(usex selinux 'selinux' '')
	)

	GOPATH="${WORKDIR}/${P}" emake BUILDTAGS="${options[*]}" \
		VERSION=1.0.0-rc92+dev.docker-19.03 \
		COMMIT="${COMMIT_ID}"
}

src_install() {
	dobin runc
}
