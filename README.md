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


<!-- ![Hangman](http://i.imgur.com/m3dh9ny.jpg) -->


To view the game play design please look at the README DIAGRAMS.pdf or click --> 
[Design](https://bitbucket.org/brpandey/elixir-hangman/raw/09d55957c1a4745de60b813fdcf9bf3cb8fc3db3/README%20DIAGRAMS.pdf)




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
  "Game Over! Average Score: 7.11, # Games: 100, Scores: (ACETIC: 5) 
  (ACQUISITION: 5) (AFTERMOST: 4) (ALLOWEDLY: 6) (ALMANDITE: 3) (ALTERABILITY: 6) 
  (BAGGERS: 11) (BOTONEE: 5) (BRAVES: 10) (BURGLARIES: 6) (BURNER: 25) (CAROLI: 6) 
  (CATHOLICATES: 3) (CIRCULARITY: 5) (CORACLE: 7) (CORACLE: 7) (CRIBBING: 10) 
  (CYCLICLY: 7) (DASHES: 8) (DEFINIENS: 4) (DEMONIZED: 9) (DEREPRESSES: 3) 
  (DEUCING: 10) (DEVILS: 8) (DEZINCING: 6) (DISESTABLISHES: 5) (DORMIE: 9) 
  (DOUGHNUTLIKE: 5) (DRIVABILITIES: 4) (EMEUS: 25) (EPIGONI: 3) (EQUERRIES: 4) 
  (FALLACIOUS: 7) (FLOODS: 8) (FORESEERS: 4) (FREESTYLER: 3) (FRICANDEAUS: 4) 
  (FUTILITARIANS: 4) (GENEALOGICALLY: 3) (GLANDS: 10) (GONOCOCCAL: 4) (HEMATOCRITS: 5) 
  (HETAIRA: 6) (HOMOTHALLISM: 6) (HURLINGS: 10) (HYLOZOISMS: 25) (IMMUNOGLOBULINS: 4) 
  (IMPROVISOR: 5) (INDIVIDUALITIES: 2) (INFUSIONS: 6) (INHABITANCY: 4) (IRREVERSIBLY: 5) 
  (LANGREL: 6) (LINESMEN: 6) (MEATLOAF: 4) (MISSUSES: 5) (MISSY: 25) (MORTALS: 8) 
  (NOTED: 9) (NURSERS: 6) (OBJURGATORY: 5) (OUTBRIBES: 7) (PAPAVERINES: 6) (PILSENER: 6) 
  (POLYPLOID: 5) (PRESENTERS: 5) (PSEPHOLOGIES: 5) (PSEUDOPODIUM: 5) (RAMOSELY: 5) 
  (REASSEMBLY: 5) (RECHANNELED: 4) (REFURBISHES: 5) (RESPONSUM: 6) (SALPID: 6) 
  (SATINWOOD: 4) (SECULARISMS: 5) (SIEGED: 5) (SKATOLS: 7) (SLAGGIER: 10) (SNIPPET: 5) 
  (SODOMIST: 7) (SOLFEGGIOS: 5) (SUPERPIMP: 6) (TECHNIC: 6) (TRAPEZES: 7) (TROWSERS: 6) 
  (TZIMMESES: 6) (UNREASONED: 4) (UNREVISED: 3) (UPCOILS: 25) (UPDIVED: 6) (VAMPERS: 25) 
  (WASHROOM: 7) (WORRYWART: 7) (WORSHIPED: 5) (YARDMEN: 5) (YIRTHS: 25) (ZEALOTS: 9) 
  (ZEALOUSNESS: 5) (ZOOGLOEAE: 3)"
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
