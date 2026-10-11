"""Geo data and tourist places per destination.

Coordinates are approximate. Distances are straight-line from the destination
centre (not driving distance). Replace this module with a live provider later,
see providers.py.
"""

# lat/lng of the destination centre, one-way road distance from a major Indian
# city (None = overseas), and the travel modes that make sense there.
GEO = {
    "bali":      {"lat": -8.5069,  "lng": 115.2625, "road_km": None, "modes": ["flight"]},
    "santorini": {"lat": 36.4167,  "lng": 25.4326,  "road_km": None, "modes": ["flight"]},
    "maldives":  {"lat": 4.1755,   "lng": 73.5093,  "road_km": None, "modes": ["flight"]},
    "kyoto":     {"lat": 34.9858,  "lng": 135.7588, "road_km": None, "modes": ["flight"]},
    "jaipur":    {"lat": 26.9124,  "lng": 75.7873,  "road_km": 600,  "modes": ["train", "flight", "bus", "car"]},
    "cusco":     {"lat": -13.5320, "lng": -71.9675, "road_km": None, "modes": ["flight"]},
    "banff":     {"lat": 51.1784,  "lng": -115.5708, "road_km": None, "modes": ["flight"]},
    "ladakh":    {"lat": 34.1526,  "lng": 77.5771,  "road_km": 1000, "modes": ["flight", "bus", "car"]},
}


def _p(id, name, category, description, lat, lng, popularity, image_url=None):
    return {"id": id, "name": name, "category": category,
            "description": description, "lat": lat, "lng": lng,
            "popularity": popularity, "image_url": image_url}


