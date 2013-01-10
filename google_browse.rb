# Google search CLI browser that can open links into a browser.

require 'uri'
require 'ostruct'

require 'bundler'
Bundler.require :default

class GoogleBrowse
  DEFAULT_RESULTS_PER_PAGE = 10

  class << self
    private :new
    def search(*args); new *args; end
  end

  def quit?; @quit end

  # @option :results_per_page [Integer] (10) Number of results to show per page.
  # @option :query [String] Initial search string.
  def initialize(options = {})
    options = {
      results_per_page: 10,
    }.merge! options

    @results_per_page = options[:results_per_page]
    
    @links = [] # All the links retrieved are cached here.
    @agent = Mechanize.new
    @agent.max_history = 1 # We cache the important data ourselves.

    @quit = false

    if options[:query]
      retrieve_initial_page options[:query]
    else
      input_new_search
    end

    puts
    list_links
    navigate until quit?
  end

  def retrieve_initial_page(query)
    @query = query
    @links.clear

    # Go to Google home page and create an initial query.
    google = get 'http://google.com'
    query_form = google.form_with name: 'f'
    
    query_form.q = @query

    query_form.submit query_form.button_with(name: 'btnK')
    @page_number = 0
    @more_pages = true

    read_links
  end

  def get(page)
    page = @agent.get page
    # Bit of a dumb way to tell whether we managed to find a real google page...
    # TODO: Has to be a better way to determine this!
    raise IOError, 'Failed to retrieve Google page' unless page.title =~ /Google/
    page
  end

  def next_page_link
    link = @agent.page.search('table#nav td a').last
    if link 
      link[:href]
    else
      :no_more_pages
    end
  end

  def retrieve_next_page
    link = next_page_link
    
    if link == :no_more_pages
      @more_pages = false
      # Cap the page number.
      @page_number = @links.size.div @results_per_page
    else
      get link
      read_links
    end
  end

  def more_pages?; @more_pages end

  # Parse all the links found on the current page.
  def read_links
    results = @agent.page.search 'li.g'
    results.each do |result|
      link = result.search('h3.r a').first
      body = result.search('span.st').first
      # Extract the proper URL from the link, disregarding any that aren't full uris
      # (e.g. google image/video links)
      uri = URI.extract(link[:href]).first

      if uri
        url = uri[/[^\&]*/] # Trim off the trailing crap.
        @links << OpenStruct.new(title: link.text, url: url, body: body.text)
      end
    end
  end

  # Index, in @links, of the first link to show.
  def first_link_index; @page_number * @results_per_page end

  # Index, in @links, of the last link to show.
  def last_link_index
    if more_pages?
      first_link_index + @results_per_page - 1
    else
      @links.size - 1
    end
  end

  # Are we showing the last page?
  def last_page?
    !more_pages? && last_link_index == (@links.size - 1)
  end

  def list_links
    # Ensure we have enough links downloaded to display them.
    retrieve_next_page while last_link_index > @links.size

    first, last = first_link_index + 1, last_link_index + 1

    if first <= last
      num_columns = last.to_s.length

      puts "Page #{@page_number + 1}, showing results #{first} to #{last} for: #{@query}"
      @links[first_link_index..last_link_index].each.with_index(first) do |link, i|
        indent = ' ' * (num_columns + 2)
        puts
        max_width = 80 - indent.size
        puts "#{i.to_s.rjust num_columns}: #{limit_text link.title, max_width}"
        puts "#{indent}#{limit_text link.body, max_width}"
        puts "#{indent}#{link.url}"
      end
    else
      # No joy. Let's try a new search...
      puts "No results for #{@query}!"
      input_new_search
      list_links
    end
  end

  def limit_text(text, length)
    if text.size < length
      text
    else
      text[0, length - 3] + '...'
    end
  end

  def navigate
    # Ask the user for instructions.
    puts

    next_ = last_page? ? '' : 'N/'
    previous = @page_number.zero? ? '' : 'p/'
    print "Enter number of link to browse or [#{next_}#{previous}h/r/s/q]: "
    input = $stdin.gets.strip

    case input.upcase
    when 'N', '' # Next page.
      unless last_page?
        @page_number += 1 
        list_links
      end

    when 'P' # Previous page.
      if @page_number > 0
        @page_number -= 1
        list_links
      end

    when 'H', '?'
      puts <<-END_OF_TEXT

Browser help
------------

N(next) - Next page (default action).
P(revious) - Previous page.
H(elp) - This help message.
R(efresh) - Clear cache and re-load this search on first page.
S(earch) - Enter a new query string.
Q(uit) - Quit the browser.
END_OF_TEXT

    when 'R' # Clear cache completely and get first page again.      
      retrieve_initial_page @query

      list_links

    when 'S' # Search
      input_new_search

      list_links

    when 'Q' # Quit.
      @quit = true

    else # Follow link to page.
      link_index = input.to_i - 1
      if link_index.between? first_link_index, last_link_index
        link = @links[link_index]
        puts
        puts "Navigating to #{link_index}: #{link.title} (#{link.url})"
        puts
        Launchy.open link.url
        puts
      else
        puts "Bad input: #{input}"
      end
    end 

    puts   
  end

  def input_new_search
    input = ''
    while input.empty?
      puts
      print "Enter search string: "
      input = $stdin.gets.strip
    end
    retrieve_initial_page input
  end
end

# ===================================================================

# Manage CLI options.
opts = Slop.parse help: true do
  banner "Usage: #{File.basename $0} [options] ['QUERY-STRING']"

  on 'n=', 'number=', 
    "Number of results per page (default: #{GoogleBrowse::DEFAULT_RESULTS_PER_PAGE})",
    as: Integer, default: GoogleBrowse::DEFAULT_RESULTS_PER_PAGE
end

exit 0 if opts.help?

def cli_error(opts, message)
  puts "ERROR: #{message}"
  puts 
  puts opts
  exit 0
end

cli_error opts, 'Must have 1 or more results per page!' unless opts[:number] >= 1

# BUG: No idea why the -n option STAYS in argv ;(
query = ARGV.empty? ? nil : ARGV.join(" ")

begin
  GoogleBrowse.search query: query, results_per_page: opts[:number]
rescue => ex
  puts
  puts "FATAL ERROR: #{ex.message}"
  puts
  exit 0
end





