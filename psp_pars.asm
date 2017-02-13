;=============================================================================
;= Fajl koji sadrzi funkciju koja sluzi za parsiranje podataka prosledjenih
;= kao parametre programa. I odnosu na te parametre odredjuje dalji tok
;= programa.
;=============================================================================

;----------------------------------------------------------------------
;- Funkcija koja sluzi za parsiranje komandne linije za paramtre koji
;- su potrebni za rad programa
;----------------------------------------------------------------------
psp_parse:
	; Prilikom parsiranja paremetara proslatih iz komandne linije treba da vrednost u registru ES bude jednak kao i DS, 
	; posto dosta komandi (SCASB, CMPSB, ...) koristi oba registra to radim ovde na pocetku
	; U registar CX postavljam poziciju u okviru PSP gde se cuva duzina prosledjenih parametra programa
	mov cx, PSP_LENGTH
	
	; U promenljivu psp_length cuvam tu vrednost da bi kasnije mogao tu vrednost da koristim
	mov word [psp_length], cx
	; cld - clears the direction flag. Ovu komandu koristim da bi resetovao direction flag (DF) posto kasnije koritim komandu 
	; SCASB koja koristi DF da bi odredila da li povecava ili smanjuje poziciju sa koje ucitava karaktere u slucaju kada se uz SCASB koristi neka od komanda tipa REPx (repe, repen)
	cld
	; Postavljam u registar DI adresu pocetka prosledjenih parametara programu
	mov	di, PSP_START
	; Preskacem sve prazne znakove koji se nalaze pre parametara programa
    mov	al, EMPTY_CHAR
	; SCASB komanda koja uporedjuje vrednost u registru AL sa vrednoscu na memorijskoj lokaciji [ES:DI], pri pozivu ove komande ofset koji se cuva u registru DI se povecava ili 
	; smanjuje u zavisnosti od direction flag-a, da bi bio siguran da se povecava taj ofset ranije sam pozvao i komandu cld
	; REPE komanda koja sluzi da se komanda SCASB ponavlja sve dok su vrednosti u registru AL i na memorijskoj lokaciji [ES:DI] jednake ili ako je SCASB ponovljeno onoliko puta koliko je 
	; postavljeno u registar CX. Zato sam na pocetku procito koliko je dugacka poruka.
	repe scasb
	; Sada registar DI smanjujem za jedan da bi pokazivao na pocetak prosledjenih parametara
	dec di
	; Cuvam pocetak prosledjenih parametara da bi mogao kasnije da koristim za utvrdjivanje koji je parametar prosledjen
	mov [pos_arg], di
	
	; Deo funkcije koja provera da li je u pitanju parametar -start
	; Posto za poredjenje parametra i konstante za parametar -start koristim komande REPE CMPSB u registar CX treba da stavim vrednost koliko najvise puta treba da se ponove te komande
	mov cx, op_start_len
	; Posto komanda CMPSB uporedjuje vrednosti na memoriskim lokacijma ES:DI i DS:SI treba da postavim registar SI da cuva memorijsku lokaciju na kojoj se cuva vrednost
	; za parametar za koji aplikacija treba da radi
	mov si, op_start
	; CMPSB instrukcija uporedjuje vrednosti na memoriskim lokacijama ES:DI i DS:SI i postavlja flegove prema tome da li su te vrednosti jednake. Posle poredjenja vrednosti na ovim
	; memorijskim lokacijama vrednosti u regisrima DI i SI povecava se ili smanjuje za 1 u zavisnosti od direction flag-a. Ja sam uradio CLD tako da ce se vrednosti u ova dva registra
	; povecavati. Posto komandu CMPSB koristim sa komandom REPE, komanda CMPSB ce se najvise ponoviti puta koliko je zadato u registru CX.
	repe cmpsb
	; Ako su vrednosti jednake skacem na dalji radi aplikacije
	je .start

	; provera da li je u pitanju - stop
	; Posto za poredjenje parametra i konstante za parametar -stop koristim komande REPE CMPSB u registar CX treba da stavim vrednost koliko najvise puta treba da se ponove te komande
	mov cx, op_stop_len
	; Posto komanda CMPSB uporedjuje vrednosti na memoriskim lokacijma ES:DI i DS:SI treba da postavim registar DI da cuva memorijsku lokaciju na kojoj se cuva vrednost
	; parametar koji je prosledjen iz komandne linije.
	mov di, [pos_arg]
	; Posto komanda CMPSB uporedjuje vrednosti na memoriskim lokacijma ES:DI i DS:SI treba da postavim registar SI da cuva memorijsku lokaciju na kojoj se cuva vrednost
	; za parametar za koji aplikacija treba da zaustavi rad TSR-a.
	mov si, op_stop
	; CMPSB instrukcija uporedjuje vrednosti na memoriskim lokacijama ES:DI i DS:SI i postavlja flegove prema tome da li su te vrednosti jednake. Posle poredjenja vrednosti na ovim
	; memorijskim lokacijama vrednosti u regisrima DI i SI povecava se ili smanjuje za 1 u zavisnosti od direction flag-a. Ja sam uradio CLD tako da ce se vrednosti u ova dva registra
	; povecavati. Posto komandu CMPSB koristim sa komandom REPE, komanda CMPSB ce se najvise ponoviti puta koliko je zadato u registru CX.
	repe cmpsb
	; Ako su vrednosti jednake skacem na zaustavljanje TSR-a
	je .stop

