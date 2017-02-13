;============================================================================================
;= Fajl koji sadrzi funkcije koje sluzi za ispis poruka preko BIOS poziva ili direktno u 
;= memoriju, sve funkcije ocekuju da adresa poruke je postavljena u DI registar
;============================================================================================

;--------------------------------------------------------------------------------------------
;- Funkcija koja sluzi da se poruka upisuje direktno u video memoriju, bez koriscenja 
;- prekida
;- @param registar bx - koristi se za odredjivanje pozicij od koje treba da se ispise tekst
;- @param registar di - u ovaj registar treba da se ucita memorijski pocetak poruke koji
;-						treba da se prikaze
;--------------------------------------------------------------------------------------------
_print_video:
	; cuvam vrednost registra ax posto ce biti koriscen u ovoj funkciji
	push ax
	
	; Posto u registar ES treba da postavim pocetak video segmenta, moram prvo vrednost za pocetak segmenta da stavim u registar AX
	; pa vrednost iz registra AX da prebacim u registar ES. Ovo je moglo da se uradi i sa fintom push VIDEO_SEGMENT pa pop ES, ali
	; posto cu kasnije registar AX korsitit, onda sam ovde resio da njega vec iskoristim
	mov ax, VIDEO_SEGMENT
	; prebacujem vrednost za pocetak video segmenta iz registra u AX u registar ES
	mov es, ax
	; cld - clears the direction flag. Ovu komandu koristim da bi resetovao direction flag (DF) posto kasnije koritim komandu 
	; loadsb koja koristi DF da bi odredila da li povecava ili smanjuje poziciju sa koje ucitava karaktere
	cld

; deo funcije koji se koristi za loop
.prn:
	; LODSB komanda koja ucitava vrednost sa memorijske lokacije [DS:SI] u registar AL. Prilikom poziva ove komande vrednost u regisru SI se povecava ili smanjuje u zavisnosti
	; od vrednost u direction flag-u. Da bi bio siguran da ce se ova vrednost menjati ka vecoj memorijskoj lokaciji sam pozvao komandu cls da bi ocitio direction flag.
	lodsb
	; na ovaj nacin kada se u al nadje nula, posto kada radimo operaciju OR nad nekom vrednoscu sa tom vrednoscu dobija se nula samo kada je ta vrednost nula
	; ovde je takodje moglo cmp al, 0 ali sto ne bi koristio razlicite fore :)
	or al, al
	; Ako je zero flag jednak 0 skacem na kraj posto bi to znacilo da sam u registru al dobio 0 koja oznacava kraj stringa
	jz .end
	; Upis znaka koji se nalazi u registru al na memorijskoj lokaciji [es:bx]
	; u ovom slucaju registar BX se koristi kao pomeraju u okviru video memorije
	mov [es:bx], al
	; Posto u video memoriji za jedan znak se koristi dva bajta (prvi bajt - znak, drugi bajt - boja, da li ce znak da trepti (blink-a)...)
	add bx, 2
	; Posto sam povecao pomeraj u okviru video memorije vracam se na ispis sledeceg znaka
	jmp .prn
; deo funcije koji vraca sa steka sacuvan registar AX i vraca kontrolu delu programa koji je pozvao funkciju _print_video
.end:
	; Posto sam na pocetku ove funkcije sacuva o registar AX vracam mu sacuvanu vrednost
	pop ax
	; Vracam se odakle sam i dosao, odnosno vracam kontrolu onome koje pozvao ovu funkciju
	ret

;--------------------------------------------------------------------------------------------
;- Funkcija koja sluzi da se znak upise direktno u video memoriju, bez koriscenja 
;- prekida
;- @param registar bx - koristi se za odredjivanje pozicij od koje treba da se ispise tekst
;- @param registar cl - u ovaj registar treba da se postavi znak koji treba da se prikaze
;--------------------------------------------------------------------------------------------
_print_video_char:
	; cuvam vrednost registra ax posto ce biti koriscen u ovoj funkciji
	push ax
	
	; Posto u registar ES treba da postavim pocetak video segmenta, moram prvo vrednost za pocetak segmenta da stavim u registar AX
	; pa vrednost iz registra AX da prebacim u registar ES. Ovo je moglo da se uradi i sa fintom push VIDEO_SEGMENT pa pop ES, ali
	; posto cu kasnije registar AX korsitit, onda sam ovde resio da njega vec iskoristim
	mov ax, VIDEO_SEGMENT
	; prebacujem vrednost za pocetak video segmenta iz registra u AX u registar ES
	mov es, ax
	; Upis znaka koji se nalazi u registru CL na memorijskoj lokaciji [es:bx]
	; u ovom slucaju registar BX se koristi kao pomeraju u okviru video memorije
	mov [es:bx], cl

	; Posto sam na pocetku ove funkcije sacuva o registar AX vracam mu sacuvanu vrednost
	pop ax
	; Vracam se odakle sam i dosao, odnosno vracam kontrolu onome koje pozvao ovu funkciju
	ret
	
;-------------------------------------------------
;- Ispisivanje poruke na ekranu upotrebom BIOS-a
;-------------------------------------------------
_print:
	; cuvam vrednost registra ax posto ce biti koriscen u ovoj funkciji
	push ax
	; cld - clears the direction flag. Ovu komandu koristim da bi resetovao direction flag (DF) posto kasnije koritim komandu 
	; loadsb koja koristi DF da bi odredila da li povecava ili smanjuje poziciju sa koje ucitava karaktere
	cld
; deo funcije koji se koristi za loop
.prn:
	; LODSB komanda koja ucitava vrednost sa memorijske lokacije [DS:SI] u registar AL. Prilikom poziva ove komande vrednost u regisru SI se povecava ili smanjuje u zavisnosti
	; od vrednost u direction flag-u. Da bi bio siguran da ce se ova vrednost menjati ka vecoj memorijskoj lokaciji sam pozvao komandu cls da bi ocitio direction flag.	
	lodsb
	; na ovaj nacin kada se u al nadje nula, posto kada radimo operaciju OR nad nekom vrednoscu sa tom vrednoscu dobija se nula samo kada je ta vrednost nula
	; ovde je takodje moglo cmp al, 0 ali sto ne bi koristio razlicite fore :)
	or al, al
	; Ako je zero flag jednak 0 skacem na kraj posto bi to znacilo da sam u registru al dobio 0 koja oznacava kraj stringa
	jz .end	
	; BIOS 10h: ah = 0eh (Teletype Mode), al = znak koji se ispisuje
	mov ah, 0eh
	; BIOS prekid za rad sa ekranom
	int 10h
	; Vracam se na ispis sledeceg znaka
	jmp .prn
; deo funcije koji vraca sa steka sacuvan registar AX i vraca kontrolu delu programa koji je pozvao funkciju _print_video
.end:
	; Posto sam na pocetku ove funkcije sacuva o registar AX vracam mu sacuvanu vrednost
	pop ax
	; Vracam se odakle sam i dosao, odnosno vracam kontrolu onome koje pozvao ovu funkciju
	ret