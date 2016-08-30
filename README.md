# Hangman

Plays really fun hangman games.  What did you expect? :)


Hangman --> 
https://en.wikipedia.org/wiki/Hangman_(game)

To see inner game play details go to config/config.exs and change logger :info to :debug and rebuild mix compile then mix escript.build or do a release build or to suppress details do vice versa

NOTES: 

The web mode is able to play parallel games using all CPU cores

The hangman game handles word not in dictionary cases.  
Current procedure is the Player.Worker crashes and is restarted to resume where it left off.

Currently the IO will ocassionally double buffer


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

fred_feed --> Game 1 has started
fred_feed Game 1, secret length --> 9
fred_feed Game 1, letter --> e
fred_feed Game 1, Round 1, status --> --E-----E; score=1; status=KEEP_GUESSING

fred_feed Game 1, letter --> a
fred_feed Game 1, Round 2, status --> --E--A--E; score=2; status=KEEP_GUESSING

fred_feed Game 1, letter --> l
fred_feed Game 1, Round 3, status --> --E--A-LE; score=3; status=KEEP_GUESSING

fred_feed Game 1, letter --> n
fred_feed Game 1, Round 4, status --> --E--A-LE; score=4; status=KEEP_GUESSING

fred_feed Game 1, letter --> c
fred_feed Game 1, Round 5, status --> --EC-ACLE; score=5; status=KEEP_GUESSING

fred_feed Game 1, word --> spectacle
fred_feed Game 1, Round 6, status --> SPECTACLE; score=5; status=GAME_WON

fred_feed Game Over!! --> Game Over! Average Score: 5.0, # Games: 1, Scores:  (SPECTACLE: 5)



./hangman_game -n enrico -t human -r 2

Player enrico, Round 1, ----------; score=0; status=KEEP_GUESSING.
5 weighted letter choices :  e*:15606 i:13788 s:13226 r:11925 a:11763 (* robot choice)
[Please input letter choice] 

Player enrico, Round 2, ----------; score=1; status=KEEP_GUESSING.
5 weighted letter choices :  i*:3852 a:3276 o:3157 n:2993 s:2968 (* robot choice)
[Please input letter choice] 

Player enrico, Round 3, ------I---; score=2; status=KEEP_GUESSING.
5 weighted letter choices :  s*:309 o:255 a:246 t:214 n:207 (* robot choice)
[Please input letter choice] 

Player enrico, Round 4, ------I--S; score=3; status=KEEP_GUESSING.
5 weighted letter choices :  n:106 o*:104 a:98 t:70 l:57 (* robot choice)
[Please input letter choice] 

Player enrico, Round 5, ------I-NS; score=4; status=KEEP_GUESSING.
5 weighted letter choices :  a*:39 o:38 t:36 l:21 c:15 (* robot choice)
[Please input letter choice] 

Possible hangman words left, 3 words: ["barbarians", "dalmatians", "mammalians"]

Player enrico, Round 6, -A--A-IANS; score=5; status=KEEP_GUESSING.
5 weighted letter choices :  l:2 m:2 b*:1 d:1 r:1 (* robot choice)
[Please input letter choice] 

Player enrico, Round 7, -A--A-IANS; score=6; status=KEEP_GUESSING.
Last word left: barbarians

BARBARIANS; score=6; status=GAME_WON

Player enrico, Round 1, ------; score=0; status=KEEP_GUESSING.
5 weighted letter choices :  e*:9356 s:6981 a:6599 r:6097 i:5518 (* robot choice)
[Please input letter choice] 

Player enrico, Round 2, -E--E-; score=1; status=KEEP_GUESSING.
5 weighted letter choices :  r*:273 d:266 s:199 t:152 l:146 (* robot choice)
[Please input letter choice] 

Player enrico, Round 3, -E--ER; score=2; status=KEEP_GUESSING.
5 weighted letter choices :  t*:50 l:41 d:32 n:30 a:29 (* robot choice)
[Please input letter choice] 

Player enrico, Round 4, -E--ER; score=3; status=KEEP_GUESSING.
5 weighted letter choices :  l*:32 d:28 a:22 n:19 i:15 (* robot choice)
[Please input letter choice] 

Player enrico, Round 5, -E--ER; score=4; status=KEEP_GUESSING.
5 weighted letter choices :  d:18 n*:17 a:12 i:11 s:10 (* robot choice)
[Please input letter choice] 

Possible hangman words left, 7 words: ["deafer", "decker", "defier", "deicer", "denier", "denser", "dewier"]

Player enrico, Round 6, DE--ER; score=5; status=KEEP_GUESSING.
5 weighted letter choices :  i:4 c*:2 f:2 n:2 a:1 (* robot choice)
[Please input letter choice] 

Possible hangman words left, 3 words: ["defier", "denier", "dewier"]

Player enrico, Round 7, DE-IER; score=6; status=KEEP_GUESSING.
3 weighted letter choices :  f*:1 n:1 w:1 (* robot choice)
[Please input letter choice] 

Game Over! Average Score: 6.5, # Games: 2, Scores:  (BARBARIANS: 6) (DEFIER: 7)




Further Notes:
        
        Unit tests are not fully complete but there are a handful in test/hangman. 
        There is "some" truth here: Dave Thomas - Agile is Dead ->  https://www.youtube.com/watch?v=a-BOSpxYJ9M 

        Also, the hangman file directory structure is flat in lib/hangman.  There should be
        directories under lib/hangman technically following the modules names but for portfolio
        simplicity purposes keeping all in the top level directory.


Future wishlist

       One game server being able to handle multiple concurrent different player games

       Players being able to communicate with each other e.g. using a lookup registry to find other players
       and being able to play in tandem

       A new type cyborg which alternates between human and robot playing

       A stumper word process which plays the games before hand with all the words and identifies
       the word stumpers for use in real game play

       New strategy algorithms which try to learn player's guessing style - aka machine learning

       Truly distributed hangman which is on multiple nodes and machines - always running