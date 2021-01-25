# frozen_string_literal: true

$VERBOSE = true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'fileutils'
require "rbconfig"

require 'netrc'
require "minitest/autorun"
