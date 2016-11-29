Hangman
=======
![Logo](https://bytebucket.org/brpandey/elixir-hangman/raw/46754306a02ecaad07edb9a71ad1c7769dd2ddaa/priv/images/hangman.jpg)

> Definition of Hangman
>
> Hangman is a paper and pencil guessing game for two or more players. 
> One player thinks of a word, phrase or sentence and the other tries 
> to guess it by suggesting letters or numbers, 
> within a certain number of guesses.
>
–  [Wikipedia](https://en.wikipedia.org/wiki/Hangman_(game))


Plays really fun hangman word games. What did you expect? :)

Plays interactive games allowing the user to choose letters
or allows the computer to guess instead.  Supports parallel play using 
CPU cores concurrently. Only when the set of secrets is 40 or greater 
is this speedup tangible

## Links

* Comic -> [9 Ways of Hangman](http://i.imgur.com/m3dh9ny.jpg)

* Game play design -> [README DIAGRAMS](https://bitbucket.org/brpandey/elixir-hangman/raw/929b9fb119a0fb32385a0f64b6e77ed121835359/README%20DIAGRAMS.pdf)

* Feature highlights -> [FEATURES](https://bitbucket.org/brpandey/elixir-hangman/raw/a10e3e0bc827ae55f11f35a0b53fcb5576204d65/FEATURES.md)


## Usage

* Hangman runs both interactive human games with manually specified
secrets e.g. --secrets or runs games with randomly generated secrets 
e.g. --random.  Interactivity is denoted by the player type `-t`,  
with values of either human or robot.

* The random `-r` secret generation option allows you to play without
knowing the secret hangman word(s) beforehand as the system randomly
selects the secret(s) to play against.

* Robot games are auto-guessed based on simple strategy heuristics. 

* Player game archival can be captured through logging, e.g. --log option
The display and log options are exclusive to the command line client. 
The human guessing timeout `-ti` option allows values between 0 secs and 10 secs
to choose a letter. The parallel `-pl` option allows games to be played on 
all the cores of your system

Command Line options:

```elixir    
    --name (player id) --type ("human" or "robot") --random (num random secrets, max 1000) 
    [--secret (hangman word(s)) --baseline] [--log --display --timeout] [--parallel]

    or aliases: 

    -n (player id) -t ("human" or "robot") -r (num random secrets, max 1000) 
    [-s (hangman word(s)) -bl] [-l -d -ti] [-pl]
```

## Install

### Step 1 - Git clone
```
    $  git clone https://brpandey@bitbucket.org/brpandey/elixir-hangman.git
```

### Step 2 - Build executable
```
    $  cd elixir-hangman
    $  mix compile
    $  mix escript.build
```

### Step 3 - Run game
```
    $  ./hangman_game -n toad -t robot -r 3
```

or alternatively you can run the release version for the web mode

```
    $  mix deps.get
    $  MIX_ENV=prod mix compile --no-debug-info
    $  MIX_ENV=prod mix release

    $  rel/hangman_game/bin/hangman_game start or use iex -S mix
```

## Examples

### Game Play - 1

Command Line - Robot type with secret specified with display feed

```elixir
    ./hangman_game -n mario -t robot -s spectacle -d

    mario_feed --> Game 1 has started
    mario_feed Game 1, secret length --> 9
    mario_feed Game 1, letter --> e
    mario_feed Game 1, Round 1, status --> --E-----E; score=1; status=KEEP_GUESSING

    mario_feed Game 1, letter --> a
    mario_feed Game 1, Round 2, status --> --E--A--E; score=2; status=KEEP_GUESSING

    mario_feed Game 1, letter --> l
    mario_feed Game 1, Round 3, status --> --E--A-LE; score=3; status=KEEP_GUESSING

    mario_feed Game 1, letter --> n
    mario_feed Game 1, Round 4, status --> --E--A-LE; score=4; status=KEEP_GUESSING

    mario_feed Game 1, letter --> c
    mario_feed Game 1, Round 5, status --> --EC-ACLE; score=5; status=KEEP_GUESSING

    mario_feed Game 1, word --> spectacle
    mario_feed Game 1, Round 6, status --> SPECTACLE; score=5; status=GAME_WON

    mario_feed Game Over!! --> 
    Game Over! Average Score: 5.0, Games: 1, Scores:  (SPECTACLE: 5)
```

### Game Play - 2

Command Line - Human type with 2 random words requested

```elixir
    ./hangman_game -n luigi -t human -r 2

    Player luigi, Round 1, ----------; score=0; status=KEEP_GUESSING.
    5 weighted letter choices :  e*:15606 i:13788 s:13226 r:11925 a:11763 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 2, ----------; score=1; status=KEEP_GUESSING.
    5 weighted letter choices :  i*:3852 a:3276 o:3157 n:2993 s:2968 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 3, ------I---; score=2; status=KEEP_GUESSING.
    5 weighted letter choices :  s*:309 o:255 a:246 t:214 n:207 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 4, ------I--S; score=3; status=KEEP_GUESSING.
    5 weighted letter choices :  n:106 o*:104 a:98 t:70 l:57 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 5, ------I-NS; score=4; status=KEEP_GUESSING.
    5 weighted letter choices :  a*:39 o:38 t:36 l:21 c:15 (* robot choice)
    [Please input letter choice] 

    Possible hangman words left, 3 words: ["barbarians", "dalmatians", "mammalians"]

    Player luigi, Round 6, -A--A-IANS; score=5; status=KEEP_GUESSING.
    5 weighted letter choices :  l:2 m:2 b*:1 d:1 r:1 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 7, -A--A-IANS; score=6; status=KEEP_GUESSING.
    Last word left: barbarians

    BARBARIANS; score=6; status=GAME_WON

    Player luigi, Round 1, ------; score=0; status=KEEP_GUESSING.
    5 weighted letter choices :  e*:9356 s:6981 a:6599 r:6097 i:5518 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 2, -E--E-; score=1; status=KEEP_GUESSING.
    5 weighted letter choices :  r*:273 d:266 s:199 t:152 l:146 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 3, -E--ER; score=2; status=KEEP_GUESSING.
    5 weighted letter choices :  t*:50 l:41 d:32 n:30 a:29 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 4, -E--ER; score=3; status=KEEP_GUESSING.
    5 weighted letter choices :  l*:32 d:28 a:22 n:19 i:15 (* robot choice)
    [Please input letter choice] 

    Player luigi, Round 5, -E--ER; score=4; status=KEEP_GUESSING.
    5 weighted letter choices :  d:18 n*:17 a:12 i:11 s:10 (* robot choice)
    [Please input letter choice] 

    Possible hangman words left, 7 words: ["deafer", "decker", "defier", 
    "deicer", "denier", "denser", "dewier"]

    Player luigi, Round 6, DE--ER; score=5; status=KEEP_GUESSING.
    5 weighted letter choices :  i:4 c*:2 f:2 n:2 a:1 (* robot choice)
    [Please input letter choice] 

    Possible hangman words left, 3 words: ["defier", "denier", "dewier"]

    Player luigi, Round 7, DE-IER; score=6; status=KEEP_GUESSING.
    3 weighted letter choices :  f*:1 n:1 w:1 (* robot choice)
    [Please input letter choice] 

    Game Over! Average Score: 6.5, Games: 2, Scores:  (BARBARIANS: 6) (DEFIER: 7)
```

### Game Play - 3

Command Line - Parallel option with 100 secrets

Open another terminal window and type `top` and press `1` to see all cores or `htop` which will automatically show the cores
After the below command has been issued, check the the cpu utilization of the cores while this runs!

```elixir
$ ./hangman_game -n yoshi -pl -r 100
   "Game Over! Average Score: 6.91, Games: 100, Scores: (BARRELS: 5) (BETIDES: 6) 
   (BRANDERS: 8) (BRILLIANTLY: 3) (BUCKISH: 10) (BUCKSHEES: 2) (CAGILY: 10) 
   (CHAFFIEST: 9) (CHARBROILER: 5) (CIRCULATABLE: 4) (CLOBBERED: 9) (COENURI: 5) 
   (CONCURRENT: 6) (CONSULTANTS: 7) (COWEDLY: 8) (CURBER: 25) (CYANOGENS: 7) 
   (DANDRIFFS: 8) (DARKENS: 10) (DEFLECTABLE: 4) (DICLINY: 7) (DOBIES: 8) 
   (DOWNPLAYS: 7) (DOZENS: 8) (ECOTYPES: 7) (ELECTROMETERS: 2) (ELEGIZING: 5) 
   (ENTASIS: 5) (ERYTHORBATE: 3) (EXTEMPORIZER: 9) (EXTENSIONALITY: 5) (FLAGPOLE: 6) 
   (FRAGMENTATES: 3) (GASTRONOMY: 6) (GEMLIKE: 7) (GENUINENESSES: 2) (HETEROCLITE: 3) 
   (IMPRESSION: 3) (INNOCUOUSLY: 4) (JACKFISH: 8) (LAYABOUT: 8) (LEPIDOPTERISTS: 2) 
   (LINGERER: 8) (LOVINGNESSES: 6) (LUMINOUSNESSES: 5) (MAILABILITIES: 5) (MARABOUTS: 7) 
   (MICROANALYST: 4) (MISPENNED: 6) (MISYOKING: 8) (MULTIENGINES: 3) (NEOPHILIAS: 6) 
   (NILGAIS: 5) (NONSALABLE: 4) (ORDEAL: 5) (OSCILLATES: 5) (OVERHUNTED: 7) 
   (PACHYSANDRA: 3) (PARIS: 25) (PHILIPPICS: 4) (PLACARDING: 6) (PREDELIVERIES: 3) 
   (PYLORUS: 25) (PYRRHICS: 8) (RACED: 6) (REEFS: 8) (RELUCTANT: 6) (REPERCUSSION: 4) 
   (RHIZOMES: 5) (ROOMETTE: 5) (ROUBLES: 10) (SAFROL: 9) (SHIVER: 10) (SNOWMOBILIST: 5) 
   (SOCIALIZED: 5) (SOVEREIGNS: 4) (SPRINGBOARD: 4) (STEDFAST: 5) (STRAIGHTEN: 6) 
   (SUBCENTERS: 5) (SUBSHELLS: 7) (SWIMMINGLY: 6) (SYMMETRIZATIONS: 4) (SYMPHONIST: 7) 
   (TENSIOMETER: 3) (TIGHTENER: 3) (TUTUS: 25) (UNBRILLIANT: 4) (UNHARNESSED: 3) 
   (UNINTERRUPTEDLY: 2) (VERBALISM: 7) (WEATHERBOARDED: 4) (WIDGEON: 8) (WINES: 25) 
   (WINIER: 25) (WONDERMENTS: 6) (WOODHENS: 9) (XENIAS: 8) (ZIGGURAT: 6) (ZIRCONIUM: 5)"
```

### Game Play - 4

Web Example - Single Game

```elixir
    $ iex -S mix
    Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:2:2] [async-threads:10] ...

    iex>       HTTPoison.get("http://127.0.0.1:3737/hangman?name=princess&secret=woodpecker")
    {:ok,
     %HTTPoison.Response{body: "(H) -----E--E-; score=1; status=KEEP_GUESSING 
     (H) -----E--E-; score=2; status=KEEP_GUESSING 
     (H) -----E--ER; score=3; status=KEEP_GUESSING 
     (H) -----E--ER; score=4; status=KEEP_GUESSING 
     (H) -----E--ER; score=5; status=KEEP_GUESSING 
     (H) -----E--ER; score=6; status=KEEP_GUESSING 
     (H) -----E--ER; score=7; status=KEEP_GUESSING 
     (H) WOODPECKER; score=7; status=GAME_WON 
     (H) Game Over! Average Score: 7.0, Games: 1, Scores:  (WOODPECKER: 7) ",
      headers: [{"server", "Cowboy"}, {"date", "Mon, 29 Aug 2016 01:20:45 GMT"},
       {"content-length", "435"},
       {"cache-control", "max-age=0, private, must-revalidate"},
       {"content-type", "text/plain; charset=utf-8"}], status_code: 200}}
```

## Appendices

### Notes
        
* Optional -- configure `config/config.exs` to see inner game play details.
Specifically change :info to :debug and then run `mix compile` and then `mix escript.build`

```elixir

    config :logger, :console,
-->   level: :info,
      format: "\n$time $metadata[$level] $levelpad$message\n",
      metadata: [:module]
```

* The web and cli modes are able to play parallel games using all CPU cores. To tangibly
  see the speedup of parallelization use 40 secrets or more.  For cli mode, simply use the 
  random option to specify a value like 60 secrets with the parallel option.  e.g. -n luigi -pl -r 60

* The hangman game handles word not in dictionary cases.  The current procedure is the Player.Worker crashes and is restarted to resume where it left off.

* The dictionary ingestion is handled through multiple GenStage Flows.  Lastly it is written to an ets dump file for
  near instantaneous load.

* If a "mix test" is run, the free version of Quick Check from quvic should be installed to avoid errors

* The hangman file directory structure is flat in lib/hangman.  There should technically be
directories under lib/hangman following the dotted modules names but for portfolio
simplicity purposes all are in the top level directory.


### Wishlist

* One game server being able to handle multiple concurrent different player games

* Multiple players on a single game. Players being able to communicate with each other 
  e.g. using a lookup registry to find other players and being able to play in tandem

* A new type cyborg which alternates between human and robot playing

* A stumper word process which plays the games before hand with all the words and identifies 
the word stumpers for use in real game play

* New strategy algorithms which try to learn player's guessing style - aka machine learning.
As well as difficulty level setting: e.g. easy, medium, or hard

* Truly distributed hangman running on multiple nodes and machines to avoid a single point of failure


## Thank You

Enjoy playing!  

**Bibek Pandey**

*bibekp@gmail.com*
