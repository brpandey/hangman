defmodule Hangman.Words.Test do
  use ExUnit.Case, async: true

  alias Hangman.Words

  # 17 words
  @words_small ["azoth", "azote", "azons", "azole", "azoic", "azlon", "azine", "azido", "azide", "azans", "ayins", "ayahs", "axons", "axone", "axmen", "axman", "axles"]

  # 1646 words
  @words_big  ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy", "ataps", "asyla", "astir", "aster", "asset", "asses", "assed", "assay", "assai", "aspis", "aspic", "asper", "aspen", "askos", "askoi", "askew", "asker", "asked", "aside", "ashes", "ashen", "ashed", "asdic", "ascus", "ascot", "argus", "argue", "argot", "argon", "argol", "argle", "argil", "argal", "arete", "arena", "areic", "areca", "areas", "areal", "areae", "ardor", "ardeb", "arcus", "arced", "arbor", "araks", "aquas", "aquae", "aptly", "apter", "apsis", "asana", "aryls", "arvos", "arval", "arums", "artsy", "artel", "artal", "arson", "arsis", "arses", "arrow", "arris", "array", "arras", "arpen", "arose", "aroma", "aroid", "armor", "armet", "armer", "armed", "arles", "arise", "arils", "ariel", "arias", "arhat", "apses", "apron", "apres", "apply", "apple", "appel", "appal", "aport", "apods", "antic", "apnea", "apish", "aping", "apian", "aphis", "aphid", "apery", "apers", "apeek", "apeak", "apart", "apace", "aorta", "anvil", "antsy", "antre", "antra", "antis", "animi", "anime", "anima", "anils", "anile", "angst", "angry", "angle", "anger", "angel", "angas", "anent", "anele", "anear", "ancon", "antes", "anted", "antas", "antae", "ansae", "anomy", "anole", "anode", "anoas", "annul", "annoy", "annex", "annas", "annal", "anlas", "ankus", "ankle", "ankhs", "anise", "anion", "amyls", "amuse", "amuck", "ampul", "amply", "ample", "amour", "amort", "among", "amole", "amoks", "amnio", "amnic", "amnia", "ammos", "amity", "amiss", "amirs", "amins", "amino", "amine", "amigo", "amiga", "amies", "amids", "amido", "amide", "amici", "amice", "amias", "ament", "amens", "amend", "ameer", "ameba", "ambry", "ambos", "amble", "ambit", "amber", "amaze", "amass", "amain", "amahs", "alway", "alums", "alula", "altos", "altho", "alter", "altar", "alpha", "aloud", "aloof", "along", "alone", "algum", "algor", "algin", "algid", "algas", "algal", "algae", "alfas", "alert", "aleph", "alefs", "alecs", "aldol", "alder", "alcid", "album", "albas", "alate", "alary", "alarm", "alant", "alans", "alang", "alane", "aland", "alamo", "alack", "akene", "akela", "akees", "ajuga", "ajiva", "aiver", "aitch", "aisle", "airts", "airth", "airns", "airer", "aired", "aioli", "aimer", "aimed", "ailed", "aloin", "aloha", "aloft", "aloes", "almug", "almud", "almes", "almeh", "almas", "almah", "allyl", "alloy", "allow", "allot", "allod", "alley", "allee", "allay", "alkyl", "alkyd", "aliya", "alive", "alist", "aline", "alike", "align", "alifs", "alien", "alibi", "aides", "aider", "aided", "ahull", "ahold", "ahead", "agues", "agria", "agree", "agora", "agony", "agons", "agone", "agmas", "aglow", "agley", "aglet", "aglee", "agist", "agism", "agios", "aging", "agile", "aghas", "aggro", "aggie", "agger", "agers", "agent", "agene", "agaze", "agave", "agate", "agars", "agape", "agama", "again", "afrit", "afoul", "afore", "afoot", "afire", "affix", "afars", "aerie", "aeons", "aegis", "aedes", "aecia", "adzes", "adyta", "adust", "adunc", "adult", "acari", "abyss", "abysm", "abyes", "abuzz", "abuts", "abuse", "adoze", "adown", "adorn", "adore", "adopt", "adobo", "adobe", "admix", "admit", "admen", "adman", "adits", "adios", "adieu", "adept", "adeem", "addle", "adder", "added", "addax", "adapt", "adage", "acyls", "acute", "actor", "actin", "acted", "acrid", "acres", "acred", "acorn", "acold", "acock", "acnes", "acned", "acmic", "acmes", "ackee", "acini", "acing", "acidy", "acids", "achoo", "aches", "ached", "aceta", "acerb", "abris", "above", "about", "abort", "aboon", "aboma", "aboil", "abohm", "abode", "abmho", "ables", "abler", "abide", "abhor", "abets", "abele", "abeam", "abbot", "abbey", "abbes", "abbas", "abate", "abash", "abase", "abamp", "abaka", "abaft", "aback", "abaci", "abaca", "aargh", "aalii", "aahed", "brume", "bruit", "bruin", "brugh", "brows", "brown", "broth", "brosy", "brose", "broos", "broom", "brook", "brood", "bronc", "bromo", "brome", "broke", "broil", "brock", "broad", "britt", "brits", "brisk", "brios", "briny", "brins", "brink", "bring", "brine", "brims", "brill", "brigs", "bries", "brier", "brief", "bride", "brick", "bribe", "briar", "brews", "breve", "brent", "brens", "brees", "breed", "brede", "bream", "break", "bread", "braze", "braza", "brays", "braxy", "braws", "brawn", "brawl", "bravo", "bravi", "brave", "brava", "brats", "brass", "brash", "brant", "brans", "brank", "brand", "braky", "brake", "brain", "brail", "braid", "brags", "braes", "brads", "bract", "brach", "brace", "bozos", "boyos", "boyla", "boyar", "boxes", "boxer", "boxed", "bowse", "bowls", "bower", "bowel", "bowed", "bovid", "bouts", "bousy", "bouse", "bourn", "bourg", "bound", "boule", "bough", "botts", "bothy", "botel", "botch", "botas", "bosun", "bossy", "boson", "bosom", "bosky", "bosks", "bortz", "borty", "borts", "boron", "borne", "boric", "bores", "borer", "bored", "borax", "boras", "boral", "boozy", "booze", "booty", "boots", "booth", "boost", "boors", "boons", "boomy", "booms", "books", "boogy", "booed", "booby", "boobs", "bonze", "bonus", "bonny", "bonne", "bonks", "bongs", "bongo", "boney", "bones", "boner", "boned", "bonds", "bombs", "bombe", "bolus", "bolts", "bolos", "bolls", "boles", "bolds", "bolas", "bolar", "boite", "boing", "boils", "bohea", "bogus", "bogle", "bogie", "boggy", "bogey", "bogan", "boffs", "boffo", "bodes", "boded", "bocks", "boche", "bocci", "bocce", "bobby", "boats", "boast", "boart", "boars", "board", "blype", "blush", "blurt", "blurs", "blurb", "blunt", "blume", "bluff", "bluey", "bluet", "blues", "bluer", "blued", "blubs", "blowy", "blows", "blown", "blots", "bloop", "bloom", "blood", "blond", "bloke", "blocs", "block", "blobs", "bloat", "blitz", "blite", "bliss", "blips", "blink", "blini", "blind", "blimy", "blimp", "blets", "blest", "bless", "blent", "blend", "bleep", "bleed", "blebs", "bleat", "blear", "bleak", "blaze", "blaws", "blawn", "blats", "blate", "blast", "blase", "blare", "blank", "bland", "blams", "blame", "blain", "blahs", "blade", "black", "blabs", "bizes", "bitty", "bitts", "bitsy", "bites", "biter", "bitch", "bison", "bisks", "bises", "birth", "birse", "birrs", "birls", "birle", "birks", "birds", "birch", "bipod", "biped", "biota", "biont", "biome", "bints", "binit", "bingo", "binge", "bines", "binds", "bindi", "binal", "bimbo", "bimas", "bimah", "billy", "bills", "bilks", "bilgy", "bilge", "biles", "bilbo", "bikie", "bikes", "biker", "biked", "bijou", "bigot", "bigly", "bight", "bifid", "biffy", "biffs", "biers", "bield", "bidet", "bides", "bider", "bided", "biddy", "bices", "bible", "bibbs", "bialy", "biali", "bhuts", "bhoot", "bhang", "bezil", "bezel", "bewig", "bevor", "bevel", "betta", "beton", "beths", "betel", "betas", "bests", "besot", "besom", "beset", "beryl", "berth", "berry", "berms", "berme", "bergs", "beret", "bents", "benny", "benni", "benne", "benes", "bendy", "bends", "bench", "bemix", "bemas", "belts", "below", "belly", "bells", "belle", "belie", "belga", "belch", "belay", "being", "beigy", "beige", "begun", "begum", "begot", "begin", "beget", "begat", "began", "befog", "befit", "beets", "beery", "beers", "beeps", "beefy", "beefs", "beech", "bedim", "bedew", "bedel", "becks", "becap", "bebop", "beaux", "beaut", "beaus", "beats", "beast", "bears", "beard", "beans", "beano", "beamy", "beams", "beaky", "beaks", "beady", "beads", "beach", "bazoo", "bazar", "bayou", "bayed", "bawty", "bawls", "bawdy", "bawds", "baulk", "bauds", "batty", "battu", "batts", "baton", "batik", "baths", "bathe", "bates", "bated", "batch", "basts", "baste", "bassy", "basso", "bassi", "basks", "basis", "basin", "basil", "basic", "bases", "baser", "based", "basal", "barye", "barre", "baron", "barny", "barns", "barmy", "barms", "barky", "barks", "baric", "barge", "barfs", "bares", "barer", "bared", "bards", "barde", "barbs", "barbe", "bahts", "baggy", "bagel", "baffy", "baffs", "badly", "badge", "baddy", "bacon", "backs", "bacca", "babus", "babul", "baboo", "babka", "babes", "babel", "babas", "banty", "banns", "banks", "banjo", "bangs", "banes", "baned", "bandy", "bands", "banco", "banal", "balsa", "balmy", "balms", "bally", "balls", "balky", "balks", "bales", "baler", "baled", "baldy", "balds", "balas", "bakes", "baker", "baked", "baize", "baiza", "baits", "baith", "bairn", "bails", "baals", "comix", "comic", "comfy", "comet", "comes", "comer", "combs", "combo", "combe", "comas", "comal", "comae", "colza", "colts", "coins", "coils", "coign", "coifs", "cohos", "cohog", "cogon", "coffs", "coeds", "codon", "codex", "codes", "coder", "coden", "coded", "codec", "codas", "color", "colon", "colog", "colly", "colin", "colic", "coles", "coled", "colds", "colas", "cokes", "coked", "coirs", "cocos", "cocoa", "cocky", "cocks", "cocci", "cocas", "cobra", "coble", "cobia", "cobby", "cobbs", "coats", "coati", "coast", "coapt", "coaly", "coals", "coala", "coact", "coach", "clunk", "clung", "clump", "clues", "clued", "cluck", "clubs", "cloze", "cloys", "clown", "clove", "clout", "clour", "cloud", "clots", "cloth", "close", "clops", "cloot", "clons", "clonk", "clone", "clomp", "clomb", "clogs", "clods", "clock", "cloak", "clits", "clipt", "clips", "clink", "cling", "cline", "clime", "climb", "clift", "cliff", "click", "clews", "clerk", "clept", "clepe", "chums", "chump", "chugs", "chuff", "chufa", "chuck", "chubs", "chows", "chott", "chose", "chore", "chord", "chops", "chook", "chomp", "cholo", "choky", "cleft", "clefs", "cleek", "cleat", "clear", "clean", "clays", "claws", "clavi", "clave", "clast", "class", "clasp", "clash", "clary", "claro", "clapt", "claps", "clans", "clank", "clang", "clams", "clamp", "claim", "clags", "clads", "clade", "clack", "clach", "civvy", "civil", "civie", "civic", "civet", "cites", "citer", "cited", "cists", "cissy", "cisco", "cirri", "cires", "circa", "cions", "cines", "cinch", "cimex", "cilia", "cigar", "cider", "cibol", "chyme", "chyle", "chute", "churr", "churn", "churl", "chunk", "choke", "choir", "chock", "chivy", "chive", "chits", "chirr", "chirp", "chiro", "chirm", "chirk", "chips", "chins", "chino", "chink", "chine", "china", "chimp", "chime", "chimb", "chill", "chili", "chile", "child", "chiel", "chief", "chide", "chics", "chico", "chick", "chias", "chiao", "chewy", "chews", "chevy", "cheth", "chest", "chess", "chert", "chemo", "chela", "chefs", "cheer", "cheep", "cheek", "check", "cheat", "cheap", "chays", "chaws", "chats", "chasm", "chase", "chary", "chart", "chars", "charr", "charm", "chark", "chare", "chard", "chapt", "chaps", "chape", "chaos", "chant", "chang", "chams", "champ", "chalk", "chair", "chain", "chaff", "chafe", "chads", "cetes", "cesti", "cesta", "ceros", "ceric", "ceria", "ceres", "cered", "cerci", "cepes", "ceorl", "centu", "cents", "cento", "cense", "cater", "catch", "casus", "casts", "caste", "casky", "casks", "cases", "cased", "casas", "carve", "carts", "celts", "celom", "cells", "cello", "celli", "cella", "celeb", "ceils", "ceiba", "cedis", "cedes", "ceder", "ceded", "cedar", "cecum", "cecal", "cebid", "cease", "cawed", "cavil", "cavie", "caves", "caver", "caved", "cause", "cauls", "caulk", "cauld", "catty", "cates", "carte", "carse", "carry", "carrs", "carps", "carpi", "carom", "carol", "carob", "carny", "carns", "carls", "carle", "carks", "cargo", "carex", "caret", "cares", "carer", "cared", "cards", "carbs", "carbo", "carat", "caput", "capos", "capon", "caphs", "capes", "caper", "caped", "canty", "cants", "canto", "calos", "calms", "calls", "calla", "calks", "calix", "calif", "calfs", "cakey", "cakes", "caked", "cajon", "cairn", "caird", "cains", "caids", "cahow", "cagey", "cages", "cager", "caged", "caffs", "cafes", "caeca", "cadre", "cadis", "cadgy", "cadge", "cadet", "cades", "caddy", "canst", "canso", "canon", "canoe", "canny", "canna", "canid", "canes", "caner", "caned", "candy", "canal", "campy", "camps", "campo", "campi", "cames", "cameo", "camel", "camas", "calyx", "calve", "buses", "bused", "busby", "burst", "burse", "bursa", "burry", "burrs", "burro", "burps", "burnt", "burns", "burly", "burls", "burke", "burin", "burgs", "burgh", "buret", "burds", "burbs", "buras", "buran", "buoys", "bunya", "bunts", "bunny", "bunns", "bunks", "bunko", "bungs", "bundt", "bunds", "bunco", "bunch", "bumpy", "bumps", "bumph", "bumfs", "bully", "bulls", "cacti", "cache", "cacas", "cacao", "cabob", "cable", "cabin", "caber", "cabby", "cabal", "byway", "bytes", "byssi", "byrls", "byres", "bylaw", "bwana", "buyer", "buxom", "butyl", "butut", "butty", "butts", "butte", "butle", "butes", "buteo", "butch", "busty", "busts", "busks", "bushy", "bulla", "bulky", "bulks", "bulgy", "bulge", "bulbs", "built", "build", "buhrs", "buhls", "bugle", "buggy", "buffy", "buffs", "buffo", "buffi", "budge", "buddy", "bucks", "bucko", "bubby", "bubal", "brute", "brusk", "brush", "brunt", "doest", "doers", "dodos", "dodgy", "dodge", "docks", "dobro", "dobra", "dobla", "dobie", "dobby", "doats", "djins", "djinn", "dizzy", "dizen", "dixit", "diwan", "divvy", "divot", "dives", "diver", "dived", "divas", "divan", "ditzy", "ditty", "ditto", "ditsy", "dites", "ditch", "ditas", "disme", "disks", "dishy", "discs", "disco", "disci", "dirty", "dirts", "dirls", "dirks", "dirge", "direr", "dipso", "dippy", "diols", "diode", "dints", "dinky", "dinks", "dingy", "dings", "dingo", "dinge", "dines", "diner", "dined", "dinar", "dimly", "dimes", "dimer", "dilly", "dills", "dildo", "dikey", "dikes", "diker", "diked", "digit", "dight", "diets", "diene", "didst", "didos", "didie", "dicty", "dicta", "dicot", "dicky", "dicks", "dewax", "dewar", "dewan", "devon", "devil", "devel", "devas", "deuce", "detox", "deter", "dicey", "dices", "dicer", "diced", "diazo", "diary", "dials", "dhuti", "dhows", "dhoti", "dhole", "dhobi", "dhals", "dhaks", "dexie", "dexes", "dewed", "desks", "desex", "derry", "derms", "derma", "derby", "deray", "derat", "depth", "depot", "deoxy", "dents", "dense", "denim", "denes", "denar", "demur", "demos", "demon", "demob", "demit", "demes", "delve", "delts", "delta", "delly", "dells", "delis", "delft", "delfs", "deles", "deled", "delay", "dekko", "dekes", "deked", "deity", "deist", "deism", "deils", "deign", "deify", "deice", "degum", "degas", "defog", "defis", "defer", "defat", "deets", "deers", "deeps", "deems", "deedy", "deeds", "dedal", "decry", "decoy", "decos", "decor", "decks", "decay", "decal", "decaf", "debye", "debut", "debug", "debts", "debit", "debar", "deave", "death", "deash", "deary", "dears", "deans", "dealt", "deals", "deair", "deads", "dazes", "dazed", "dawts", "dawns", "dawks", "dawen", "dawed", "davit", "daven", "dauts", "daunt", "dauby", "daubs", "daube", "datum", "datto", "datos", "dates", "dater", "dated", "dashy", "dashi", "darts", "darns", "darky", "darks", "daric", "dares", "darer", "dared", "darbs", "danio", "dangs", "dandy", "dance", "damps", "damns", "dames"]




  describe "Words creation" do

    test "empty new" do
      
      # create empty Words abstraction with length key 5
      assert 0 = Words.new(5) |> Words.count

      assert 11 = Words.new(11) |> Words.key
    end

    test "small streams new" do

      stream = @words_small |> Stream.take(4) # Take four items
      assert 4 = Words.new(5, stream) |> Words.count

      words = %Words{} = Words.new(5, stream)
      assert 5 = words |> Words.key

      stream = @words_small |> Stream.take(1_000) # Take 10_000 items
      assert Enum.count(@words_small) == Words.new(5, stream) |> Words.count
    end
      
    test "big streams new" do

      stream = @words_big |> Stream.take(671) # Take 671 items
      assert 671 = Words.new(5, stream) |> Words.count

      stream = @words_big |> Stream.take(1136) # Take 1136 items
      assert 1136 = Words.new(5, stream) |> Words.count

      stream = @words_big |> Stream.take(10_000) # Take 10_000 items
      assert Enum.count(@words_big) == Words.new(5, stream) |> Words.count
    end


  end



  describe "Words read" do

    test "collect small" do
      stream = @words_small |> Stream.take(100)

      # we sort the list alphabetically
      assert ["axles", "axman", "axmen", "axone", "axons", "ayahs", "ayins",
              "azans", "azide", "azido", "azine", "azlon", "azoic", "azole",
              "azons", "azote", "azoth"] = 
        Words.new(5, stream) |> Words.collect(100)

      stream = @words_small |> Stream.take(100)

      # grab first 4 words and then sort the list alphabetically
      assert ["azole", "azons", "azote", "azoth"] =
        Words.new(5, stream) |> Words.collect(4)
    end


    test "collect big" do
      stream = @words_big |> Stream.take(100)

      # we sort the list alphabetically
      assert ["assay", "assed", "asses", "asset", "aster", "astir", "asyla",
              "ataps", "ataxy", "atilt", "atlas", "atman", "atmas", "atoll",
              "atoms"] =
        Words.new(5, stream) |> Words.collect(15)


      stream = @words_big |> Stream.take(100)

      # grab first 4 words and then sort the list alphabetically
      assert ["atman", "atmas", "atoll", "atoms"] =
        Words.new(5, stream) |> Words.collect(4)
    end


  end


  describe "Words filter" do

    test "filter simple match no o" do
      regex = ~r/^[^o]*$/

      stream = @words_small |> Stream.take(100)      

      words = Words.new(5, stream)
      words = words |> Words.filter(regex)
      list = words |> Words.collect(100)

      assert ["axles", "axman", "axmen", "ayahs", "ayins", "azans", "azide",
            "azine"] = list
      
    end

    test "filter complex pattern match" do
      regex = ~r/^[^aeio][^aeio][^aeio][^aeio][^aeio]$/

      stream = @words_big |> Stream.take(700)      

      words = Words.new(5, stream)
      words = words |> Words.filter(regex)
      list = words |> Words.collect(100)

      assert ["blubs", "bluff", "blunt", "blurb", "blurs", "blurt", "blush",
              "brugh"] = list

    end

  end

  describe "Words add" do

    test "small stream" do

      count = Enum.count(@words_small)
      binary_list = @words_small |> :erlang.term_to_binary

      entry = {binary_list, count}

      words = Words.new(5) |> Words.add(entry)

      assert ["axles", "axman", "axmen", "axone", "axons", "ayahs", "ayins",
              "azans", "azide", "azido", "azine", "azlon", "azoic", "azole",
              "azons", "azote", "azoth"] = 
        words |> Words.collect(100)
    end

  end
  

end
