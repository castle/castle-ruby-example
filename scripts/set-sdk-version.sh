#!/usr/bin/env bash
# Point the example app at a specific Castle Ruby SDK source.
#
#   set-sdk-version.sh develop   -> track the SDK's develop branch (pre-release testing)
#   set-sdk-version.sh 9.3.0     -> pin the released ~> 9.3 gem from RubyGems
#
# Rewrites the castle-rb line in the Gemfile and regenerates Gemfile.lock.
set -euo pipefail

target="${1:?usage: set-sdk-version.sh <develop|X.Y.Z>}"

ruby - "$target" <<'RUBY'
target = ARGV[0]
path = "Gemfile"
content = File.read(path)
pattern = /^\s*gem ['"]castle-rb['"].*$/
abort "no castle-rb gem line found in #{path}" unless content.match?(pattern)
line =
  if target == "develop"
    "gem 'castle-rb', github: 'castle/castle-ruby', branch: 'develop'"
  else
    minor = target.split(".")[0, 2].join(".")
    "gem 'castle-rb', '~> #{minor}'"
  end
File.write(path, content.gsub(pattern, line))
RUBY

bundle lock
