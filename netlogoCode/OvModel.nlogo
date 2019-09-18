breed [females female]
breed [males male]

females-own [female_MV female_attractiveness Ftype cue_modulator f_cue_modulator i_cue_modulator 
  ovulating cycle_day males_on_patch cur_mate mate_list pregnant offspring_investment offspring_count 
  cum_paternal_i aggressor aggress_damage]  ;amp_amount is how much females enhance thier fertile appearance when ovulating (either actively or passively)
males-own [male_MV male_attractiveness move_threshold cur_mate mate_list male_promiscuity]

to setup
 ca
 random-seed new-seed
 
 ;;THIS SEEMS TO BE NECESSARY TO AVOID ANY DIEQUILIBRIUM IN INITIALIZING TWO TYPES OF FEMALE AGENTS
 ifelse random-float 1 < 0.5 [
   create-AcSig
   create-Cons
   ]
 [
   create-Cons
   create-AcSig
   ]
  
 create-males num_males
  [
  set shape "male"
  setxy random-xcor random-ycor
  set male_MV random-normal 50 5 ; sets males to mate value average 50 sd 5
  set male_attractiveness male_MV
  set mate_list []
  ifelse prop_m_promiscuity > random 100  [set male_promiscuity 100] [set male_promiscuity 0]
  ]
  
 ask turtles [update-screen]
 color-turtles
end

to create-AcSig
  create-females AcSig_num
  [
    set shape "female"
    set Ftype 1
    set color red
    set cycle_day random 28
    set female_MV random-normal 50 SD_female_MV ; sets females to mate value average 50 sand sd set by SD_female_MV
    set mate_list []
    set pregnant 0
    set offspring_investment 0
    set f_cue_modulator initial_f_mod
;    set f_cue_modulator 1
;    set i_cue_modulator 1
    ifelse decrement = TRUE [
      set i_cue_modulator (( 24 - ((f_cue_modulator - 1) * 4)) / 24) ;  This sets i_cue_mod so that average desirability modification is the same over the cycle
      ]
    [
      set i_cue_modulator 1
      ]
    ;;set i_cue_modulator (( 28 - ((f_cue_modulator - 1) * 0)) / 28) ;  This sets i_cue_mod so that average desirability modification is the same over the cycle
    ;; THIS MEANS THAT c_cue_modulator is 0.958 when initial_f_mod is 1.25
    ifelse prop_f_aggress > random 100  [set aggressor 1] [set aggressor 0]
    setxy random-xcor random-ycor
    set-cue
    set aggress_damage 0
  ]
end

to create-Cons
  create-females FertConceal_num
  [
    set shape "female"
    set Ftype 0
    set color pink
    set cycle_day random 28
    set female_MV random-normal 50 SD_female_MV ; sets females to mate value average 50 and sd set by SD_female_MV
    set mate_list []
    set pregnant 0
    set offspring_investment 0
    set f_cue_modulator 1 
    set i_cue_modulator 1 
    ifelse prop_f_aggress > random 100  [set aggressor 1] [set aggressor 0]
    setxy random-xcor random-ycor
    set-cue
    set aggress_damage 0
  ]
end

to go   
 ask females 
  [
  ifelse pregnant = 0                                      ;if females aren't pregnant/lactating they 'invest' in cycleling, if they are pregnant/lactating
   [
   set heading random 360
   fd 1
   cycle
   ]
   [
   set offspring_investment offspring_investment + 1
   if offspring_investment > 1999 
    [
    set offspring_count offspring_count + 1
    set pregnant 0
    set offspring_investment 0
    ]
   ]
  set-cue                            ;sets the effect of fertility on desirability
  update-screen
  set males_on_patch count males-here
  ifelse males_on_patch > 0 
   [
   let temp max [male_attractiveness] of males-here  
   set cur_mate [who] of one-of males-here with [male_attractiveness = temp]     ;selects one of the highest mate value males from the current patch
   set mate_list fput cur_mate mate_list                                         ;adds him to the mate list
   let my_who who
   if (cycle_day > 11 and cycle_day < 16) and (preg_likelihood > random 100)       ;if she is fertile, she can get pregnant
;   if (cycle_day > 7 and cycle_day < 22) and (preg_likelihood > random 100)       ;if she is fertile, she can get pregnant
     [
     set pregnant 1
     set cycle_day -1
     ]
    ask turtle cur_mate                                                           ;sets the male partners current mate to self and adds self to his mate list
     [
     set cur_mate my_who
     set mate_list fput cur_mate mate_list 
     ]
    ]
    [
    set cur_mate -1  
    ]  
    if (likelihood_f_aggress > random 100) [aggress-to-rivals]
    decay-aggress-damage               ;the effects of past aggression are reduced
    set-aggression-damage              ;deducts the damage from aggression from desirability
  ]
  
  
 ask males
  [
  ifelse count females-here > 0  ;execute this if there are more than 0 females in your current location
   [
    ifelse male_promiscuity > random 100                          ;this is ifelse because energy is either spent on search or offspring of partner
    [
    set move_threshold max [female_attractiveness] of females-here 
    set heading random 360  ;now promiscuous males start by moving a bit and looking around
    fd 1 
    if (count females in-radius search_radius > 0)                 ;this way the model doesn't halt if there are no females in search radius 
     [
     ifelse max [female_attractiveness] of females in-radius search_radius > move_threshold
      [
      ;print "temptation"    
      move-to max-one-of females in-radius search_radius [female_attractiveness]
      ]
    ;execute this if you are not switching partners
      [
      ]
     ]
    ]
    
    [
    move-to turtle cur_mate
    ask turtle cur_mate
     [
     set offspring_investment offspring_investment + 1       ;if energy not spent on mate search, gets spent on offspring of partner
     set cum_paternal_i cum_paternal_i + 1                   ;female tracks total paternal investment
     ]  
    ]
   ]
  ;execute this if there are no females in your current locations  
  [
  ifelse count females in-radius search_radius > 0  
   [
   move-to max-one-of females in-radius search_radius [female_attractiveness]  
   ]
  ;if no females in search radius set heading randomly and move fd 1 
   [
   set heading random 360  
   fd 1
   ]
  ]
 ]
 
 
 color-turtles
 tick
 update-plots
 ;check-print
