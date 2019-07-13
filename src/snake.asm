.286P
IDEAL
MODEL small
STACK 100h

; ----------------- Snake -----------------
; Snake game written in assembly by Ben Gabay
; TASM Syntax
; 32-bit x86 - DOS
; -----------------------------------------


MAX_BMP_WIDTH = 320
MAX_BMP_HEIGHT = 200
SMALL_BMP_HEIGHT = 40
SMALL_BMP_WIDTH = 40

DATASEG
	; Messsages
	messege_score db 'SCORE: ', 10, 13,'$' 
	messege_score2 db 'Your score is: ', 10, 13,'$' 
	BmpFileErrorMsg db 'Error At Opening Bmp File .', 0dh, 0ah,'$'
	HighscoreMessage db 'Best score: ', 10, 13,'$' 
	
	; Game
	x dw 160
	y dw 100
	apple2 db 0
	
	;Snake Movement
	right2 db 0
	left2 db 0
	down2 db 0
	up2 db 0
	
	; BMP File data
	FileHandle	dw ?
	Header db 54 dup(0)
	Palette db 400h dup (0)
	BmpLeft dw ?
	BmpTop dw ?
	BmpColSize dw ?
	BmpRowSize dw ?	
	OneBmpLineOneBmpLine db MAX_BMP_WIDTH dup (0)  ; One Color line read buffer
	ScreenLineMax db MAX_BMP_WIDTH dup (0)  ; One Color line read buffer	
	
	; Images
	menu_image db 'snake/images/Menu.bmp',0
	loading1_image db 'snake/images/Loading1.bmp', 0
	loading2_image db 'snake/images/Loading2.bmp', 0
	loading3_image db 'snake/images/Loading3.bmp', 0
	instructions_image db 'snake/images/Instructions.bmp',0
	game_over_image db 'snake/images/GameOver.bmp',0
	quit_image db 'snake/images/Quit.bmp',0
	highscore_image db 'snake/images/HighScore.bmp',0
	win_image db 'snake/images/Win.bmp',0
	
	newhigh db 0
	score db 0
	random_number db 0
	random_number2 db 0
	backto db 0
	returnaddress dw ?
	Clock equ es:6ch
	ErrorFile db 0
	color db ?
	
CODESEG

proc PrintImage near
	push cx
	push bx
	call OpenBmpFile
	cmp [ErrorFile],1
	je @@ExitProc
	call ReadBmpHeader
	call ReadBmpPalette
	call CopyBmpPalette
	call ShowBMP 
	call CloseBmpFile
@@ExitProc:
	pop bx
	pop cx
	ret
endp PrintImage
	
proc OpenBmpFile near						 
	mov ah, 3Dh
	xor al, al
	int 21h
	jc @@ErrorAtOpen
	mov [FileHandle], ax
	jmp @@ExitProc	
@@ErrorAtOpen:
	mov [ErrorFile],1
@@ExitProc:	
	ret
endp OpenBmpFile

proc CloseBmpFile near
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile

proc ReadBmpHeader near					
	push cx
	push dx
	mov ah,3fh
	mov bx, [FileHandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	pop dx
	pop cx
	ret
endp ReadBmpHeader

proc ReadBmpPalette near 		
	push cx
	push dx
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	pop dx
	pop cx
	ret
endp ReadBmpPalette

proc CopyBmpPalette near															
	push cx
	push dx
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
CopyNextColor:
	mov al,[si+2] ; Red				
	shr al,2 ; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution)		
	out dx,al 						
	mov al,[si+1] ; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] ; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 ; Point to next color.  (4 bytes for each color BGR + null)									
	loop CopyNextColor	
	pop dx
	pop cx
	ret
endp CopyBmpPalette

