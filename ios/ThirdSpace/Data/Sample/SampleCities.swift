extension SampleCity {
    static let all = [losAngeles, sanFrancisco, newYork, chicago, boston, seattle, austin] + nationwideAdditions

    private static let losAngeles = SampleCity(
        name: "Los Angeles", state: "CA", timeZoneID: "America/Los_Angeles",
        places: [
            SamplePlace(
                "Reservoir Roasters", .cafe, street: "Silver Lake Blvd", 34.0870, -118.2690,
                about: "Small-batch coffee roasted in the back room, with a patio that looks out over the hills.",
                events: [
                    SampleEvent(
                        "Cupping Morning", day: 1, at: 9, hours: 1.5, capacity: 12,
                        about: "Taste three new single-origin roasts side by side and learn what to look for."),
                    SampleEvent(
                        "Latte Art Throwdown", day: 9, at: 18.5, hours: 2,
                        about: "Baristas from around the neighborhood go head to head. Come vote for your favorite pour."),
                ]),
            SamplePlace(
                "Junction Taqueria", .restaurant, street: "Sunset Blvd", 34.0907, -118.2790,
                about: "Handmade tortillas, slow-cooked carnitas, and a salsa bar that changes with the seasons.",
                events: [
                    SampleEvent(
                        "Tamale Making Class", day: 5, at: 11, hours: 3, capacity: 16,
                        about: "Mix the masa, fold, and steam your own tamales, then take a dozen home."),
                ]),
            SamplePlace(
                "Hyperion Records & Tapes", .shop, street: "Hyperion Ave", 34.0960, -118.2785,
                about: "Used vinyl, cassettes, and a listening booth tucked in the corner.",
                events: [
                    SampleEvent(
                        "Crate Digging Night", day: 3, at: 19, hours: 3,
                        about: "Fresh used arrivals hit the bins at 7, with local DJs spinning straight from the stacks."),
                    SampleEvent(
                        "Cassette Swap", day: 12, at: 13, hours: 3,
                        about: "Bring the tapes you're done with and leave with ones you've never heard."),
                ]),
            SamplePlace(
                "Clay & Current Studio", .artsStudio, street: "Rowena Ave", 34.1040, -118.2660,
                about: "Open ceramics studio with wheel classes for every level.",
                events: [
                    SampleEvent(
                        "Intro to the Wheel", day: 2, at: 18, hours: 2.5, capacity: 8,
                        about: "Center, open, and pull your first bowl. Clay and firing included."),
                    SampleEvent(
                        "Studio Sale", day: 17, at: 10, hours: 6,
                        about: "Seconds, one-offs, and seasonal pieces straight from studio members."),
                ]),
            SamplePlace(
                "Silver Lake Run Collective", .fitness, street: "Griffith Park Blvd", 34.0985, -118.2745,
                about: "Free community runs around the reservoir. Every pace is welcome.",
                events: [
                    SampleEvent(
                        "Sunrise Reservoir Loop", day: 1, at: 6.5, hours: 1,
                        about: "An easy 2.2-mile loop around the reservoir. Nobody gets left behind."),
                    SampleEvent(
                        "Hill Repeats", day: 4, at: 18, hours: 1, capacity: 25,
                        about: "Short, steep, and social. Walk the downhills and cheer on the uphills."),
                ]),
            SamplePlace(
                "The Junction Commons", .communitySpace, street: "Sunset Blvd", 34.0880, -118.2740,
                about: "A shared room for neighborhood meetups, workshops, and potlucks.",
                events: [
                    SampleEvent(
                        "Neighborhood Potluck", day: 6, at: 17, hours: 3,
                        about: "Bring a dish that means something to you. Plates and music are on us."),
                ]),
        ])

    private static let sanFrancisco = SampleCity(
        name: "San Francisco", state: "CA", timeZoneID: "America/Los_Angeles",
        places: [
            SamplePlace(
                "Valencia Morning Bread", .cafe, street: "Valencia St", 37.7640, -122.4216,
                about: "Sourdough, morning buns, and strong coffee from a tiny corner counter.",
                isYours: true,
                events: [
                    SampleEvent(
                        "Sourdough Starter Clinic", day: 3, at: 10, hours: 2, capacity: 12,
                        about: "Revive a sluggish starter or begin a new one. Everyone leaves with a jar."),
                ]),
            SamplePlace(
                "Dolores Social Club", .bar, street: "18th St", 37.7615, -122.4250,
                about: "Cocktail bar a block from the park, with a rotating guest bartender.",
                events: [
                    SampleEvent(
                        "Pub Quiz Night", day: 2, at: 20, hours: 2,
                        about: "Teams of up to six. Winners pick the next guest cocktail."),
                    SampleEvent(
                        "Guest Shift: Mezcal Menu", day: 11, at: 18, hours: 4,
                        about: "A visiting bartender takes over with a one-night mezcal menu."),
                ]),
            SamplePlace(
                "Mission Screen & Mural", .artsStudio, street: "24th St", 37.7527, -122.4150,
                about: "Print and mural studio teaching screen printing and street art.",
                events: [
                    SampleEvent(
                        "Screen Print a Tote", day: 5, at: 14, hours: 2, capacity: 10,
                        about: "Design, burn, and print your own tote bag in one afternoon."),
                    SampleEvent(
                        "Mural Walk", day: 8, at: 11, hours: 1.5,
                        about: "A guided walk past the neighborhood's murals with the artists who painted them."),
                ]),
            SamplePlace(
                "Casa Nopal", .restaurant, street: "Mission St", 37.7600, -122.4190,
                about: "Family-run kitchen serving Oaxacan moles and crisp tlayudas.",
                events: [
                    SampleEvent(
                        "Mole Tasting Night", day: 7, at: 18.5, hours: 2.5, capacity: 30,
                        about: "Five moles, five stories. Taste family recipes three generations in the making."),
                ]),
            SamplePlace(
                "Guerrero Street Cycles", .services, street: "Guerrero St", 37.7590, -122.4235,
                about: "Bike repair and tune-ups, plus a free fix-it bench on weekends.",
                events: [
                    SampleEvent(
                        "Fix Your Flat Clinic", day: 4, at: 10, hours: 2,
                        about: "Learn to patch a tube and true a wheel. Tools and coffee provided."),
                ]),
            SamplePlace(
                "Dolores Park Chess Club", .other, street: "Dolores St", 37.7580, -122.4262,
                about: "Open chess tables on the edge of the park. Boards provided, all levels welcome.",
                events: [
                    SampleEvent(
                        "Blitz Tournament", day: 6, at: 13, hours: 3, capacity: 32,
                        about: "Five-minute games, bracket style. Bring your fastest openings."),
                    SampleEvent(
                        "Beginner Lessons", day: 13, at: 11, hours: 1.5,
                        about: "Learn how the pieces move and play your first full game."),
                ]),
        ])

    private static let newYork = SampleCity(
        name: "Brooklyn", state: "NY", timeZoneID: "America/New_York",
        places: [
            SamplePlace(
                "Bedford Bean Bar", .cafe, street: "Bedford Ave", 40.7178, -73.9573,
                about: "Espresso bar by day, with a record player and window seats that fill up fast.",
                events: [
                    SampleEvent(
                        "Open Mic Coffeehouse", day: 2, at: 19, hours: 2.5,
                        about: "Songs, poems, and stories. Sign up at the counter for a ten-minute slot."),
                ]),
            SamplePlace(
                "Wythe Street Pizza Lab", .restaurant, street: "Wythe Ave", 40.7205, -73.9598,
                about: "Naturally leavened pies from a wood-fired oven, plus a late-night slice window.",
                events: [
                    SampleEvent(
                        "Pizza Dough 101", day: 6, at: 15, hours: 2, capacity: 12,
                        about: "Mix, stretch, and bake your own pie, then take home a ball of dough."),
                ]),
            SamplePlace(
                "Northside Climbing Co.", .fitness, street: "N 6th St", 40.7196, -73.9578,
                about: "Bouldering gym with first-timer classes and a rooftop training deck.",
                events: [
                    SampleEvent(
                        "First-Timer Bouldering", day: 1, at: 18, hours: 1.5, capacity: 12,
                        about: "Shoes, chalk, and a coach included. Leave knowing how to read a route."),
                    SampleEvent(
                        "Community Comp", day: 14, at: 12, hours: 5,
                        about: "A friendly bouldering competition with categories for every level."),
                ]),
            SamplePlace(
                "Kent Avenue Flea", .shop, street: "Kent Ave", 40.7215, -73.9615,
                about: "Weekend market for vintage clothes, furniture, and local makers.",
                events: [
                    SampleEvent(
                        "Vintage Market", day: 3, at: 10, hours: 7,
                        about: "Forty vendors of vintage clothing, furniture, and oddities."),
                    SampleEvent(
                        "Makers Night Market", day: 10, at: 17, hours: 5,
                        about: "Local makers, food stalls, and live music by the water."),
                ]),
            SamplePlace(
                "Driggs Riso Press", .artsStudio, street: "Driggs Ave", 40.7155, -73.9545,
                about: "Risograph studio with open press hours and zine workshops.",
                events: [
                    SampleEvent(
                        "Make a Zine in a Day", day: 5, at: 12, hours: 4, capacity: 14,
                        about: "Write, lay out, and print a short zine on the riso, start to finish."),
                ]),
            SamplePlace(
                "Metropolitan Mending Co.", .services, street: "Metropolitan Ave", 40.7143, -73.9560,
                about: "Alterations and repairs while you wait, plus mending classes.",
                events: [
                    SampleEvent(
                        "Visible Mending Workshop", day: 8, at: 18.5, hours: 2, capacity: 10,
                        about: "Turn holes into patterns with sashiko and darning. Bring something worn."),
                ]),
            SamplePlace(
                "Grand Street Sound", .bar, street: "Grand St", 40.7130, -73.9590,
                about: "Listening bar with a hi-fi system and a natural wine list.",
                events: [
                    SampleEvent(
                        "Album Night", day: 4, at: 20, hours: 3,
                        about: "A classic album played front to back on the big system. Phones down, volume up."),
                ]),
        ])

    private static let chicago = SampleCity(
        name: "Chicago", state: "IL", timeZoneID: "America/Chicago",
        places: [
            SamplePlace(
                "Six Corners Coffee", .cafe, street: "Milwaukee Ave", 41.9095, -87.6765,
                about: "Corner coffee shop at the busiest intersection in the neighborhood.",
                events: [
                    SampleEvent(
                        "Coffee & Sketch", day: 2, at: 9, hours: 2, category: .artsStudio,
                        about: "Bring a sketchbook. We'll set up still lifes and keep the refills coming."),
                ]),
            SamplePlace(
                "Damen Avenue Deli", .restaurant, street: "Damen Ave", 41.9060, -87.6775,
                about: "Italian beef, house-made giardiniera, and a new sandwich every week.",
                events: [
                    SampleEvent(
                        "Giardiniera Pickling Class", day: 9, at: 14, hours: 2, capacity: 12,
                        about: "Chop, brine, and jar a batch of the house giardiniera to take home."),
                ]),
            SamplePlace(
                "Blue Line Books", .shop, street: "Milwaukee Ave", 41.9075, -87.6735,
                about: "Independent bookstore with a big poetry section and a reading nook upstairs.",
                events: [
                    SampleEvent(
                        "Poetry Open Mic", day: 3, at: 19, hours: 2,
                        about: "Five minutes at the mic. Read your own work or a poem you love."),
                    SampleEvent(
                        "Author Reading & Signing", day: 15, at: 18.5, hours: 1.5, capacity: 40,
                        about: "A local novelist reads from their new book, followed by a signing."),
                ]),
            SamplePlace(
                "North Avenue Boxing Club", .fitness, street: "North Ave", 41.9104, -87.6800,
                about: "Boxing and conditioning classes for every level. Gloves provided.",
                events: [
                    SampleEvent(
                        "Intro to Boxing", day: 1, at: 18, hours: 1, capacity: 16,
                        about: "Stance, footwork, and your first combinations. No experience needed."),
                ]),
            SamplePlace(
                "Wicker Park Neighbors Hall", .communitySpace, street: "Wood St", 41.9080, -87.6720,
                about: "Community room hosting block club meetings, swaps, and classes.",
                events: [
                    SampleEvent(
                        "Plant & Seed Swap", day: 5, at: 11, hours: 3,
                        about: "Bring cuttings, seeds, or pots and trade with your neighbors."),
                    SampleEvent(
                        "Block Club Meeting", day: 12, at: 18.5, hours: 1.5,
                        about: "Hear what's happening on your block and help plan the next street fair."),
                ]),
            SamplePlace(
                "Division Street Jazz Room", .bar, street: "Division St", 41.9033, -87.6740,
                about: "Low-lit bar with live jazz every night and no cover before 9.",
                events: [
                    SampleEvent(
                        "Late Night Jam Session", day: 2, at: 21, hours: 3,
                        about: "The house trio starts at 9. Players sign up to sit in after the first set."),
                ]),
        ])

    private static let boston = SampleCity(
        name: "Boston", state: "MA", timeZoneID: "America/New_York",
        places: [
            SamplePlace(
                "Union Park Coffee", .cafe, street: "Tremont St", 42.3440, -71.0720,
                about: "Neighborhood coffee shop with pastries from bakers down the block.",
                events: [
                    SampleEvent(
                        "Pour-Over Basics", day: 4, at: 10, hours: 1.5, capacity: 10,
                        about: "Dial in grind, ratio, and pour. Leave able to brew a great cup at home."),
                ]),
            SamplePlace(
                "Tremont Table", .restaurant, street: "Tremont St", 42.3415, -71.0760,
                about: "Seasonal New England plates served at one long communal table.",
                events: [
                    SampleEvent(
                        "Chef's Communal Supper", day: 7, at: 18.5, hours: 2.5, capacity: 24,
                        about: "One long table, five courses, and a room full of new neighbors."),
                ]),
            SamplePlace(
                "Harrison Avenue Makers Loft", .artsStudio, street: "Harrison Ave", 42.3395, -71.0665,
                about: "Shared studios for painters, jewelers, and woodworkers, with open studios every month.",
                events: [
                    SampleEvent(
                        "Open Studios Night", day: 3, at: 17, hours: 4,
                        about: "Wander the loft, meet the artists, and see work in progress."),
                    SampleEvent(
                        "Intro to Jewelry Making", day: 10, at: 18, hours: 2, capacity: 8,
                        about: "Saw, file, and solder a simple silver ring to take home."),
                ]),
            SamplePlace(
                "Columbus Cycle Studio", .fitness, street: "Columbus Ave", 42.3450, -71.0765,
                about: "Indoor cycling and strength classes set to live DJ sets.",
                events: [
                    SampleEvent(
                        "DJ Ride", day: 1, at: 18.5, hours: 1, capacity: 30,
                        about: "Forty-five minutes of climbs and sprints to a live DJ set."),
                ]),
            SamplePlace(
                "Shawmut Stitch & Repair", .services, street: "Shawmut Ave", 42.3428, -71.0705,
                about: "Shoe and leather repair, key cutting, and sewing machine rentals.",
                events: [
                    SampleEvent(
                        "Leather Care Workshop", day: 6, at: 11, hours: 1.5, capacity: 10,
                        about: "Clean, condition, and waterproof your boots and bags."),
                ]),
            SamplePlace(
                "South End Library of Things", .communitySpace, street: "Washington St", 42.3405, -71.0690,
                about: "Borrow tools, camping gear, and board games with a free membership.",
                events: [
                    SampleEvent(
                        "Board Game Night", day: 2, at: 18, hours: 3, category: .other,
                        about: "Pick from over two hundred games, with teachers on hand for anything new."),
                    SampleEvent(
                        "Repair Café", day: 13, at: 10, hours: 3, category: .services,
                        about: "Volunteers help you fix lamps, toasters, and torn jackets for free."),
                ]),
        ])

    private static let seattle = SampleCity(
        name: "Seattle", state: "WA", timeZoneID: "America/Los_Angeles",
        places: [
            SamplePlace(
                "Broadway Brew Lab", .cafe, street: "Broadway E", 47.6215, -122.3210,
                about: "Experimental coffee bar pouring cold brew flights and seasonal tonics.",
                events: [
                    SampleEvent(
                        "Cold Brew Flight Tasting", day: 2, at: 14, hours: 1.5, capacity: 12,
                        about: "Four cold brews, four brewing methods. Taste how much the process matters."),
                ]),
            SamplePlace(
                "Pike Pine Noodle House", .restaurant, street: "E Pike St", 47.6140, -122.3180,
                about: "Hand-pulled noodles and late-night bowls.",
                events: [
                    SampleEvent(
                        "Hand-Pulled Noodle Demo", day: 5, at: 17, hours: 1, capacity: 20,
                        about: "Watch the chef stretch dough into noodles, then eat what they make."),
                ]),
            SamplePlace(
                "Olive Way Outfitters", .shop, street: "E Olive Way", 47.6185, -122.3255,
                about: "Rain gear, packs, and trail maps, plus free weekend hike meetups.",
                events: [
                    SampleEvent(
                        "Trail Meetup", day: 3, at: 8, hours: 5, category: .fitness,
                        about: "Carpool from the shop to a moderate trail and be back by early afternoon."),
                ]),
            SamplePlace(
                "Cal Anderson Yoga", .fitness, street: "12th Ave", 47.6125, -122.3165,
                about: "Donation-based yoga, with classes outside in the park when it's dry.",
                events: [
                    SampleEvent(
                        "Park Yoga Flow", day: 1, at: 7.5, hours: 1,
                        about: "An hour of flow on the grass. Bring a mat or borrow one of ours."),
                    SampleEvent(
                        "Candlelight Yin", day: 8, at: 19.5, hours: 1.25, capacity: 20,
                        about: "Slow, deep stretches in a room lit only by candles."),
                ]),
            SamplePlace(
                "Pine Street Comedy Cellar", .bar, street: "E Pine St", 47.6152, -122.3200,
                about: "Basement bar with stand-up most nights and an open mic for first-timers.",
                events: [
                    SampleEvent(
                        "New Voices Open Mic", day: 2, at: 20, hours: 2,
                        about: "Five minutes each for first-time and newer comics. Be kind, laugh loud."),
                    SampleEvent(
                        "Headliner Showcase", day: 9, at: 21, hours: 2, capacity: 80,
                        about: "Four touring comics, with a local favorite closing the night."),
                ]),
            SamplePlace(
                "Hill Collective Gallery", .artsStudio, street: "15th Ave E", 47.6245, -122.3125,
                about: "Artist-run gallery showing work by artists who live on the Hill.",
                events: [
                    SampleEvent(
                        "First Look Opening", day: 11, at: 18, hours: 3,
                        about: "Opening night for the new group show, with the artists in the room."),
                ]),
        ])

    private static let austin = SampleCity(
        name: "Austin", state: "TX", timeZoneID: "America/Chicago",
        places: [
            SamplePlace(
                "East Side Grind", .cafe, street: "E 6th St", 30.2638, -97.7300,
                about: "Coffee, breakfast tacos, and a shaded patio that's busy from 7am.",
                events: [
                    SampleEvent(
                        "Morning Makers Meetup", day: 3, at: 8, hours: 1.5, category: .other,
                        about: "Freelancers and founders trade ideas over coffee. No pitches, just people."),
                ]),
            SamplePlace(
                "Chicon Street Smokehouse", .restaurant, street: "Chicon St", 30.2660, -97.7220,
                about: "Post oak-smoked brisket, sold until it's gone.",
                events: [
                    SampleEvent(
                        "Backyard BBQ Class", day: 6, at: 10, hours: 4, capacity: 15,
                        about: "Trim, rub, and smoke a brisket with the pitmaster. Lunch included."),
                ]),
            SamplePlace(
                "Riverbend Paddle Co.", .fitness, street: "E Cesar Chavez St", 30.2585, -97.7280,
                about: "Paddleboard rentals and guided tours on the lake.",
                events: [
                    SampleEvent(
                        "Sunset Paddle", day: 2, at: 19, hours: 1.5, capacity: 12,
                        about: "A guided paddle toward downtown as the sun goes down. Boards included."),
                ]),
            SamplePlace(
                "Twelfth Street Letterpress", .artsStudio, street: "E 12th St", 30.2725, -97.7260,
                about: "Letterpress studio known for hand-set gig posters.",
                events: [
                    SampleEvent(
                        "Gig Poster Workshop", day: 7, at: 13, hours: 3, capacity: 10,
                        about: "Hand-set the type and pull your own two-color gig poster."),
                ]),
            SamplePlace(
                "Sixth Street Two-Step Hall", .bar, street: "E 6th St", 30.2625, -97.7235,
                about: "Dance hall with free two-step lessons before the band goes on.",
                events: [
                    SampleEvent(
                        "Free Two-Step Lesson", day: 1, at: 19, hours: 1,
                        about: "Learn the basics in an hour, then stay and dance to the band."),
                    SampleEvent(
                        "Live Country Night", day: 4, at: 20.5, hours: 3,
                        about: "A local honky-tonk band plays two sets. The dance floor opens at 8:30."),
                ]),
            SamplePlace(
                "Eleventh Street Market Hall", .shop, street: "E 11th St", 30.2695, -97.7295,
                about: "Covered market of local growers, bakers, and makers.",
                events: [
                    SampleEvent(
                        "Growers Market", day: 3, at: 9, hours: 4,
                        about: "Produce, eggs, and flowers from farms within an hour of the city."),
                    SampleEvent(
                        "Night Market", day: 16, at: 18, hours: 4,
                        about: "Makers, food trucks, and string lights under the market roof."),
                ]),
        ])
}
