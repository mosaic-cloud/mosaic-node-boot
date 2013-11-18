#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

if test -n "${mosaic_application_fqdn:-}" ; then
	true
elif test -n "${mos_application_private_fqdn:-}" ; then
	mosaic_application_fqdn="${mos_application_private_fqdn}"
elif test -n "${mos_application_public_fqdn:-}" ; then
	mosaic_application_fqdn="${mos_application_public_fqdn}"
else
	mosaic_application_fqdn=
fi

if test -n "${mosaic_node_fqdn:-}" ; then
	true
elif test -n "${mos_node_private_fqdn:-}" ; then
	mosaic_node_fqdn="${mos_node_private_fqdn}"
elif test -n "${mos_node_public_fqdn:-}" ; then
	mosaic_node_fqdn="${mos_node_public_fqdn}"
else
	echo "[ww] missing node FQDN; trying to auto-detect..." >&2
	mosaic_node_fqdn="$( hostname -f 2>/dev/null | tr ' ' '\n' | head -n 1 || true )"
fi

if test -n "${mosaic_node_ip:-}" ; then
	true
elif test -n "${mos_node_private_ip:-}" ; then
	mosaic_node_ip="${mos_node_private_ip}"
elif test -n "${mos_node_public_ip:-}" ; then
	mosaic_node_ip="${mos_node_public_ip}"
else
	echo "[ww] missing node IP; trying to auto-detect..." >&2
	mosaic_node_ip="$( hostname -i 2>/dev/null | tr ' ' '\n' | head -n 1 || true )"
fi

if test -n "${mosaic_node_temporary:-}" ; then
	true
elif test -n "${mos_fs_tmp:-}" ; then
	mosaic_node_temporary="${mos_fs_tmp}/platform"
else
	echo "[ww] missing node temporary; falling to defaults..." >&2
	mosaic_node_temporary="/tmp/mosaic/platform"
fi

if test -n "${mosaic_node_log:-}" ; then
	true
elif test -n "${mos_fs_log:-}" ; then
	mosaic_node_log="${mos_fs_log}/platform.log"
else
	echo "[ww] missing node log; falling to defaults..." >&2
	mosaic_node_log="${mosaic_node_temporary}/platform.log"
fi

if test -n "${mosaic_node_path:-}" ; then
	true
else
	echo "[ww] missing node PATH; trying to auto-detect..." >&2
	mosaic_node_path="$(
			(
				find /opt -maxdepth 1 -exec test -d {} -a -d {}/bin \; -print \
				| sed -r -e 's|^.*$|&/bin|'
				tr ':' '\n' <<<"${_PATH}"
			) \
			| tr '\n' ':'
	)"
fi

echo "[ii] using the application FQDN \`${mosaic_application_fqdn}\`;" >&2
echo "[ii] using the node FQDN \`${mosaic_node_fqdn}\`;" >&2
echo "[ii] using the node IP \`${mosaic_node_ip}\`;" >&2
echo "[ii] using the node log \`${mosaic_node_log}\`;" >&2
echo "[ii] using the node temporary \`${mosaic_node_temporary}\`;" >&2
echo "[ii] using the node PATH \`${mosaic_node_path}\`;" >&2

export mosaic_application_fqdn
export mosaic_node_fqdn
export mosaic_node_ip
export mosaic_node_log
export mosaic_node_temporary
export mosaic_node_path

if test ! -e "${mosaic_node_temporary}" ; then
	mkdir -p -- "${mosaic_node_temporary}"
fi

if test ! -e "${mosaic_node_temporary}/home" ; then
	mkdir -p -- "${mosaic_node_temporary}/home"
fi

if test ! -e "${mosaic_node_temporary}/.iptables" ; then
	touch "${mosaic_node_temporary}/.iptables"
	iptables -t nat -A PREROUTING -p tcp --dport 80 -m state --state NEW -j DNAT --to :31000 2>/dev/null || true
fi

export HOME="${mosaic_node_temporary}/home"
export PATH="${mosaic_node_path}"

if test "${#}" -eq 0 ; then
	exec mosaic-node--run-node
else
	exec mosaic-node--run-node "${@}"
fi

exit 1
