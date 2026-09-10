// Louage price calculator based on the official Tunisian Ministry of Transport
// tariff (in effect since 15 December 2022, Arrêté du Ministère du Transport).
//
// Formula (per seat, A/C vehicle):
//   ≤ 10 km        : 0.850 TND flat
//   10 – 150 km    : 0.086 TND/km  × distance  (+15 % A/C surcharge)
//   > 150 km       : 0.071 TND/km  × distance  (+12 % A/C surcharge)
//
// City-to-city road distances (km) are approximate values based
// on the Tunisian road network.  All distances are symmetric.

/// Approximate road distance in km between two Tunisian cities.
/// Keys are lowercase city names; the map is symmetric — only one direction
/// needs to be stored.
const Map<String, Map<String, int>> _cityDistances = {
  'tunis': {
    'ariana': 12,
    'ben arous': 14,
    'manouba': 18,
    'nabeul': 65,
    'zaghouan': 60,
    'bizerte': 65,
    'béja': 107,
    'jendouba': 160,
    'kef': 175,
    'siliana': 130,
    'sousse': 145,
    'monastir': 162,
    'mahdia': 195,
    'sfax': 270,
    'kairouan': 157,
    'kasserine': 266,
    'sidi bouzid': 265,
    'gabès': 405,
    'medenine': 490,
    'tataouine': 530,
    'gafsa': 335,
    'tozeur': 440,
    'kébili': 480,
  },
  'ariana': {
    'ben arous': 20,
    'manouba': 10,
    'nabeul': 72,
    'zaghouan': 65,
    'bizerte': 60,
    'béja': 112,
    'jendouba': 165,
    'kef': 180,
    'siliana': 135,
    'sousse': 152,
    'monastir': 170,
    'mahdia': 202,
    'sfax': 278,
    'kairouan': 163,
    'kasserine': 272,
    'sidi bouzid': 272,
    'gabès': 412,
    'medenine': 498,
    'tataouine': 538,
    'gafsa': 342,
    'tozeur': 448,
    'kébili': 488,
  },
  'ben arous': {
    'manouba': 25,
    'nabeul': 68,
    'zaghouan': 55,
    'bizerte': 72,
    'béja': 115,
    'jendouba': 168,
    'kef': 183,
    'siliana': 138,
    'sousse': 148,
    'monastir': 166,
    'mahdia': 198,
    'sfax': 274,
    'kairouan': 160,
    'kasserine': 268,
    'sidi bouzid': 268,
    'gabès': 408,
    'medenine': 494,
    'tataouine': 534,
    'gafsa': 338,
    'tozeur': 444,
    'kébili': 484,
  },
  'manouba': {
    'nabeul': 78,
    'zaghouan': 70,
    'bizerte': 55,
    'béja': 100,
    'jendouba': 155,
    'kef': 170,
    'siliana': 125,
    'sousse': 158,
    'monastir': 175,
    'mahdia': 208,
    'sfax': 284,
    'kairouan': 170,
    'kasserine': 278,
    'sidi bouzid': 278,
    'gabès': 418,
    'medenine': 504,
    'tataouine': 544,
    'gafsa': 348,
    'tozeur': 454,
    'kébili': 494,
  },
  'nabeul': {
    'zaghouan': 55,
    'bizerte': 120,
    'béja': 165,
    'jendouba': 220,
    'kef': 230,
    'siliana': 185,
    'sousse': 90,
    'monastir': 108,
    'mahdia': 140,
    'sfax': 215,
    'kairouan': 105,
    'kasserine': 210,
    'sidi bouzid': 210,
    'gabès': 350,
    'medenine': 435,
    'tataouine': 475,
    'gafsa': 280,
    'tozeur': 385,
    'kébili': 425,
  },
  'zaghouan': {
    'bizerte': 120,
    'béja': 155,
    'jendouba': 210,
    'kef': 220,
    'siliana': 95,
    'sousse': 100,
    'monastir': 118,
    'mahdia': 150,
    'sfax': 225,
    'kairouan': 105,
    'kasserine': 205,
    'sidi bouzid': 205,
    'gabès': 345,
    'medenine': 430,
    'tataouine': 470,
    'gafsa': 275,
    'tozeur': 380,
    'kébili': 420,
  },
  'bizerte': {
    'béja': 90,
    'jendouba': 145,
    'kef': 155,
    'siliana': 165,
    'sousse': 200,
    'monastir': 218,
    'mahdia': 250,
    'sfax': 325,
    'kairouan': 212,
    'kasserine': 320,
    'sidi bouzid': 320,
    'gabès': 460,
    'medenine': 545,
    'tataouine': 585,
    'gafsa': 390,
    'tozeur': 495,
    'kébili': 535,
  },
  'béja': {
    'jendouba': 55,
    'kef': 75,
    'siliana': 75,
    'sousse': 200,
    'monastir': 218,
    'mahdia': 250,
    'sfax': 325,
    'kairouan': 215,
    'kasserine': 220,
    'sidi bouzid': 255,
    'gabès': 420,
    'medenine': 510,
    'tataouine': 550,
    'gafsa': 295,
    'tozeur': 400,
    'kébili': 440,
  },
  'jendouba': {
    'kef': 65,
    'siliana': 120,
    'sousse': 250,
    'monastir': 268,
    'mahdia': 300,
    'sfax': 375,
    'kairouan': 260,
    'kasserine': 215,
    'sidi bouzid': 280,
    'gabès': 420,
    'medenine': 510,
    'tataouine': 550,
    'gafsa': 285,
    'tozeur': 390,
    'kébili': 430,
  },
  'kef': {
    'siliana': 75,
    'sousse': 235,
    'monastir': 253,
    'mahdia': 285,
    'sfax': 360,
    'kairouan': 200,
    'kasserine': 130,
    'sidi bouzid': 195,
    'gabès': 370,
    'medenine': 460,
    'tataouine': 500,
    'gafsa': 215,
    'tozeur': 320,
    'kébili': 360,
  },
  'siliana': {
    'sousse': 150,
    'monastir': 168,
    'mahdia': 200,
    'sfax': 275,
    'kairouan': 120,
    'kasserine': 140,
    'sidi bouzid': 170,
    'gabès': 345,
    'medenine': 430,
    'tataouine': 470,
    'gafsa': 210,
    'tozeur': 315,
    'kébili': 355,
  },
  'sousse': {
    'monastir': 22,
    'mahdia': 60,
    'sfax': 128,
    'kairouan': 57,
    'kasserine': 165,
    'sidi bouzid': 148,
    'gabès': 265,
    'medenine': 350,
    'tataouine': 390,
    'gafsa': 215,
    'tozeur': 320,
    'kébili': 360,
  },
  'monastir': {
    'mahdia': 38,
    'sfax': 107,
    'kairouan': 68,
    'kasserine': 177,
    'sidi bouzid': 155,
    'gabès': 248,
    'medenine': 333,
    'tataouine': 373,
    'gafsa': 215,
    'tozeur': 320,
    'kébili': 360,
  },
  'mahdia': {
    'sfax': 70,
    'kairouan': 100,
    'kasserine': 210,
    'sidi bouzid': 175,
    'gabès': 215,
    'medenine': 300,
    'tataouine': 340,
    'gafsa': 220,
    'tozeur': 325,
    'kébili': 365,
  },
  'sfax': {
    'kairouan': 127,
    'kasserine': 200,
    'sidi bouzid': 130,
    'gabès': 138,
    'medenine': 223,
    'tataouine': 263,
    'gafsa': 190,
    'tozeur': 295,
    'kébili': 335,
  },
  'kairouan': {
    'kasserine': 110,
    'sidi bouzid': 95,
    'gabès': 250,
    'medenine': 335,
    'tataouine': 375,
    'gafsa': 180,
    'tozeur': 285,
    'kébili': 325,
  },
  'kasserine': {
    'sidi bouzid': 80,
    'gabès': 260,
    'medenine': 345,
    'tataouine': 385,
    'gafsa': 95,
    'tozeur': 200,
    'kébili': 240,
  },
  'sidi bouzid': {
    'gabès': 230,
    'medenine': 315,
    'tataouine': 355,
    'gafsa': 115,
    'tozeur': 220,
    'kébili': 260,
  },
  'gabès': {
    'medenine': 87,
    'tataouine': 127,
    'gafsa': 155,
    'tozeur': 250,
    'kébili': 135,
  },
  'medenine': {
    'tataouine': 50,
    'gafsa': 245,
    'tozeur': 350,
    'kébili': 220,
  },
  'tataouine': {
    'gafsa': 285,
    'tozeur': 390,
    'kébili': 260,
  },
  'gafsa': {
    'tozeur': 95,
    'kébili': 135,
  },
  'tozeur': {
    'kébili': 95,
  },
};

