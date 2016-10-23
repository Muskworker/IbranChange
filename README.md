# IbranChange

## What is this?

Automation of [the Ibran sound changes](http://www.frathwiki.com/Ibran_sound_changes) with some additional undeclared changes.  This replaces the abandoned/incomplete [kohath/Ibran-GMP](https://github.com/kohath/Ibran-GMP). 

## Usage

### Inherit from Latin

Convert a Latin word into an Ibran word: To get the Ibran descendant of _verbum_, do:

    ./IbranChange.rb verbum

This produces the below breakdown:

````
## VERBUM > PI vieur [vjœːr], RI вјө̄р / vieur [vjœːr]
0.  | ˈverbum | verbum
1.  | ˈverbu  | verbu
8.  | ˈvɛrbu  | verbu
9.  | ˈvɛrbɔ  | verbo
----------------------- VL verbo
24. | ˈvjɛrbɔ | vierbo
26. | vjɛrb   | vierb
x4. | vjɛwr   | vieur
x6. | vjœːr   | vieur
----------------------- OI vieur
----------------------- CI vieur
RI
----------------------- RI вјө̄р / vieur
PI
----------------------- PI vieur
````

### Borrow from Old Dutch

To convert an Old Dutch / Old Low Franconian word into an Ibran word, add the `--OLF` flag.

    ./IbranChange.rb --OLF wort

This gives:

````
## OLF WORT > PI wort [wɔrt], RI орт / wort [ɔrt]
0.  | wɔrt | wort
----------------- OI wort
----------------- CI wort
RI
5.  | ɔrt  | wort
----------------- RI орт / wort
PI
----------------- PI wort
````

### Reborrow from Latin

To get the outcome of a Latin word reborrowed into Ibran, add the `--LL` flag.

    ./IbranChange.rb --LL verbum

gives:

````
## LL VERBUM > PI vérb [verb], RI вирп / vérb [verp]
0.  | verb | vérb
----------------- CI vérb
RI
9.  | verp | vérb
----------------- RI вирп / vérb
PI
----------------- PI vérb
````

### Verb tables

Get the regular conjugation of a verb.  (Not guaranteed to be good.)

    ./IbranChange.rb -v passāre

````
## PASSĀRE > PI passar [pəˈzɑr], RI пазар / passar [pɑˈzɑr]
0.  | pasˈsaːre | passāre
8.  | pasˈsɑre  | passare
9.  | pɑsˈsɑrɛ  | passare
--------------------------- VL passare
17. | pɑˈsɑrɛ   | passare
26. | pɑˈsɑr    | passar
--------------------------- OI passar
3.  | pɑˈzɑr    | passar
--------------------------- CI passar
RI
--------------------------- RI пазар / passar
PI
5.  | pəˈzɑr    | passar
--------------------------- PI passar
+------------+--------+
| Infinitive | пазар  |
+------------+ passar |
             | pɑˈzɑr |
             +--------+
             | passar |
             | pəˈzɑr |
             +--------+
+---------+
| Present |
+--------------+--------------+--------------+--------------+--------------+--------------+
| па’          | паз          | паз          | пазѡ̄’        | пазѡ̄’        | паз          |
| pass         | passes       | passe        | passaũs      | passaus      | passen       |
| pɑʰ          | pɑz          | pɑz          | pɑˈzoːʰ      | pɑˈzoːʰ      | pɑz          |
+--------------+--------------+--------------+--------------+--------------+--------------+
| pass         | passăs       | passă        | passaus      | passaus      | passăn       |
| pɑs          | ˈpɑzəs       | ˈpɑzə        | pəˈzoːs      | pəˈzoːs      | ˈpɑzə̃        |
+--------------+--------------+--------------+--------------+--------------+--------------+
+-----------+
| Imperfect |
+--------------+--------------+--------------+--------------+--------------+--------------+
| паза         | паза’        | паза         | пазѡ̄’        | пазѡ̄’        | пазан        |
| passa        | passas       | passa        | passaũs      | passaus      | passan       |
| pɑˈzɑ        | pɑˈzɑʰ       | pɑˈzɑ        | pɑˈzoːʰ      | pɑˈzoːʰ      | pɑˈzɑ̃        |
+--------------+--------------+--------------+--------------+--------------+--------------+
| passa        | passas       | passa        | passaus      | passaus      | passan       |
| pəˈzɑ        | pəˈzɑs       | pəˈzɑ        | pəˈzoːs      | pəˈzoːs      | pəˈzɑ̃        |
+--------------+--------------+--------------+--------------+--------------+--------------+
+-----------+
| Preterite |
+--------------+--------------+--------------+--------------+--------------+--------------+
| пазеј        | пазатт       | пазеј        | пазѡ̄’        | пазатт       | пазарон      |
| passei       | passast      | passei       | passaũs      | passastes    | passaron     |
| pɑˈzɛj       | pɑˈzɑtt      | pɑˈzɛj       | pɑˈzoːʰ      | pɑˈzɑtt      | pɑˈzɑrɔ̃      |
+--------------+--------------+--------------+--------------+--------------+--------------+
| passei       | passât       | passei       | passaus      | passâtăs     | passarăn     |
| pəˈzɛj       | pəˈzɑt       | pəˈzɛj       | pəˈzoːs      | pəˈzɑtəs     | pəˈzɑrə̃      |
+--------------+--------------+--------------+--------------+--------------+--------------+
+---------------------+
| Present Subjunctive |
+--------------+--------------+--------------+--------------+--------------+--------------+
| па’          | паз          | па’          | пазө̄’        | пазө̄’        | пазен        |
| pass         | passes       | pass         | passéũs      | passéus      | passen       |
| pɑʰ          | pɑz          | pɑʰ          | pɑˈzøːʰ      | pɑˈzøːʰ      | ˈpɑzɛ̃        |
+--------------+--------------+--------------+--------------+--------------+--------------+
| pass         | passăs       | pass         | passéus      | passéus      | passăn       |
| pɑs          | ˈpɑzəs       | pɑs          | pəˈzøːs      | pəˈzøːs      | ˈpɑzə̃        |
+--------------+--------------+--------------+--------------+--------------+--------------+
+-----------------------+
| Imperfect Subjunctive |
+--------------+--------------+--------------+--------------+--------------+--------------+
| паза’        | пазаз        | паза’        | пазъзө̄’      | пазъзө̄’      | пазазен      |
| passass      | passasses    | passass      | passesséũs   | passesséus   | passassen    |
| pɑˈzɑʰ       | pɑˈzɑz       | pɑˈzɑʰ       | pɑzəˈzøːʰ    | pɑzəˈzøːʰ    | pɑˈzɑzɛ̃      |
+--------------+--------------+--------------+--------------+--------------+--------------+
| passass      | passassăs    | passass      | passesséus   | passesséus   | passassăn    |
| pəˈzɑs       | pəˈzɑzəs     | pəˈzɑs       | pəzəˈzøːs    | pəzəˈzøːs    | pəˈzɑzə̃      |
+--------------+--------------+--------------+--------------+--------------+--------------+
+-------------+
| Conditional |
+--------------+--------------+--------------+--------------+--------------+--------------+
| пазарѡ̄жи     | пазарѡ̄жи     | пазарѡ̄жи     | пазаръжжѡ̄’   | пазаръжжѡ̄’   | пазарѡ̄жи     |
| passareuyée  | passareuyées | passareuyée  | passaresjaũs | passaresjaus | passareuyéen |
| pɑzɑroːˈʝe   | pɑzɑroːˈʝe   | pɑzɑroːˈʝe   | pɑzɑrəˈʒʒoːʰ | pɑzɑrəˈʒʒoːʰ | pɑzɑroːˈʝe   |
+--------------+--------------+--------------+--------------+--------------+--------------+
| passareuyéa  | passareuyéas | passareuyéa  | passaresjaus | passaresjaus | passareuyéan |
| pəzəroːˈjeə  | pəzəroːˈjeəs | pəzəroːˈjeə  | pəzərəˈʒʒoːs | pəzərəˈʒʒoːs | pəzəroːˈjeə̃  |
+--------------+--------------+--------------+--------------+--------------+--------------+
+--------+
| Future |
+--------------+--------------+--------------+--------------+--------------+--------------+
| пазаря̄ш      | пазарѡ̄’      | пазарѡ̄       | пазарѡ̄жө̄’    | пазарѡ̄жө̄’    | пазаравен    |
| passaraez    | passaraus    | passarau     | passareuyéũs | passareuyéus | passaraven   |
| pɑzɑˈraːʃ    | pɑzɑˈroːʰ    | pɑzɑˈroː     | pɑzɑroːˈʝøːʰ | pɑzɑroːˈʝøːʰ | pɑzɑˈrɑvɛ̃    |
+--------------+--------------+--------------+--------------+--------------+--------------+
| passaraez    | passaraus    | passarau     | passareuyéus | passareuyéus | passaravăn   |
| pəzəˈrɑjʃ    | pəzəˈroːs    | pəzəˈroː     | pəzəroːˈjøːs | pəzəroːˈjøːs | pəzəˈrɑvə̃    |
+--------------+--------------+--------------+--------------+--------------+--------------+
+------------+--------+--------+
| Imperative | паз    | пазѡ̄   |
+------------+ passe  | passau |
             | pɑz    | pɑˈzoː |
             +--------+--------+
             | passă  | passau |
             | ˈpɑzə  | pəˈzoː |
             +--------+--------+
+--------+---------+
| Gerund | пазант  |
+--------+ passand |
         | pɑˈzɑ̃t  |
         +---------+
         | passand |
         | pəˈzɑ̃d  |
         +---------+
+-----------------+--------+
| Past Participle | пазѡ̄   |
+-----------------+ passau |
                  | pɑˈzoː |
                  +--------+
                  | passau |
                  | pəˈzoː |
                  +--------+
````

### Special stress rules

Append the following characters to the input to change the stress rules:

* `!` — Force stress on the final syllable, e.g. `illāc!`
* `-` — Force a word to be unstressed (to start with — there's a rule that may assign stress later).
* `>` — Force stress to move one syllable to the right of where it would naturally be. (May need to be escaped, `\>`.)