end

to cycle
 set cycle_day (cycle_day + 1)
 if cycle_day > 28
  [set cycle_day 1]
end

to set-cue
 ifelse (cycle_day > 11 and cycle_day < 16) 
 ;;ifelse (cycle_day > 7 and cycle_day < 22) 
  [
  set ovulating 1
  set cue_modulator f_cue_modulator
  ]
  [
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ----------------------- ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;; SHOULDN'T BE THIS "0"??
  ;;set ovulating 1
  set ovulating 0
  set cue_modulator i_cue_modulator
  ]
 set female_attractiveness (female_MV * cue_modulator)

end


to aggress-to-rivals
       ;the cost to females of aggressing affects aggress_damage (i.e., as in a direct fight where it may be costly to aggress)
   if aggressor = 1 
    [
    if (count females in-radius competitor_radius > 0)                 ;this way the model doesn't halt if there are no females in competitor radius 
     [
     ifelse f_detectOv? = true  ;if females can detect ovulating females they target ovulators, else they target most attractive female
;     if f_detectOv? = true  ;if females can detect ovulating females they target ovulators, else they target most attractive female
           
       [
       if count females in-radius competitor_radius with [(ovulating = 1) and (Ftype = 1)] > 0 ;if there is a female around who is ovulating and emitting ovulation cues
        [
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ----------------------- ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          ;;; HERE THE TARGET OF THE AGGRESSION WILL BE ANY (ONE-OF) FEMALE IN RADIUS OVULATING WITH TYPE=1 (i.e.,SIGNALING)
        ask one-of females in-radius competitor_radius with [(ovulating = 1) and (Ftype = 1)] 
         [
         set aggress_damage (aggress_damage + costO_aggress)
         ]
        ]
       ]
       
       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ----------------------- ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       ;;;;;;;;;;;;;;;;;;;; THIS IS THE BRANCH  WHERE THE AGGRESSION IS PERFORMED AGAINST ATTRACTIVE FEMALES ;;;;;;;;;;;;;;;;;
       [
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ----------------------- ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          ;;; HERE THE TARGET OF THE AGGRESSION WILL BE ANY FEMALE IN RADIUS MAXIMIZING THE ATTRACTIVENESS (AND WITH ATTRACTIVENESS > MY ATTRACTIVENESS)
          ;;; WHAT ABOUT THE INTERPLAY BETWEEN ATTRACTIVENESS & ABILITY IN PERFORMING AGGRESSION AND / OR TOLERATING THE AGGRESSION ??
       if max [female_attractiveness] of females in-radius competitor_radius > female_attractiveness ;if there is a female around who is more desirable than me
        [
        ask max-one-of females in-radius competitor_radius [female_attractiveness] 
         [
         set aggress_damage (aggress_damage + costO_aggress) ;cost to the target of aggression
         ]
        ]
       ]
       
      set aggress_damage (aggress_damage + costS_aggress) ;this is the cost to the female doing the aggressing
      ]
     ]
end
 
to decay-aggress-damage  
 set aggress_damage (aggress_damage * (1 - ad_decay)) ;where ad_decay is very small
 if aggress_damage < 0 [set aggress_damage 0] ;so aggress_damage cannot be negative
 if aggress_damage > 100 [set aggress_damage 100] ;so aggress_damage cannot be greater than 100%