/// Station-pair distances for intra-governorate routes
/// where the city name is the same but stations differ.
const Map<String, Map<String, int>> _stationDistances = {
  'station ben gardane':         {'station medenine': 60},
  'station djerba (houmt souk)': {'station medenine': 75},
  'station sbeitla':             {'station kasserine': 40},
  'station kelibia':             {'station nabeul': 50, 'station hammamet': 70},
  'station nabeul':              {'station kelibia': 50, 'station hammamet': 30},
  'station hammamet':            {'station nabeul': 30, 'station kelibia': 70},
  'station menzel bourguiba':    {'station bizerte': 22},
  'station bizerte':             {'station menzel bourguiba': 22},
  'station jendouba':            {'station tabarka': 70},
  'station tabarka':             {'station jendouba': 70},
  'station raoued':              {'station ariana centre': 15},
  'station ariana centre':       {'station raoued': 15},
  'station ben arous':           {'station rades': 10},
  'station rades':               {'station ben arous': 10},
  'station sfax bab jebli':      {'station sfax sud': 8},
  'station sfax sud':            {'station sfax bab jebli': 8},
  'station sousse bab jedid':    {'station sousse nord': 5},
  'station sousse nord':         {'station sousse bab jedid': 5},
  'station bab alioua':          {'station moncef bey': 4, 'station bab saadoun': 3, 'station place barcelone': 2},
  'station moncef bey':          {'station bab alioua': 4, 'station bab saadoun': 5, 'station place barcelone': 3},
  'station bab saadoun':         {'station bab alioua': 3, 'station moncef bey': 5, 'station place barcelone': 4},
  'station place barcelone':     {'station bab alioua': 2, 'station moncef bey': 3, 'station bab saadoun': 4},
};

