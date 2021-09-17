# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Dogecoin Core live development version of blockchain node and RPC server."
HOMEPAGE="https://github.com/dogecoin"
EGIT_REPO_URI="https://github.com/dogecoin/dogecoin.git"
inherit git-r3
LICENSE="MIT"
SLOT="0"
DB_VER="5.3"
IUSE="gui +src test +wallet zmq"
REQUIRED_USE="^^ ( wallet )"
RESTRICT="!test? ( test )"
DOGEDIR="/opt/${PN}"
DEPEND="
	dev-libs/libevent:=
	dev-libs/protobuf
	dev-libs/openssl
	sys-devel/libtool
	sys-devel/automake:=
	=dev-libs/boost-1.76.0-r1
	wallet? ( sys-libs/db:"${DB_VER}"=[cxx] )
	gui? ( dev-qt/qtcore dev-qt/qtgui dev-qt/qtwidgets dev-qt/qtdbus dev-qt/linguist-tools:= media-gfx/qrencode )
	zmq? ( net-libs/cppzmq )
"
RDEPEND="${DEPEND}"
BDEPEND="
	sys-devel/autoconf
	sys-devel/automake
"
WORKDIR_="${WORKDIR}/dogecoin-9999"
S=${WORKDIR_}

src_configure() {
	chmod 755 ./autogen.sh
	./autogen.sh || die "autogen failed"
	local my_econf=(
		--enable-cxx
		--with-incompatible-bdb
		--bindir="${DOGEDIR}/bin"
		--datadir="${DOGEDIR}/dogecoind"
		CPPFLAGS="-I/usr/include/db${DB_VER}" CFLAGS="-I/usr/include/db${DB_VER}"
		--with-gui=$(usex gui qt5 no)
		$(use_enable test tests)
		$(use_with gui qt-incdir /usr/include/qt5)
		$(use_enable zmq)
	)
	econf "${my_econf[@]}"
}

src_install() {
	emake DESTDIR="${D}" install
	insinto "${DOGEDIR}/dogecoind"
	#Derived from net-p2p/bitcoind file operations.
	newins "${FILESDIR}/dogecoin.conf" "dogecoin.conf"
	newins "${FILESDIR}/dogecoin.example.conf" "dogecoin.example.conf"
	fperms 600 "${DOGEDIR}/dogecoind/dogecoin.conf"
	fperms 600 "${DOGEDIR}/dogecoind/dogecoin.example.conf"
	if use src; then
		insinto "${DOGEDIR}/src"
		doins -r "${WORKDIR_}"
		elog "Dogecoin Core source files have been placed in ${DOGEDIR}/src."
	fi
}

pkg_postinst() {
	elog "${P} live development version has been installed."
	elog "Dogecoin Core binaries have been placed in ${DOGEDIR}/bin."
	elog "dogecoin.conf is in ${DOGEDIR}/dogecoind/dogecoin.conf.  It can be symlinked with where the .dogecoin resides, for example: 'ln -s ${DOGEDIR}/dogecoind/dogecoin.conf /root/.dogecoin/dogecoin.conf'."
}
