# Google search CLI browser that can open links into a browser.
require 'bundler/setup'
require 'mechanize'
require 'launchy'

require 'uri'
require 'ostruct'

require_relative "google_browse/scraper"
require_relative "google_browse/browser"
require_relative "google_browse/version"
