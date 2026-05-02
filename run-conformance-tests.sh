#!/usr/bin/env bash
# run-conformance-tests.sh — Download (if needed) and run the W3C XML
# Conformance Test Suite against cl-xml.
#
# Usage:
#   ./run-conformance-tests.sh [xmlconf-dir]
#
# If xmlconf-dir is provided it is used directly.
# Otherwise the script looks for /tmp/xmlts/xmlconf/ and, if absent,
# downloads and extracts the test suite there.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

XMLTS_URL="https://www.w3.org/XML/Test/xmlts20130923.zip"
XMLTS_ZIP="/tmp/xmlts20130923.zip"
XMLTS_EXTRACT="/tmp/xmlts"
DEFAULT_XMLTS_DIR="/tmp/xmlts/xmlconf/"

# ── Locate the xmlconf directory ──────────────────────────────────────────

if [[ $# -ge 1 ]]; then
    export XMLTS_DIR="$1"
elif [[ -n "${XMLTS_DIR:-}" && -f "${XMLTS_DIR}/xmlconf.xml" ]]; then
    : # use existing env var
elif [[ -f "${DEFAULT_XMLTS_DIR}/xmlconf.xml" ]]; then
    export XMLTS_DIR="$DEFAULT_XMLTS_DIR"
else
    echo "W3C XML Test Suite not found.  Downloading from W3C..."
    curl -fsSL -o "$XMLTS_ZIP" "$XMLTS_URL"
    unzip -q "$XMLTS_ZIP" -d "$XMLTS_EXTRACT"
    export XMLTS_DIR="$DEFAULT_XMLTS_DIR"
fi

echo "Using XMLTS_DIR=${XMLTS_DIR}"

# ── Run the conformance tests via SBCL ───────────────────────────────────

# Collect available Common Lisp library source directories
CL_SRCS=""
for dir in /usr/share/common-lisp/source/fiveam \
           /usr/share/common-lisp/source/cl-trivial-gray-streams \
           /usr/share/common-lisp/source/alexandria \
           /usr/share/common-lisp/source/trivial-backtrace; do
    if [[ -d "$dir" ]]; then
        CL_SRCS="${CL_SRCS}(push #p\"${dir}/\" asdf:*central-registry*) "
    fi
done

sbcl --non-interactive \
    --eval '(require :asdf)' \
    --eval "${CL_SRCS}" \
    --eval "(push #p\"${REPO_DIR}/\" asdf:*central-registry*)" \
    --eval '(asdf:load-system :cl-xml.conformance)' \
    --eval "(cl-xml.conformance:run-conformance-tests :verbose t)"
