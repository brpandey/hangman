defmodule Hangman.Reduction.Engine.Stub do # Hangman Word Reduction Engine

  alias Hangman.{Counter, Types.Reduction.Pass}

	def reduce(:game_start, 
		{id, game_no, round_no} = _pass_key, filter_options) 
		when is_binary(id) and is_number(game_no) and is_number(round_no) do

		{:ok, true} =	Keyword.fetch(filter_options, :game_start)
		{:ok, _length_filter_key}  = Keyword.fetch(filter_options, :secret_length)
		
		simulate_reduce_sequence(game_no, 1)
	end

	def reduce(:correct_letter, 
		{id, game_no, round_no} = _pass_key, filter_options)
		when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# leave this in until we are assured the regex is faster
		{:ok, _correct_letter} = Keyword.fetch(filter_options, :correct_letter)

		{:ok, _exclusion_filter_set} = Keyword.fetch(filter_options, :guessed_letters)
		{:ok, _regex} = Keyword.fetch(filter_options, :regex)
	
		simulate_reduce_sequence(game_no, round_no)	
	end

 	def reduce(:incorrect_letter, 
 		{id, game_no, round_no} = _pass_key, filter_options) 
 		when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# leave this in until we are assured the regex is faster
		{:ok, _incorrect_letter} = Keyword.fetch(filter_options, :incorrect_letter)

		{:ok, _exclusion_filter_set} = Keyword.fetch(filter_options, :guessed_letters)
		{:ok, _regex} = Keyword.fetch(filter_options, :regex)
		
		simulate_reduce_sequence(game_no, round_no)
	end


	# Game 1 - word is: cumulate

	def simulate_reduce_sequence(1, 1) do

		size = 28558

		tally = Counter.new(%{"e" => 19600, "s" => 16560, "i" => 15530, "a" => 14490, "r" => 14211, "n" => 12186, "t" => 11870, "o" => 11462, 
		"l" => 11026, "d" => 8046, "c" => 7815, "u" => 7377, "g" => 6009, "m" => 5793, "p" => 5763, "h" => 5111, "b" => 4485, 
		"y" => 3395, "f" => 2897, "k" => 2628, "w" => 2313, "v" => 2156, "z" => 783, "x" => 662, "q" => 422, "j" => 384})

		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{1, pass_info}
	end

	def simulate_reduce_sequence(1, 2) do

		size = 1833

		tally = Counter.new(%{"a" => 1215, "i" => 1154, "l" => 940, "o" => 855, "t" => 807, "s" => 689, "r" => 688, "n" => 662, "u" => 548, 
		"c" => 527, "b" => 425, "p" => 387, "m" => 380, "d" => 348, "g" => 280, "h" => 257, "k" => 228, "f" => 169, 
		"v" => 155, "y" => 127, "z" => 112, "w" => 111, "q" => 35, "x" => 24, "j" => 18})

		#_possible = ["AUTOLYZE", "GINGIVAE", "FIGULINE", "AIGUILLE", "OUTSTATE", "ROUGHAGE", "WORKFARE", "POSSIBLE", "MINIMIZE", "DRAWABLE", "FOOTLIKE", "AUTOLYSE", "MUSTACHE", "MAXIMISE", "QUINTILE", "CATALASE", "DUSTLIKE", "TRAMLINE", "ABSOLUTE", "MAXIMITE", "TRICHITE", "TITHABLE", "MAXIMIZE", "SONGLIKE", "CABRIOLE", "TRIPTANE", "SATURATE", "SINFONIE", "UNTANGLE", "OUTSTARE", "SINKABLE", "MINIMISE", "OBDURATE", "DIASPORE", "BRAUNITE", "DISSOLVE", "INTONATE", "GLANDULE", "WISHBONE", "TORTOISE", "MASTLIKE", "BURNABLE", "FRONDOSE", "COMPRISE", "AFFIANCE", "SNOWLIKE", "TACONITE", "SYCAMORE", "LILYLIKE", "NOMINATE", "COMPRIZE", "NODULOSE", "UNCLOTHE", "STRADDLE", "CONGLOBE", "SALIVATE", "SCRIBBLE", "MOLDABLE", "BORACITE", "SUMMABLE", "OUTRAISE", "STANHOPE", "ZOOSPORE", "STRICKLE", "LAZULITE", "ABORTIVE", "MISRAISE", "HOOFLIKE", "PAPULOSE", "ACTINIDE", "GRAVIDAE", "COIFFURE", "WASTABLE", "OPTIMISE", "TIPPYTOE", "ACAUDATE", "FINDABLE", "ZOOPHILE", "OPTIMIZE", "ACTINIAE", "INITIATE", "PLAYABLE", "FOOTROPE", "DOPAMINE", "INDICATE", "COLICINE", "ZOOCHORE", "SCAPULAE", "DOWNSIZE", "AUTOSOME", "CALIFATE", "PATINATE", "HANGABLE", "INCISURE", "LATINIZE", "DOWNSIDE", "CULTLIKE", "RADWASTE", "HUISACHE", "HALFTONE", "TRUNCATE", "SUBFRAME", "ANGULOSE", "GRILLAGE", "STRIGOSE", "IMITABLE", "FORCIBLE", "GRILLADE", "FILATURE", "AMPUTATE", "AUTOCADE", "MUCKRAKE", "ZOOPHOBE", "INUNDATE", "BUGHOUSE", "RUFFLIKE", "BACKBONE", "LOBULOSE", "MISSHAPE", "CAVITATE", "HOLYTIDE", "AMMONITE", "FUMARASE", "UNPOLITE", "BOILABLE", "COLLOGUE", "OUTCURSE", "UNIVALVE", "FUMARATE", "ROBOTIZE", "ANTRORSE", "OUTCURVE", "TOLIDINE", "BOOKABLE", "COGITATE", "MISSTATE", "LAZURITE", "CARABINE", "FOOTNOTE", "SLOWPOKE", "IRRIGATE", "RIPPABLE", "FLOCCOSE", "ABSTRUSE", "ROADSIDE", "DRIFTAGE", "MISDROVE", "PROGNOSE", "SUNSTONE", "SINGABLE", "LARKSOME", "ABDICATE", "INSTABLE", "PROPHASE", "CYTOSINE", "THIONINE", "OUTDROVE", "OXTONGUE", "TAILPIPE", "WINNABLE", "UNSUBTLE", "SAWHORSE", "SODOMITE", "POSTHOLE", "CARAPACE", "CRABWISE", "ANKYLOSE", "CORONATE", "SODOMIZE", "HALFTIME", "PROPHAGE", "ANTIMALE", "BUSTLINE", "BAGHOUSE", "CRISPATE", "CONFLATE", "PRACTISE", "TRICHOME", "QUARTILE", "TUCKAHOE", "PAWNABLE", "TOTALISE", "SHAPABLE", "LOTHSOME", "DRAGROPE", "ACRIDINE", "ALLIABLE", "SUNSHADE", "TOTALIZE", "DATABASE", "TROTLINE", "HARDWIRE", "VALIDATE", "POSTCODE", "FARMWIFE", "BONIFACE", "BALLGAME", "UNIONIZE", "PRACTICE", "BANKNOTE", "ISSUANCE", "ROOMMATE", "CANTICLE", "BULLNOSE", "LIFTGATE", "VALIANCE", "BOOKLORE", "LAUDABLE", "COCKLIKE", "PARAKITE", "STIBNITE", "TABULATE", "CURBABLE", "BUNCOMBE", "HARDWARE", "PORPOISE", "COMANAGE", "MISPLACE", "UNIONISE", "GAINABLE", "CASTRATE", "FORBORNE", "BUSHFIRE", "UNDOCILE", "TUBULURE", "NIZAMATE", "VOLATILE", "WARHORSE", "BARNLIKE", "DISCLIKE", "PINNULAE", "BOLTHOLE", "BROCHURE", "FOLKTALE", "OUTSCORE", "CURBSIDE", "OUTQUOTE", "NONCRIME", "LOGOTYPE", "CANONIZE", "SUBSCALE", "DOMINATE", "CLAYMORE", "CANONISE", "PROLAPSE", "WARPLANE", "CORNCAKE", "VIRICIDE", "STORABLE", "HYMNLIKE", "SULPHATE", "VIBRANCE", "SLIPSOLE", "SPICULAE", "CONTRIVE", "CONTRITE", "QUAGMIRE", "MUTATIVE", "LORDLIKE", "MISROUTE", "JUBILATE", "LOGICISE", "IDOCRASE", "IODINATE", "SUITABLE", "OUTFABLE", "TRIANGLE", "VAGINATE", "SQUILLAE", "LOGICIZE", "WORMHOLE", "SCALABLE", "TITRABLE", "VALORISE", "COCKSURE", "OTOSCOPE", "LANDLINE", "VALORIZE", "GRAFTAGE", "BUTYRATE", "SOLARIZE", "LYSOZYME", "TUBBABLE", "RATICIDE", "SOLARISE", "PITTANCE", "TWIGLIKE", "TASTABLE", "BOOKCASE", "BRISANCE", "SIGHLIKE", "PATINIZE", "APHANITE", "UNDOABLE", "TRIPLANE", "ALLSPICE", "FISHLINE", "FLATWARE", "ISOCHIME", "PISHOGUE", "DIOPTASE", "CHOWTIME", "BIJUGATE", "SUBTITLE", "APPRAISE", "FLOCCULE", "ALLOCATE", "POSTLUDE", "LAITANCE", "FISHLIKE", "MISGUIDE", "PLANULAE", "BAILABLE", "FARINOSE", "RINSABLE", "TRIPHASE", "SHOWCASE", "AUTOMATE", "NOOKLIKE", "ALBACORE", "SIMULATE", "KINGSIDE", "ULTIMATE", "TURNPIKE", "COURANTE", "PRISTINE", "BUTANONE", "FANTASIE", "WORKMATE", "MISDRIVE", "UNUSABLE", "ACUTANCE", "CULPABLE", "DIATRIBE", "UMPIRAGE", "PUMPLIKE", "LAPSIBLE", "DRACHMAE", "BOLDFACE", "SUBULATE", "ALLANITE", "BADINAGE", "PORTHOLE", "SQUIGGLE", "MARYJANE", "HOOPLIKE", "GASHOUSE", "IMMOLATE", "ISOCHORE", "DRAINAGE", "FUMIGATE", "MISLODGE", "ORDNANCE", "CULTRATE", "SIBILATE", "BOOKLICE", "SIMONIZE", "MASKABLE", "ROLAMITE", "THURIBLE", "ARBUSCLE", "PRISTANE", "DISPLODE", "BICHROME", "SOLANINE", "QUAYSIDE", "SHINBONE", "PARTIBLE", "FOLKMOTE", "LIPOCYTE", "PACKABLE", "LOCKABLE", "ISOLOGUE", "AMYGDULE", "SLAKABLE", "SUBSTATE", "INKSTONE", "RATSBANE", "THROTTLE", "SAPPHIRE", "CROSSTIE", "VITALISE", "SANDPILE", "CONSPIRE", "PISCINAE", "COLORIZE", "PISOLITE", "DAWNLIKE", "LOCUSTAE", "VITALIZE", "DUOLOGUE", "LABORITE", "SODALITE", "CAMPFIRE", "SUBSTAGE", "TUBULOSE", "SUPINATE", "DORMOUSE", "CAMPHINE", "BARONAGE", "AIRPLANE", "OUTRANGE", "PARTICLE", "HAMULATE", "HANDMADE", "TAPHOUSE", "BOTANISE", "CAMPHIRE", "BIDDABLE", "PANTOFLE", "OUTRANCE", "INVOCATE", "INVIABLE", "BACKBITE", "AGITABLE", "TOPSTONE", "POOLSIDE", "GRAPLINE", "ADUNCATE", "BOTANIZE", "FORMULAE", "DIAMANTE", "SPILLAGE", "ANNOUNCE", "HUARACHE", "MOSCHATE", "MOTIVATE", "DIAPHONE", "OLDSTYLE", "TARTRATE", "ANAPHASE", "SUNSHINE", "FOOTPACE", "CONVINCE", "BARRABLE", "LIMACINE", "CHORDATE", "DOCKSIDE", "PHALANGE", "MINUTIAE", "ALLUSIVE", "OCTANGLE", "GRANDAME", "CAULICLE", "HALAZONE", "STRUGGLE", "FILARIAE", "CHASUBLE", "OXYPHILE", "CLUBABLE", "APPANAGE", "PLUVIOSE", "INSOLATE", "BALDPATE", "OUTDRIVE", "BRIBABLE", "CYTIDINE", "INCUDATE", "STOPPAGE", "MISTITLE", "TURFLIKE", "COPULATE", "XYLIDINE", "ATRAZINE", "FISTULAE", "ARGININE", "MANDIBLE", "BUNTLINE", "SHIITAKE", "MISSABLE", "DONATIVE", "PROSTATE", "INSCRIBE", "ROSULATE", "AGMINATE", "VALUABLE", "VALKYRIE", "INACTIVE", "GANTLINE", "OPPILATE", "APOLOGUE", "CRUCIBLE", "DOMICILE", "LACUNATE", "SOLITUDE", "FIBRANNE", "BOATLIKE", "HILLSIDE", "SPATHOSE", "WAILSOME", "GNATHITE", "PARAVANE", "MONITIVE", "PAVONINE", "TANKLIKE", "XANTHATE", "HAWKNOSE", "ARTIFICE", "SILICONE", "SPOILAGE", "ORGANDIE", "FUCHSINE", "UNMINGLE", "BLOVIATE", "FOLLICLE", "SAGAMORE", "SURFLIKE", "DIVAGATE", "LISTABLE", "JUNCTURE", "BARYTONE", "SPINULAE", "ASTRINGE", "FAYALITE", "PAGINATE", "OUTSNORE", "SABOTAGE", "HARDCORE", "ACCOLADE", "SCRAPPLE", "SMARAGDE", "ASPARKLE", "PARLANTE", "FAVORITE", "MISJUDGE", "ABRASIVE", "SCROUNGE", "ZABAJONE", "TIPPABLE", "INFINITE", "NOVALIKE", "FISTNOTE", "DAMNABLE", "LADYLOVE", "CRUCIATE", "NUISANCE", "CAMISOLE", "ALLIANCE", "HOODLIKE", "SKYWRITE", "UNPUZZLE", "PARLANCE", "FLATWISE", "VARIANCE", "ANNOTATE", "SILIQUAE", "SULPHIDE", "VARICOSE", "HORNLIKE", "PORTANCE", "INFUSIVE", "OPSONIZE", "USQUABAE", "JAUNDICE", "TRANSUDE", "SUBACUTE", "FRAMABLE", "SATIABLE", "VOIDANCE", "MYLONITE", "WORMLIKE", "CAPITATE", "PYROLYZE", "SULPHITE", "SAMPHIRE", "PROCAINE", "CHLORATE", "DISGUISE", "GONGLIKE", "STROBILE", "TRUCKAGE", "BATHROBE", "COULISSE", "PALMLIKE", "TACHISME", "TRISTATE", "ARROGATE", "ZOOPHYTE", "PASSABLE", "TUBULATE", "DISPLUME", "TACHISTE", "COHOBATE", "BOLTROPE", "ROCKROSE", "GLACIATE", "MITIGATE", "ANTINUKE", "PRINCIPE", "RIDDANCE", "SYNCLINE", "PHYSIQUE", "MISGAUGE", "INSWATHE", "TAILBONE", "SULPHONE", "FAWNLIKE", "QUAYLIKE", "RUGULOSE", "OUTVALUE", "SCRABBLE", "COMATOSE", "SALVABLE", "RUSTABLE", "IMMOBILE", "OUTSWORE", "PYRUVATE", "CLAYWARE", "CURLYCUE", "SOCIABLE", "LAMBASTE", "HOTHOUSE", "MILLIARE", "PALINODE", "SKYWROTE", "MISWRITE", "SORPTIVE", "POLYPORE", "GANTLOPE", "LICORICE", "SLIDABLE", "RIBOSOME", "HORRIBLE", "WOODBINE", "MUDSTONE", "OBVOLUTE", "OFFSTAGE", "MULTIAGE", "PURCHASE", "FARFALLE", "SCURRILE", "GULFLIKE", "FISHABLE", "TURNABLE", "MONGOOSE", "MISUSAGE", "TRACTIVE", "ORDINATE", "WOMBLIKE", "LATITUDE", "PSAMMITE", "STONABLE", "FROTTAGE", "OUTSPOKE", "TRICYCLE", "TRACTILE", "ISOCLINE", "CABOODLE", "BARBWIRE", "SPARLIKE", "CURLICUE", "POTSTONE", "WILLABLE", "KNOWABLE", "SCRAMBLE", "SQUABBLE", "BARITONE", "OBTURATE", "DISHWARE", "MONOTYPE", "ANALCIME", "SYCOMORE", "KRYOLITE", "AIRSCAPE", "ARGINASE", "ANALCITE", "POSTGAME", "GALOPADE", "PRATIQUE", "RURALIZE", "CARRIAGE", "GLIADINE", "PALPABLE", "APPLIQUE", "SHOWTIME", "TINSTONE", "DIALLAGE", "NONISSUE", "VINCIBLE", "BOWLLIKE", "BASTILLE", "COINMATE", "MUDSLIDE", "BUNKMATE", "ALTITUDE", "ILLUSIVE", "WASPLIKE", "GIFTWARE", "COPRINCE", "TUMPLINE", "AIRFRAME", "RINGSIDE", "IMMATURE", "LANOLINE", "USTULATE", "CASIMIRE", "MASSACRE", "BIRDLIME", "ISSUABLE", "DISCIPLE", "DOLOMITE", "CLOSABLE", "RIVULOSE", "SHARABLE", "SKINLIKE", "SHIPSIDE", "NASALISE", "GRADUATE", "SALICINE", "INVOLUTE", "POPULATE", "PYRANOSE", "FLINKITE", "MIGRAINE", "NICOTINE", "CHANTAGE", "PUPILAGE", "GARGOYLE", "GLISSADE", "BIRDCAGE", "HANDLIKE", "VIRTUOSE", "OUTWRITE", "DUMBCANE", "FRUSTULE", "TROILITE", "NASALIZE", "UMANGITE", "INCHOATE", "PICAYUNE", "SCUMLIKE", "DISABUSE", "BROOKITE", "VOLITIVE", "BANKSIDE", "VARIABLE", "COQUILLE", "CARDCASE", "CATAMITE", "HAMULOSE", "SONATINE", "SLIPCASE", "APPLAUSE", "LANGUAGE", "FLATMATE", "BUNGHOLE", "RURALITE", "NUTHOUSE", "RURALISE", "NONTITLE", "MURRHINE", "SHIPMATE", "MANICURE", "HALOLIKE", "MOISTURE", "AMBIANCE", "POLYPIDE", "INNOVATE", "OUTCHIDE", "COLONIZE", "BILOBATE", "ADAPTIVE", "CAVATINE", "CITYWIDE", "SUCCUBAE", "HOMICIDE", "COLONISE", "UNCHASTE", "BACKFIRE", "TRIAZINE", "TANGIBLE", "SMOOTHIE", "LITHARGE", "PATOOTIE", "NONIMAGE", "WINDABLE", "TORQUATE", "CASCABLE", "SIMAZINE", "ALGINATE", "TAILGATE", "POTLACHE", "UNORNATE", "POPULACE", "COLOCATE", "RAISABLE", "CONVULSE", "COASSUME", "UNCHARGE", "KNOBLIKE", "SORORATE", "IRONSIDE", "OUTGLARE", "LOOPHOLE", "CHLORIDE", "COOKWARE", "LADYLIKE", "DIAPAUSE", "GONOCYTE", "ALKYLATE", "ARMILLAE", "UPSTROKE", "FILMABLE", "CHLORINE", "ACAULOSE", "OILSTONE", "PARKLIKE", "KILOBYTE", "FRUCTOSE", "TOPOTYPE", "CHLORITE", "TILTABLE", "NARWHALE", "SUBPHASE", "TITMOUSE", "ARBORIZE", "BLAMABLE", "SUBCASTE", "FOURSOME", "MISATONE", "IRONWARE", "VOCALISE", "PUTATIVE", "TINCTURE", "VITIABLE", "SYLLABLE", "CALORIZE", "SCISSURE", "FUGITIVE", "OUTTRADE", "INDAMINE", "TRIAZOLE", "UNSWATHE", "NARGHILE", "SHOWABLE", "SAPONITE", "INARABLE", "GLADSOME", "LAXATIVE", "UMBONATE", "PROBABLE", "ANTIDOTE", "ATTITUDE", "OUTWROTE", "LAGNAPPE", "SAPONINE", "MARITIME", "VOCALIZE", "INDAGATE", "SUITCASE", "SOLSTICE", "HAWKLIKE", "AGLYCONE", "MONOPOLE", "CLODPATE", "OUTGUIDE", "RAVIGOTE", "BUOYANCE", "BALKLINE", "ROCAILLE", "IMPOLITE", "LIONLIKE", "ARCATURE", "RINGBONE", "MONOPODE", "AGIOTAGE", "FOLKLIKE", "GIRASOLE", "VIZIRATE", "PROTRUDE", "FOLKLIFE", "GULLABLE", "BONHOMIE", "SILKLIKE", "BANALIZE", "MARGRAVE", "THIAMINE", "IRONLIKE", "POSITIVE", "UROSTYLE", "CONTINUE", "SUCHLIKE", "SKIPLANE", "LOCULATE", "SUBCAUSE", "PLOTLINE", "PAGANISE", "OUTBRAVE", "FLUORIDE", "MISWROTE", "VOCATIVE", "TRACTATE", "OBLIGATE", "GUNKHOLE", "PAGANIZE", "MISQUOTE", "RHAMNOSE", "AUNTLIKE", "TOLLGATE", "RUBYLIKE", "CALOTYPE", "COALHOLE", "MUCILAGE", "PAPILLAE", "DIVINIZE", "SUBGRADE", "LONGWISE", "HOROLOGE", "BACULINE", "SCIURINE", "INVASIVE", "AVIANIZE", "AVOWABLE", "WHARFAGE", "KNOTHOLE", "POLYTYPE", "RASHLIKE", "PLAUSIVE", "MINIBIKE", "CUTINISE", "AMYGDALE", "ALKOXIDE", "ADOPTIVE", "OUTBRIBE", "HORNPIPE", "CUTINIZE", "DIVINISE", "ALDOLASE", "PICOLINE", "FLUORINE", "SILICIDE", "PORTABLE", "WAIFLIKE", "PRIMROSE", "INCISIVE", "FLUORITE", "BACKDATE", "SWANLIKE", "CRANNOGE", "CONCLAVE", "DOWNPIPE", "SNOWSHOE", "BIRDLIKE", "COACTIVE", "LOANABLE", "VITULINE", "WOMANISE", "STRUMOSE", "AIRBORNE", "VIRUCIDE", "SCOPULAE", "CANULATE", "FOLKLORE", "RINGDOVE", "OUTHOUSE", "SILOXANE", "FOAMLIKE", "POLARISE", "ADVOCATE", "DIASTOLE", "HIGHLIFE", "APTITUDE", "RADIANCE", "QUATORZE", "ADDITIVE", "TANNABLE", "DRAWTUBE", "TRIVALVE", "FLATLINE", "POLARIZE", "MARINATE", "WOMANIZE", "ADAMSITE", "TUNICATE", "CONVOLVE", "SUFFRAGE", "LYRICIZE", "CAMISADE", "LAMBLIKE", "LONGSOME", "MODULATE", "SQUAMATE", "STRAGGLE", "LYRICISE", "DOWNTIME", "MARINADE", "SURFABLE", "JACULATE", "CIVILIZE", "DURATIVE", "SACKLIKE", "FIGURINE", "SUBOXIDE", "CIVILISE", "GUSTABLE", "PARAGOGE", "CAMOMILE", "INTIMATE", "MORTGAGE", "POSTDIVE", "WARDROBE", "FAROUCHE", "SCYPHATE", "HALIDOME", "ROTATIVE", "KALIFATE", "OPTATIVE", "ACTIVIZE", "CANNULAE", "ABATABLE", "VATICIDE", "VAMBRACE", "GUIDABLE", "LACROSSE", "BANKABLE", "ARILLATE", "DRUMLIKE", "ROOFLIKE", "SPIRULAE", "ROOFLINE", "APOCRINE", "FLOATAGE", "CROCOITE", "FOCALISE", "PINTSIZE", "MOCKABLE", "MONOCYTE", "DILATIVE", "SALINIZE", "FOOTSORE", "FURANOSE", "COMBLIKE", "BUTYLATE", "WHIPLIKE", "HANDSOME", "CULICINE", "MULTIUSE", "WARTLIKE", "DRUMFIRE", "INSULATE", "APHOLATE", "MOTORIZE", "JAZZLIKE", "IRRITATE", "KAMIKAZE", "SPRATTLE", "SAXATILE", "SOULLIKE", "ACAULINE", "SILICATE", "APOSTATE", "MONOTONE", "APOPHYGE", "TYROSINE", "RUINABLE", "PALATINE", "UNCINATE", "CUPULATE", "INTRIGUE", "SUBOVATE", "PLAYDATE", "BARNACLE", "CARRIOLE", "CASHABLE", "POURABLE", "PYROLIZE", "MOTORISE", "PASTILLE", "KNOTLIKE", "FITTABLE", "POTHOUSE", "CARACOLE", "CUMULATE", "GOADLIKE", "MAINLINE", "FISHBONE", "ABROGATE", "CLAMBAKE", "CHINBONE", "MASKLIKE", "STRAVAGE", "INTRORSE", "FAUNLIKE", "RAISONNE", "MULTIPLE", "GRAMARYE", "CALYCATE", "UNMUZZLE", "GRAZABLE", "LIPOSOME", "PLUSSAGE", "TITANATE", "FOCALIZE", "LONGLINE", "LAMINOSE", "PRUNABLE", "SOAPLIKE", "CALFLIKE", "PAPPOOSE", "WINGLIKE", "TABORINE", "TARTUFFE", "STOCKADE", "BIUNIQUE", "UNGULATE", "XANTHINE", "URBANISE", "SUITLIKE", "THIRLAGE", "LIGROINE", "BALLONNE", "UNSTABLE", "ACROSOME", "FRONTAGE", "YARMULKE", "HARDCASE", "URBANIZE", "HUGGABLE", "URBANITE", "MAPPABLE", "IMMUNIZE", "URTICATE", "FIGURATE", "POSTIQUE", "ARCHDUKE", "LAPIDATE", "IMMUNISE", "PROVABLE", "MILLRACE", "PILOTAGE", "MISVALUE", "SPORTIVE", "VAPORIZE", "SHAVABLE", "CRITIQUE", "MYOSCOPE", "PITIABLE", "PUNCTURE", "AUTOTYPE", "PUSSLIKE", "PUNITIVE", "VAPORISE", "ANTIPODE", "UNVIABLE", "ARGUABLE", "PYRONINE", "PLAYLIKE", "MOSSLIKE", "TRIPWIRE", "FILTRATE", "ROMANISE", "BRACIOLE", "FURLABLE", "GROWABLE", "POULTICE", "BOOTLACE", "ROMANIZE", "NAVIGATE", "MAXILLAE", "PROSTYLE", "ANTIPOLE", "CARINATE", "OUTCASTE", "MISSPOKE", "ANTIPOPE", "CARUNCLE", "UNDULATE", "SALTLIKE", "ORGANIZE", "DISUNITE", "MAILABLE", "COMPADRE", "THROSTLE", "SLABLIKE", "NONWHITE", "ROCKABYE", "ORGANISE", "SHAKABLE", "BLINDAGE", "MILLABLE", "OMNIVORE", "PROVINCE", "TURNSOLE", "SCISSILE", "UNDOUBLE", "VITAMINE", "LORICATE", "SUBTRIBE", "CASTABLE", "AMITROLE", "TUMULOSE", "RUNAGATE", "PHYLLOME", "CALAMITE", "JAROSITE", "VOIDABLE", "HOMINIZE", "BUSHLIKE", "CALAMINE", "WOODNOTE", "PHYLLODE", "ACCOUTRE", "POSTICHE", "ANTINODE", "HOMININE", "ALGICIDE", "CLAVICLE", "SPRADDLE", "OUTDANCE", "SAUTOIRE", "PROMULGE", "WOODLORE", "UNSONSIE", "SANGUINE", "BRATTICE", "HOOKNOSE", "AMORTISE", "LIGATIVE", "RHAPSODE", "CHACONNE", "OUTPRICE", "SMOKABLE", "SORICINE", "PARSABLE", "AMORTIZE", "POSTBASE", "LOCATIVE", "CYTOKINE", "MONOXIDE", "IMMINGLE", "MANGROVE", "FORKLIKE", "BIGARADE", "LIGULATE", "FARADIZE", "MURICATE", "FLUIDIZE", "DISKLIKE", "XANTHONE", "GLORIOLE", "FLUIDISE", "QUANTIZE", "FARADISE", "AUTODYNE", "COINABLE", "FOAMABLE", "MUTILATE", "SODAMIDE", "OVARIOLE", "MAYAPPLE", "FISHWIFE", "PLIMSOLE", "GNATLIKE", "ACTIVATE", "BOATABLE", "QUANTILE", "PYRIDINE", "PINOCHLE", "GIGABYTE", "GOATLIKE", "STOWABLE", "MISPOISE", "ADORABLE", "POUNDAGE", "DILATATE", "BACKACHE", "COOKABLE", "TYRAMINE", "OUTWASTE", "CATALYZE", "SPRINKLE", "MISSTYLE", "FIRMWARE", "HAIRLIKE", "AIRSPACE", "COADMIRE", "ANTITYPE", "BINDABLE", "HAIRLINE", "SPOLIATE", "SOLVABLE", "FOXGLOVE", "INURBANE", "ALBICORE", "LANDMINE", "SUNCHOKE", "FASCICLE", "CONATIVE", "ACRYLATE", "INCORPSE", "HUMANIZE", "MISGRADE", "BURSTONE", "HUMANISE", "KINGLIKE", "ALLOTYPE", "IMMOTILE", "FASCIATE", "RADIABLE", "LOCOMOTE", "PLOTTAGE", "VICARATE", "SMALTINE", "VICARAGE", "AUDITIVE", "FRUITAGE", "SMALTITE", "LAPSABLE", "TITIVATE", "DISBURSE", "NUBILOSE", "DISHLIKE", "UNSADDLE", "BUFFABLE", "INDULINE", "FLUXGATE", "PAPYRINE", "CAMPAGNE", "ARMATURE", "COINCIDE", "BIOCYCLE", "SOFTWARE", "PARASITE", "FURUNCLE", "MARQUISE", "HALFLIFE", "MOTHLIKE", "WALKYRIE", "LOCALISE", "CANAILLE", "LOCALITE", "TALKABLE", "LIRIPIPE", "RINGLIKE", "INSHRINE", "LACUNOSE", "HOOKLIKE", "CHRISTIE", "LYOPHILE", "CONCLUDE", "LOCALIZE", "FRACTURE", "ALBUMOSE", "THIAZIDE", "SMALLAGE", "PASTICHE", "CALYCINE", "HARDLINE", "SOUTACHE", "SUBNICHE", "INSTROKE", "CALLIOPE", "TRAPLINE", "SINICIZE", "DAUPHINE", "OUTSWARE", "MARRIAGE", "CANOODLE", "THIAZINE", "PIQUANCE", "TRAPLIKE", "TRAUCHLE", "DRAWBORE", "LUNULATE", "MISCIBLE", "QUAALUDE", "JAROVIZE", "SNAGLIKE", "CLODPOLE", "CYNOSURE", "BURGRAVE", "COINSURE", "PALISADE", "DOCTRINE", "MACULATE", "TOILSOME", "BOTRYOSE", "GASOLINE", "ANGINOSE", "CHROMIDE", "WOODPILE", "FIMBRIAE", "OBVIABLE", "PRIORATE", "FORDABLE", "PLAYMATE", "LYSOSOME", "PAYGRADE", "PULICIDE", "INFRINGE", "GRAPHITE", "HUSKLIKE", "SURPLICE", "HARDNOSE", "LOBULATE", "MORALISE", "ZARATITE", "JUGULATE", "PINNACLE", "BIFORATE", "WAGONAGE", "DARKSOME", "ILLUMINE", "TOPAZINE", "BULLDOZE", "TAILRACE", "SANITATE", "CALLABLE", "ALCIDINE", "INDOCILE", "CORKLIKE", "BAROUCHE", "THIAZOLE", "JOINABLE", "LITIGATE", "DISPLACE", "MORALIZE", "LOFTLIKE", "NONSTYLE", "PROGRADE", "OUTSMOKE", "ISOLABLE", "TRIPLITE", "SUFFLATE", "DISSUADE", "FANGLIKE", "ACCURATE", "NALOXONE", "UINTAITE", "BIOSCOPE", "INHUMANE", "CRIBBAGE", "PLACABLE", "APHORIZE", "OUTSHINE", "CORNICLE", "LANDSIDE", "CORNICHE", "BLOWTUBE", "UNBRIDLE", "ANYPLACE", "SURPRISE", "DIASTASE", "DOUBLURE", "WILDLIFE", "TRADABLE", "VALVULAE", "OUTDODGE", "SURPRIZE", "SYNDROME", "PROROGUE", "APHORISE", "RADICATE", "SYBARITE", "DIOPSIDE", "CAUSABLE", "MADHOUSE", "SANDLIKE", "SORTABLE", "DRAPABLE", "FROGLIKE", "SQUAMOSE", "DUTIABLE", "BUBALINE", "ALKALIZE", "ALKALINE", "RINSIBLE", "CARTABLE", "PRODROME", "DRYSTONE", "ALKALISE", "CHROMIZE", "JACINTHE", "GIBBSITE", "SPADILLE", "STARNOSE", "INTITULE", "FALLIBLE", "SANDSHOE", "CHROMITE", "PORRIDGE", "RHYOLITE", "MOONLIKE", "BOURRIDE", "FORSWORE", "SONICATE", "PROLONGE", "AMPULLAE", "CUTTABLE", "AQUILINE", "PICOMOLE", "IBOGAINE", "ABIDANCE", "FOOTRACE", "PUMICITE", "DISGORGE", "DILUTIVE", "GLABRATE", "MALAMUTE", "AMICABLE", "KISSABLE", "ZABAIONE", "PASSIBLE", "SLIPPAGE", "ARISTATE", "TUSKLIKE", "WOOLLIKE", "WINDPIPE", "MAGAZINE", "CLAYLIKE", "CUBATURE", "SHUNPIKE", "RIDICULE", "ARCHAISE", "AIRDROME", "NOTARIZE", "UNTHRONE", "MYSTIQUE", "HANGFIRE", "STAGNATE", "BOUTIQUE", "DIVISIVE", "PALLIATE", "DISPRIZE", "ASTATINE", "JALOUSIE", "PHYLLITE", "ROOTLIKE", "PROLOGUE", "OPPOSITE", "SATIRISE", "ROCKLIKE", "OUTVOICE", "BLOWPIPE", "OUTSHAME", "SATIRIZE", "UNCOUPLE", "SCARIOSE", "TRAVOISE", "ARCHAIZE", "PLUMLIKE", "ATROPINE", "MANCIPLE", "SORBABLE", "OMISSIVE", "SPITFIRE", "ATONABLE", "MISPRIZE", "DISTASTE", "GUIDANCE", "FARMABLE", "VICINAGE", "DRIVABLE", "POSTFACE", "OUTSMILE", "JAPANIZE", "ARILLODE", "APPOSITE", "MIGNONNE", "ANTILIFE", "CORDLIKE", "MASTICHE", "HUMMABLE", "DOGHOUSE", "SWAYABLE", "JOINTURE", "CURRICLE", "SAILABLE", "CORNPONE", "TOWNHOME", "NOONTIME", "FLOORAGE", "QUOTABLE", "MIDSPACE", "SUBSPACE", "LINKABLE", "CONSTRUE", "TAILLIKE", "HYOSCINE", "KAMACITE", "DIPPABLE", "NONGLARE", "MISPRICE", "DIGITIZE", "LAMINATE", "CAMPSITE", "MUSICALE", "MATURATE", "BROADAXE", "COLLAPSE", "STATABLE", "NOONTIDE", "HABITUDE", "RHABDOME", "ANNULATE", "BROCKAGE", "SANITIZE", "PARRIDGE", "NONDANCE", "STILBITE", "BILLABLE", "MIDRANGE", "INTHRONE", "CURARINE", "OSCULATE", "MYXOCYTE", "PARADISE", "OUTSHONE", "ACICULAE", "FURCULAE", "GLASSINE", "ANALOGUE", "INVIRILE", "FOLDABLE", "BONDABLE", "ANCILLAE", "CRISTATE", "FORMABLE", "DISPROVE", "FUMAROLE", "QUADRATE", "SINKHOLE", "MISFRAME", "BACKSIDE", "RUSHLIKE", "SHORTAGE", "GLADIATE", "CURATIVE", "HOLDABLE", "LONGTIME", "KICKABLE", "OPUSCULE", "GARROTTE", "WALKABLE", "UNICYCLE", "LUSTRATE", "DISGRACE", "BOBWHITE", "SYMBIOTE", "AMPHORAE", "BOOTABLE", "STUMPAGE", "CHATCHKE", "OUTARGUE", "POULARDE", "RUMINATE", "FLAGPOLE", "INSTANCE", "POLYSOME", "WISPLIKE", "TUTORAGE", "DRAGLINE", "INDURATE", "INCUBATE", "SOURDINE", "CATHOUSE", "SKYBORNE", "AMUSABLE", "CAPRIOLE", "NICKNAME", "ADAMANCE", "MILLCAKE", "CRANIATE", "COMPLINE", "SCABLIKE", "AMBULATE", "COMPLICE", "DISLODGE", "FINALISE", "CRYOLITE", "ANNULOSE", "ABSINTHE", "TOMBLIKE", "PUNCTATE", "TILLABLE", "MORPHINE", "PINAFORE", "LODICULE", "DISCLOSE", "BLOWHOLE", "SANATIVE", "PLAYTIME", "PTOMAINE", "FORJUDGE", "RAMULOSE", "WORKABLE", "INTUBATE", "HUNTABLE", "WRITABLE", "FUNGIBLE", "FISHPOLE", "BIRAMOSE", "MONAZITE", "FINALIZE", "SCHMOOZE", "STRANGLE", "TRACKAGE", "SCHMOOSE", "TROMBONE", "CHROMATE", "UNBUCKLE", "SANITISE", "VIOLABLE", "CHASTISE", "SPARABLE", "TOADLIKE", "MUNGOOSE", "OUTBLAZE", "POSTDATE", "ILLATIVE", "MISSPACE", "THIONATE", "CURARIZE", "WILDFIRE", "PLOWABLE", "ABLATIVE", "CADASTRE", "TRIOXIDE", "VOMITIVE", "STANNITE", "OMNIMODE", "GOODWIFE", "BURNOOSE", "DISTANCE", "SYCAMINE", "MOBILISE", "POSTPONE", "DIMMABLE", "OUTSKATE", "CAPONIZE", "GONOPORE", "CANALIZE", "MOBILIZE", "MISTRACE", "WARPWISE", "DISVALUE", "FULLFACE", "PISTACHE", "SYNONYME", "LIFTABLE", "MANDRAKE", "OFFSHORE", "OBSTACLE", "DIAGNOSE", "CANALISE", "SUNBATHE", "SABULOSE", "POPSICLE", "GRUMPHIE", "PRUINOSE", "GRADABLE", "BINNACLE", "DYNAMITE", "MONOSOME", "AUTUNITE", "CAPSTONE", "AQUACADE", "CLAWLIKE", "ISOPHOTE", "KILOMOLE", "LINGUINE", "MOATLIKE", "VOLPLANE", "OXIDABLE", "CHALAZAE", "BLOCKADE", "PARALYSE", "TRAPPOSE", "FIXATIVE", "CONSOMME", "BLOCKAGE", "NORMANDE", "TITANITE", "MOONRISE", "PARALYZE", "WASHABLE", "ANTIRAPE", "ANGULATE", "RAMILLIE", "DIALOGUE", "KILOBASE", "UNRIDDLE", "AQUATONE", "COROTATE", "CABOTAGE", "COMINGLE", "WOLFLIKE", "LANGSYNE", "NOCTURNE", "CRUSTOSE", "STARLIKE", "HOLOTYPE", "CORMLIKE", "ABUSABLE", "FOILABLE", "UNMUFFLE", "FILICIDE", "SURICATE", "OSCININE", "POSTFIRE", "POSTRACE", "SPIRACLE", "AMANDINE", "INFAUNAE", "FINITUDE", "TINPLATE", "DIGITATE", "MITICIDE", "MISPARSE", "LARDLIKE", "BRASSAGE", "CUTPURSE", "LIMONITE", "MILITATE", "TRACHYTE", "UNBUNDLE", "GULLIBLE", "LAVALIKE", "PURSLANE", "GNAWABLE", "ROSTRATE", "STARGAZE", "HARANGUE", "LIGATURE", "DOWNCOME", "VANADATE", "SHAMABLE", "CINCTURE", "BALMLIKE", "LANGRAGE", "SLIPWARE", "TRICORNE", "ASPIRATE"]
		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["e"]
		_guess_letter = "a"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{2, pass_info}
	end

	def simulate_reduce_sequence(1, 3) do

		size = 236

		tally = Counter.new(%{"t" => 162, "i" => 121, "o" => 108, "u" => 97, "r" => 94, "l" => 89, "s" => 86, "c" => 78, "g" => 63, "n" => 58, "p" => 55, "m" => 50, "b" => 44, "d" => 36, "f" => 28, "h" => 25, "k" => 19, "v" => 13, "w" => 11, "y" => 4, "j" => 3, "x" => 2, "z" => 2, "q" => 1})

		#_possible = ["OUTSTATE", "ROUGHAGE", "WORKFARE", "TRIPTANE", "OUTSTARE", "OBDURATE", "INTONATE", "NOMINATE", "INITIATE", "INDICATE", "TRUNCATE", "SUBFRAME", "GRILLAGE", "GRILLADE", "MUCKRAKE", "INUNDATE", "MISSHAPE", "COGITATE", "MISSTATE", "IRRIGATE", "DRIFTAGE", "PROPHASE", "CORONATE", "PROPHAGE", "CRISPATE", "CONFLATE", "SUNSHADE", "BONIFACE", "ROOMMATE", "LIFTGATE", "MISPLACE", "FOLKTALE", "SUBSCALE", "DOMINATE", "CORNCAKE", "SULPHATE", "JUBILATE", "IDOCRASE", "IODINATE", "BUTYRATE", "BOOKCASE", "TRIPLANE", "DIOPTASE", "BIJUGATE", "TRIPHASE", "SHOWCASE", "SIMULATE", "ULTIMATE", "WORKMATE", "UMPIRAGE", "BOLDFACE", "SUBULATE", "IMMOLATE", "FUMIGATE", "CULTRATE", "SIBILATE", "PRISTANE", "SUBSTATE", "SUBSTAGE", "SUPINATE", "INVOCATE", "SPILLAGE", "MOSCHATE", "MOTIVATE", "FOOTPACE", "CHORDATE", "INSOLATE", "INCUDATE", "STOPPAGE", "COPULATE", "SHIITAKE", "PROSTATE", "ROSULATE", "OPPILATE", "SPOILAGE", "BLOVIATE", "CRUCIATE", "CHLORATE", "TRUCKAGE", "TRISTATE", "TUBULATE", "COHOBATE", "MITIGATE", "PYRUVATE", "MILLIARE", "OFFSTAGE", "MULTIAGE", "PURCHASE", "MISUSAGE", "ORDINATE", "FROTTAGE", "OBTURATE", "DISHWARE", "POSTGAME", "COINMATE", "BUNKMATE", "GIFTWARE", "USTULATE", "POPULATE", "PUPILAGE", "GLISSADE", "BIRDCAGE", "DUMBCANE", "INCHOATE", "SLIPCASE", "SHIPMATE", "INNOVATE", "BILOBATE", "NONIMAGE", "TORQUATE", "UNORNATE", "POPULACE", "COLOCATE", "SORORATE", "OUTGLARE", "COOKWARE", "SUBPHASE", "IRONWARE", "OUTTRADE", "UMBONATE", "SUITCASE", "CLODPATE", "VIZIRATE", "SKIPLANE", "LOCULATE", "OUTBRAVE", "OBLIGATE", "TOLLGATE", "MUCILAGE", "SUBGRADE", "CONCLAVE", "SILOXANE", "TUNICATE", "SUFFRAGE", "MODULATE", "INTIMATE", "MORTGAGE", "SCYPHATE", "BUTYLATE", "INSULATE", "IRRITATE", "SILICATE", "UNCINATE", "CUPULATE", "SUBOVATE", "CUMULATE", "PLUSSAGE", "STOCKADE", "UNGULATE", "THIRLAGE", "FRONTAGE", "URTICATE", "FIGURATE", "MILLRACE", "PILOTAGE", "FILTRATE", "BOOTLACE", "UNDULATE", "BLINDAGE", "LORICATE", "POSTBASE", "LIGULATE", "MURICATE", "MUTILATE", "POUNDAGE", "FIRMWARE", "SPOLIATE", "INURBANE", "MISGRADE", "PLOTTAGE", "FRUITAGE", "TITIVATE", "FLUXGATE", "SOFTWARE", "OUTSWARE", "LUNULATE", "BURGRAVE", "PRIORATE", "LOBULATE", "JUGULATE", "BIFORATE", "LITIGATE", "DISPLACE", "PROGRADE", "SUFFLATE", "DISSUADE", "INHUMANE", "CRIBBAGE", "SONICATE", "FOOTRACE", "SLIPPAGE", "OUTSHAME", "VICINAGE", "POSTFACE", "FLOORAGE", "MIDSPACE", "SUBSPACE", "NONGLARE", "MUSICALE", "BROCKAGE", "OSCULATE", "CRISTATE", "MISFRAME", "SHORTAGE", "LUSTRATE", "DISGRACE", "STUMPAGE", "RUMINATE", "TUTORAGE", "INDURATE", "INCUBATE", "NICKNAME", "MILLCAKE", "PUNCTATE", "INTUBATE", "CHROMATE", "OUTBLAZE", "POSTDATE", "MISSPACE", "THIONATE", "OUTSKATE", "MISTRACE", "FULLFACE", "VOLPLANE", "BLOCKADE", "BLOCKAGE", "KILOBASE", "COROTATE", "SURICATE", "POSTRACE", "TINPLATE", "DIGITATE", "MILITATE", "PURSLANE", "ROSTRATE", "SLIPWARE"]
		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e"]
		_guess_letter = "t"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{3, pass_info}
	end

	def simulate_reduce_sequence(1, 4) do

		size = 79

		tally = Counter.new(%{"i" => 43, "o" => 42, "u" => 40, "l" => 35, "c" => 29, "n" => 27, "r" => 24, "s" => 20, "m" => 17, "b" => 15, "p" => 13, "d" => 12, "h" => 9, "g" => 9, "v" => 6, "f" => 6, "j" => 3, "y" => 2, "k" => 2, "x" => 1, "z" => 1, "w" => 1})

		#_possible = ["OBDURATE", "NOMINATE", "INDICATE", "INUNDATE", "IRRIGATE", "CORONATE", "CRISPATE", "CONFLATE", "ROOMMATE", "DOMINATE", "SULPHATE", "JUBILATE", "IODINATE", "BIJUGATE", "SIMULATE", "WORKMATE", "SUBULATE", "IMMOLATE", "FUMIGATE", "SIBILATE", "SUPINATE", "INVOCATE", "MOSCHATE", "CHORDATE", "INSOLATE", "INCUDATE", "COPULATE", "ROSULATE", "OPPILATE", "BLOVIATE", "CRUCIATE", "CHLORATE", "COHOBATE", "PYRUVATE", "ORDINATE", "COINMATE", "BUNKMATE", "POPULATE", "INCHOATE", "SHIPMATE", "INNOVATE", "BILOBATE", "UNORNATE", "COLOCATE", "SORORATE", "UMBONATE", "CLODPATE", "VIZIRATE", "LOCULATE", "OBLIGATE", "MODULATE", "SCYPHATE", "INSULATE", "SILICATE", "UNCINATE", "CUPULATE", "SUBOVATE", "CUMULATE", "UNGULATE", "FIGURATE", "UNDULATE", "LORICATE", "LIGULATE", "MURICATE", "SPOLIATE", "FLUXGATE", "LUNULATE", "PRIORATE", "LOBULATE", "JUGULATE", "BIFORATE", "SUFFLATE", "SONICATE", "OSCULATE", "RUMINATE", "INDURATE", "INCUBATE", "CHROMATE", "SURICATE"]
		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "t"]

		_guess_letter = "o"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{4, pass_info}		
	end

	def simulate_reduce_sequence(1, 5) do

		size = 37

		tally = Counter.new(%{"u" => 29, "i" => 24, "l" => 16, "n" => 13, "c" => 12, "s" => 12, 
											"r" => 10, "g" => 8, "m" => 7, "p" => 7, "b" => 6, "d" => 5, "f" => 4, 
											"h" => 3, "j" => 3, "v" => 2, "y" => 2, "k" => 1, "x" => 1, "z" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "o", "t"]

		_guess_letter = "i"
		
		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{5, pass_info}		
	end

	def simulate_reduce_sequence(1, 6) do

		size = 13

		tally = Counter.new(%{"u" => 12, "l" => 10, "n" => 4, "p" => 4, "s" => 4, "c" => 3, "g" => 3, "b" => 2, "f" => 2, "h" => 2, "m" => 2, "y" => 2, "d" => 1, "k" => 1, "j" => 1, "r" => 1, "v" => 1, "x" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "i", "o", "t"]
	
		_guess_letter = "l"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{6, pass_info}		
	end

	def simulate_reduce_sequence(1, 7) do

		size = 7

		tally = Counter.new(%{"u" => 7, "c" => 2, "g" => 2, "n" => 2, "s" => 2, "b" => 1, "d" => 1, "f" => 1, "j" => 1, "m" => 1, "p" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "i", "l", "o", "t"]

    _guess_letter = "c"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: "" }

		{7, pass_info}		
	end

	def simulate_reduce_sequence(1, 8) do

		size = 2

		tally = Counter.new(%{"u" => 2, "m" => 1, "p" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "c", "e", "i", "l", "o", "t"]

		_guess_letter = "m"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: "" }

		{8, pass_info}		
	end

	def simulate_reduce_sequence(1, 9) do

		size = 1

		tally = Counter.new(%{"u" => 2})

		#_possible = ["CUMULATE"]
		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "c", "e", "i", "l", "m", "o", "t"]

		_guess_word = "cumulate"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: "cumulate" }

		{9, pass_info}		
	end



	# Game 2, word is: avocado

	def simulate_reduce_sequence(2, 1) do
		
		size = 23208

		tally = Counter.new(%{"e" => 15273, "s" => 12338, "i" => 11028, "a" => 10830, 
			"r" => 10516, "n" => 8545, "t" => 8034, "o" => 7993, "l" => 7946, "d" => 5995, 
			"u" => 5722, "c" => 5341, "g" => 4590, "p" => 4308, "m" => 4181, "h" => 3701, 
			"b" => 3292, "y" => 2564, "f" => 2115, "k" => 2100, "w" => 1827, "v" => 1394, 
			"z" => 611, "x" => 504, "j" => 412, "q" => 301})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = []
		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{1, pass_info}
	end

	def simulate_reduce_sequence(2, 2) do

		size = 7395

		tally = Counter.new(%{"i" =>  4824, "a" =>  4607, "s" =>  4139, "n" =>  3721, "o" =>  3632,
		 "r" =>  2819, "l" =>  2779, "t" =>  2699, "u" =>  2432, "g" =>  2228, "c" =>  2048, 
		 "m" =>  1694, "p" =>  1537, "h" =>  1522, "d" =>  1490, "y" =>  1364, "b" =>  1252, "k" =>  816, 
		 "f" =>  815, "w" =>  648, "v" =>  312, "z" =>  206, "j" =>  159, "x" =>  143, "q" =>  102})


		_guessed = ["e"]
		_guess_letter = "a"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{2, pass_info}
	end

	def simulate_reduce_sequence(2, 3) do
		
		size = 48

		tally = Counter.new(%{"s" =>  25, "r" =>  23, "i" =>  20, "n" =>  16, "l" =>  15, "t" =>  13,
		 "o" =>  12, "c" =>  11, "h" =>  11, "m" =>  11, "d" =>  7, "w" =>  7, "y" =>  7, "b" =>  6,
		  "g" =>  6, "p" =>  6, "f" =>  5, "u" =>  5, "k" =>  4, "v" =>  2, "j" =>  1})


		_guessed = ["a", "e"]
		_guess_letter = "s"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{3, pass_info}
	end

	def simulate_reduce_sequence(2, 4) do

		size = 23

		tally = Counter.new(%{"r" =>  13, "i" =>  11, "c" =>  8, "t" =>  8, "m" =>  7, "o" =>  7,
		 "n" =>  6, "d" =>  5, "l" =>  5, "g" =>  4, "h" =>  4, "p" =>  4, "b" =>  3, "k" =>  3, "w" =>  3,
		 "y" =>  3, "f" =>  2, "u" =>  2, "v" =>  1})

		_guessed = ["a", "e", "s"]
		_guess_letter = "r"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{4, pass_info}
	end

	def simulate_reduce_sequence(2, 5) do

		size = 10

		tally = Counter.new(%{"i" =>  6, "o" =>  5, "g" =>  4, "m" =>  4, "l" =>  4, "n" =>  4,
		 "t" =>  3, "c" =>  2, "d" =>  2, "f" =>  2, "p" =>  2, "y" =>  2, "b" =>  1, "h" =>  1,
		 "u" =>  1, "v" =>  1})

		_guessed = ["a", "e", "r", "s"]
		_guess_letter = "i"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{5, pass_info}
	end

	def simulate_reduce_sequence(2, 6) do

		size = 4

		tally = Counter.new(%{"o" =>  3, "d" =>  2, "m" =>  2, "l" =>  2, "p" =>  2, "y" =>  2,
		 "c" =>  1, "g" =>  1, "n" =>  1, "u" =>  1, "v" =>  1})

		_guessed = ["a", "d", "e", "r", "s"]
		_guess_letter = "d"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{6, pass_info}
	end

	def simulate_reduce_sequence(2, 7) do

		size = 1

		tally = Counter.new(%{"o" => 2, "v" => 1, "c" => 1})

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: "avocado"}

		{7, pass_info}
	end

	def simulate_reduce_sequence(2, 8) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{8, pass_info}
	end

	def simulate_reduce_sequence(2, 9) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{9, pass_info}
	end



	# Game 3, word is eruptive

	def simulate_reduce_sequence(3, 1) do
		
		size = 28558

		tally = Counter.new(%{"e" =>  19600, "s" =>  16560, "i" =>  15530, "a" =>  14490, "r" =>  14211,
			"n" =>  12186, "t" =>  11870, "o" =>  11462, "l" =>  11026, "d" =>  8046, "c" =>  7815,
			"u" =>  7377, "g" =>  6009, "m" =>  5793, "p" =>  5763, "h" =>  5111, "b" =>  4485, "y" =>  3395,
			"f" =>  2897, "k" =>  2628, "w" =>  2313, "v" =>  2156, "z" =>  783, "x" =>  662,
			"q" =>  422, "j" =>  384})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = []
		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{1, pass_info}
	end

	def simulate_reduce_sequence(3, 2) do

		size = 101

		tally = Counter.new(%{"i" =>  61, "a" =>  56, "l" =>  50, "t" =>  42, "o" =>  34, "s" =>  34,
			"n" =>  31, "c" =>  30, "r" =>  27, "u" =>  23, "p" =>  22, "v" =>  21, "d" =>  20, "g" =>  20,
			"b" =>  18, "m" =>  14, "x" =>  14, "h" =>  12, "y" =>  5, "z" =>  5, "q" =>  4, "k" =>  3, 
			"f" =>  2, "w" =>  1})

		_guessed = ["e"]
		_guess_letter = "a"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{2, pass_info}
	end

	def simulate_reduce_sequence(3, 3) do
		
		size = 45

		tally = Counter.new(%{"i" =>  36, "o" =>  25, "l" =>  21, "s" =>  19, "c" =>  14,
			"p" =>  14, "r" =>  14, "n" =>  11, "u" =>  11, "t" =>  11, "d" =>  8, "g" =>  8,
			"x" =>  8, "m" =>  7, "v" =>  7, "b" =>  6, "h" =>  4, "y" =>  4, "z" =>  4, 
			"k" =>  3, "f" =>  1, "q" =>  1})

		_guessed = ["a", "e"]
		_guess_letter = "i"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{3, pass_info}
	end

	def simulate_reduce_sequence(3, 4) do

		size = 14

		tally = Counter.new(%{"o" =>  9, "s" =>  7, "l" =>  6, "u" =>  6, "c" =>  5, "r" =>  5, 
			"g" =>  4, "t" =>  4, "v" =>  4, "n" =>  3, "x" =>  3, "m" =>  2, "p" =>  2, "z" =>  2, 
			"d" =>  1, "f" =>  1, "h" =>  1})

		_guessed = ["a", "e", "i"]
		_guess_letter = "o"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{4, pass_info}
	end

	def simulate_reduce_sequence(3, 5) do

		size = 5

		tally = Counter.new(%{"u" =>  4, "v" =>  4, "s" =>  3, "r" =>  2, "t" =>  2, "c" =>  1,
		 "d" =>  1, "f" =>  1, "h" =>  1, "m" =>  1, "l" =>  1, "n" =>  1, "p" =>  1})

		_guessed = ["a", "e", "i", "r"]
		_guess_letter = "r"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{5, pass_info}
	end

	def simulate_reduce_sequence(3, 6) do

		size = 1

		tally = Counter.new(%{"u" => 1, "p" => 1, "t" => 1, "v" => 1})

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: "eruptive"}

		{6, pass_info}
	end

	def simulate_reduce_sequence(3, 7) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{7, pass_info}
	end

	def simulate_reduce_sequence(3, 8) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{8, pass_info}
	end

	def simulate_reduce_sequence(3, 9) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{9, pass_info}
	end



	# Game 4

	def simulate_reduce_sequence(4, 1) do

		size = 0

		tally = Counter.new

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = []
		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{1, pass_info}
	end

	def simulate_reduce_sequence(4, 2) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{2, pass_info}
	end

	def simulate_reduce_sequence(4, 3) do
		
		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{3, pass_info}
	end

	def simulate_reduce_sequence(4, 4) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{4, pass_info}
	end

	def simulate_reduce_sequence(4, 5) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{5, pass_info}
	end

	def simulate_reduce_sequence(4, 6) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{6, pass_info}
	end

	def simulate_reduce_sequence(4, 7) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{7, pass_info}
	end

	def simulate_reduce_sequence(4, 8) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{8, pass_info}
	end

	def simulate_reduce_sequence(4, 9) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{9, pass_info}
	end

end