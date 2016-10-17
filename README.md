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
> – Wikipedia

 [Wikipedia Description](https://en.wikipedia.org/wiki/Hangman_(game))

Plays really fun hangman word games. What did you expect? :)

Plays interactive games allowing the user to choose letters
or allows the computer to guess instead.  Supports parallel play using 
CPU cores concurrently. Only when the set of secrets is 40 or greater 
is this speedup tangible


![Hangman](http://i.imgur.com/m3dh9ny.jpg)


To view the game play design please look at the README DIAGRAMS.pdf or click below
[Hangman Design](https://bitbucket.org/brpandey/elixir-hangman/raw/09d55957c1a4745de60b813fdcf9bf3cb8fc3db3/README%20DIAGRAMS.pdf)




## Usage

* Hangman runs both interactive human games with manually specified
secrets e.g. --secrets or runs games with randomly generated secrets 
e.g. --random, either with interactive game play (human) or not (robot).
Therefore the type of the player `-t` determines the user interaction type.

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
    Game Over! Average Score: 5.0, # Games: 1, Scores:  (SPECTACLE: 5)
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

    Game Over! Average Score: 6.5, # Games: 2, Scores:  (BARBARIANS: 6) (DEFIER: 7)
```

### Game Play - 3

Command Line - Parallel option with 100 secrets

Open another terminal window and type `top` and press `1` to see all cores or `htop` which will automatically show the cores
After the below command has been issued, check the the cpu utilization of the cores while this runs!

```elixir
$ ./hangman_game -n yoshi -pl -r 100
  "Game Over! Average Score: 6.31, # Games: 100, Scores:  (ASSURED: 5) (NARWHALES: 6) 
  (WIRRA: 6) (NURSE: 10) (RETROFIT: 5) (WILLOWWARE: 7) (DOBLAS: 8) (OVOLI: 6) 
  (HUARACHES: 5) (STROBILATIONS: 6) (BEARABLY: 6) (AQUATINTED: 5) (IMMATERIALIZING: 3) 
  (JEALOUSNESS: 5) (DANDLER: 9) (OXYPHIL: 6) (UNILOCULAR: 5) (SUPPOSITION: 4) 
  (WHORING: 9) (WATERPROOFER: 3) (INQUIETS: 6) (ROISTEROUS: 4) (SAPROPEL: 4) 
  (REDBIRDS: 6) (YEGGS: 25) (WIRRA: 6) (COFOUNDS: 5) (BITCHILY: 7) (ALGEBRAICALLY: 4) 
  (RECLAMES: 7) (CYCASIN: 6) (ASSURED: 5) (NONEXPLOSIVE: 5) (UNDERCOATS: 7) 
  (ANTHILLS: 5) (COARSENESSES: 5) (SIMULTANEITY: 2) (INTERCESSORY: 5) (ODORIZE: 5) 
  (STALAGMITIC: 4) (WOESOME: 6) (CAVILING: 6) (ORDINARIES: 6) (RALLY: 7) 
  (INHIBITIONS: 4) (SOTERIOLOGIES: 4) (TRIBE: 9) (STOCKROOMS: 5) (SIPHONED: 7) 
  (EQUESTRIANS: 5) (BOWDLERIZATIONS: 6) (PEEVES: 6) (LUMINESCENCE: 2) (REAVOWING: 6) 
  (AGENTING: 6) (SWEPT: 6) (SWIFTLY: 5) (ETHNOHISTORIAN: 2) (STEWBUM: 7) 
  (PARAMETRICALLY: 3) (ONSCREEN: 4) (PRECODED: 6) (VENDETTA: 6) (PEKOES: 25) 
  (COLOBOMA: 5) (CORROBORATOR: 3) (DEVOICES: 7) (EPICURISMS: 3) (GLUTTING: 10) 
  (RAVIGOTES: 7) (ENFEVERS: 4) (NONHOSTILE: 5) (TUTORED: 8) (CRAWLER: 10) 
  (NATUROPATHS: 5) (THERAPEUTICS: 4) (BASTERS: 6) (BRUTISM: 25) (CONDENSING: 4) 
  (RANKS: 8) (BAPTISE: 6) (SATURNALIAN: 6) (TEMPOS: 6) (PARTNERSHIP: 3) (COLPORTEURS: 5) 
  (CAPORALS: 6) (SMART: 8) (SCRIVE: 9) (BLURRY: 9) (BALLETOMANE: 3) (DANDLER: 9) 
  (PETTIFOG: 5) (PREDOMINANCY: 5) (TAPERED: 6) (DENUDEMENT: 4) (BLOODWORM: 5) 
  (ROSEFISH: 8) (FARDS: 9) (REGRESSORS: 7) (QUIBBLER: 7)"
```

### Game Play - 4

Web Example - Single Game

```elixir
    $ iex -S mix
    Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:2:2] [async-threads:10] ...

    iex>       HTTPoison.get("http://127.0.0.1:3737/hangman?name=princess&secret=woodpecker")
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

* The dictionary logic of the game transforms the original dictionary file multiple times to a format
  suitable for `ETS`.  This was written before `Experimental.GenStage` and each transform file is
  stored in `priv/dictionary/data`.  Though `GenStage` is great, this happens to show each file after
  each transform step which is an interesting transform artifact.

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

* New strategy algorithms which try to learn player's guessing style - aka machine learning

* Truly distributed hangman running on multiple nodes and machines


## Thank You

Enjoy playing!  

**Bibek Pandey**

*bibekp@gmail.com*
