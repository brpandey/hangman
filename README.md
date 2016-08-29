# Hangman

Plays really fun hangman games.  What did you expect? :)


Hangman --> 
https://en.wikipedia.org/wiki/Hangman_(game)

To see inner game play details go to config/config.exs and change logger :warn to :debug and rebuild mix compile then mix escript.build or do a release build or to suppress details do vice versa

NOTE: The web mode is able to play parallel games using all CPU cores

NOTE: Currently the IO will ocassionally double buffer

Usage

--name (player id) --type ("human" or "robot") --random (num random secrets, max 10) [--secret (hangman word(s)) --baseline] [--log --display --timeout]

or aliases: -n (player id) -t ("human" or "robot") -r (num random secrets, max 10) [-s (hangman word(s)) -bl] [-l -d -ti]


$  git clone https://brpandey@bitbucket.org/brpandey/elixir-hangman.git

$  cd elixir-hangman

$  mix compile
$  mix escript.build

$  ./hangman_game -n fred -t robot -r 3

or you can run the release version for your environment

$  mix deps.get
$  MIX_ENV=prod mix compile --no-debug-info
$  MIX_ENV=prod mix release

$  rel/hangman_game/bin/hangman_game start or use iex -S mix

$ iex -S mix
Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:2:2] [async-threads:10] [kernel-poll:false]


