# Hangman

Plays really fun hangman games.  What did you expect? :)


Hangman --> 
https://en.wikipedia.org/wiki/Hangman_(game)

To see inner game play details go to config/config.exs and change logger :warn to :debug and rebuild mix compile then mix escript.build or do a release build or to suppress details do vice versa

Currently setup in :debug mode to see extra details

Usage

--name (player id) --type ("human" or "robot") --random (num random secrets, max 10) [--secret (hangman word(s)) --baseline] [--log --display]

or aliases: -n (player id) -t ("human" or "robot") -r (num random secrets, max 10) [-s (hangman word(s)) -bl] [-l -d]


$  git clone https://brpandey@bitbucket.org/brpandey/elixir-hangman.git

$  cd elixir-hangman

$  mix compile
$  mix escript.build

$  ./hangman -n fred -t robot -r 3

or you can run the release version for your environment

$  mix deps.get
$  MIX_ENV=prod mix compile --no-debug-info
$  MIX_ENV=prod mix release

$  rel/hangman/bin/hangman start

$  curl "http://127.0.0.1:3737/play?name=julio&secret=woodpecker"
(#) -----E--E-; score=1; status=KEEP_GUESSING (#) -----E--E-; score=2; status=KEEP_GUESSING (#) -----E--ER; score=3; status=KEEP_GUESSING (#) -----E--ER; score=4; status=KEEP_GUESSING (#) -----E--ER; score=5; status=KEEP_GUESSING (#) -----E--ER; score=6; status=KEEP_GUESSING (#) -----E--ER; score=7; status=KEEP_GUESSING (#) WOODPECKER; score=7; status=GAME_WON (#) Game Over! Average Score: 7.0, # Games: 1, Scores:  (WOODPECKER: 7) 

$  curl "http://127.0.0.1:3737/play?name=julio&random=2"
(#) -E-E-----------; score=1; status=KEEP_GUESSING (#) -E-E------A----; score=2; status=KEEP_GUESSING (#) -ESE-S----A----; score=3; status=KEEP_GUESSING (#) DESENSITIZATION; score=3; status=GAME_WON (#) --E----E; score=1; status=KEEP_GUESSING (#) --ER---E; score=2; status=KEEP_GUESSING (#) --ER---E; score=3; status=KEEP_GUESSING (#) --ERT--E; score=4; status=KEEP_GUESSING (#) INERTIAE; score=4; status=GAME_WON (#) Game Over! Average Score: 3.5, # Games: 2, Scores:  (DESENSITIZATION: 3) (INERTIAE: 4)

$  curl "http://127.0.0.1:3737/play?name=julio&random=2"
(#) -------; score=1; status=KEEP_GUESSING (#) --A----; score=2; status=KEEP_GUESSING (#) --A----; score=3; status=KEEP_GUESSING (#) --A--O-; score=4; status=KEEP_GUESSING (#) S-A--O-; score=5; status=KEEP_GUESSING (#) S-A--O-; score=6; status=KEEP_GUESSING (#) S-ALLO-; score=7; status=KEEP_GUESSING (#) SCALLO-; score=8; status=KEEP_GUESSING (#) SCALLOP; score=8; status=GAME_WON (#) ---------E; score=1; status=KEEP_GUESSING (#) A-----A--E; score=2; status=KEEP_GUESSING (#) A-----A--E; score=3; status=KEEP_GUESSING (#) A-----A--E; score=4; status=KEEP_GUESSING (#) AB---BA--E; score=5; status=KEEP_GUESSING (#) ABSORBANCE; score=5; status=GAME_WON (#) Game Over! Average Score: 6.5, # Games: 2, Scores:  (SCALLOP: 8) (ABSORBANCE: 5) 

(NOTE --> Result will be different each time since we are specifying the random n words options)

$  rel/hangman/bin/hangman stop


EXAMPLES:

$ ./hangman -n stanley -t human -r 2

Player stanley, Round 1, -------; score=0; status=KEEP_GUESSING.
5 weighted letter choices :  e*:15273 s:12338 i:11028 a:10830 r:10516 (* robot choice)
[Please input letter choice] e

Player stanley, Round 2, -E----E; score=1; status=KEEP_GUESSING.
5 weighted letter choices :  r*:173 i:144 t:131 a:129 l:115 (* robot choice)
[Please input letter choice] r

Player stanley, Round 3, -E----E; score=2; status=KEEP_GUESSING.
5 weighted letter choices :  i:84 t*:75 l:74 n:63 a:62 (* robot choice)
[Please input letter choice] t

Player stanley, Round 4, -E----E; score=3; status=KEEP_GUESSING.
5 weighted letter choices :  l:50 i*:44 n:33 a:31 s:30 (* robot choice)
[Please input letter choice] i

Player stanley, Round 5, -E----E; score=4; status=KEEP_GUESSING.
5 weighted letter choices :  a*:27 l:26 b:15 n:15 c:14 (* robot choice)
[Please input letter choice] l

Possible hangman words left, 4 words: ["deglaze", "deplane", "deplume", "seclude"]

Player stanley, Round 6, -E-L--E; score=5; status=KEEP_GUESSING.
5 weighted letter choices :  d:4 a*:2 p:2 u:2 c:1 (* robot choice)
[Please input letter choice] p

Possible hangman words left, 2 words: ["deglaze", "seclude"]

Player stanley, Round 7, -E-L--E; score=6; status=KEEP_GUESSING.
5 weighted letter choices :  d:2 a*:1 c:1 g:1 s:1 (* robot choice)
[Please input letter choice] d

Player stanley, Round 8, DE-L--E; score=7; status=KEEP_GUESSING.
Last word left: deglaze

DEGLAZE; score=7; status=GAME_WON

Player stanley, Round 1, ---------; score=0; status=KEEP_GUESSING.
5 weighted letter choices :  e*:18314 s:16133 i:15255 r:13650 a:13625 (* robot choice)
[Please input letter choice] e

Player stanley, Round 2, ------E--; score=1; status=KEEP_GUESSING.
5 weighted letter choices :  s*:1529 i:1051 r:1033 t:948 n:779 (* robot choice)
[Please input letter choice] s

Player stanley, Round 3, ------E-S; score=2; status=KEEP_GUESSING.
5 weighted letter choices :  r*:396 a:245 o:227 l:199 i:198 (* robot choice)
[Please input letter choice] r

Player stanley, Round 4, ------ERS; score=3; status=KEEP_GUESSING.
5 weighted letter choices :  a*:113 i:110 l:104 o:102 n:97 (* robot choice)
[Please input letter choice] a

Player stanley, Round 5, ------ERS; score=4; status=KEEP_GUESSING.
5 weighted letter choices :  i:67 o*:64 l:52 n:48 c:39 (* robot choice)
[Please input letter choice] o

Possible hangman words left, 38 words: ["bicyclers", "blighters", "chucklers", "clinchers", "cucumbers", "cylinders", "divulgers", "dulcimers", "flichters", "flinchers", "imbitters", "impingers", "impugners", "incliners", "incumbers", "indicters", "indulgers", "kibitzers", "knucklers", "milliners", "mimickers", "plighters", "quibblers", "twiddlers", "twinklers", "twitchers", "typifiers", "uglifiers", "unitizers", "unlimbers", "unpuckers", "unwinders", "uplifters", "utilizers", "vilifiers", "vivifiers", "whifflers", "whittlers"]

Player stanley, Round 6, ------ERS; score=5; status=KEEP_GUESSING.
5 weighted letter choices :  i*:34 l:24 n:16 u:16 c:15 (* robot choice)
[Please input letter choice] i

Possible hangman words left, 2 words: ["vilifiers", "vivifiers"]

Player stanley, Round 7, -I-I-IERS; score=6; status=KEEP_GUESSING.
3 weighted letter choices :  f:2 v:2 l*:1 (* robot choice)
[Please input letter choice] v

Player stanley, Round 8, VI-I-IERS; score=7; status=KEEP_GUESSING.
Last word left: vilifiers

VILIFIERS; score=7; status=GAME_WON

Game Over! Average Score: 7.0, # Games: 2, Scores:  (DEGLAZE: 7) (VILIFIERS: 7)



$ ./hangman -n fred -t robot -s spectacle

--E-----E; score=1; status=KEEP_GUESSING

--E--A--E; score=2; status=KEEP_GUESSING

--E--A-LE; score=3; status=KEEP_GUESSING

--E--A-LE; score=4; status=KEEP_GUESSING

--EC-ACLE; score=5; status=KEEP_GUESSING

SPECTACLE; score=5; status=GAME_WON

Game Over! Average Score: 5.0, # Games: 1, Scores:  (SPECTACLE: 5)
