;===============================================================================================
;= Fajl u kojem se nalaze sve funkcije koje su potrebne za instaliranje i brisanje tsr apliacije
;===============================================================================================

;-------------------------------------------------------------------
;- Funkcija koja sluzi da se proveri da li je moj TSR pokrenut u 
;-		memoriji. Ako je pokrenut korisnik dobija poruku o tome. A 
;-		ako nije onda se pokrece
;- @return u slucaju da postoji ova vrednost ce postaviti zero flag,
;-		a ako ne postoji zero flag ce biti resetovan.
;-------------------------------------------------------------------
tstPresent:
	; Pozivam metodu koja provera da li je moj TSR vec u memoriji. Ako je program vec
	; u memoriji ova funkcija postavlja zero flag (ZF), ako nije cisti ZF
	call seeIfPresent
	; Ako moj TSR nije ucitan ovaj JUMP ce se izvrsiti i skociti na funkciju koja
	; sluzi da probam da ucitan moj TSR
    jne getTSRID
	; Posto ova funkcija koristi registar SI cuva tu vrednost
	push si
	; Posto moj TSR je vec ucitan, hocu da obavesti korisnika
	; Posto funkcija _print ocekuje da se pocetak poruke za prikaz nalazi u registru SI
	mov si, tsr_already_present
	; Poziv funkcje _print
	call _print
	; Na kraju vracam sa stek vrednost koju je registra SI imao pre poziva ove fukcije
	pop si
	; Posto posle stampanja poruke nemam sta vise da radim skacem na kraj
	ret
	
;-------------------------------------------------------------------
;- Funkcija koja sluzi da se proveri da li je moj TSR pokrenut u 
;-		memoriji. I to radi tako sto prolazi kroz sve vrednosti od
;-		0FFh do 0C0h i proverava da li je neki od interat hendler-a
;-		moj. Proveru vrsi tako sto na adresi [ES:DI] ocekuje id string
;-		moje aplikacije. Ako je moj TSR vec ucitan ova funkcija setuje
;-		zero flag (ZF), a ako nije cisti ZF.
;-------------------------------------------------------------------	
seeIfPresent:
	; Na stek prebacujem sadrzaj registra ES, posto prilikom prolaza
	; svih funkcija interapta 2Fh ove vrednosti ce se menjati.
	push es
	; Na stek prebacujem sadrzaj registra DS, posto prilikom prolaza
	; svih funkcija interapta 2Fh ove vrednosti ce se menjati.
    push ds
	; Na stek prebacujem sadrzaj registra DI, posto prilikom prolaza
	; svih funkcija interapta 2Fh ove vrednosti ce se menjati.
    push di
	; Prolaz kroz vrednosti od 0C0h do 0FFh idem u opadajucem redosledu,
	; tj. od 0FFh do 0C0h posto prilikom instalacije ja idem bas u ovom
	; redosled. I ovde koristim registra CX da bi ocitio
	; registar CL. Razlog zasto uzimam samo vrednosti od 0C0h do 0FFh je
	; sto prema literaturi ID-jevi od 00h do 0BFh su zauzeti od MS DOS-a
	; i IBM-a.
    mov cx, 0ffh
	; cld - clears the direction flag. Ovu komandu koristim da bi resetovao direction flag (DF) posto kasnije koritim komandu 
	; SCASB koja koristi DF da bi odredila da li povecava ili smanjuje poziciju sa koje ucitava karaktere u slucaju kada se uz SCASB koristi neka od komanda tipa REPx (repe, repen)
	cld