PLACES = {
    "bali": [
        _p("tegallalang", "Tegallalang Rice Terraces", "Nature", "Stepped rice paddies north of Ubud, best early in the morning.", -8.4312, 115.2796, 90, "https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=600&q=80"),
        _p("monkey-forest", "Sacred Monkey Forest Sanctuary", "Nature", "Forest sanctuary with temples and free-roaming macaques.", -8.5190, 115.2588, 85, "https://images.unsplash.com/photo-1540573133985-87b6da6d54a9?w=600&q=80"),
        _p("tirta-empul", "Tirta Empul Temple", "Religious", "Water temple known for its purification pools.", -8.4153, 115.3153, 80, "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600&q=80"),
        _p("uluwatu", "Uluwatu Temple", "Religious", "Clifftop sea temple, famous for sunsets and kecak dance.", -8.8291, 115.0849, 92, "https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=600&q=80"),
        _p("seminyak", "Seminyak Beach", "Beaches", "Wide sandy beach with beach clubs and sunset bars.", -8.6913, 115.1585, 78, "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80"),
    ],
    "santorini": [
        _p("oia", "Oia Village", "Historical", "Cliffside village of white lanes and blue domes, famous for sunsets.", 36.4618, 25.3753, 98, "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600&q=80"),
        _p("akrotiri", "Akrotiri Archaeological Site", "Historical", "Bronze Age town preserved under volcanic ash.", 36.3519, 25.4033, 80, "https://images.unsplash.com/photo-1533105079780-92b9be482077?w=600&q=80"),
        _p("red-beach", "Red Beach", "Beaches", "Beach framed by red volcanic cliffs.", 36.3483, 25.3945, 82, "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80"),
        _p("perissa", "Perissa Beach", "Beaches", "Long black-sand beach with tavernas along the shore.", 36.3585, 25.4739, 75, "https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?w=600&q=80"),
        _p("santo-wines", "Santo Wines Winery", "Food", "Winery with caldera views and local wine tastings.", 36.3787, 25.4228, 70, "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=600&q=80"),
    ],
    "maldives": [
        _p("hulhumale", "Hulhumale Beach", "Beaches", "Easygoing city beach with cafes and water sports.", 4.2105, 73.5400, 80, "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80"),
        _p("hukuru-miskiy", "Hukuru Miskiy (Old Friday Mosque)", "Religious", "17th-century coral stone mosque in Male.", 4.1757, 73.5108, 70, "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=600&q=80"),
        _p("fish-market", "Male Local Fish Market", "Food", "Busy morning market with the day's tuna catch.", 4.1767, 73.5171, 65, "https://images.unsplash.com/photo-1534482421-64566f976cfa?w=600&q=80"),
        _p("national-museum", "National Museum", "Historical", "Royal artefacts and Maldivian history in Sultan Park.", 4.1750, 73.5097, 60, "https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=600&q=80"),
        _p("maafushi", "Maafushi Island", "Adventure", "Local island popular for snorkelling and diving trips.", 3.9419, 73.4908, 85, "https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=600&q=80"),
    ],
    "kyoto": [
        _p("fushimi-inari", "Fushimi Inari Shrine", "Religious", "Thousands of red torii gates winding up a forested hill.", 34.9671, 135.7727, 98, "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600&q=80"),
        _p("kinkakuji", "Kinkaku-ji (Golden Pavilion)", "Historical", "Zen temple covered in gold leaf beside a mirror pond.", 35.0394, 135.7292, 92, "https://images.unsplash.com/photo-1578637387939-43c525550085?w=600&q=80"),
        _p("arashiyama", "Arashiyama Bamboo Grove", "Nature", "Tall bamboo path on Kyoto's western edge.", 35.0170, 135.6713, 90, "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=600&q=80"),
        _p("nishiki", "Nishiki Market", "Food", "Narrow covered market with snacks and local produce.", 35.0050, 135.7646, 82, "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&q=80"),
        _p("kiyomizu", "Kiyomizu-dera", "Religious", "Hillside temple with a wooden stage and city views.", 34.9949, 135.7850, 94, "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600&q=80"),
    ],
    "jaipur": [
        _p("amber-fort", "Amber Fort", "Historical", "Hilltop fort-palace with courtyards and mirrored halls.", 26.9855, 75.8513, 95, "https://images.unsplash.com/photo-1603288967324-4f40f0c053c0?w=600&q=80"),
        _p("hawa-mahal", "Hawa Mahal", "Historical", "The honeycomb 'Palace of Winds' on the old city's main street.", 26.9239, 75.8267, 90, "https://images.unsplash.com/photo-1599661046289-e31897846e41?w=600&q=80"),
        _p("city-palace", "City Palace", "Historical", "Royal complex with museums and courtyards.", 26.9258, 75.8237, 80, "https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=600&q=80"),
        _p("johari-bazaar", "Johari Bazaar", "Shopping", "Old-city market for jewellery, textiles and block prints.", 26.9190, 75.8266, 75, "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=600&q=80"),
        _p("nahargarh", "Nahargarh Fort", "Nature", "Ridge-top fort known for sunset views over the city.", 26.9372, 75.8153, 78, "https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?w=600&q=80"),
    ],
    "cusco": [
        _p("sacsayhuaman", "Sacsayhuaman", "Historical", "Massive Inca stone walls above the city.", -13.5088, -71.9817, 90, "https://images.unsplash.com/photo-1526392060635-9d6019884377?w=600&q=80"),
        _p("qorikancha", "Qorikancha", "Religious", "Inca sun temple with a colonial convent built on top.", -13.5198, -71.9753, 78, "https://images.unsplash.com/photo-1589802829985-817e51171b92?w=600&q=80"),
        _p("san-pedro-market", "San Pedro Market", "Food", "Lively market for fruit, juices and local dishes.", -13.5232, -71.9811, 72, "https://images.unsplash.com/photo-1534482421-64566f976cfa?w=600&q=80"),
        _p("pisac", "Pisac Ruins", "Historical", "Terraced Inca citadel in the Sacred Valley.", -13.4161, -71.8497, 80, "https://images.unsplash.com/photo-1580619305218-8423a7ef79b4?w=600&q=80"),
        _p("rainbow-mountain", "Rainbow Mountain (Vinicunca)", "Adventure", "High-altitude day hike to striped mineral slopes.", -13.8697, -71.3030, 85, "https://images.unsplash.com/photo-1509299349698-dd22323b5963?w=600&q=80"),
    ],
    "banff": [
        _p("lake-louise", "Lake Louise", "Nature", "Glacier-fed lake below Victoria Glacier.", 51.4254, -116.1773, 98, "https://images.unsplash.com/photo-1508873696983-2df57046475a?w=600&q=80"),
        _p("moraine-lake", "Moraine Lake", "Nature", "Vivid turquoise lake ringed by peaks. Check current access rules.", 51.3217, -116.1860, 95, "https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=600&q=80"),
        _p("banff-gondola", "Banff Gondola", "Adventure", "Cable car up Sulphur Mountain with panoramic views.", 51.1465, -115.5724, 85, "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&q=80"),
        _p("bow-falls", "Bow Falls", "Nature", "Wide, easy-access waterfall near the town.", 51.1650, -115.5560, 70, "https://images.unsplash.com/photo-1517824806704-9040b037703b?w=600&q=80"),
        _p("upper-hot-springs", "Banff Upper Hot Springs", "Entertainment", "Mountain-view hot pools open year-round.", 51.1670, -115.5590, 72, "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80"),
    ],
    "ladakh": [
        _p("leh-palace", "Leh Palace", "Historical", "Ruined nine-storey royal palace above the old town.", 34.1648, 77.5847, 80, "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?w=600&q=80"),
        _p("shanti-stupa", "Shanti Stupa", "Religious", "White-domed stupa with sunrise and sunset views.", 34.1678, 77.5668, 85, "https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=600&q=80"),
        _p("pangong-tso", "Pangong Tso", "Nature", "High-altitude lake that shifts colour through the day. Permit needed.", 33.7595, 78.6674, 98, "https://images.unsplash.com/photo-1581793745862-99fde7fa73d2?w=600&q=80"),
        _p("nubra-valley", "Nubra Valley (Diskit)", "Adventure", "Desert valley reached over Khardung La. Permit needed.", 34.5436, 77.5570, 90, "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600&q=80"),
        _p("thiksey", "Thiksey Monastery", "Religious", "Hilltop monastery that looks like a small Potala Palace.", 34.0486, 77.6666, 75, "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?w=600&q=80"),
    ],
}
