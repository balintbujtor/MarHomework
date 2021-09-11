; -----------------------------------------------------------
; Mikrokontroller alapú rendszerek házi feladat
; Készítette: Bujtor Bálint
; Neptun code: G3M1AW
; Feladat leírása:
;		Adott karaktersorozat (alsztring) megkeresése
;		belső memóriában tárolt sztringben (a sztringek végén lezáró 0 van).
;		Bemenet: sztring kezdőcíme, alsztring kezdőcíme (mutatók).
;		Kimenet: az először megtalált egyezés kezdőcíme a sztringben (mutató).
;		Amennyiben a keresett karaktersorozat nem fordul elő, a mutató a sztring végét jelző 0-ra mutat.
; -----------------------------------------------------------

$NOMOD51 ; a standard 8051 regiszter definíciók nem szükségesek

$INCLUDE (SI_EFM8BB3_Defs.inc) ; regiszter és SFR definíciók

; Ugrótábla létrehozása
	CSEG AT 0
	SJMP Main

myprog SEGMENT CODE			;saját kódszegmens létrehozása
RSEG myprog 				;saját kódszegmens kiválasztása
; ------------------------------------------------------------
; Fõprogram
; ------------------------------------------------------------
; Feladata: a szükséges inicializációs lépések elvégzése és a
;			feladatot megvalósító szubrutin(ok) meghívása
; ------------------------------------------------------------
Main:

	CLR IE_EA ; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh ; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA ; interruptok engedélyezése


;-----------------------------------------------
; string feltöltése (azért nem ciklussal, mert így könnyebben rakhatunk bele
;random elemeket és könnyebben tudunk más adatokat is tesztelni)
;string egy a 0x30as cimtol: almafa0 (ez nem ascii nulla, hanem 0x00)
;alstring a 0x40es cimtol: ez a keresendo alstring szinten 0x00 lezarassal
;-----------------------------------------------

	;string betoltese
	MOV R0, #0x30
	MOV @R0, #'a'
	INC R0
	MOV @R0, #'b'
	INC R0
	MOV @R0, #'a'
	INC R0
	MOV @R0, #'b'
	INC R0
	MOV @R0, #'a'
	INC R0
	MOV @R0, #'c'
	INC R0
	MOV @R0, #0x00

	;substring betoltese
	MOV R0, #0x40
	MOV @R0, #'a'
	INC R0
	MOV @R0, #'b'
	INC R0
	MOV @R0, #'a'
	INC R0
;	MOV @R0, #'k'
;	INC R0
	MOV @R0, #'c'
	INC R0
;	MOV @R0, #'i'
;	INC R0
	MOV @R0, #0x00

	MOV R3, #0x30
	MOV R4, #0x40


	CALL FINDSUBSTRING

;----------------------------------------------------------
;bennehagytam direkt par kikommentezett sort,
;hogy konnyebben lehessen ellenorizni adott esetekre
;----------------------------------------------------------

	JMP $ ;vegtelen ciklusban varakozunk


;------------------------------------------------------------
;FINDSUBSTRING szubrutin
; -----------------------------------------------------------
; Funkció:		megvizsgalja hogy megtalalhato e az alsztring a sztringben
; Bementek:		R3,R4 - a string es az alstring kezdocime
; Kimenetek:  	R2 - a megtalalt alstring kezdocime, ha nincs talalat, akkor a stringlezaro nulla
; A szubrutin ezeket a egisztereket módosítja: A,R0,R1,R2,R3,R4,R5,R6,PSW
; -----------------------------------------------------------
FINDSUBSTRING:
	MOV A, R3
	MOV R0, A ; r0t fogom a string pointerekent/iteratorakent hasznalni
	MOV A, R4
	MOV R1, A ;r1t pedig a substring pointerekent/iteratorakent
	MOV R5, #0x01 ;R5 regisztert fogom ellenorzesre hasznalni, hogy tudjam vissza kell e lepni,
					;az elso korben biztosan nem kell meg visszalepni ezert egyes

LOOP:
	MOV A, @R0 ; accba mozgatom az elemet
	XRL A, @R1 ; xorolom a substring elemevel, ha nulla akkor egyeznek

	JZ ITSAMATCH

	MOV A, R5 ;ha az elozo korben match volt de most nincs akkor r5ben nulla lesz, ekkor vissza kell ugrani
	JZ PREVMATCH

	INC R0 ;ha nincs match akkor csak a string pointeret kell leptetni
CONTINUE:
	MOV R5, #0x01
	MOV A, R0 ;atalittom a matchaddresst a kovetkezo elemre, errol meg nem tudjuk hogy azonos e
	MOV R2, A
	MOV A, R4
	MOV R1, A ;r1et visszaallitom hogy a string elso elemere mutasson
	MOV A, @R0 ;megnezem hogy vege van e a fostringnek, ha nem akkor folytatom a loopot
	JNZ LOOP

ENDOFSEARCH:
	;itt meg azt kell megvizsgalni, hogy ha a stringnek vege es egyezes van az utolso karakterig, viszont az alsztringnek
	;meg nincs vege akkor ne dobjon egyezest

	MOV A, @R1
	JZ ENDOFPROGRAM ; ha vegigertunk az alstringen akkor ertelemszeruen egyezes van, tehat nem kell semmit sem vizsgalni

	XRL A, @R0 ;itt azt nezzuk meg hogy egyezik e az utolso ket elem pl almafa0 es fa0 eseten talalatunk van, ekkor sem kell
				;mast csinalni
	JZ ENDOFPROGRAM

	MOV A, R0 ; kulonben problema van tehat allitani kell a "match" cimet a string vegere
	MOV R2, A

ENDOFPROGRAM: ;szubrutin vege
	RET

ITSAMATCH:
	MOV R5, #0x00
	INC R0
	INC R1 ;match eseten novelem mindketto pointert, hogy a kovetkezo elemre mutassanak
	MOV A, @R1 ;megnezem hogy vege van e az alstringnek
	JZ ENDOFSEARCH ;ha vege akkor loopbol kilepunk
	MOV A, @R0
	JNZ LOOP ;megnezem hogy vege van e a fostringnek, ha nem akkor folytatom a loopot
	JMP ENDOFSEARCH ;ha vege akkor kilepunk a loopbol

PREVMATCH:
	DEC R1
	MOV A, R1
	CLR C
	SUBB A, R4 ; kiszamoljuk hogy meddig jutottunk el a szubsztringben
							;meddig volt match, ennel eggyel kevesebbet kell visszaugrani

	MOV R6, A 	;elmentjuk hogy mennyit kell majd visszamenni a fosztringben
	MOV A, R0
	CLR C
	SUBB A, R6	;ezt kivonjuk a fosztring eppen aktualis ertekebol
	MOV R0, A	;es elmentjuk, hogy innen folytassa tovabb a fostring ellenorzeset
	JMP CONTINUE ;folytatjuk a tovabb mintha siman nem lenne match

END