; Label koja sluzi da se napravi petlja
.idLoop:
	; Ovde vrednost iz registra CL prebacuje u registar AH, posto interapt 2Fh prema
	; specifikaciji u registru ocekuje ID za koji se proverava
	mov ah, cl
	; Vrednost iz registra CX prebacujem na stek da bi za svaki slucaj sacuvao vrednost
	; dokle sam stigao sa loop-om. Jer posle poziva interapta 2Fh moze se naci druga vrednost u tom registru,
	; a meni je bitno da se ta vrednost ne menja
    push cx
	; Interapt 2Fh za proveru da li je ID slobodan ocekuje u registru AL 0.
    mov al, 0
	; Pozivam interapt 2Fh da bi proverio da li moj TSR vec instaliran
    int 2Fh
	; Vracam sa steka moju vrednost u registar CX, ova vrednost predstavlja,
	; ID za koji sam pokusao da vidm da li je slobodan
    pop cx
	; Ako je prosledjen ID slobodan interapt 21h u registru AL vraca 0, zato sada proveravam
	; vracenu vrednost u registru AL
    cmp al, 0
	; Ako je ID slobodan ovaj JUMP ce biti izvrsen i skacem na label gde treba da se vrednost
	; za ID smanjuje i pokusava opet
    je .tryNext

	; U ovom delu program vrsim dodatnu proveru da li se radi o mom TSR-u, posto se moze desiti da neki
	; ne savestan program bez prover uzeo moj ID. I ovu proveru vrsim tako sto znam da ako je moj TSR
	; on ce na [ES:DI] vratiti moj ID string. Za ovu poveru koristi cu komande REPE CMPSB
	; Komada REPE ocekuje vrednost u registru CX, tu vrednost cu prebaciti na stek, pa cu je posle skinut sa steka
	push cx
	; Posto koristim REPE u registar CX postavljam duzinu mog ID stringa
	mov cx, isString_len
	; Posto komanda CMPSB uporedjuje vrednosti na memoriskim lokacijma ES:DI i DS:SI treba da postavim registar SI da cuva memorijsku lokaciju na kojoj se cuva vrednost
	; mog ID stringa.
	mov si, idString
	; CMPSB instrukcija uporedjuje vrednosti na memoriskim lokacijama ES:DI i DS:SI i postavlja flegove prema tome da li su te vrednosti jednake. Posle poredjenja vrednosti na ovim
	; memorijskim lokacijama vrednosti u regisrima DI i SI povecava se ili smanjuje za 1 u zavisnosti od direction flag-a. Ja sam uradio CLD tako da ce se vrednosti u ova dva registra
	; povecavati. Posto komandu CMPSB koristim sa komandom REPE, komanda CMPSB ce se najvise ponoviti puta koliko je zadato u registru CX.
	repe cmpsb
	; Vracam sa steka vrednost do koje sam stigao u proveri slobodnog ID-a
	pop cx
	; Ako se ne radi o mom ID idem sa sledecim ID
	jne .tryNext
	; Ako je provera uspela vrsim JUMP na zadnji label u ovoj funkciji, i komande REPE CMPSB postavljaju vrednost za zero flag (ZF).
	; A ovaj flag se koristi kao return value ove funkcije
    jmp .success
	
; Deo koda gde se vrednost u registru CL smanjuje sve do 0BFh za proveru da li je moj TSR ucitan.
.tryNext:
	; Smanjujem vrednost u registru CL
	dec cl
	; Proveravam da li je vrednost u registru CL stigla do kraja povere, tacnije
	; do vrednosti 0BFh od koje pocinju MS DOS i IBM id.
	cmp cl, 0BFh
	; Ako je vrednost u registru CL veca od 0BFh, ovaj JUMP ce se izvrsiti i skociti na label .idLoop
	jg .idLoop
	; Ako sam probao sve ID vrednosti cistim zero flag da bi ova funkcija vratila da moj TSR se ne
	; nalazi u memoriji
    cmp cx, 0

; Zavrsni deo seeIfPresent fukcije gde vracam stare vrednosti registra DI, DS i ES
.success:
	; Sa steka vracam sadrzaj registra DI
	pop di
	; Sa steka vracam sadrzaj registra DS
    pop ds
	; Sa steka vracam sadrzaj registra ES
    pop es
	; Vracam se tamo gde je bila pozvana ova funkcija
    ret
	
