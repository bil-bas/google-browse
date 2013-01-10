# Google search CLI browser that can open links into a browser.

require 'uri'
require 'ostruct'

require 'bundler'
Bundler.require :default

class GBrowser
  DEFAULT_RESULTS_PER_PAGE = 10

  class << self
    private :new
    def search(*args); new *args; end
  end

  def quit?; @quit end

  def initialize(query, options = {})
    options = {
      results_per_page: 10,
    }.merge! options

    @results_per_page = options[:results_per_page]
    
    @links = [] # All the links retrieved are cached here.
    @agent = Mechanize.new

    retrieve_initial_page query

    @quit = false

    begin
      list_links
      navigate
    end until quit?
  end

  def retrieve_initial_page(query)
    @query = query
    @links.clear

    # Go to Google home page and create an initial query.
    google = @agent.get 'http://google.com'
    query_form = google.form_with name: 'f'
    query_form.q = @query

    query_form.submit query_form.button_with(name: 'btnK')
    @page_number = 1 # Page number starts from 1 for sense.
    @more_pages = true

    read_links
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
    else
      page = @agent.get link
      read_links
    end
  end

  def more_pages?; @more_pages end

  # Parse all the links found on the current page.
  def read_links
    query_links = @agent.page.search "h3.r a"
    query_links.each do |link|
      # Extract the proper URL from the link, disregarding any that aren't full uris
      # (e.g. google image/video links)
      uri = URI.extract(link[:href]).first

      if uri
        url = uri[/[^\&]*/] # Trim off the trailing crap.
        @links << OpenStruct.new(title: link.text, url: url)
      end
    end
  end

  # Index, in @links, of the first link to show.
  def first_link_index; (@page_number - 1) * @results_per_page end

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

    num_columns = last.to_s.length

    puts "Page #{@page_number}, showing results #{first} to #{last} for: #{@query}"
    @links[first_link_index..last_link_index].each.with_index(first) do |link, i|
      puts
      puts "#{i.to_s.rjust num_columns}: #{link.title}"
      puts "#{' ' * num_columns}  #{link.url}"
    end
  end

  def navigate
    # Ask the user for instructions.
    puts

    next_ = last_page? ? '' : 'N(ext)/'
    previous = @page_number == 1 ? '' : 'P(revious)/'
    print "Enter number of link to browse or #{next_}#{previous}R(efresh)/S(earch)/Q(uit): "
    input = $stdin.gets.strip

    case input.upcase
    when 'N', '' # Next page.
      @page_number += 1

    when 'P' # Previous page.
      @page_number -= 1 if @page_number > 1

    when 'R' # Clear cache completely and get first page again.      
      retrieve_initial_page @query

    when 'S' # Search
      input_new_search

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
      print "Enter new search string: "
      input = $stdin.gets.strip
    end
    retrieve_initial_page input
  end
end

# ===================================================================

# Manage CLI options.
opts = Slop.parse help: true do
  banner "Usage: #{File.basename $0} [options] 'QUERY-STRING'"

  on 'n=', 'number=', 
    "Number of results per page (default: #{GBrowser::DEFAULT_RESULTS_PER_PAGE})",
    as: Integer, default: GBrowser::DEFAULT_RESULTS_PER_PAGE
end

exit 0 if opts.help?

def cli_error(opts, message)
  puts "ERROR: #{message}"
  puts 
  puts opts
  exit 0
end

cli_error opts, 'Query string is required!' if ARGV.empty?
cli_error opts, 'Must have 1 or more results per page!' unless opts[:number] >= 1

query = ARGV.join " "

GBrowser.search query, results_per_page: opts[:number]





