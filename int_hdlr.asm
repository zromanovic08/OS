;=================================================================================
;= Fajl koji sadrzi funkcije koje predstavljaju handler-e za prekide, takodje u 
;= ovom fajlu se nalaze i pomocne fukcije koju su potrebne za handler-e
;=================================================================================

;------------------------------------------------------------------------------
;- Handler za prekid 2Fh (TSR, The multiplex interrupt)
;- @param registar AL - u ovom registru treba proslediti jednu od dve sledece
;-		vrednosti:
;-			1. 00 - provera da li je moj int 2Fh handler instaliran, ako je
;-				ova vrednost prosledjena kao povratnu vrednosti u slucaju da
;-				je moj 2Fh handler instaliran su:
;-					u AL je vrednost 0FFh i pokazivac na ID string u paru
;-					registra ES:DI.
;-			2. 01 - ako treba da obrisem moj 2Fh handler
;- @param registar AH - u ovom registru treba proslediti TSR ID, za koji 
;-		treba proveriti da li moj 2Fh handler.
;------------------------------------------------------------------------------
myInt2F:
	; Uporedjujem prosledjeni TSR ID u registru AH, sa mojim sacuvanom vrednoscu
	; u promenljivoj myTSRID
	cmp ah, [myTSRID]
	; Ako je u pitanju moj handler skacem na funkciju koja treba da obavi ostatak
	; posla za moj 2Fh handler
	je myInt2F_work
	; U slucaju da ne radi se o mom handler treba proslediti predhodnom handler-u
	; za interapt 2Fh koji je sacuvan na memorijskoj lokaciji OldInt2F
	jmp far [cs:OldInt2F]

;------------------------------------------------------------------------------
;- Funkcija koja sluzi da se moj handler za interapt 2Fh obrise ili da se vrati
;- da je vec instaliran. Ovo zavisi od vrednosti prosledjene u registru al.
;- @param registar AL - u ovom registru treba proslediti jednu od dve sledece
;-		vrednosti:
;-			1. 00 - provera da li je moj int 2Fh handler instaliran, ako je
;-				ova vrednost prosledjena kao povratnu vrednosti u slucaju da
;-				je moj 2Fh handler instaliran su:
;-					u AL je vrednost 0FFh i pokazivac na ID string u paru
;-					registra ES:DI.
;-			2. 01 - ako treba da obrisem moj 2Fh handler
;------------------------------------------------------------------------------
myInt2F_work:
	; Proveravm prosledjenu vrednost u registru AL, da bi znako
	; sta treba da radim
	cmp al, 0
	; Ako je AL razlicito od 0 ovaj JUMP ce se izvrsiti i moj handler ce biti obrisan
	jne tryRmv
	; Posto prema specifikacije interapta 2Fh u slucaju da se radi o interat handler
	; koji sam ja intalirao treba da vratim vrednost 0FFh
	mov al, 0ffh
	; Nardne tri linije sluze da se na memorijskoj lokaciji [ES:DI] nadje id moje
	; aplikacije, sto se koristi kao dodatni korak u proveri da li je moj interapt
	; 2Fh handler instaliran
	; Na stek stavljam ds, da ne bi mora da diram registar AX koji vec u sebi ima
	; neku vrednost, naravno mogao sam da koristim neki drugi registar, ali ovako
	; je pretty nice.
	push ds
	; U registar ES stavljam vrednost sa steka, tacnije vrednost koja se nalazi
	; u registru DS
	pop es
	; U registar DI stavljam da se pokazuje na memorijsku lokaciju gde se nalazi
	; id string moje aplikacije
	mov di, idString
	; Posto sam zavrsio rad u interapt handler treba da pozovem iret umesto ret
	iret

;------------------------------------------------------------------------------
;- Funkcija koja sluzi kao handler za prekid za rad sa tastaturom
;------------------------------------------------------------------------------
myInt09:
	; Na stek prebacujem sve registre opste namene
	pusha

	push gs
	pop ds	
	; Pozivam funkcju koja sluzi da proveri da li je pritisnuto F11 da bi se
	; sadrzaj video memorije sacuva u fajlu
	call myInt09_check
	; Sa steka vracam sve registre opste namene
	popa
	; Ovde pozivam stari interapt handler za 09h, jer ako ne bi to uradio
	; korisnik vise ne bi video znakove koje unosi. Odnosno ignoriso bi
	; standardni handler za interapt 09h
	jmp far [cs:OldInt09]

;------------------------------------------------------------------------------
;- Funkcija koja sluzi kao pomocna funkcija za proveru koji je taster pritisnut
;- na tastaturi. I slucaju kada je pritisnut taster F11 sadrzaj video memorije
;- bi ce sacuvan u fajl
;------------------------------------------------------------------------------
myInt09_check:
	; Ucitavam scan_code iz I/O registra tastature  
	in al, KBD
	; Vrednost scan code cuvam u promenljivoj kbdata
    mov [kbdata], al
	; U registar al stavaljam za End Of Interrupt (EOI) da bi tastatura mogla
	; da nastavi sa primanjem novih znakova
    mov al, EOI
	; EOI saljem 8259A (PIC) da bi znao da sam zavrsio sa primanjem podataka
    out Master_8259, al 
	; Proveravm da li se u promenljivoj kbdata nalazi vrednost za scan code za 
	; taster F11, ako se ne nalazi zavrsavm ako ne pozivam funkciju za cuvanje
	; sadrzaja video memorije u fajl
	cmp byte [kbdata], F11
	; Ako je scan code razlicit od F11 ovaj JUMP ce se izvrsiti, a samim tim
	; zavrsavm rad sa ovom funkcijom
    jne .end
	; pozivam funkciju checkInDOSFlag da bi proverio da li mogu da uradim pisanje u fajl
	call checkInDOSFlag
	je .call_printscreen
	
	mov byte [do_printscreen], 1
	jmp .end
.call_printscreen:
	; Pozivam funkciju koja sluzi da se sacuva sadrzaj video memorije u fajl
	call printscreen
.end:
	; Zavrsen rad u funkciji vracam se tamo gde je ova funkcija bila pozvana
	ret
	
;------------------------------------------------------------------------------
;- Funkcija koja sluzi kao handler za prekid 1Ch, korsnicka funkcija za timer
;- Ovde bi trebalo da proverim da li je su ispunjeni svi uslovi za upis u fajl
;------------------------------------------------------------------------------
myInt1C:
	cmp byte [do_printscreen], 0
	je .end
	; jos jednom proveravam InDOS flag
	call checkInDOSFlag
	jne .end
	
	; odma resetujem ovaj flag da se ne bi desio mozda dupli pokusaj upisa
	mov byte [do_printscreen], 0
	
	; Pozivam funkciju koja sluzi da se sacuva sadrzaj video memorije u fajl
	call printscreen
.end:
	jmp far [cs:OldInt1C]

;------------------------------------------------------------------------------
;- Funkcija koja sluzi da proveri InDOS fleg.
;------------------------------------------------------------------------------
checkInDOSFlag:
	pusha
	push es
	
	mov ah, 34h
	int 21h
	
	cmp byte [es:bx], 0	
	
	pop es
	popa
	ret