;---------------------------------------------------------------------------
;- Funkcija koja sluzi da se pronadje prvi slobodan TSR ID.
;- @return Ako je pronadjen slobodan TSR ID taj ID se vraca u registru Cl i
;-		zero flag je setovan. A ako nije pronadjena slobodna lokacija ZF se
;-		cisti.
;---------------------------------------------------------------------------
findID:
	; Na stek prebacujem sadrzaj registra ES, posto prilikom prolaza
	; svih funkcija interapta 2Fh ove vrednosti ce se menjati.
	push es
	; Na stek prebacujem sadrzaj registra DS, posto prilikom prolaza
	; svih funkcija interapta 2Fh ove vrednosti ce se menjati.
    push ds
	; Na stek prebacujem sadrzaj registra DI, posto prilikom prolaza
	; svih funkcija interapta 2Fh ove vrednosti ce se menjati.
    push di
	; Prolaz kroz vrednosti od 0C0h do 0FFh idem u opadajucem redosledu,
	; tj. od 0FFh do 0C0h posto veca verovatnoca je da cu naici brze na slobodan
	; TSR id u ovom redosled. I ovde koristim registra CX da bi ocitio
	; registar CL. Razlog zasto uzimam samo vrednosti od 0C0h do 0FFh je
	; sto prema literaturi ID-jevi od 00h do 0BFh su zauzeti od MS DOS-a
	; i IBM-a.
    mov cx, 0ffh

; Label koja sluzi da se napravi petlja
.idLoop:
	; Ovde vrednost iz registra CL prebacuje u registar AH, posto interapt 2Fh prema
	; specifikaciji u registru ocekuje ID za koji se proverava da li je slobodan
	mov ah, cl
	; Vrednost iz registra CX prebacujem na stek da bi za svaki slucaj sacuvao vrednost
	; dokle sam stigao sa loop-om. Jer posle poziva interapta 2Fh moze se naci druga vrednost u tom registru,
	; a meni je bitno da se ta vrednost ne menja
	push cx
	; Interapt 2Fh za proveru da li je ID slobodan ocekuje u registru AL 0.
    mov al, 0
	; Pozivam interapt 2Fh da bi proverio da li moj TSR vec instaliran
    int 2Fh
	; Vracam sa steka moju vrednost u registar CX, ova vrednost predstavlja,
	; ID za koji sam pokusao da vidm da li je slobodan
    pop cx
	; Ako je prosledjen ID slobodan interapt 21h u registru AL vraca 0, zato sada proveravam
	; vracenu vrednost u registru AL
    cmp al, 0
	; Ako je TSR ID slobodan skacem na label .success
    je .success
	; Smanjume vrednost za koju pokusavam da proverim da li je slobodan ID
    dec cl
    ; Proveravam da li je vrednost u registru CL stigla do kraja povere, tacnije
	; do vrednosti 0BFh od koje pocinju MS DOS i IBM id.
	cmp cl, 0BFh
	; Ako je vrednost u registru CL veca od 0BFh, ovaj JUMP ce se izvrsiti i skociti na label .idLoop
	jg .idLoop
	; Ako se prilikom izvrsavanja stiglo dovde to znaci da nije nadjen ni jedan slobdan TSR ID
	; Cistim registar CX, da bi ga iskoristo da za ciscenje zero flag-a (ZF)
    xor cx, cx
	; Ovim poredjenjem dobijem da ocistim zero flag (ZF), jer pozivac bi trebalo da proveri ovaj flag
	; da bi proverio da li nadjen slobodan ID.
    cmp cx, 1

; Zavrsni deo findID fukcije gde vracam stare vrednosti registra DI, DS i ES
.success:
	; Sa steka vracam sadrzaj registra DI
	pop di
	; Sa steka vracam sadrzaj registra DS
    pop ds
	; Sa steka vracam sadrzaj registra ES
    pop es
	; Vracam se tamo gde je bila pozvana ova funkcija
    ret

;----------------------------------------------------------
;- Funkcija koja sluzi da uzme TSR ID, ako ne uspe na
;- terminalu ce ispisati poruku o tom problemu. A ako 
;- uspe instalira moj TSR i cuva dobijeni TSR ID
;----------------------------------------------------------
getTSRID:
	call findID
	je storeTSRId
	mov si, txt_too_many_tsr
    call _print
	ret

;----------------------------------------------------------
;- Funkcija koja sluzi da sacuva dobijeni TSR ID takodje
;- 		ova funkcija sluzi da se instaliraju moji handler-i
;- 		za prekide.
;- @param registar CL - u ovom registru treba proslediti 
;- 		vrednost za TSR ID
;----------------------------------------------------------
storeTSRId:
	pusha
	push es
	
	mov [myTSRID], cl