; Stampanje poruke o gresci kada aplikaciji nisu prosledjeni odgovarajucu parametri	
.print_error_msg:
	; Posto funkcija _print ocekuje da se pocetak poruke za prikaz nalazi u registru SI
	mov si, error_msg
	; Poziv funkcje _print
	call _print
	; Posto posle stampanja poruke nemam sta vise da radim skacem na kraj
	jmp .end

; Deo programa koji se izvrsava kada korisnik prosledi -start kao parametar programa
.start:
	; preskacem sve praznine koje se nalaze izmedju parametra za start (-start) i imena fajla
	mov cx, [psp_length]

	; Posto hocu da hocu da preskocim sve praznine koje se nalaze posle parametra -start i pre naziva fajal u kojem treba da se sacuva sadrzaj video memorije
	; u registar AL stavljam prazan znak. U AL moram da stavim posto naredna komanda SCASB koristi bas taj registar za poredjenje.
    mov al, EMPTY_CHAR
	; SCASB komanda koja uporedjuje vrednost u registru AL sa vrednoscu na memorijskoj lokaciji [ES:DI], pri pozivu ove komande ofset koji se cuva u registru DI se povecava ili 
	; smanjuje u zavisnosti od direction flag-a, da bi bio siguran da se povecava taj ofset ranije sam pozvao i komandu cld
	; REPE komanda koja sluzi da se komanda SCASB ponavlja sve dok su vrednosti u registru AL i na memorijskoj lokaciji [ES:DI] jednake ili ako je SCASB ponovljeno onoliko puta koliko je 
	; postavljeno u registar CX. Zato sam na pocetku procito koliko je dugacka poruka.
	repe scasb
	
	; Zbog nacina na koji funkcionise komanda SCASB moram da vrednost u registru DI smanjim za 1 da bi pokazivao na prvi znak koji bi trebalo da predstavlja pocetak naziva fajla
	; u koji treba da upisem sadrzaj video memorije
	dec di
	
	; Ovde proverava da li je korisnik uneo naziv fajla u koji treba da se upise sadrzaj video memorije, tako da ako je trenutni znak na memorijskoj lokaciji [ES:DI] jednak znaku za CR - ENTER 
	; to znaci da sam stigao do kraj stringa koji je prosledjen kao parametar programu sa komandne linije. I ovom slucaju bi trebalo da zavrsim rad programa.
	cmp byte [es:di], CR_ENTER
	; U slucaju da je znak na memorijskoj lokaciji jednak CR - ENTER skacem na ispis poruke o gresci da je zaboravio da unse naziv fajla
	je .missing_file_name
	
	; U ovom delu funkcije hocu da nadjem znak za CR - ENTER i da njega zamenim sa 0 da bi to predstavljalo naziv fajla u kojem treba da se sacuva video memorija
	; U registru DI trenutno se nalazi pocetak naziva fajla u koji treba da se sacuva sadrzaj video memorije. I njega hocu da sacuva za kasnije koriscenje i zato 
	; tu vrednost prebacujem u promenljivu file_name
	mov [file_name], di
	; Posto hocu da preskocim sve znakove do znaka za CR - ENTER koji predstavlja kraj unetih parametra
	; u registar AL stavljam znak za CR - ENTER. U AL moram da stavim posto naredna komanda SCASB koristi bas taj registar za poredjenje.
    mov al, CR_ENTER
	; SCASB komanda koja uporedjuje vrednost u registru AL sa vrednoscu na memorijskoj lokaciji [ES:DI], pri pozivu ove komande ofset koji se cuva u registru DI se povecava ili 
	; smanjuje u zavisnosti od direction flag-a, da bi bio siguran da se povecava taj ofset ranije sam pozvao i komandu cld
	; REPNE komanda koja sluzi da se komanda SCASB ponavlja sve dok su vrednosti u registru AL i na memorijskoj lokaciji [ES:DI] razlicite ili ako je SCASB ponovljeno onoliko puta koliko je 
	; postavljeno u registar CX. Zato sam na pocetku procito koliko je dugacka poruka.
	repne scasb
	; Posto komanda SCASB posle poziva povecava DI za jedan, ovde moram da smanjim za jedan da bi bio na poziciji na kojoj se nalazi znak za CR - ENTER i da taj znak zamenim sa 0
	; i tako dobio validan string.
	mov byte [di - 1], 0

	; Ovde pokusavam da napravim prosledjeni fajl da bi proverio da li je naziv fajla dobro formatiran
	; Posto funkcija open_file ocekuje da se u registru DI postavi pocetna lokacija u memoriji gde se
	; cuva naziv fajla.
	mov di, [file_name]
	; Poziva se funkcija open_file
	call open_file
	; Ako funkcija open_file ne uspe da otvori fajl, zbog samo nacina funkcionisanja DOS int 3Ch koji se koristi
	; za pravljenje fajla carry flag ce biti setovan i ja ovde proverim carry flag ako je setovan skacem na ispis
	; greske u nazivu fajla. Posto sam zainteresovan sa stanje carry flag koristim komandu JC koja proverava stanje
	; carry flag-a i ako je carry flag = 1 skace na navedeni label:
	jc .wrong_file_name
	
	; Zatvarm fajl za svaki slucaj posto se moze desiti da korisnik ne pozove opciju za cuvanje
	; sadrzaja video memorije
	call close_file

	; Posto sve potrebne provere su uradjene mogu da pozovem funkciju tstPresent da bi proverio da li je TSR vec instaliran,
	; ako jeste korisnik ce dobiti poruku na terminalu o tome. A ako nije TSR instalira bice instaliran.
	call tstPresent
	; Po zavrsetku funkcije tstPresent nemam vise sta da radim i zato skacem na .end
	jmp .end
	
