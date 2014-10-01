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

if test -n "${mosaic_node_definitions:-}" ; then
	true
else
	echo "[ww] missing node definitions; falling to defaults..." >&2
	mosaic_node_definitions=''
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
	mosaic_node_path="${_PATH}"
fi

echo "[ii] using the application FQDN \`${mosaic_application_fqdn}\`;" >&2
echo "[ii] using the node FQDN \`${mosaic_node_fqdn}\`;" >&2
echo "[ii] using the node IP \`${mosaic_node_ip}\`;" >&2
echo "[ii] using the node log \`${mosaic_node_log}\`;" >&2
echo "[ii] using the node definitions \`${mosaic_node_definitions}\`;" >&2
echo "[ii] using the node temporary \`${mosaic_node_temporary}\`;" >&2
echo "[ii] using the node PATH \`${mosaic_node_path}\`;" >&2

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

_exec_env=(
		mosaic_application_fqdn="${mosaic_application_fqdn}"
		mosaic_node_fqdn="${mosaic_node_fqdn}"
		mosaic_node_ip="${mosaic_node_ip}"
		mosaic_node_log="${mosaic_node_log}"
		mosaic_node_definitions="${mosaic_node_definitions}"
		mosaic_node_temporary="${mosaic_node_temporary}"
		mosaic_node_path="${mosaic_node_path}"
		HOME="${mosaic_node_temporary}/home"
		PATH="${mosaic_node_path}"
)

if test "${#}" -eq 0 ; then
	exec env -i "${_exec_env[@]}" mosaic-node--run-node
else
	exec env -i "${_exec_env[@]}" mosaic-node--run-node "${@}"
fi

exit 1