; Deo funkcije storeTSRId gde se vrsi instalacija mojih hendler-a za interapt-e
.installInts:
	; Ispisujem poruku o instalaciji na komandnoj liniji
	; Posto funkcija _print ocekuje da se pocetak poruke za prikaz nalazi u registru SI
	mov si, txt_installing
	; Pozivam funkciju _print
	call _print
	
	; Sa komandom cli iskljucujem interapte, da ne bi se desio neki 
	; problem prilikom postavljanja noivh interat hendler-a
	cli	
	xor ax, ax
	mov es, ax
	
	; Prekid za vreme - start
    mov ax, [es:1Ch * 4]
    mov [OldInt1C], ax
    mov ax, [es:1Ch * 4 + 2]
    mov [OldInt1C + 2], ax
	
	mov dx, myInt1C
    mov [es:1Ch * 4], dx
	mov ax, cs
    mov [es:1Ch * 4 + 2], ax
	; Prekid za vreme - end
	
	; Prekid za tastaturu - start
    mov ax, [es:09h * 4]
    mov [OldInt09], ax
    mov ax, [es:09h * 4 + 2]
    mov [OldInt09 + 2], ax
	
	mov dx, myInt09
    mov [es:09h * 4], dx
	mov ax, cs
    mov [es:09h * 4 + 2], ax
	; Prekid za tastaturu - end
	
	; Prekid za 2F - start
    mov ax, [es:2Fh * 4]
    mov [OldInt2F], ax
    mov ax, [es:2Fh * 4 + 2]
    mov [OldInt2F + 2], ax
	
	mov dx, myInt2F
    mov [es:2Fh * 4], dx
	mov ax, cs
    mov [es:2Fh * 4 + 2], ax
	; Prekid za 2F - stop
	
	pop es
	popa
	
	push ds
	pop gs
	
	; Posto sam instalirao nove interapt handler-e mogu opet da ukljucim interapte.
	; A to radim sa komandom sti.
    sti
	; Zavrsavam sa radom u ovoj funkciji
	ret

;----------------------------------------------------------
;- Funkcija koja sluzi da se proveri da li mogu da se 
;- 		obrisu moji handler-i za interapte.
;- @param registar AL - u ovom registru se ocekuje vrednost
;-		1, a ako se ne prosledi ta vrednost ispisuje se
;-		poruka o gresci
;- @return u slucaju da brisanje nije uspelo u registru AX
;-		bice vracena 1.
;----------------------------------------------------------
tryRmv:
	; Proveravam da li se u registru AL nalazi 1, a ako se
	; ne nalazi treba da skocim na illegalOp gde ce se ispisati 
	; poruka o gresci
	cmp al, 1
	; Ako u AL nije 1 ovaj JUMP ce se izvrsti
    jne illegalOp

	; Pozivam funkciju koja provera da li mogu da obrisem 
	; moje handler-e za interapte
	call tstRemovable
	; Ako mogu ovaj JUMP ce se izvrsiti i funkcija removeMyInts bice pozvana
	je removeMyInts
	; U slucaju da nisam uspeo da obrisem vracam 1
	mov ax, 1
	iret

