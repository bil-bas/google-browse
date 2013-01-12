Google-Browse
=============

This is a very simple text browser which aids in searching and navigating on Google.com. Shows results as a simple list, any of which may be opened in a full
browser.

Not really intended for real use, since it is only really a toy.

WARNING: Used excessively, this tool may get Google locking you out thinking that you are an evil scraper bot! Be careful!

Installation
------------

Add this line to your application's Gemfile:

    gem 'google-browse'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google-browse

Usage
-----

    The gem provides a single command which starts the text search browser:

    $ google-browse

    $ google-browse -q "spooner github"

Example output
--------------

    $ google-browse -q fish

    Google Browse v0.1.3


    Page 1, showing results 1 to 5 for: fish
    ________________________________________

    1: Fish - Wikipedia, the free encyclopedia
       A fish is any member of a paraphyletic group of organisms that consist of ...
       http://en.wikipedia.org/wiki/Fish

    2: Official Fish site
       Official site for Fish: writer, actor and vocalist. Extensive information ...
       http://www.fish-thecompany.com/

    3: Clever Bird Goes Fishing - YouTube
       Sign in with your YouTube Account (YouTube, Google+, Gmail, Orkut, Picasa,...
       http://www.youtube.co.uk/watch?v=uBuPiC3ArL8

    4: Robot Fish - YouTube
       For more cool animal videos http://ow.ly/7v79B ...
       http://www.youtube.com/watch?v=eO9oseiCTdk

    5: Fish! | Fish Kitchen! | Jarvis » Fish Kitchen Group
       Celebrity restaurateur Tony Allan started the fish! empire when he opened ...
       http://www.fishkitchen.com/


    Enter number of link to browse or [N/h/s/q]: n

    Page 2, showing results 6 to 10 for: fish
    _________________________________________

     6: Fish | Life and style | The Guardian
        Latest news and comment on Fish from guardian.co.uk.
        http://www.guardian.co.uk/lifeandstyle/fish

     7: Pet Fish Supplies for Sale at Pets At Home: Fish Pond Supplies, Fish ...
        Buy fish products from Pets at Home, the UK's largest pet shop, with fast...
        http://www.petsathome.com/shop/fish/

     8: Fish recipes | Salmon recipes, fish stew & more | Jamie Oliver recipes
        Good fresh fish smells of the sea and is packed full of good stuff. Check...
        http://www.jamieoliver.com/recipes/fish-recipes

     9: Hugh's Fish Fight - Half of all fish caught in the North Sea is thrown ...
        Half of all fish caught in the North Sea is thrown back overboard dead. B...
        http://www.fishfight.net/

    10: Grafixation web design and business services - Welcome to our site
        Grafixation: specialists in web design, graphics, site renovation, promot...
        http://www.the-company.com/


    Enter number of link to browse or [N/p/h/s/q]: s

    Enter search string: frog

    Page 1, showing results 1 to 5 for: frog
    ________________________________________

    1: Frog - Wikipedia, the free encyclopedia
       Frogs are a diverse and largely carnivorous group of short-bodied,  taille...
       http://en.wikipedia.org/wiki/Frog

    2: Frog Learning Platform | The UKs most advanced Learning Platform
       'Frog is like a Lego® kit that allows users to build most things that can ...
       http://www.frogtrade.com/

    3: frog
       We are a global innovation firm. We help create and bring to market meanin...
       http://www.frogdesign.com/

    4: Frog Song - YouTube
       ... to add danielinvt's video to your playlist. Sign in. Statistics Report...
       http://www.youtube.com/watch?v=lfFGXG2-6kg

    5: Frog VLE Nonsuch
       To log in to the Nonsuch Learning Environment enter your username and pass...
       http://www.nonsuch.sutton.sch.uk/


    Enter number of link to browse or [N/h/s/q]: 4

    ((Opens Frog Song Youtube video in default browser))


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
