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

  def initialize(query, options = {})
    options = {
      results_per_page: 10,
    }.merge! options

    @query = query
    @results_per_page = options[:results_per_page]
    
    @links = [] # All the links retrieved are cached here.
    @agent = Mechanize.new

    retrieve_initial_page
    list_links
  end

  def retrieve_initial_page
    # Go to Google home page and create an initial query.
    google = @agent.get 'http://google.com'
    query_form = google.form_with name: 'f'
    query_form.q = @query

    query_form.submit query_form.button_with(name: 'btnK')
    @page_number = 1 # Page number starts from 1 for sense.
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
    page = @agent.get next_page_link

    if page == :no_more_pages
      :no_more_pages
    else
      read_links
    end
  end

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

  def first_link_index; (@page_number - 1) * @results_per_page end
  def last_link_index; first_link_index + @results_per_page - 1 end

  def list_links
    # Ensure we have enough links downloaded to display them.
    retrieve_next_page while last_link_index > @links.size

    first, last = first_link_index + 1, last_link_index + 1

    num_columns = last.to_s.length

    puts "Page #{@page_number}, showing results #{first} to #{last} for '#{@query}'"
    @links[first_link_index..last_link_index].each.with_index(first) do |link, i|
      puts
      puts "#{i.to_s.rjust num_columns}: #{link.title}"
      puts "#{' ' * num_columns}  #{link.url}"
    end

    navigate
    list_links
  end

  def navigate
    # Ask the user for instructions.
    puts

    previous = @page_number == 1 ? '' : 'P(revious)/'
    print "Enter number of link to browse or N(ext)/#{previous}R(efresh)/Q(uit): "
    input = $stdin.gets.strip

    case input
    when 'N', 'n', '' # Next page.
      @page_number += 1

    when 'P', 'p' # Previous page.
      @page_number -= 1 if @page_number > 1

    when 'R', 'r' # Clear cache completely and get first page again.      
      @links.clear
      retrieve_initial_page

    when 'Q', 'q' # Quit.
      puts
      exit

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

GBrowser.search "cheese", results_per_page: opts[:number]





