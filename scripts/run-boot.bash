#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

# FIXME: Remove this hack!
if test "${UID}" -eq 0 ; then
	find /mos -mindepth 1 -maxdepth 1 -type d -exec chmod 1777 -- {} \;
fi

if test "$( getent passwd -- mos-services | cut -f 3 -d : )" -ne "${UID}" ; then
	exec sudo -u mos-services -g mos-services -E -n -- "${0}" "${@}"
	exit 1
fi

umask 0022

if test -n "${mosaic_cluster_nodes_fqdn:-}" ; then
	true
elif test -n "${mos_cluster_nodes_private_fqdn:-}" ; then
	mosaic_cluster_nodes_fqdn="${mos_cluster_nodes_private_fqdn}"
elif test -n "${mos_cluster_nodes_public_fqdn:-}" ; then
	mosaic_cluster_nodes_fqdn="${mos_cluster_nodes_public_fqdn}"
else
	mosaic_cluster_nodes_fqdn=
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
	mosaic_node_temporary="${mos_fs_tmp}/mosaic/node"
else
	echo "[ww] missing node temporary; falling to defaults..." >&2
	mosaic_node_temporary="/tmp/mosaic/node"
fi

if test -n "${mosaic_node_tmpdir:-}" ; then
	true
elif test -n "${mos_fs_tmp:-}" ; then
	mosaic_node_tmpdir="${mos_fs_tmp}"
else
	echo "[ww] missing node TMPDIR; falling to defaults..." >&2
	mosaic_node_tmpdir="/tmp"
fi

if test -n "${mosaic_node_log:-}" ; then
	true
elif test -n "${mos_fs_log:-}" ; then
	mosaic_node_log="${mos_fs_log}/mosaic/node/node.log"
else
	echo "[ww] missing node log; falling to defaults..." >&2
	mosaic_node_log="${mosaic_node_temporary}/node.log"
fi

if test -n "${mosaic_node_path:-}" ; then
	true
else
	mosaic_node_path="${_PATH}"
fi

if test -n "${mosaic_node_home:-}" ; then
	true
else
	mosaic_node_home="${mosaic_node_temporary}/home"
fi

echo "[ii] using the cluster FQDN \`${mosaic_cluster_nodes_fqdn}\`;" >&2
echo "[ii] using the node FQDN \`${mosaic_node_fqdn}\`;" >&2
echo "[ii] using the node IP \`${mosaic_node_ip}\`;" >&2
echo "[ii] using the node log \`${mosaic_node_log}\`;" >&2
echo "[ii] using the node definitions \`${mosaic_node_definitions}\`;" >&2
echo "[ii] using the node temporary \`${mosaic_node_temporary}\`;" >&2
echo "[ii] using the node TMPDIR \`${mosaic_node_tmpdir}\`;" >&2
echo "[ii] using the node PATH \`${mosaic_node_path}\`;" >&2
echo "[ii] using the node HOME \`${mosaic_node_home}\`;" >&2

if test ! -e "${mosaic_node_temporary}" ; then
	mkdir -p -- "${mosaic_node_temporary}"
fi

if test ! -e "$( dirname -- "${mosaic_node_log}" )" ; then
	mkdir -p -- "$( dirname -- "${mosaic_node_log}" )"
fi

if test ! -e "${mosaic_node_temporary}/home" ; then
	mkdir -p -- "${mosaic_node_temporary}/home"
fi

if test ! -e "${mosaic_node_temporary}/cwd" ; then
	mkdir -p -- "${mosaic_node_temporary}/cwd"
fi

_exec_env=(
		mosaic_cluster_nodes_fqdn="${mosaic_cluster_nodes_fqdn}"
		mosaic_node_fqdn="${mosaic_node_fqdn}"
		mosaic_node_ip="${mosaic_node_ip}"
		mosaic_node_log="${mosaic_node_log}"
		mosaic_node_definitions="${mosaic_node_definitions}"
		mosaic_node_temporary="${mosaic_node_temporary}"
		mosaic_node_path="${mosaic_node_path}"
		mosaic_node_home="${mosaic_node_home}"
		TMPDIR="${mosaic_node_tmpdir}"
		PATH="${mosaic_node_path}"
		HOME="${mosaic_node_home}"
)

cd -- "${mosaic_node_temporary}/cwd"

if test "${#}" -eq 0 ; then
	exec env -i "${_exec_env[@]}" mosaic-node--run-node
else
	exec env -i "${_exec_env[@]}" mosaic-node--run-node "${@}"
fi

exit 1