/// Returns the approximate road distance (km) between two cities (or stations).
/// Provide [fromStation]/[toStation] for intra-city routes.
/// Returns null if the pair is unknown.
int? getDistanceKm(String cityA, String cityB,
    {String fromStation = '', String toStation = ''}) {
  final a = cityA.toLowerCase().trim();
  final b = cityB.toLowerCase().trim();

  // Same city — try station-level lookup
  if (a == b && fromStation.isNotEmpty && toStation.isNotEmpty) {
    final sa = fromStation.toLowerCase().trim();
    final sb = toStation.toLowerCase().trim();
    if (sa == sb) return 0;
    final d = _stationDistances[sa]?[sb] ?? _stationDistances[sb]?[sa];
    return d;
  }

  if (a == b) return 0;

  // City-level lookup
  final direct = _cityDistances[a]?[b];
  if (direct != null) return direct;
  final reverse = _cityDistances[b]?[a];
  if (reverse != null) return reverse;

  return null;
}

/// Calculates the louage ticket price (TND) for a single passenger seat.
/// Pass [fromStation]/[toStation] for intra-city routes.
/// Returns null if the distance between the two cities is unknown.
double? getLouagePrice(String fromCity, String toCity,
    {String fromStation = '', String toStation = ''}) {
  final distKm = getDistanceKm(fromCity, toCity,
      fromStation: fromStation, toStation: toStation);
  if (distKm == null) return null;
  if (distKm == 0) return null;

  double price;
  double acSurcharge;

  if (distKm <= 10) {
    price = 0.850;
    acSurcharge = 0.15;
  } else if (distKm <= 150) {
    price = distKm * 0.086;
    acSurcharge = 0.15;
  } else {
    price = distKm * 0.071;
    acSurcharge = 0.12;
  }

  final total = price * (1 + acSurcharge);
  return (total * 10).roundToDouble() / 10;
}

/// Returns a formatted price string like "12.4 TND" or "—" if unknown.
String formatLouagePrice(String fromCity, String toCity,
    {String fromStation = '', String toStation = ''}) {
  final price = getLouagePrice(fromCity, toCity,
      fromStation: fromStation, toStation: toStation);
  if (price == null) return '— TND';
  return '${price.toStringAsFixed(1)} TND';
}
