# Google search CLI browser that can open links into a browser.

require 'uri'
require 'ostruct'

module GoogleBrowse
  class << self
    def search(*args); Browser.new *args; end
  end

  class Browser
    DEFAULT_RESULTS_PER_PAGE = 10
    MAX_RESULTS_PER_PAGE = 20 # Avoid being rude to Google.
    BASE_PAGE = 'http://google.com'
    RESULTS_PER_REQUEST = 100 # TODO: Use this! &num=100?

    class << self
      def search(*args); new *args; end
    end

    # @option :results_per_page [Integer] (10) Number of results to show per page.
    # @option :query [String] Initial search string.
    def initialize(options = {})
      options = {
        results_per_page: 10,
      }.merge! options

      @results_per_page = [
          [0, options[:results_per_page]].max,
          MAX_RESULTS_PER_PAGE
      ].min
      
      @links = [] # All the links retrieved are cached here.
      @agent = Mechanize.new do |agent|
        agent.max_history = 1 # We cache the important data ourselves.
        agent.user_agent = 'Safari' # And why not?
        agent.user_agent_alias = 'Mac Safari' # And why not?
        agent.keep_alive = false
      end

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

    protected
    def retrieve_initial_page(query)
      @query = query
      @links.clear

      # Go to Google home page and create an initial query.
      get BASE_PAGE
      query_form = @agent.page.form_with name: /f/
      
      # Make the search.
      query_form.q = @query

      query_form.submit query_form.button_with(name: 'btnK')

      @page_number = 0
      @more_pages = true

      parse_links
    end

    protected
    def get(page)
      @agent.get page
    rescue Net::HTTPServiceUnavailable
      puts
      puts "ERROR: HTTPServiceUnavailable"
      puts "Google has probably temporarily banned you for being a bad bot."
      puts "You may need to complete a capture on Google to unlock it (AND THEN STOP USING THIS SCRIPT!)."
      Launchy.open BASE_PAGE
      @quit = true     
    end

    protected
    def next_page_link
      link = @agent.page.search('table#nav td a').last
      if link 
        link[:href]
      else
        :no_more_pages
      end
    end

    protected
    def retrieve_next_page
      link = next_page_link
      
      if link == :no_more_pages
        @more_pages = false
        # Cap the page number.
        @page_number = @links.size.div @results_per_page
      else
        get link
        parse_links
      end
    end

    protected
    # Parse all the links found on the current page.
    def parse_links
      results = @agent.page.search 'li.g'
      results.each do |result|
        # May be youtube or google images/video links, so ignore these.
        link = result.search('h3.r a').first
        next unless link

        body = result.search('span.st').first || OpenStruct.new(text: '')

        # Extract the proper URL from the link, disregarding any that aren't full uris
        # (e.g. google image/video links)
        uri = URI.extract(link[:href]).first

        if uri
          url = uri[/[^\&]*/] # Trim off the trailing crap.
          @links << OpenStruct.new(title: link.text, url: url, body: body.text)
        end
      end
    end

    protected
    def quit?; @quit end
    def more_pages?; @more_pages end
    # Index, in @links, of the first link to show.
    def first_link_index; @page_number * @results_per_page end

    protected
    # Index, in @links, of the last link to show.
    def last_link_index
      if more_pages?
        first_link_index + @results_per_page - 1
      else
        @links.size - 1
      end
    end

    protected
    # Are we showing the last page?
    def last_page?
      !more_pages? && last_link_index == (@links.size - 1)
    end

    protected
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

    protected
    def limit_text(text, length)
      if text.size < length
        text
      else
        text[0, length - 3] + '...'
      end
    end

    protected
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

    protected
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
end





