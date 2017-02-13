;=============================================================================
;= Fajl u kojem cuvam sve promenljive i konstante koje se koriste u aplikaciji
;============================================================================

segment .data
	MyData db "00.00.00 00:00:00", 0
	MyStore dw 16 

; Deo gde se definise sve vezano za parametre aplikacije
parametri_app: 
	; Promenljiva koja cuva oznaku za paremetar koji se prosledjuje kao paremetar za pocetak rada aplikacije
	op_start db '-start'
	; Konstanta koja cuva ukupnu duzinu paremetra za pocetak rada aplikacije
	op_start_len EQU $ - op_start
	; Promenljiva koja cuva oznaku za paremetar koji se prosledjuje kao paremetar za kraj rada aplikacije
	op_stop db '-stop'
	; Konstanta koja cuva ukupnu duzinu paremetra za kraj rada aplikacije
	op_stop_len EQU $ - op_stop
	; Promenljiva koja cuva pocetak prvog argumenta u prosledjenim parmetrima aplikacije
	pos_arg dw 0
	; Promenljiva koja cuva ukupnu duzinu prosledjenih parametara
	psp_length dw 0
	; Promenljiva u kojoj cuvam memorijsku lokaciju na kojoj pocinje naziv fajla u kojem treba da sacuvam sadrzaj video memorije
	file_name dw 0
	
; Deo gde se definisu sve poruke koja se salju korisniku
poruke_app:
	; Poruka koja se ispisuje korisniku kada nije uneo odgovarajuce argumente
	error_msg db 'Niste uneli odgovarajucu argument!', 0
	; Poruka koja se prosledjuje korisniku ako je TSR vec ucitan u memoriju
	tsr_already_present db 'ScreenShot je vec pokrenut da bi sacuvali sadrzaj video memorije pritisnite F11.', 0
	; Poruka koja se ispisuje korisniku ako TSR aplikacija nije uctan, a korisnik pokusa da zaustavi
	tsr_is_not_loaded db 'ScreenShot nije startovan, tako da ne moze da se zaustavi. ScreenShot pokrenuti sa opcijom -start <ime_fajla>', 0
	; Poruka koja se ispisuje korisniku ako nema vise slobodnih mesta kada koristimo tehniku Multiplex Interrupt (interrupt 2Fh)
	txt_too_many_tsr db 'Sva mesta za TSR su zauzeta, ScreenShot ne moze da se pokrene!', 0
	; Porkua koja se ispisuje kada se instaliraju int handler-i za potrebne interapte
	txt_installing db 'Interrupt handlers - Instalacija', 0
	; Porkua koja se ispisuje kada se brisu handler-i za potrebne interapte
	txt_uninstalling db 'Interrupt handlers - Deinstalacija', 0
	; Poruka kaja se ispisuje kada korisnik zaboravi da unesi naziv fajala
	txt_missing_file_name db 'Treba da unesete naziv fajla u koji treba da se upise sadrzaj video memorije!', 0
	; Poruka koja se ispisuje kada korisnik unese ne ispravan naziv fajla
	txt_wrong_file_name db 'Proverite naziv fajla, posto fajl pod tim imenom ne moze se napravi!', 0
	
; Deo gde se definisu svi potrebne promenljive za rad sa fajlom
fajl_app:
	; Potrebni znaci za novi red koji treba da se upisu u fajl
	new_line db 0Dh, 0Ah
	; Duzina poruke za novi red, posto ovo treba da prosledjume funkciji za upis u fajl
	; Sa $ - newline ustvari racunam koliko je dugacka new_line, mogao sam da stavim samo 2,
	; ali u slucaju da treba da promenim promenljivu na ovaj nacin nemoram da brinem i o 
	; promeni ove promenljive
	new_line_len EQU $ - new_line
	; Promenljiva koju koristim za racunanje trenutne pozicije u video memoriji
	video_pointer dw 0
	; Promenljiva koju koristim za cuvanje handler-a za fajl u koji treba da upisujem podatke
	filehndl dw 0
	; Promenljiva u kojoj cuvam procitani znak iz video memorije
	char db 0h
	
; Deo gde se definisu sve promenljive koje se koriste za rad sa tastaturom
tastatura_app:
	; Promenljiva koja sluzi da se sacuva trenutno pritisnut taster na tastaturi
	kbdata db 0
	; Scan code za ESC, ovo nije isto sto ASCII kod!!!!
	ESC equ 001h
	; Scan code za P, ovo nije isto sto ASCII kod!!!!
	P equ 19h
	; Scan code za F11
	F11 equ 57h
; Deo programa u kojem se definise identifikator aplikacije
base_app:
	; Promenljiva koja cuva naziv aplikacije koju kasnije koristim kada se pozove int 2Fh za proveru da li je moja aplikacija ucitana
	idString db 'ScreenShot', 0
	; Konstanta u kojoj cuva duzinu id stringa, ovo mi treba za proveru da li se radi o mom interaptu
	isString_len equ $ - idString
	; Pormenljiva koja sluzi da se odredi da li treba da se uradi upis u fajl kada na tater nije uspelo
	do_printscreen db 0
	; Konstanta koja predstavlja null vrednost
	NULL equ 000h
	; Konstanta koja predstavlja pocetak video segmenta u memoriji
	VIDEO_SEGMENT equ 0B800h
	; Konstanta koja predstavlja prazan znak
	EMPTY_CHAR equ ' '
	; Konstanta koja predstavlja ASCII vrednost za Enter (Carriage Return)
	CR_ENTER equ 13
	; Konstanta koja predstavlja memorijsku lokaciju u okviru PSP-a gde se cuva duzina prosledjenih parametara aplikacije
	PSP_LENGTH equ 0080h
	; Konstanta koja predstavlja memorijsku lokaciju u okviru PSP-a gde pocinju prosledjeni parametri
	PSP_START equ 0081h
	; U/I registar u koji se upisuje scan_code koji stize sa mikroprocesora 8048  
	KBD equ 060h
	; Nespecificna EOI komanda za zavrsetak obrade prekida
	EOI equ 020h
	; Master_8259 je na U/I adresi 0A0h
	Master_8259 equ 020h

;--------------------------------------------------------------------------------------
;- Segment .bss predstavlja segment gde se ucitavaju staticke promenljive za program
;--------------------------------------------------------------------------------------
segment .bss
	; "Globalna" promenljiva u kojoj se cuva id mog TSR-a
	myTSRID resb 1
	; "Globalna" promenljiva u kojoj cuvam stari handler za prekid 1Ch
	OldInt1C resw 2
	; "Globalna" promenljiva u kojoj cuvam stari handler za prekid 16h
	OldInt09 resw 2
	; "Globalna" promenljiva u kojoj cuvam stari handler za prekid 2Fh
	OldInt2F resw 2