Interactive Elixir (1.3.2) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>       HTTPoison.get("http://127.0.0.1:3737/hangman?name=melvin&random=200", [],  [recv_timeout: :infinity])
{:ok,
 %HTTPoison.Response{body: " (GROWLER: 11) (CHAIRLIFTS: 5) (BUGGED: 25) (SNOWBLOWERS: 7) (WORKFARE: 9) (SEASIDE: 6) (ACETANILID: 3) (PALPABLE: 5) (OVERRUNNING: 5) (NOMADISM: 7) (ENSHRINING: 5) (NOVAE: 6) (EMBRYOPHYTES: 3) (SELFLESSNESSES: 4) (WORKMATES: 9) (NYALAS: 7) (WINNOCKS: 25) (POACH: 7) (EXACTED: 6) (FOREIGN: 5) (ABDUCED: 7) (STRUNTS: 25) (ORTHODONTICS: 5) (FRECKLIEST: 5) (PERVASION: 6) (DISTRIBUTE: 4) (CONSCRIBING: 6) (LUNATE: 8) (GUIDES: 25) (OUTLASTED: 7) (PULSARS: 5) (HOTDOGS: 9) (SECULARISES: 8) (RESOLIDIFIED: 3) (VAPIDITIES: 8) (SIMPER: 10) (TOSSPOTS: 6) (NIGHTLY: 8) (WEAPONLESS: 3) (WOBBLY: 9) (PARAGENESIS: 5) (SHOWERING: 8) (SUBMUNITIONS: 5) (STRUNTS: 25) (TRANSPLANTED: 6) (FIFTYISH: 6) (STACK: 8) (COMMUNIONS: 6) (CREATINE: 5) (MAINSTAYS: 7) (BIPAROUS: 9) (LACTALBUMINS: 4) (DEMISSIONS: 4) (EXTEMPORANEOUS: 3) (INARTICULACY: 4) (NONAFFILIATED: 3) (CONTEMNING: 5) (MISSENDING: 5) (FLICKERS: 11) (KARYOTYPES: 6) (UNICYCLISTS: 5) (DATELINED: 6) (ENTHUSE: 6) (COGNAC: 6) (OVERMATURITY: 4) (ELECTRONEGATIVE: 1) (PROPENDS: 7) (OFFICIOUS: 6) (LOCATED: 9) (OWLET: 7) (BISHOPRIC: 6) (TERCETS: 5) (ROUGHCAST: 7) (BABYING: 25) (INSENSITIVENESS: 2) (CEREBRUMS: 5) (COCKLE: 9) (DECEITS: 8) (UNTIRED: 25) (PERCEPTIBLE: 3) (BASIFICATION: 6) (NEUROLEPTIC: 4) (POSTSTIMULATION: 4) (CINDERS: 10) (VIRGINAL: 7) (REDFISHES: 3) (FLORIDNESS: 5) (CRANKER: 8) (LAMBKILL: 6) (LEANT: 7) (UNDERNOURISHED: 4) (REVENGEFULNESS: 1) (BISECTIONAL: 4) (OVERRUNNING: 5) (URETHRITIS: 4) (ERYTHROSINE: 2) (CHOWED: 25) (UNSUBDUED: 5) (PROPHECY: 8) (KASHRUTH: 6) (REINDUCES: 4) (SUCTORIAN: 7) (FRIENDLINESS: 3) (HETEROSPOROUS: 5) (BECARPET: 5) (PREORDAINED: 2) (BIOMORPHIC: 3) (GRAMMATICALLY: 3) (ULTRADISTANT: 5) (CONJUNCTIVES: 7) (COTANGENT: 6) (DANDYISM: 7) (STRODE: 8) (DERELICTION: 4) (CADDISH: 9) (BISHOPRIC: 6) (TRIREMES: 2) (RATIOCINATES: 4) (SALLOWING: 25) (JACKBOOT: 8) (PAWKIER: 25) (ABSORBANCES: 4) (LYRICISES: 7) (LANDSMEN: 6) (HEBDOMADAL: 4) (BACKSPACES: 5) (WORDBOOK: 7) (SUCCULENCE: 3) (BRAVERS: 9) (DECEITS: 8) (ALOINS: 8) (PERSONNEL: 5) (OUTPUSHING: 7) (PHOTOIONIZATION: 5) (PIQUET: 25) (ENGARLANDS: 5) (NUCLEOLE: 6) (BLACKCAPS: 6) (TIERCELS: 5) (MILDEWY: 8) (SERVOMOTORS: 5) (DISBOSOMS: 7) (AERIFIES: 6) (SYNTONIC: 6) (VELARS: 8) (OUTSULK: 8) (STRUNTS: 25) (CLINCHES: 9) (IMPERILMENT: 6) (CONVERTIBLES: 6) (BEDIM: 25) (COGITOS: 7) (RUMINATED: 6) (PRETESTING: 5) (PROTOHISTORIAN: 3) (KNUCKLEHEADED: 2) (FIENDISH: 3) (DERELICTION: 4) (SUPPOSITITIOUS: 4) (WITTIER: 7) (DEGLAZES: 7) (CONTEMNING: 5) (LIMELIGHTING: 4) (ALOINS: 8) (AIRBRUSHES: 3) (COGITOS: 7) (DUMBEST: 9) (SUBFREEZING: 3) (GONIDIAL: 6) (POLARIMETERS: 4) (DISTENT: 3) (INSINUATIONS: 4) (CAPITALS: 6) (RESIGNER: 5) (NOMADISM: 7) (UNCRITICALLY: 4) (ZARIBA: 6) (BENEFICIALNESS: 2) (COLIPHAGE: 6) (BOOMERANGING: 6) (EXCURSIVE: 6) (RESTFULNESSES: 3) (HYPOCAUST: 4) (GUNSMITHS: 5) (VERGE: 6) (CLOBBER: 10) (GROUNDWOOD: 6) (SALUBRITY: 5) (DORMANT: 8) (DISHONEST: 3) (BURETS: 6) (RATTAN: 5) (BEACON: 8) (APOLOGIZE: 7) (SELFLESSNESSES: 4) (CLITORAL: 5) (PLEDGING: 9) (SUPERPLASTIC: 6) (KARAOKE: 6) (WIFTIER: 8)",
  headers: [{"server", "Cowboy"}, {"date", "Mon, 29 Aug 2016 01:18:12 GMT"},
   {"content-length", "3039"},
   {"cache-control", "max-age=0, private, must-revalidate"},
   {"content-type", "text/plain; charset=utf-8"}], status_code: 200}}

