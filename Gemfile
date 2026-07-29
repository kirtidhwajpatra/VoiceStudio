# Pinning fastlane in a Gemfile (rather than `brew install fastlane`) means
# your Mac and the CI runner execute the exact same fastlane version.
# Gemfile.lock is committed for the same reason Package.resolved is:
# reproducible builds beat convenient builds.

source "https://rubygems.org"

gem "fastlane", "~> 2.228"

# Loads any plugins declared in fastlane/Pluginfile.
plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
