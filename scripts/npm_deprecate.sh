#!/bin/bash

# Run from package root dir!

>&2 echo "For safety reasons command is only echoed and not executed"
>&2 echo "To execute command:"
>&2 echo "./scripts/npm_deprecate.sh | bash"
>&2 echo ""

pkg_min_version="0.5.0-alpha.1"

pkg_name=$(cat package.json \
    | grep name \
    | head -1 \
    | awk -F: '{ print $2 }' \
    | sed 's/[",]//g' \
    | tr -d '[[:space:]]')

pkg_version=$(npm view $pkg_name version)

echo npm deprecate $pkg_name@"\">=${pkg_min_version} <${pkg_version}\"" "\"Using deprecated version! Please upgrade package.\""