; Stampanje poruke o gresci kada aplikaciji nije prosledjen naziv fajla
.missing_file_name:
	; Posto funkcija _print ocekuje da se pocetak poruke za prikaz nalazi u registru SI
	mov si, txt_missing_file_name
	; Poziv funkcje _print
	call _print
	; Posto posle stampanja poruke nemam sta vise da radim skacem na kraj
	jmp .end
	
; Stampanje poruke o gresci kada korisnik unese pogresan naziv fajla
.wrong_file_name:
	; Posto funkcija _print ocekuje da se pocetak poruke za prikaz nalazi u registru SI
	mov si, txt_wrong_file_name
	; Poziv funkcje _print
	call _print
	
	; Posto posle stampanja poruke nemam sta vise da radim skacem na kraj
	jmp .end
	
; Deo programa koji se izvrsava kada korisnik prosledi -stop kao parametar programa
.stop:	
	; Pozivam funkciju seeIfPresent koja sluzi da proveri da li je moj TSR ucitan u moriji
	call seeIfPresent
	; Posle poziva funkcije seeIfPresent ako je zero flag setovan onda mogu brisem TSR i vratim predhodne handler-e za prekide
    je removeIt
	; U slucaju da moj TSR nije jos uvek ucitan ili je prekinut jos ranije
	; korisnika obavestavam o tome tako sto ispisujem poruku
	; U registar SI postavljam lokaciju gde se nalazi pocetak poruke ispisem na terminal, takodje ovaj string se zavrsava sa 0 sto je oblezava kraj stringa
	mov si, tsr_is_not_loaded
	; Pozivam funkciju _print koja ce ispisati poruku na terminal, memorijska lokacija na kojoj se nalazi pocetak ove poruke mora biti ucitan u registar SI
	call _print
.end:
	ret