end

to set-aggression-damage
 set female_attractiveness (female_attractiveness * ( (100 - aggress_damage) / 100 )) ;where aggress damage is a % damage to desirability
end

to color-turtles
 ask males [set color scale-color sky male_promiscuity 200 -100]
 ;ask females
 ; [
 ; ifelse pregnant = 0
 ;  [set color scale-color red female_attractiveness 150 -100]
 ;  [set color scale-color orange offspring_investment 2200 -1000 ]
 ; ] 
end

to update-screen
  ask females
   [   
    set label ""
    if show-males_on_patch?
     [set label males_on_patch]  
   ] 
end

to update-plots
  set-current-plot-pen "AcSigs"
  if count females with [Ftype = 1] > 0
   [
   plot mean [offspring_count] of females with [Ftype = 1]  
   ] 
  set-current-plot-pen "Con"
  if count females with [Ftype = 0] > 0
   [
   plot mean [offspring_count] of females with [Ftype = 0]  
   ] 
  ;set-current-plot-pen "ExSex"
  ;if count females with [Ftype = 2] > 0
  ; [
  ; plot mean [offspring_count] of females with [Ftype = 2]  
  ; ] 
End

to check-print
 if (ticks = 10000)
  [
  print "type 1"  
  ask females with [Ftype = 1]
   [
   show female_MV
   show offspring_count
   ] 
  print "type 2" 
  ask females with [Ftype = 2]
   [
   show female_MV
   show offspring_count
   ]
  ] 
end

@#$#@#$#@
GRAPHICS-WINDOW
366
11
901
567
10
10
25.0
1
10
1
1
1
0
1
1
1
-10
10
-10
10
1
1
1
ticks

BUTTON
35
32
101
65
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
36
104
99
137
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
992
77
1164
110
search_radius
search_radius
0
25
2
1
1
NIL
HORIZONTAL

SWITCH
962
32
1164
65
show-males_on_patch?
show-males_on_patch?
1
1
-1000

SLIDER
992
221
1174
254
prop_m_promiscuity
prop_m_promiscuity
0
100
20
1
1
NIL
HORIZONTAL

SLIDER
992
114
1164
147
preg_likelihood
preg_likelihood
0
100
30
1
1
NIL
HORIZONTAL

MONITOR
35
162
111
207
Pregnancies
count females with [pregnant = 1] / count females
17
1
11

MONITOR
154
163
227
208
Offspring
mean [offspring_count] of females
2
1
11

MONITOR
98
479
188
524
Con Offspring
mean [offspring_count] of females with [Ftype = 0]
2
1
11

MONITOR
14
481
97
526
Con Preg
count females with [pregnant = 1 and Ftype = 0] / count females with [Ftype = 1]
2
1
11

MONITOR
257
164
329
209
Average PI
mean [cum_paternal_i] of females\n
2
1
11

MONITOR
192
482
265
527
Con PI
mean [cum_paternal_i] of females with [Ftype = 0]\n
2
1
11

SLIDER
176
26
348
59
AcSig_num
AcSig_num
0
100
50
1
1
NIL
HORIZONTAL

MONITOR
13
421
97
466
Ac Preg
count females with [pregnant = 1 and Ftype = 1] / count females with [Ftype = 0]
2
1
11

MONITOR
98
425
187
470
Ac Offspring
mean [offspring_count] of females with [Ftype = 1] 
2
1
11

MONITOR
191
425
262
470
Ac PI
mean [cum_paternal_i] of females with [Ftype = 1]
2
1
11

PLOT
34
226
332
399
RS of Strategies
Time
RS
0.0
10.0
0.0
5.0
true
true
PENS
"AcSigs" 1.0 0 -2674135 true
"Con" 1.0 0 -2064490 true

SLIDER
177
69
349
102
FertConceal_num
FertConceal_num
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
996
157
1168
190
num_males
num_males
0
200
100
1
1
NIL
HORIZONTAL

SLIDER
992
583
1164
616
initial_f_mod
initial_f_mod
1
2
1.25
.05
1
NIL
HORIZONTAL

SLIDER
993
546
1165
579
sd_female_MV
sd_female_MV
0
10
10
.5
1
NIL
HORIZONTAL

SLIDER
993
305
1174
338
likelihood_f_aggress
likelihood_f_aggress
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
993
263
1174
296
prop_f_aggress
prop_f_aggress
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
991
351
1175
384
costO_aggress
costO_aggress
0
50
10
1
1
NIL
HORIZONTAL

SLIDER
990
400
1175
433
costS_aggress
costS_aggress
0
10
0
1
1
NIL
HORIZONTAL

SLIDER
992
444
1164
477
ad_decay
ad_decay
0
1
0.01
.01
1
NIL
HORIZONTAL

