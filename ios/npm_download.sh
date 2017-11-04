#!/bin/bash
package="$1"
baseUrl="https://registry.npmjs.org"
version=$(node pkgversion.js ${package})
archive="${package}-${version}.tgz"
mkdir "${package}"
echo "Downloading ${archive}"
curl --progress-bar \
  "${baseUrl}/${package}/-/${archive}" | \
  tar xz --strip-components 1 -C "${package}"
