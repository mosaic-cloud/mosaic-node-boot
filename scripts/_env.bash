#!/dev/null

set -e -E -u -o pipefail -o noclobber -o noglob +o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "${BASH_COMMAND}" >&2' ERR || exit 1
export -n BASH_ENV

_workbench="$( readlink -e -- . )"
_scripts="${_workbench}/scripts"
_tools="${mosaic_distribution_tools:-${_workbench}/.tools}"
_outputs="${_workbench}/.outputs"
_temporary="${mosaic_distribution_temporary:-/tmp}"

_PATH="${_tools}/bin:${PATH}"

_generic_env=(
		PATH="${_PATH}"
		TMPDIR="${_temporary}"
)

_package_name="$( basename -- "$( readlink -e -- . )" )"
_package_version="${mosaic_distribution_version:-0.7.0_mosaic_dev}"
_package_scripts=( run-boot )