SLIDER
994
490
1166
523
competitor_radius
competitor_radius
0
50
2
1
1
NIL
HORIZONTAL

MONITOR
264
425
347
470
Ac A-Damage
mean [aggress_damage] of females with [Ftype = 1]
2
1
11

MONITOR
266
481
359
526
Con A-Damage
mean [aggress_damage] of females with [Ftype = 0]
2
1
11

SWITCH
189
117
318
150
f_detectOv?
f_detectOv?
1
1
-1000

SWITCH
770
591
916
624
decrement
decrement
1
1
-1000

@#$#@#$#@
WHAT IS IT?
-----------
This model is designed to explore the viability of hypotheses regarding ovulatory cues and fertility signaling.

HOW IT WORKS
------------
Females have an ovulatory cycle which is 28 days long.  They are considered fertile (i.e., capable of concieving) between days 12-16.  If they are not ovulating, their ovulation cue is (by default) set to 0.  If they are ovulating, they fertile cue is set to the amplification level (amp_amount) particular to that female.  Their fertile cue (between 0-10) gets added to thier mate value (between 0-100) to determine thier overall attractiveness to males.  Females hold thier last mate in cur_mate.

Males have the ability to move to the most attractive female (determined by mate value and fertile cue) within thier search radius (modifiable in the interface).  Females select the male with the highest mate value in their patch to be thier mate.  

Males attractiveness is determined only by thier mate value.  Males have a promiscuity parameter which is the likelihood of leaving the current female if there is a more attractive female within the search radius.

Females get pregnant if they mate with a male during their fertile period with some probability.  If they are pregnant/lactating, they obligately invest 1 unit in thier offspring each time period (else they invest thier 1 unit in cycling).  Males choose to invest thier 1 unit in search (scanning thier radius for fertile females) or thier mate/offspring.


CREDITS AND REFERENCES
----------------------
This model with created by Athena Aktipis and modified by Marco Campenni and Scott Classens. A manuscript reporting results from this model is currently in preparation.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

female
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 150 225 150 300 165 300 165 225
Rectangle -7500403 true true 120 255 195 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

male
false
0
Circle -7500403 true true 83 83 134
Polygon -7500403 true true 210 60 180 90 195 105 225 75 240 90 240 45 195 45 225 75

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment 1 (No Aggression)" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <enumeratedValueSet variable="prop_m_promiscuity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competitor_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ad_decay">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_f_mod">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costO_aggress">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costS_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 2 (Aggression Towards Higher Mate Value)" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <enumeratedValueSet variable="prop_m_promiscuity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competitor_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ad_decay">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_f_mod">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costO_aggress">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costS_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 3 (Aggression Towards Ovulating)" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <enumeratedValueSet variable="prop_m_promiscuity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competitor_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ad_decay">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_f_mod">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costO_aggress">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costS_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sensitivity Analysis 1 (Proportion of Promiscuous Males)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <steppedValueSet variable="prop_m_promiscuity" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competitor_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ad_decay">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_f_mod">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costO_aggress">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costS_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sensitivity Analysis 2 (Decay of Aggression Damage)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <enumeratedValueSet variable="prop_m_promiscuity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competitor_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ad_decay" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="initial_f_mod">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costO_aggress">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costS_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sensitivity Analysis 3 (Cost of Aggression to Self / Other)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <enumeratedValueSet variable="prop_m_promiscuity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competitor_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ad_decay">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_f_mod">
      <value value="1.25"/>
    </enumeratedValueSet>
    <steppedValueSet variable="costO_aggress" first="0" step="0.5" last="2"/>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="costS_aggress" first="0" step="0.5" last="2"/>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sensitivity Analysis 4 (Initial F Mod)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <enumeratedValueSet variable="prop_m_promiscuity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competitor_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search_radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ad_decay">
      <value value="0.01"/>
    </enumeratedValueSet>
    <steppedValueSet variable="initial_f_mod" first="0" step="0.25" last="2"/>
    <enumeratedValueSet variable="costO_aggress">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costS_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sensitivity Analysis 5 (Search and Competitor Radiuses)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [cum_paternal_i] of females with [Ftype = 0]</metric>
    <metric>mean [cum_paternal_i] of females with [Ftype = 1]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 0]</metric>
    <metric>mean [offspring_count] of females with [Ftype = 1]</metric>
    <enumeratedValueSet variable="prop_m_promiscuity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="f_detectOv?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_female_MV">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_males">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competitor_radius" first="2" step="1" last="5"/>
    <steppedValueSet variable="search_radius" first="2" step="1" last="5"/>
    <enumeratedValueSet variable="ad_decay">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_f_mod">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costO_aggress">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AcSig_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FertConceal_num">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decrement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-males_on_patch?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costS_aggress">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="likelihood_f_aggress">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preg_likelihood">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
