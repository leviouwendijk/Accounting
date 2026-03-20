#!/usr/bin/env bash

set -euo pipefail

ZIP_URL='https://www.referentiegrootboekschema.nl/sites/default/files/kennisbank/NT20_RGS_20251210.zip'
ZIP_FILE="${TMPDIR:-/tmp}/NT20_RGS_20251210.zip"

ENTRYPOINT='www.nltaxonomie.nl/rgs/nt20/rgs/20251210/entrypoints/rgs-to-bd-rpt-ihz-aangifte-2025.xsd'

MAP_COM='www.nltaxonomie.nl/rgs/nt20/rgs/20251210/mapping/map-bd-ihz_bd-lr-hd_csn-par_com-ihz.xml'
MAP_COM_BEG='www.nltaxonomie.nl/rgs/nt20/rgs/20251210/mapping/map-bd-ihz_bd-lr-hd_csn-par_com-tim_beg-ihz.xml'
MAP_COM_END='www.nltaxonomie.nl/rgs/nt20/rgs/20251210/mapping/map-bd-ihz_bd-lr-hd_csn-par_com-tim_end-ihz.xml'
MAP_DEC='www.nltaxonomie.nl/rgs/nt20/rgs/20251210/mapping/map-bd-ihz_bd-lr-hd_par_dec-ihz.xml'

ensure_zip() {
    if [[ ! -f "$ZIP_FILE" ]]; then
        echo "downloading ZIP to: $ZIP_FILE" >&2
        curl -L "$ZIP_URL" -o "$ZIP_FILE"
    fi
}

zipcat() {
    local member="$1"
    ensure_zip
    unzip -p "$ZIP_FILE" "$member"
}

show_usage() {
    cat <<'EOF'
Usage:
    inspect-ihz.sh list
    inspect-ihz.sh entrypoint-head
    inspect-ihz.sh entrypoint-grep
    inspect-ihz.sh map-head [com|beg|end|dec]
    inspect-ihz.sh map-grep [com|beg|end|dec]
    inspect-ihz.sh map-first-block [com|beg|end|dec]
    inspect-ihz.sh raw <zip-member-path>

Commands:
    list
        List IHZ-related files in the ZIP.

    entrypoint-head
        Show first 160 lines of the IHZ RGS entrypoint XSD.

    entrypoint-grep
        Show import/linkbaseRef/roleRef/arcroleRef lines from the entrypoint.

    map-head <variant>
        Show first 220 lines of a mapping XML.

    map-grep <variant>
        Grep for the first semantically interesting mapping lines.

    map-first-block <variant>
        Print the first chunk around the first non-locator mapping hit.

    raw <zip-member-path>
        Print any arbitrary member from the ZIP.
EOF
}

resolve_map() {
    local variant="${1:-com}"

    case "$variant" in
        com)
            printf '%s\n' "$MAP_COM"
            ;;
        beg)
            printf '%s\n' "$MAP_COM_BEG"
            ;;
        end)
            printf '%s\n' "$MAP_COM_END"
            ;;
        dec)
            printf '%s\n' "$MAP_DEC"
            ;;
        *)
            echo "unknown variant: $variant" >&2
            exit 1
            ;;
    esac
}

cmd_list() {
    ensure_zip
    unzip -Z1 "$ZIP_FILE" | grep 'www.nltaxonomie.nl/rgs/nt20/rgs/20251210/' | grep -E 'entrypoints/rgs-to-bd-rpt-ihz-aangifte-2025\.xsd|mapping/map-bd-ihz_'
}

cmd_entrypoint_head() {
    zipcat "$ENTRYPOINT" | sed -n '1,160p'
}

cmd_entrypoint_grep() {
    zipcat "$ENTRYPOINT" | grep -nE 'linkbaseRef|import|include|roleRef|arcroleRef'
}

cmd_map_head() {
    local member
    member="$(resolve_map "${1:-com}")"
    zipcat "$member" | sed -n '1,220p'
}

cmd_map_grep() {
    local member
    member="$(resolve_map "${1:-com}")"

    zipcat "$member" \
        | grep -nE 'xlink:from=|xlink:to=|xlink:type="resource"|<rgs:|<gen:|datapoint|explicitDimension|typedDimension|qname|member|container'
}

cmd_map_first_block() {
    local member
    member="$(resolve_map "${1:-com}")"

    zipcat "$member" | awk '
        /xlink:from=|xlink:to=|xlink:type="resource"|<rgs:|datapoint|explicitDimension|typedDimension|qname|member|container/ {
            start = NR - 20
            if (start < 1) {
                start = 1
            }
            end = NR + 80
            found = 1
        }
        found && NR >= start && NR <= end {
            printf "%6d  %s\n", NR, $0
        }
        found && NR > end {
            exit
        }
    '
}

cmd_raw() {
    local member="$1"
    zipcat "$member"
}

main() {
    local cmd="${1:-}"

    case "$cmd" in
        list)
            cmd_list
            ;;
        entrypoint-head)
            cmd_entrypoint_head
            ;;
        entrypoint-grep)
            cmd_entrypoint_grep
            ;;
        map-head)
            shift
            cmd_map_head "${1:-com}"
            ;;
        map-grep)
            shift
            cmd_map_grep "${1:-com}"
            ;;
        map-first-block)
            shift
            cmd_map_first_block "${1:-com}"
            ;;
        raw)
            shift
            if [[ $# -lt 1 ]]; then
                echo "raw requires a zip member path" >&2
                exit 1
            fi
            cmd_raw "$1"
            ;;
        ""|-h|--help|help)
            show_usage
            ;;
        *)
            echo "unknown command: $cmd" >&2
            echo >&2
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
