org 100h

;================================================================
;= Taster F11 sluzi za cuvanje sadrzaja video memorije u fajlu
;================================================================

; Glavani label od kojeg pocinje sve
main:
	; Pozivam funkciju psp_parse koja parsira podatke koji su prosledjeni iz komandne linije
	call psp_parse
	; I svemu sto je lepo dodje kraj, odnosno ovde se zavrsava program
	ret	
	
; Fajl koji sadrzi funkciju koja sluzi za parsiranje podataka prosledjenih kao parametre programa. I odnosu na te parametre odredjuje dalji tok programa.
%include "psp_pars.asm"
; Fajl koji sadrzi funkcije koje predstavljaju handler-e za prekide, takodje u ovom fajlu se nalaze i pomocne fukcije koju su potrebne za handler-e
%include "int_hdlr.asm"
; Fajl koji sadrzi funkcije koje sluzi za ispis poruka preko BIOS poziva ili direktno u memoriju, sve funkcije ocekuju da adresa poruke je postavljena u DI registar
%include "print.asm"
; Fajl u kojem se nalaze sve funkcije koje su potrebne za instaliranje i brisanje tsr apliacije
%include "tsr.asm"
; Fajl u kojem se nalaze sve funkcije koje su potrebne za rad sa fajlom
%include "file.asm"
; Fajl u kojem se nalaze sve funkcije koje su potrebne za citanje video memorije koju treba upisati u fajlom
%include "printscr.asm"
; Fajl u kojem se nalaze sve promenljive koje se koriste u aplikaciji kao i konstante
%include "pro_kon.asm"


;---- Literatura
; The New Peter Norton Programmer's Guide To The IBM PC & PS/2, autori Peter Norton, Richard Wilton
; http://flint.cs.yale.edu/cs422/doc/art-of-asm/pdf/CH18.PDF
; https://en.wikipedia.org/wiki/.bss
; http://stanislavs.org/helppc/int_21-34.html
; Materijali sa vezbe za predmet Operativni Sistemi skolska 2015/2016, Racunarski fakultet