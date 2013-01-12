# Google search CLI browser that can open links into a browser.
module GoogleBrowse
  class Scraper
    BASE_PAGE = 'http://google.com'
    RESULTS_PER_REQUEST = 100 # TODO: Use this! &num=100?

    attr_reader :query
    def num_links; @links.size; end
    def more_pages?; @more_pages end

    # @option :query [String] Initial search string.
    def initialize(query)      
      @links = [] # All the links retrieved are cached here.
      @agent = Mechanize.new do |agent|
        agent.max_history = 1 # We cache the important data ourselves.
        agent.user_agent = 'Safari' # And why not?
        agent.user_agent_alias = 'Mac Safari' # And why not?
        agent.keep_alive = false
      end

      self.query = query
    end

    # Set the search query string.
    def query=(text)
      retrieve_initial_page text
    end

    # @param index [Integer, Range]
    def [](index)
      case index
      when Integer
        retrieve_next_page while more_pages? and index > @links.size 
        @links[index]

      when Range
        retrieve_next_page while more_pages? and index.max > @links.size
        @links[index]

      else
        raise TypeError, "Expected Integer or Range"
      end
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
    # Index, in @links, of the last link to show.
    def last_link_index
      if more_pages?
        first_link_index + @results_per_page - 1
      else
        @links.size - 1
      end
    end
  end
end





