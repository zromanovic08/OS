

refresh_datetime:
	pusha

	push gs
	pop ds
	
	mov si, MyData
	;read date 
	mov al, 7 
	mov ah, 1 
	call read_cmos_bcd 
	
	;read month 
	mov al, 8 
	mov ah, 1 
	inc si 
	call read_cmos_bcd 

	;read year 
	mov al, 9 
	mov ah, 2
	inc si
	call read_cmos_bcd

	;read hour 
	mov al, 4 
	mov ah, 1 
	inc si 
	call read_cmos_bcd 

	;read munite 
	mov al, 2 
	mov ah, 1 
	inc si 
	call read_cmos_bcd 

	;read second 
	mov al,0 
	mov ah,1 
	inc si 
	call read_cmos_bcd 

	mov si, MyData ;string start addr 

	mov bx, 07eh
	call _print_video
	popa
	iret

read_cmos_bcd: 
	;Args: 
	;al => start addr 
	;Return: 
	;Write converted string in ds:si 
	;si point to the end of string after called 
	push cx 

	out 70h, al 
	in al, 71h ;read one byte 
	mov ah, al 
	;For convenience 
	;al store byte high 4 bit 
	;ah store byte low 4 bit 
	;Because,human read order 
	;High bit put low addr 
	;Example:string "12","1" must store in low addr in memory 

	mov cl, 4 
	shr al, cl ;only retain high 4 bit 
	and ah, 00001111b ;clear high 4 bit to 0 

	add ah, 30h 
	add al, 30h 

	mov [ds:si], ax 
	add si, 2 

	pop cx 
	ret