;------------------------------------------------------------------------
;- Funkcija koja sluzi da se vrate stari handler-i za interapte. A moji
;-		ce biti "obrisan", odnosno sklonicu ih sa tih lokacija.
;------------------------------------------------------------------------
removeMyInts:
	; Stampam poruku o brisanju mojih interapt hendler-a
	mov si, txt_uninstalling
	call _print
	; Na stek prebacujem vrednost u registru ES, posto cu ovaj registra koristiti u 
	; ovoj funkciji
    push es
	; Na stek prebacuje sve registre opste namene, posto ce neke od njih koristiti
    pusha
	
	; Sa komandom cli iskljucujem interapte, da ne bi se desio neki 
	; problem prilikom vracanja starih interapta
	cli
	; U registar AX postavljam 0 da bi nulu mogao da postavim u registar ES
    mov ax, 0
	; Registar ES u ovom slucaju koristim kao segment za tabelu sa svim interaptima
    mov es, ax
	; U registar AX sada stavljam vrednost registra CS
	mov ax, cs
	
	; Vracanje starog hendler-a za interapt 1C - start
	mov ax, word [OldInt1C]
    mov [es:1Ch * 4], ax
    mov ax, word [OldInt1C + 2]
	mov [es:1Ch * 4 + 2], ax
	; Vracanje starog hendler-a za interapt 1C - stop
	
	; Vracanje starog hendler-a za interapt 09 - start
	mov ax, word [OldInt09]
    mov [es:09h * 4], ax
    mov ax, word [OldInt09 + 2]
	mov [es:09h * 4 + 2], ax
	; Vracanje starog hendler-a za interapt 09 - stop

	; Vracanje starog hendler-a za interapt 2F - start
	mov ax, word [OldInt2F]
	mov [es:2Fh * 4], ax
	mov ax, word [OldInt2F + 2]
	mov [es:2Fh * 4 + 2], ax
	; Vracanje starog hendler-a za interapt 2F - stop
	
	; Sa steka vracam stare vrednosti svih registra opste namene
	popa
	; Sa steka vracam staru vrednost registra ES
    pop es
	; Vracam 0 da koja predstavlja da je sve proslo kako treba
    mov ax, 0
	; Posto sam vratio stare interapt handler-e mogu opet da ukljucim interapte.
	; A to radim sa komandom sti.
	sti
	
    iret

;--------------------------------------------------------------------------------
;- Funkcija koja sluzi da proveri da li mogu da obrisem svoje interapt handler-e.
;-		Ova povera se vrsi tako sto proveravam da li se na lokacijam za interapt
;-		handler-e nalaze moje interapt handler-i
;- @return ako su handler-i za interapte mogu obrisati zero flag ce biti
;-		setovan, a ko ne mogu zero flag ce biti resetovan
;--------------------------------------------------------------------------------
tstRemovable:	
	; Sa komandom cli iskljucujem interapte, da ne bi se desio neki 
	; problem prilikom provere da li su moji interapt ucitani.
	cli
	; Posto registar DS koristim u ovoj fukciji njega prebacujem na stek
	push ds
	; Posto registar AX koristim u ovoj fukciji njega prebacujem na stek
	pusha
	
	
    mov ax, 0
    mov ds, ax
	mov ax, cs

    cmp [ds:1Ch * 4], word myInt1C
    jne .trDone
    cmp [ds:1Ch * 4 + 2], ax
    jne .trDone

	cmp [ds:09h * 4], word myInt09
    jne .trDone
    cmp [ds:09h * 4 + 2], ax
    jne .trDone
	
    cmp [ds:2Fh * 4], word myInt2F
    jne .trDone
    cmp [ds:2Fh * 4 + 2], ax
	
; Doe funkcije tstRemovable koja predstavlja kraj fukcije gde omogucavam interapt-e
.trDone:
	; Sa steka vracam stare vrednosti svih registra opste namene
	popa
	; Sa steka vracam staru vrednost registra DS
	pop ds
	; Posto sam zavrsio sa svim proverama mogu opet da ukljucim interapte.
	; A to radim sa komandom sti.
    sti
	; Vracam se tamo gde je ova funkcija bila pozvana
	ret

;----------------------------------------------------------------------
;- Funkcija koja sluzi da se u slucaju pozivanja funkcije tryRmv sa
;- 		pogresnim parametrima ignorisem taj problem
;----------------------------------------------------------------------
illegalOp:      
	mov ax, 0
    iret	

;------------------------------------------------------------------------
;- Funkcija koja sluzi da se obrise moji interapt handler-i za moj TSR ID
;------------------------------------------------------------------------
removeIt:       
	mov	[myTSRID], cl
	
    mov ah, cl
    mov al, 1
	int 2Fh
	cmp al, 1
	je rmvFailure
	ret

;------------------------------------------------------------------------
;- Funkcija koja sluzi za ispis poruke o gresci kada moj TSR se ne nalazi
;-		u memriji
;------------------------------------------------------------------------
rmvFailure:
	push si
	mov si, tsr_is_not_loaded
	call _print
	pop si
	ret