iex(3)>       HTTPoison.get("http://127.0.0.1:3737/hangman?name=melvin&secret=woodpecker")
{:ok,
 %HTTPoison.Response{body: "(#) -----E--E-; score=1; status=KEEP_GUESSING (#) -----E--E-; score=2; status=KEEP_GUESSING (#) -----E--ER; score=3; status=KEEP_GUESSING (#) -----E--ER; score=4; status=KEEP_GUESSING (#) -----E--ER; score=5; status=KEEP_GUESSING (#) -----E--ER; score=6; status=KEEP_GUESSING (#) -----E--ER; score=7; status=KEEP_GUESSING (#) WOODPECKER; score=7; status=GAME_WON (#) Game Over! Average Score: 7.0, # Games: 1, Scores:  (WOODPECKER: 7) ",
  headers: [{"server", "Cowboy"}, {"date", "Mon, 29 Aug 2016 01:20:45 GMT"},
   {"content-length", "435"},
   {"cache-control", "max-age=0, private, must-revalidate"},
   {"content-type", "text/plain; charset=utf-8"}], status_code: 200}}



EXAMPLES:


./hangman_game -n fred -t robot -s spectacle -d

#fred_feed --> Game 1 has started
#fred_feed Game 1, secret length --> 9
#fred_feed Game 1, letter --> e
#fred_feed Game 1, Round 1, status --> --E-----E; score=1; status=KEEP_GUESSING

#fred_feed Game 1, letter --> a
#fred_feed Game 1, Round 2, status --> --E--A--E; score=2; status=KEEP_GUESSING

#fred_feed Game 1, letter --> l
#fred_feed Game 1, Round 3, status --> --E--A-LE; score=3; status=KEEP_GUESSING

#fred_feed Game 1, letter --> n
#fred_feed Game 1, Round 4, status --> --E--A-LE; score=4; status=KEEP_GUESSING

#fred_feed Game 1, letter --> c
#fred_feed Game 1, Round 5, status --> --EC-ACLE; score=5; status=KEEP_GUESSING

#fred_feed Game 1, word --> spectacle
#fred_feed Game 1, Round 6, status --> SPECTACLE; score=5; status=GAME_WON

#fred_feed Game Over!! --> Game Over! Average Score: 5.0, # Games: 1, Scores:  (SPECTACLE: 5)


#stanley_feed --> Game 1 has started
#stanley_feed Game 1, secret length --> 9

Player stanley, Round 1, ---------; score=0; status=KEEP_GUESSING.
5 weighted letter choices :  e*:18314 s:16133 i:15255 r:13650 a:13625 (* robot choice)
[Please input letter choice] e
#stanley_feed Game 1, letter --> e
#stanley_feed Game 1, Round 1, status --> --E------; score=1; status=KEEP_GUESSING


Player stanley, Round 2, --E------; score=1; status=KEEP_GUESSING.
5 weighted letter choices :  r*:410 s:363 i:354 o:305 a:299 (* robot choice)
[Please input letter choice] r
#stanley_feed Game 1, letter --> r
#stanley_feed Game 1, Round 2, status --> --ER-----; score=2; status=KEEP_GUESSING


Player stanley, Round 3, --ER-----; score=2; status=KEEP_GUESSING.
5 weighted letter choices :  o*:96 s:87 v:75 i:63 l:55 (* robot choice)
[Please input letter choice] s
#stanley_feed Game 1, letter --> s
#stanley_feed Game 1, Round 3, status --> --ER----S; score=3; status=KEEP_GUESSING


Player stanley, Round 4, --ER----S; score=3; status=KEEP_GUESSING.
5 weighted letter choices :  o*:39 v:32 l:25 a:18 i:18 (* robot choice)
[Please input letter choice] #stanley_feed Game 1, letter --> o
[Please input letter choice] #stanley_feed Game 1, Round 4, status --> O-ER----S; score=4; status=KEEP_GUESSING

[Please input letter choice] 
Possible hangman words left, 18 words: ["operatics", "overbills", "overcalls", "overfills", "overfunds", "overgilds", "overhands", "overhangs", "overhauls", "overhunts", "overkills", "overlands", "overmilks", "overplans", "overplays", "overpumps", "overtalks", "overwinds"]

Player stanley, Round 5, O-ER----S; score=4; status=KEEP_GUESSING.
5 weighted letter choices :  v:17 l*:11 a:9 i:7 n:7 (* robot choice)
[Please input letter choice] [Please input letter choice] #stanley_feed Game 1, letter --> v
[Please input letter choice] #stanley_feed Game 1, Round 5, status --> OVER----S; score=5; status=KEEP_GUESSING

