;=============================================================================
;= Fajl koji sadrzi funkciju koja sluzi za citanje video memorije i upis u
;= fajl.
;=============================================================================

;-----------------------------------------------------------------------------
;- Funkcija koja sluzi da se cela video memorija upise u fajl
;-----------------------------------------------------------------------------
printscreen:
	pusha
	; U registru ES hocu da postavim vrednost za video segment da bi mogao da citam znakove
	; U registar AX stavljam vrednost za VIDEO_SEGMENT, da bi u narednom koraku prebacio u
	; registar ES, tako je zbog komande MOV
	mov ax, VIDEO_SEGMENT
	; Sada prebacujem vrednost iz registra AX u registar ES
	mov es, ax

	; Posto funkcija open_file ocekuje da se u registru DI postavi pocetna lokacija u memoriji gde se
	; cuva naziv fajla.
	mov di, [file_name]
	; Poziva se funkcija open_file
	call open_file
	; Promenljivu video_pointer resetuje uvek na 0, da bi se uvek pocinjalo od 0
	mov word [video_pointer], 0
	
; Deo koda gde se cita sadrzaj video memorije i vrsi upis u memoriju
.read_vm_write_f:
	; uzimanje znaka iz video lokacije
	; da bi uzeo znak treba prvo da napravim tacnu adresu i zato u registar BX stavljam offset
	mov bx, [video_pointer]
	; I ovde sa memorijske lokacije [es:bx] stavljam vrednost u registar AX, posto tako mov radi
	mov ax, [es:bx]
	; U promenljivu char stavljam znak koji je procitan iz memorije, posto sama funkcija write_file
	; cita sa prosledjene memorijske lokacije i upisuje u fajl
	mov [char], ax
	
	; ovde se u fajl upsuje znak iz memorije
	; Broj bajtova koliko treba da upisem u fajl, a posto citam i upisujem po jedan znak zato ovde stoji 1
	mov cx, 1
	; Adresa znaka koji treba da upisem u fajl
	mov dx, char
	; Pozivam "funkciju" write_file koja ocekuje u registru CX broj bajtova koje treba da upisem u fajl i u registru DX adresu poruke koju treba da upise u fajl
	call write_file
	
	; Dodajem 2 na video_pointer da bi presao na sledeci znak, jer se za jednu poziciju u video memoriji koriste dva bajta. Prvi bajt za znak, drugi bajt za informaciju o boji
	add word [video_pointer], 2
	
	; 0FA0h je 4000 sto predstavlja broj bajtova koji se koristi za video memoriju, 80x25 i ovo koristim da bi zavrsio sa upisom u fajl
	cmp word [video_pointer], 0FA0h
	; U slucaju da sam procitao sve podatke skacem na zatvaranje fajla
	jge .end

	; provera da li treba da se istampa znak za novi red
	; posto funkcija div ocekuje vrednost koju delim u registru ax, prebacujem vrednost pokazivaca u memoriji u ovoj registar
	mov ax, [video_pointer]
	
	; U registar cl stavljam vrednost koja predstavlja deljenik i ovaj registar cu koristiti za funkciju div.	
	; posto svaki red na terminalu ima 80 pozicija i za svaku poziciju u memoriji dodeljeno je 2 bajta. Prvi bajt je informacija, odnosno ASCII znak, a drugi bajt je informacija o boji.
	; I ako rezultat deljenja bude jednak null to znaci da treba da predjem u novi red, posto u tom slucaju video_pointer pokazuje na sledeci redu na video terminalu
	mov cl, 0A0h
	; Vrsim deljenje registra AX sa registrom CL
	div cl
	; Posto prema specifikaciji funkcije div u registru ah se nalazi ostatak pri deljenju i ja to koristim da uporedim sa 0,
	; jer to bi znacilo da u fajlu treba da predjemo u novi red
	cmp ah, 0	
	; Ako ah nije jednako 0 onda nastavljam sa regularnim ispisom znakova zato skacem na label read_vm_write_f
	jne .read_vm_write_f
	
; Ovde vrsim upis novog reda u fajl, ova "funkcija" uvek se vraca na citanje iz memorije i upis u fajl (read_vm_write_f)
.write_new_line:
	; broj bajtova koliko treba da upisem u fajl, "funkcija" write_file ocekuje ovaj parametar u ovom registru
	mov cx, new_line_len
	; adresa poruke koju treba da upisem u fajl, "funkcija" write_file ocekuje ovaj parametar u ovom registru
	mov dx, new_line
	; poziv "funkcije" za upis u fajl
	call write_file
	
	; nastavljam za citanjem iz memorije i upis u fajl
	jmp .read_vm_write_f
	
; Ovde se zavrsava rad funkcije printscreen i zatvaram fajl
.end:
	; Pozivam funkciju za zatvaranje fajla
	call close_file
	
	popa
	
	; Vracam se odakle sam i dosao
	ret