proc ShowBMP 
	push cx
	mov ax, 0A000h
	mov es, ax
	mov cx,[BmpRowSize]
	mov ax,[BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	xor dx,dx
	mov si,4
	div si
	mov bp,dx
	mov dx,[BmpLeft]
@@NextLine:
	push cx
	push dx
	mov di,cx ; Current Row at the small bmp (each time -1)
	add di,[BmpTop] ; add the Y on entire screen
	mov cx,di
	shl cx,6
	shl di,8
	add di,cx
	add di,dx
	mov ah,3fh
	mov cx,[BmpColSize]  
	add cx,bp ; Extra bytes to each row must be divided by 4
	mov dx,offset ScreenLineMax
	int 21h
	cld ; Clear direction flag, for movsb
	mov cx,[BmpColSize]  
	mov si,offset ScreenLineMax
	rep movsb ; Copy line to the screen
	pop dx
	pop cx
	loop @@NextLine
	pop cx
	ret
endp ShowBMP 

; Change to graphic mode and clear the screen
proc  SetGraphic
    push ax
	mov ax,13h   
	int 10h
	pop ax
	ret
endp SetGraphic

; Wait 0.5 seconds
proc Timer
    pusha
    mov ax, 40h
    mov es, ax
    mov ax, [Clock]
FirstTick:
    cmp ax, [Clock]
    je FirstTick
    mov cx, 1 
DelayLoop:
    mov ax, [Clock]
Tick:
    cmp ax, [Clock]
    je Tick
    loop DelayLoop
    popa
    ret 
endp Timer

; Prints an image with the highscore of the player
proc highscore
	pusha
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset highscore_image
	call PrintImage
	mov dl, 11
	mov dh, 4
	mov bx, 0
	mov ah, 2
	int 10h
	mov dx, offset HighscoreMessage
	mov ah, 9h
	int 21h
	mov dl, 24
	mov dh, 4
	mov bx, 0
	mov ah, 2
	int 10h
	mov dl, [newhigh] ; same as: mov dl, 58h
    add dl, 30h 
    mov ah, 2
    int 21h
enterchar2: ; Input for exit.
	mov dl, 0
	mov dh, 0
	mov bx, 0
	mov ah, 2
	int 10h
	mov ah, 1
	int 21h
	cmp al, 'e'
jne enterchar2
	mov [backto], 1
	popa
	ret
endp highscore

; Checks whether the score reach 9 points. if it does, it shows the win image
proc point_under_9
	pusha
	cmp [score], 9
	jb under_9
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset win_image
	call PrintImage
enterchar3: ;Input for exit.
	mov dl, 0
	mov dh, 0
	mov bx, 0
	mov ah, 2
	int 10h
	mov ah, 1
	int 21h
	cmp al, 'e'
	jne enterchar3
	mov [backto], 1
under_9:
	popa
	ret
endp point_under_9

; Prints the instructions of the game
proc instructions
    pusha
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset instructions_image
	call PrintImage 
enterchar: ; Input for exit
	mov dl, 0
	mov dh, 0
	mov bx, 0
	mov ah, 2
	int 10h
	mov ah, 1
	int 21h
	cmp al, 'e'
	jne enterchar
	mov [backto], 1
	popa
    ret
endp instructions

; Prints pixel to the screen
proc pixel
    pusha
    mov bh,0h
    mov cx,[x]
    mov dx,[y]
    mov al,[color]
    mov ah,0ch
    int 10h
	popa
    ret
endp pixel

; Checks the color of the pixel, and puts his value in AL
proc check_pixel_green
    pusha
	mov bh,0h
    mov cx,[x]
    mov dx,[y]
    mov ah,0Dh
    int 10h ; return al the pixel value read
	cmp al, 2
	jne ex1
	mov [backto], 1
ex1:
	popa
	ret
endp check_pixel_green

; Checks if all the pixels on the frame changed to green, and finish the game if it does
proc check_frame
    pusha
	mov [x], 10
	mov [y], 10
    mov cx, 300
shc12:
    call check_pixel_green
	inc [x]
	loop shc12
	mov cx, 170
shc13:
    call check_pixel_green
	inc [y]
	loop shc13
	mov cx, 300
shc14:
    call check_pixel_green
	dec [x]
	loop shc14
	mov cx, 170
shc15:
    call check_pixel_green
	dec [y]
	loop shc15
	popa
	ret
endp check_frame

; Draw horizontal rectangle
proc horizontal_oblong
    pusha
	mov ax, 5
shc1:
	mov cx, 25
shc2:
    push cx
	inc [x]
	call pixel
	pop cx
	loop shc2
	inc [y]
	sub [x], 25
	dec ax
	cmp ax, 0
	jne shc1
	sub [y], 5
	popa
    ret
endp horizontal_oblong

; Draw vertical rectangle
proc vertical_oblong
    pusha
	mov ax, 5
shc3:
	mov cx, 25
shc4:
    push cx
	inc [y]
	call pixel
	pop cx
	loop shc4
	inc [x]
	sub [y], 25
	dec ax
	cmp ax, 0
	jne shc3
	sub [x], 5
	popa
    ret
endp vertical_oblong

; Draw an appple (5X5 red pixels)
proc apple
    pusha
	mov ax, 5
shc5:
	mov cx, 5
shc6:
    push cx
	inc [y]
	call pixel
	pop cx
	loop shc6
	inc [x]
	sub [y], 5
	dec ax
	cmp ax, 0
	jne shc5
	sub [y], 5
	sub [x], 5
	popa
    ret
endp apple

; Clear a vertical rectangle
proc clear_oblong_vertical
    pusha
	mov [color], 0
	call vertical_oblong
	popa
	ret
endp clear_oblong_vertical

; Clear a horizontal rectangle
proc clear_oblong_horizontal
    pusha
	mov [color], 0
	call horizontal_oblong
	popa
	ret
endp clear_oblong_horizontal

; Draw a blue frame
proc frame
    pusha
	mov [color], 1
	mov [x], 10
	mov [y], 10
    mov cx, 300
shc8:
    call pixel
	inc [x]
	loop shc8
	mov cx, 170
shc9:
    call pixel
	inc [y]
	loop shc9
	mov cx, 300
shc10:
    call pixel
	dec [x]
	loop shc10
	mov cx, 170
shc11:
    call pixel
	dec [y]
	loop shc11
	mov [x], 160
	mov [y], 100
	popa
    ret
endp frame

; Prints loading images before the game starts
proc loading_messages
    pusha
	mov cx, 2
loading:
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset loading3_image
	call PrintImage 
	call Timer
	call Timer
	call Timer
	call Timer
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset loading2_image
	call PrintImage
	call Timer
	call Timer
	call Timer
	call Timer
	jmp beinaim2
beinaim:
	loop loading
	jmp end_messege
beinaim2:
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset loading1_image
	call PrintImage 
	call Timer
	call Timer
	call Timer
	call Timer
	jmp beinaim
end_messege:
	call SetGraphic
    popa
    ret
endp loading_messages

; Moves the snake up
proc up
    pusha
	mov [color], 2
    sub [y], 5
	call vertical_oblong
	mov cx, [y]
	mov bx, [x]
	call check_frame
	mov [y], cx
	mov [x], bx
	popa
	ret
endp up

; Moves the snake down
proc down
    pusha
	mov [color], 2
	add [y], 5
	call vertical_oblong
	mov cx, [y]
	mov bx, [x]
	call check_frame
	mov [y], cx
	mov [x], bx
	popa
	ret
endp down

; Moves the snake right
proc right
    pusha
	mov [color], 2
	add [x], 5
	call horizontal_oblong
	mov cx, [y]
	mov bx, [x]
	call check_frame
	mov [y], cx
	mov [x], bx
	popa
    ret
endp right

; Moves the snake left
proc left
    pusha
	mov [color], 2
	sub [x], 5
	call horizontal_oblong
	mov cx, [y]
	mov bx, [x]
	call check_frame
	mov [y], cx
	mov [x], bx
	popa
	ret
endp left

; Fix the snake movement to go up
proc fix_up
	pusha
	cmp [right2], 1
	jne u1
	call clear_oblong_horizontal
	add [x], 25
	sub [y], 25
u1:
    cmp [left2], 1
	jne u2
	call clear_oblong_horizontal
	sub [y], 25
u2:
	popa
	ret
endp fix_up

; Fix the snake movement to go down
proc fix_down
    pusha
	cmp [right2], 1
	jne d1
	call clear_oblong_horizontal
	add [x], 25
d1:
	popa
	ret
endp fix_down

; Fix the snake movement to go right
proc fix_right
    pusha 
	cmp [down2], 1
	jne r1
	call clear_oblong_vertical
	add [y], 25
r1:
	popa
	ret
endp fix_right

; Fix the snake movement to go left.
proc fix_left	
    pusha
	cmp [up2], 1
	jne l1
	call clear_oblong_vertical
	sub [x], 25
l1:
    cmp [down2], 1
	jne l2
	call clear_oblong_vertical
	sub [x], 25
	add [y], 25
l2:
	call clear_oblong_vertical
	popa 
	ret
endp fix_left

; Checks whether the player disqalified. if he does, the procedure show the relevant message
proc print_score_game_over
	pusha
	mov dl, 11
	mov dh, 4
	mov bx, 0
	mov ah, 2
	int 10h
	mov dx, offset messege_score2
	mov ah, 9h
	int 21h
	mov dl, 26
	mov dh, 4
	mov bx, 0
	mov ah, 2
	int 10h
	mov dl, [score]
    add dl, 30h 
    mov ah, 2
    int 21h
	popa
	ret
endp print_score_game_over

; Prints the current score of the player in the left side down
proc print_score
	pusha
	mov dl, 4
	mov dh, 23
	mov bx, 0
	mov ah, 2
	int 10h
	mov dx, offset messege_score
	mov ah, 9h
	int 21h
	mov dl, 10
	mov dh, 23
	mov bx, 0
	mov ah, 2
	int 10h
	mov dl, [score]	
    add dl, 30h 
    mov ah, 2
    int 21h
	popa
	ret
endp print_score

; Checks the snake's movement and clean it accordingly
proc main_clear
    pusha
	cmp [up2], 1
	jne clear1
	call clear_oblong_vertical
clear1:
    cmp [down2], 1
	jne clear2
	call clear_oblong_vertical
clear2:
    cmp [right2], 1
	jne clear3
	call clear_oblong_horizontal
clear3:
    cmp [left2], 1
	jne clear4
	call clear_oblong_horizontal
clear4: 
	popa 
	ret
endp main_clear

; Prints the apple randomly
proc random_apple
    pusha
	mov [color], 4
	xor ah, ah
	call random_vertical
	mov al, [random_number2]
	mov [y], ax
	call random_horizontal
	mov al, [random_number]
	mov [x], ax
	add [y], 11
	add [x], 11
	call apple
	popa
	ret
endp random_apple

; Check if the pixel is green
proc check_pixel_green2
	pusha
	mov bh,0h
    mov cx,[x]
    mov dx,[y]
    mov ah,0Dh
    int 10h ; return al the pixel value read
	cmp al, 2
	jne green
	mov [apple2], 1
green:
	popa
	ret
endp check_pixel_green2

; Checks if the apple eaten by the snake
proc check_apple
	pusha
	xor ah, ah
	mov al, [random_number2]
	mov [y], ax
	mov al, [random_number]
	mov [x], ax
	add [y], 11
	add [x], 11
	mov ax, 5
shc55:
	mov cx, 5
shc66:
    push cx
	inc [y]
	call check_pixel_green2
	pop cx
	loop shc66
	inc [x]
	sub [y], 5
	dec ax
	cmp ax, 0
	jne shc55
	sub [y], 5
	sub [x], 5
	popa
    ret
endp check_apple

; Delets the apple
proc delet_apple
    pusha
	mov [color], 0
	xor ah, ah
	mov al, [random_number2]
	mov [y], ax
	mov al, [random_number]
	mov [x], ax
	add [y], 11
	add [x], 11
	call apple
	popa
	ret
endp delet_apple

; The procedure is incharge of the snake's movement
proc movement
    pusha
	cmp [up2], 1
	jne lbb1
	call up	
lbb1:
    cmp [down2], 1
	jne lbb2
	call down
lbb2:
    cmp [right2], 1
	jne lbb3
	call right
lbb3:
    cmp [left2], 1
	jne lbb4
	call left
lbb4:
	popa
	ret
endp movement

proc play
    pusha
	call loading_messages
    call frame
	mov [color], 2
	call horizontal_oblong
	call Timer
	call clear_oblong_horizontal
	mov [right2], 1
	mov cx, [x]
	mov bx, [y]
	call random_apple
	mov [x], cx
	mov [y], bx
looplabe2:
    cmp [backto], 1
	jne lb1
    call game_over
	jmp lb7
lb1:
    call print_score
    call movement
	call Timer
	mov cx, [x]
	mov bx, [y]
	call check_apple
	cmp [apple2], 0
	je not_eat_by_snake
	call delet_apple
	call random_apple
	inc [score]
	jmp lb6
check_score:
	mov [apple2], 0
not_eat_by_snake:
    mov [x], cx
	mov [y], bx
	call point_under_9
	call main_clear
	; Checks if a key was pressed
	in al, 64h ; Read keyboard status port
    cmp al, 10b ; Data in buffer ?
	je lb1 ; if no key was pressed, repeat
	; Gets the pressed key
    in al, 60h ; Get keyboard data
	; AL = scan code pressed key
	cmp al, 48h ; Checks if key up is pressed
	jne lb2
	cmp [down2], 1 ; Checks whether the snake is on his way down, and if it does, the program prevent it from going up
	je lb2
	call fix_up
	mov [right2], 0
	mov [down2], 0
	mov [left2], 0
	mov [up2], 1
	call movement
	call Timer
	call clear_oblong_vertical
	jmp looplabe2
lb2:
    cmp al, 4Bh ; Checks if key left is pressed
	jne lb3
	cmp [right2], 1 ; Checks whether the snake is on his way right, and if it does, the program prevent it from going left
	je lb3
    call fix_left
	mov [down2], 0
	mov [up2], 0
	mov [right2], 0
	mov [left2], 1
	call movement
	call Timer
	call clear_oblong_horizontal
	jmp looplabe2
lb3:
	cmp al, 50h ; Checks if key down is pressed
	jne lb4
	cmp [up2], 1 ; Checks whether the snake is on his way up, and if it does, the program prevent it from going down
	je lb4
	call fix_down
	mov [right2], 0
	mov [up2], 0
	mov [left2], 0
	mov [down2], 1
	call movement
	call Timer
	call clear_oblong_vertical
shortcut:
	jmp looplabe2
shortcut2:
	jmp check_score
lb4:
	cmp al, 4dh ; Checks if key right is pressed
	jne lb5
	cmp [left2], 1 ; Checks whether the snake is on his way left, and if it does, the program prevent it from going right
	je lb5
	call fix_right
	mov [up2], 0
	mov [left2], 0
	mov [down2], 0
	mov [right2], 1
	call movement
	call Timer
	call clear_oblong_horizontal
	jmp looplabe2
lb5:
    cmp al, 12h ; Check if 'e' is pressed, and if it does, the program goes back to the main menu
	jne shortcut
    mov [backto], 1
	jmp lb7
lb6:
	call point_under_9 ; Reset the movement variables at the end of the game
	cmp [backto], 1
	je lb7
	jne shortcut2
lb7:
    mov [right2], 0 
	mov [left2], 0
	mov [up2] ,0
	mov [down2], 0
	popa
    ret
endp play

proc game_over
    pusha
    mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset game_over_image
	call PrintImage
	call print_score_game_over
    mov cx, 25
wait_3_sec:	
	call Timer
	loop wait_3_sec
	popa
	ret
endp game_over

proc random_horizontal
    pusha
    mov ax, 40h
    mov es, ax
    mov cx, 10
    mov bx, 0
RandLoop:
    mov ax, [Clock] 
    mov ah, [byte cs:bx]
    xor al, ah 
    and al, 11111111b 
	mov [random_number], al
    loop RandLoop
	popa
	ret
endp random_horizontal

proc random_vertical 
    pusha
    mov ax, 40h
    mov es, ax
    mov cx, 10
    mov bx, 0
RandLoop2:
    mov ax, [Clock] 
    mov ah, [byte cs:bx]
    xor al, ah 
    and al, 10011111b 
	mov [random_number2], al
    loop RandLoop2
	popa
	ret
endp random_vertical

start:
    mov ax, @data
	mov ds, ax	
	call SetGraphic 
menu1:
    mov al, [score]
	cmp al, [newhigh] ; Compare between the highscore and the current score
	ja newhighscore
menu2:
    mov [score], 0
    mov [backto], 0 
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset menu_image
	call PrintImage 
	mov dl, 0
	mov dh, 0
	mov bx, 0
	mov ah, 2
	int 10h
	mov ah, 1
	int 21h
	cmp al, 'w'
	je label_1
	cmp al, 's'
	je label_2
	cmp al, 'q'
	je befor_exit
	cmp al, 'h'
	je label_3
	jne menu1
newhighscore:
	mov [newhigh], al ; Insert the current score to the highscore variable
	jmp menu2
label_1:
    call play
	cmp [backto], 1
	je menu1
label_2:
    call instructions
	cmp [backto], 1
	je menu1
label_3:
    call highscore
	cmp [backto], 1
	je menu1
befor_exit: ; Prints an image when the player exit the game
    mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] , 200
	mov dx,offset quit_image
	call PrintImage
    mov cx, 20
wait_2_seco:
	call Timer
	loop wait_2_seco
exit:
    mov ax, 2
	int 10h
	mov ax, 4c00h
	int 21h
END start