[Please input letter choice] 
Possible hangman words left, 17 words: ["overbills", "overcalls", "overfills", "overfunds", "overgilds", "overhands", "overhangs", "overhauls", "overhunts", "overkills", "overlands", "overmilks", "overplans", "overplays", "overpumps", "overtalks", "overwinds"]

Player stanley, Round 6, OVER----S; score=5; status=KEEP_GUESSING.
5 weighted letter choices :  l:11 a*:8 n:7 i:6 d:5 (* robot choice)
[Please input letter choice] [Please input letter choice] 
[Please input letter choice] #stanley_feed Game 1, letter --> l
[Please input letter choice] #stanley_feed Game 1, Round 6, status --> OVER----S; score=6; status=KEEP_GUESSING

[Please input letter choice] 
Possible hangman words left, 6 words: ["overfunds", "overhands", "overhangs", "overhunts", "overpumps", "overwinds"]

Player stanley, Round 7, OVER----S; score=6; status=KEEP_GUESSING.
5 weighted letter choices :  n:5 d*:3 h:3 u:3 a:2 (* robot choice)
[Please input letter choice] [Please input letter choice] 
[Please input letter choice] #stanley_feed Game 1, letter --> n
[Please input letter choice] #stanley_feed Game 1, Round 7, status --> OVER--N-S; score=7; status=KEEP_GUESSING

[Please input letter choice] 
Possible hangman words left, 5 words: ["overfunds", "overhands", "overhangs", "overhunts", "overwinds"]

Player stanley, Round 8, OVER--N-S; score=7; status=KEEP_GUESSING.
5 weighted letter choices :  d:3 h:3 a*:2 u:2 f:1 (* robot choice)
[Please input letter choice] [Please input letter choice] #stanley_feed Game 1, letter --> d
[Please input letter choice] #stanley_feed Game 1, Round 8, status --> OVER--NDS; score=8; status=KEEP_GUESSING

[Please input letter choice] 
Possible hangman words left, 3 words: ["overfunds", "overhands", "overwinds"]

Player stanley, Round 9, OVER--NDS; score=8; status=KEEP_GUESSING.
5 weighted letter choices :  a*:1 f:1 h:1 i:1 u:1 (* robot choice)
[Please input letter choice] [Please input letter choice] 
[Please input letter choice] #stanley_feed Game 1, letter --> a
[Please input letter choice] #stanley_feed Game 1, Round 9, status --> OVER--NDS; score=9; status=KEEP_GUESSING

[Please input letter choice] 
Possible hangman words left, 2 words: ["overfunds", "overwinds"]

Player stanley, Round 10, OVER--NDS; score=9; status=KEEP_GUESSING.
4 weighted letter choices :  f*:1 i:1 u:1 w:1 (* robot choice)
[Please input letter choice] [Please input letter choice] f
[Please input letter choice] #stanley_feed Game 1, letter --> f
[Please input letter choice] #stanley_feed Game 1, Round 10, status --> OVERF-NDS; score=10; status=KEEP_GUESSING

[Please input letter choice] 
Player stanley, Round 11, OVERF-NDS; score=10; status=KEEP_GUESSING.
Last word left: overfunds
[Please input letter choice] #stanley_feed Game 1, word --> overfunds
[Please input letter choice] #stanley_feed Game 1, Round 11, status --> OVERFUNDS; score=10; status=GAME_WON

[Please input letter choice] #stanley_feed Game Over!! --> Game Over! Average Score: 10.0, # Games: 1, Scores:  (OVERFUNDS: 10)




NOTE: Unit tests are not fully complete but there are a handful in test/hangman. 
      There is "some" truth here: Dave Thomas - Agile is Dead ->  https://www.youtube.com/watch?v=a-BOSpxYJ9M 

NOTE: Also, the hangman file directory structure is flat in lib/hangman.  There should be
      directories under lib/hangman technically following the modules names but for portfolio
      simplicity purposes keeping all in the top level directory.