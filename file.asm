;=============================================================================================
;= Fajl u kojem se nalaze sve potrebne metode koje sluze za rad sa fajlovima
;=============================================================================================

;------------------------------------------------------------------------
;- Funkcija koja sluzi za otvaranje fajla
;- @param registar DI - adresa gde se nalazi 
;-			naziv kako treba da se nazove fajl.
;-			Naziv fajla koji treba da se zavrsi sa 0,
;-			tj. string treba da bude u format ASCIIZ (ASCII-Zero)
;- Napomena: Ova funkcija koristi promenljivu filehndl za rad sa fajlom
;------------------------------------------------------------------------
open_file:
	; funkcija prekida 21h za otvaranje/pravljenje fajla
	mov ah, 03Ch
	; atribut za fajl - normal file
	mov cx, 020h
	; naziv fajla koji treba da se zavrsi sa 0, tj. string treba da bude u format ASCIIZ (ASCII-Zero)
	lea dx, [di]
	; Pozivam int 21h
	int 21h
	; posle poziva int 21h sa funkcijom 03Ch u registru ax se nalazi "handler" za rad sa fajlom
	mov [filehndl], ax
	; Zavrsen rad sa funkcijom
	ret

;--------------------------------------------------------------------------------------------------------
;- Funkcija koja sluzi za upis u fajl
;- @param registar CX - treba postaviti broj bajtova koje treba upisati u fajl
;- @param registar DX - treba postaviti adresa poruke koju treba upisati u fajl 
;- Napomena: Ova funkcija koristi promenljivu filehndl za rad sa fajlom
;--------------------------------------------------------------------------------------------------------
write_file:
	; Posto u ovoj "funkcija" koristi registar AH prvo da sacuvam registar AX da ne bi pokvario podatke	
	push ax
	; Posto u ovoj "funkcija" koristi registar BH prvo da sacuvam registar BX da ne bi pokvario podatke
	push bx
	
	; Funkcija prekida 21h za upis u fajl
	mov ah, 040h
	; handler fajla treba postaviti u registar bx
	mov bx, [filehndl]
	; Pozivam interapt 21h
	int 21h
	
	; Vracam sa steka vrednost registra BX, koju sam sacuva na pocetku ove "funkcije"
	pop bx
	; Vracam sa steka vrednost registra AX, koju sam sacuva na pocetku ove "funkcije"
	pop ax
	
	; Vracam se tamo gde sam i pozvao ovu "funkciju", tacnije na narednu instrukciju
	ret
	
;--------------------------------------------------------------------------------------------------------
;- Funkcija koja sluzi da se zatvori fajl
;- Napomena: Ova funkcija koristi promenljivu filehndl za rad sa fajlom
;--------------------------------------------------------------------------------------------------------
close_file:
	; Posto u ovoj "funkcija" koristi registar AH prvo da sacuvam registar AX da ne bi pokvario podatke	
	push ax
	; Posto u ovoj "funkcija" koristi registar BH prvo da sacuvam registar BX da ne bi pokvario podatke
	push bx
	
	; Funkcija 03Eh prekida 21 sluzi za zatvaranje fajla
	mov ah, 03Eh
	; U BX stvljamo handler od fajla koji treba da zatvorim
	mov bx, [filehndl]
	; Pozivam interapt 21h
	int 21h
	
	; Vracam sa steka vrednost registra BX, koju sam sacuva na pocetku ove "funkcije"
	pop bx
	; Vracam sa steka vrednost registra AX, koju sam sacuva na pocetku ove "funkcije"
	pop ax
	
	; Vracam se tamo gde sam i pozvao ovu "funkciju", tacnije na narednu instrukciju
	ret
	
;--------------------------------------------------------------------------------------------------------
;- Funkcija koja sluzi da se obrise fajl
;- Napomena: Ova funkcija koristi promenljivu filehndl za rad sa fajlom
;--------------------------------------------------------------------------------------------------------
delete_file:
	; Posto u ovoj "funkcija" koristi registar AH prvo da sacuvam registar AX da ne bi pokvario podatke	
	push ax
	
	; Funkcija 41h prekida 21 sluzi za brisanje fajla
	mov ah, 41h
	; Pozivam interapt 21h
	int 21h
	
	; Vracam sa steka vrednost registra AX, koju sam sacuva na pocetku ove "funkcije"
	pop ax
	
	; Vracam se tamo gde sam i pozvao ovu "funkciju", tacnije na narednu instrukciju
	ret	
	
	; postavljanje pocetka video segmenta u es registar, naravno da bi to uradio
	; moram da zongliram registrima :)
	;mov ax, VIDEO_SEGMENT
	;mov es, ax
	