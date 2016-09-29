Hangman
=======

Plays really fun hangman word games.  

Plays interactive games allowing the player to choose letters
or allows the computer robot to guess instead.  

Supports parallel play of games using CPU cores concurrently, 
speeding up the game play of 40 secrets or greater tangibly

What did you expect? :)


[Hangman Description](https://en.wikipedia.org/wiki/Hangman_(game))

> Definition of Hangman
>
> Hangman is a paper and pencil guessing game for two or more players. 
> One player thinks of a word, phrase or sentence and the other tries 
> to guess it by suggesting letters or numbers, 
> within a certain number of guesses.
>
> – Wikipedia


![Hangman](http://i.imgur.com/m3dh9ny.jpg)


To view the game play design please look at the README DIAGRAMS.pdf


### Usage

Hangman runs both interactive human games with manually specified
secrets and also runs games with randomly generated secrets 
either interactive (human) or not (robot).

The random secret generation option allows you to play without
knowing the secret hangman word(s) beforehand as the game randomly
selects the secrets to play against.

Robot games are auto-guessed based on simple strategy heuristics. 
Player game archival can be captured through logging, e.g. --log option

The display and log options are exclusive to the command line client. 
The human guessing timeout option, allows values between 0 secs and 10 secs
to choose a letter. The parallel option allows games to be played on 
all the cores of your system


```elixir    
    --name (player id) --type ("human" or "robot") --random (num random secrets, max 1000) 
    [--secret (hangman word(s)) --baseline] [--log --display --timeout] [--parallel]

    or aliases: 

    -n (player id) -t ("human" or "robot") -r (num random secrets, max 1000) 
    [-s (hangman word(s)) -bl] [-l -d -ti] [-pl]
```


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
    $  ./hangman_game -n fred -t robot -r 3
```

or alternatively you can run the release version for the web mode

```
    $  mix deps.get
    $  MIX_ENV=prod mix compile --no-debug-info
    $  MIX_ENV=prod mix release

    $  rel/hangman_game/bin/hangman_game start or use iex -S mix
```


### Game Play Example 1

Command Line - Robot type with secret specified with display feed

```elixir
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

    fred_feed Game Over!! --> 
    Game Over! Average Score: 5.0, # Games: 1, Scores:  (SPECTACLE: 5)
```

### Game Play Example 2

Command Line - Human type with 2 random words requested

```elixir
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

    Possible hangman words left, 7 words: ["deafer", "decker", "defier", 
    "deicer", "denier", "denser", "dewier"]

    Player enrico, Round 6, DE--ER; score=5; status=KEEP_GUESSING.
    5 weighted letter choices :  i:4 c*:2 f:2 n:2 a:1 (* robot choice)
    [Please input letter choice] 

    Possible hangman words left, 3 words: ["defier", "denier", "dewier"]

    Player enrico, Round 7, DE-IER; score=6; status=KEEP_GUESSING.
    3 weighted letter choices :  f*:1 n:1 w:1 (* robot choice)
    [Please input letter choice] 

    Game Over! Average Score: 6.5, # Games: 2, Scores:  (BARBARIANS: 6) (DEFIER: 7)
```

### Game Play Example 3

Command Line - Parallel option with 100 secrets

Open another terminal window and type `top` and press `1` to see all cores or `atop` which will automatically show the cores
After the below command has been issued, check the the cpu utilization of both cores while this runs!

```elixir
$ ./hangman_game -n yoshi -pl -r 100
" (TUMBLEBUG: 7) (BEATIFIC: 5) (BOUDOIRS: 7) (RAVENOUSNESS: 2) (PLEADING: 10) 
  (CHICANER: 6) (HELMETLIKE: 5) (MISLABEL: 5) (WANDERINGS: 6) (TENDERLY: 4) 
  (TAENIASES: 6) (PROVOCATIVENESS: 6) (SPACESHIPS: 6) (DAYDREAMER: 6) (TALKIE: 5) 
  (BAROUCHE: 5) (REPULSIVE: 7) (PASTINA: 6) (THWARTS: 7) (DEMANDERS: 4) 
  (FOSTERAGES: 4) (COMPUTE: 9) (MISLEADER: 5) (REPPED: 7) (WORSHIPPER: 3) 
  (ABOULIC: 6) (CEROTYPES: 6) (LISLES: 25) (BEHAVIOUR: 4) (ANTIMACASSARS: 3) 
  (BLOWTORCH: 6) (DREDGING: 9) (WIDOWHOODS: 3) (RABIC: 8) (SURVIVABILITIES: 6) 
  (BACKSIDE: 7) (WESTER: 9) (MISFUNCTION: 5) (WREATHEN: 5) (PATCHERS: 9) 
  (REACCLIMATIZE: 2) (TERRIBLENESS: 4) (WANIEST: 9) (DESICCATE: 6) (DINGS: 8) 
  (LANDLUBBERLY: 5) (DOWNTRODDEN: 5) (FADING: 25) (CONCUPISCENCES: 2) (DRIBBLERS: 7) 
  (OUTRANGE: 8) (SYLLABLE: 6) (DUMBFOUNDERING: 4) (MISTIER: 6) (WOLFRAMITES: 5) 
  (DIAPOSITIVE: 4) (GLUCINUM: 6) (ARCHAEANS: 2) (UNDERTRICKS: 4) (LONESOMELY: 5) 
  (CHICANER: 6) (HALYARD: 10) (PLEADING: 10) (CRATED: 9) (RAGGEDY: 5) 
  (CONCUPISCENCES: 2) (CATER: 6) (OUTRODE: 7) (MIDLAND: 7) (NEPHRISMS: 6) 
  (SOUNDS: 7) (AMMONITIC: 4) (GRUNTLED: 25) (KNOBKERRIE: 2) (INTERMEDDLERS: 4) 
  (LEFTISM: 7) (CARVEL: 25) (PSYCHOCHEMICALS: 4) (AGREEABLE: 2) (DOGSLEDS: 7) 
  (OUTSCORNS: 6) (TETRAHYMENAS: 2) (HINTERLANDS: 5) (BOUNCED: 10) (INEDUCABILITIES: 3) 
  (ANTHOPHYLLITE: 5) (ENGARLANDED: 3) (PROPHECIES: 6) (SUPERHEAVY: 5) (SNEAP: 6) 
  (CHARADES: 6) (FUNNER: 25) (RISKING: 10) (PERISHABLES: 3) (SNORT: 9) 
  (ETYMOLOGIST: 3) (URETER: 6) (HETEROGAMOUS: 5) (GRANITELIKE: 3) (ATAXIAS: 6)"
```

### Game Play - Example 4

Web Example - Single Game

```elixir
    iex>       HTTPoison.get("http://127.0.0.1:3737/hangman?name=melvin&secret=woodpecker")
    {:ok,
     %HTTPoison.Response{body: "(#) -----E--E-; score=1; status=KEEP_GUESSING 
     (#) -----E--E-; score=2; status=KEEP_GUESSING 
     (#) -----E--ER; score=3; status=KEEP_GUESSING 
     (#) -----E--ER; score=4; status=KEEP_GUESSING 
     (#) -----E--ER; score=5; status=KEEP_GUESSING 
     (#) -----E--ER; score=6; status=KEEP_GUESSING 
     (#) -----E--ER; score=7; status=KEEP_GUESSING 
     (#) WOODPECKER; score=7; status=GAME_WON 
     (#) Game Over! Average Score: 7.0, # Games: 1, Scores:  (WOODPECKER: 7) ",
      headers: [{"server", "Cowboy"}, {"date", "Mon, 29 Aug 2016 01:20:45 GMT"},
       {"content-length", "435"},
       {"cache-control", "max-age=0, private, must-revalidate"},
       {"content-type", "text/plain; charset=utf-8"}], status_code: 200}}
```


Notes:
        
* Optional -- configure `config/config.exs` to see inner game play details.
Specifically change :info to :debug and then run `mix compile` and then `mix escript.build`

```elixir

    config :logger, :console,
      level: :info,
      format: "\n$time $metadata[$level] $levelpad$message\n",
      metadata: [:module]
```

* The web and cli modes are able to play parallel games using all CPU cores. To tangibly
  see the speedup of parallelization use 40 secrets or more.  For cli mode, simply use the 
  random option to specify a value like 60 secrets with the parallel option.  e.g. -n luigi -pl -r 60

* The hangman game handles word not in dictionary cases.  The current procedure is the Player.Worker crashes and is restarted to resume where it left off.

* The dictionary logic of the game transforms the original dictionary file multiple times to a format
  suitable for `ETS`.  This was written before `Experimental.GenStage` and each format transform is
  stored in `priv/dictionary/data`.  Though `GenStage` is slick, this happens to show each file after
  each transform step which is an interesting transform artifact.

* If a "mix test" is run, the free version of Quick Check from quvic should be installed

* The hangman file directory structure is flat in lib/hangman.  There should be
directories under lib/hangman technically following the modules names but for portfolio
simplicity purposes keeping all in the top level directory.


Wishlist:

* One game server being able to handle multiple concurrent different player games

* Multiple players on a single game. Players being able to communicate with each other 
  e.g. using a lookup registry to find other players and being able to play in tandem

* A new type cyborg which alternates between human and robot playing

* A stumper word process which plays the games before hand with all the words and identifies 
the word stumpers for use in real game play

* New strategy algorithms which try to learn player's guessing style - aka machine learning

* Truly distributed hangman running on multiple nodes and machines



Enjoy!  Bibek Pandey