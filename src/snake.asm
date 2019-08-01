.286P
IDEAL
MODEL small
STACK 100h

; --------------------- Snake -------------------
; Snake game written in assembly by Ben Gabay
; TASM Syntax
; 32-bit x86 - DOS
; -----------------------------------------------

MAX_BMP_WIDTH = 320
MAX_BMP_HEIGHT = 200
SMALL_BMP_HEIGHT = 40
SMALL_BMP_WIDTH = 40

DATASEG

	; General
	CurrentPixelX dw ?
	CurrentPixelY dw ?
	CurrentPixelColor db ?
	Clock equ es:6ch
	ErrorFile db 0
	
	; Messsages
	ScoreMessage db 'SCORE: ', 10, 13,'$' 
	ScoreMessegeGameOver db 'Your score is: ', 10, 13,'$' 
	BmpFileErrorMsg db 'Error At Opening Bmp File .', 0dh, 0ah,'$'
	HighscoreMessage db 'Best score: ', 10, 13,'$' 
	
	; Menu
	PlayKey db 'w'
	InstructionsKey db 's'
	HighScoreKey db 'h'
	BackKey db 'e'
	QuitKey db 'q'
	BackToMenu db ?
	
	; Game
	AppleEaten db 0
	IsGameOver db ?
	CurrentScore db 0
	HighScore db 0
	MaxScore db 9
	KeyPressed db 0
	BoardHeight dw 170
	BoardWidth dw 300
	SnakeX dw 160
	SnakeY dw 100
	BaseSnakeWidth dw 5
	BaseSnakeHeight dw 25
	SnakeWidth dw ?
	SnakeHeight dw ?
	AppleX dw ?
	AppleY dw ?
	AppleWidth dw 5
	AppleHeight dw 5
	StartingFrameX dw 10
	StartingFramey dw 10
	SnakeMovementDistance dw 5
	SnakeIncreamentSize dw 2
	
	;Snake Movement
	IsUp db 0
	IsDown db 0
	IsRight db 0
	IsLeft db 0
	
	; BMP File data
	FileHandle	dw ?
	Header db 54 dup(0)
	Palette db 400h dup (0)	
	BmpLeft dw 0
	BmpTop dw 0
	BmpColSize dw 320
	BmpRowSize dw 200
	OneBmpLineOneBmpLine db MAX_BMP_WIDTH dup (0)  ; One Color line read buffer
	ScreenLineMax db MAX_BMP_WIDTH dup (0)  ; One Color line read buffer	
	
	; Images
	MenuImage db 'snake/images/Menu.bmp',0
	InstructionsImage db 'snake/images/Instruc.bmp',0
	GameOverImage db 'snake/images/GameOver.bmp',0
	QuitImage db 'snake/images/Quit.bmp',0
	HighscoreImage db 'snake/images/HScore.bmp',0
	WinImage db 'snake/images/Win.bmp',0
	
	; Pixel Colors
	Black db 0
	Blue db 1
	Green db 2
	Red db 4
	Organge db 6
	
	; Direction Keys
	LeftKeyCode db 4Bh
	RightKeyCode db 4dh
	UpKeyCode db 48h
	DownKeyCode db 50h
	EKeyCode db 12h
	
CODESEG

; ---------------------- Utils ----------------------

proc  SetGraphicMode
    push ax
	mov ax, 13h   
	int 10h
	pop ax
	ret
endp SetGraphicMode

proc GetInput
	mov ah, 1
	int 21h
	ret
endp GetInput

proc DrawPixel
    pusha
    mov bh,0h
    mov cx, [CurrentPixelX]
    mov dx, [CurrentPixelY]
    mov al, [CurrentPixelColor]
    mov ah,0ch
    int 10h
	popa
    ret
endp DrawPixel

proc GetPixelColor
	pusha
    mov cx, [CurrentPixelX]
    mov dx, [CurrentPixelY]
    mov ah, 0Dh
    int 10h ; return al the pixel value read
	mov [CurrentPixelColor], al
	popa
	ret
endp GetPixelColor

proc Sleep
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
endp Sleep

proc Sleep2Seconds
	mov cx, 20
wait_2_seco:
	call Sleep
	loop wait_2_seco
endp Sleep2Seconds

; ---------------------- BMP Procedures ----------------------

proc PrintImage near
	push cx
	push bx
	call OpenBmpFile
	cmp [ErrorFile], 1
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
	mov [ErrorFile], 1
@@ExitProc:	
	ret
endp OpenBmpFile

proc CloseBmpFile near
	mov ah, 3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile

proc ReadBmpHeader near					
	push cx
	push dx
	mov ah, 3fh
	mov bx, [FileHandle]
	mov cx, 54
	mov dx, offset Header
	int 21h
	pop dx
	pop cx
	ret
endp ReadBmpHeader

proc ReadBmpPalette near 		
	push cx
	push dx
	mov ah, 3fh
	mov cx, 400h
	mov dx, offset Palette
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
	mov cx, [BmpRowSize]
	mov ax, [BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	xor dx, dx
	mov si,4
	div si
	mov bp,dx
	mov dx,[BmpLeft]
@@NextLine:
	push cx
	push dx
	mov di, cx ; Current Row at the small bmp (each time -1)
	add di, [BmpTop] ; add the Y on entire screen
	mov cx,di
	shl cx, 6
	shl di, 8
	add di, cx
	add di, dx
	mov ah, 3fh
	mov cx, [BmpColSize]  
	add cx, bp ; Extra bytes to each row must be divided by 4
	mov dx, offset ScreenLineMax
	int 21h
	cld ; Clear direction flag, for movsb
	mov cx,[BmpColSize]  
	mov si, offset ScreenLineMax
	rep movsb ; Copy line to the screen
	pop dx
	pop cx
	loop @@NextLine
	pop cx
	ret
endp ShowBMP 

; ---------------------- Move Values Between Variables Procedures ----------------------

proc MoveSnakeCoordinatesToCurrentCoordinates
	pusha
	mov bx, [SnakeX]
	mov dx, [SnakeY]
	mov [CurrentPixelX], bx
	mov [CurrentPixelY], dx
	popa
	ret
endp MoveSnakeCoordinatesToCurrentCoordinates

proc MoveSnakeBaseCoordinatesToCurrentCoordinates
	pusha
	mov bx, [BaseSnakeWidth]
	mov dx, [BaseSnakeHeight]
	mov [SnakeWidth], bx
	mov [SnakeHeight], dx
	popa
	ret
endp MoveSnakeBaseCoordinatesToCurrentCoordinates

proc MoveAppleCoordinatesToCurrentCoordinates
	pusha
	mov bx, [AppleX]
	mov dx, [AppleY]
	mov [CurrentPixelX], bx
	mov [CurrentPixelY], dx
	popa
	ret
endp MoveAppleCoordinatesToCurrentCoordinates

proc MoveFrameCoordinatesToCurrentCoordinates
	pusha
	mov ax, [StartingFrameX]
	mov bx, [StartingFramey]
	mov [CurrentPixelX], ax
	mov [CurrentPixelY], bx
	popa
	ret
endp MoveFrameCoordinatesToCurrentCoordinates

proc MoveCurrentCoordinatesToSnakeCoordinates
	pusha
	mov ax, [CurrentPixelX]
	mov bx, [CurrentPixelY]
	mov [SnakeX], ax
	mov [SnakeY], bx
	popa
	ret
endp MoveCurrentCoordinatesToSnakeCoordinates

; ---------------------- Game ----------------------

proc CheckWin
	pusha
	mov al, [MaxScore]
	cmp al, [CurrentScore]
	ja not_win
	call Win
not_win:
	popa
	ret
endp CheckWin

proc Win
	pusha
	mov [BackToMenu], 1
	mov dx,offset WinImage
	call PrintImage
win_input:
	mov ah, 2
	int 10h
	mov ah, 1
	int 21h
	cmp al, [BackKey]
	jne win_input
	popa
	ret
endp Win

; Prints an image with the highscore of the player
proc ShowHighscore
	pusha
	mov dx,offset HighscoreImage
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
	mov dl, [HighScore] ; same as: mov dl, 58h
    add dl, 30h 
    mov ah, 2
    int 21h
highscore_exit_input: ; Input for exit.
	mov ah, 2
	int 10h
	mov ah, 1
	int 21h
	cmp al, [BackKey]
	jne highscore_exit_input
	popa
	ret
endp ShowHighscore

; Prints the instructions of the game
proc Instructions
    pusha
	mov dx,offset InstructionsImage
	call PrintImage 
instructions_exit_input: ; Input for exit.
	mov ah, 2
	int 10h
	mov ah, 1
	int 21h
	cmp al, [BackKey]
	jne instructions_exit_input
	popa
    ret
endp instructions

proc CheckFramePixel
	call GetPixelColor
	mov al, [CurrentPixelColor]
	cmp al, [Blue]
	je frame_not_overide
	mov [IsGameOver], 1
frame_not_overide:
	ret
endp CheckFramePixel

; Checks if one of the pixels on the frame changed to green, and finish the game if it does
proc CheckFrame
    pusha
	call MoveFrameCoordinatesToCurrentCoordinates
    mov cx, [BoardWidth]
check_frame_upper_row:
	call CheckFramePixel
	inc [CurrentPixelX]
	loop check_frame_upper_row
	mov cx, [BoardHeight]
check_frame_right_column:
	call CheckFramePixel
	inc [CurrentPixelY]
	loop check_frame_right_column
	mov cx, [BoardWidth]
check_frame_bottom_row:
	call CheckFramePixel
	dec [CurrentPixelX]
	loop check_frame_bottom_row
	mov cx, [BoardHeight]
check_frame_left_column:
	call CheckFramePixel
	dec [CurrentPixelY]
	loop check_frame_left_column
	popa
	ret
endp CheckFrame

proc CheckDisqualification
	call CheckFrame
	; call CheckSnakeHitsGimself
	cmp [IsGameOver], 1
	jne game_continues
	call GameOver
game_continues:
	ret
endp CheckDisqualification

proc DrawHorizontalSnake
    pusha
	call MoveSnakeCoordinatesToCurrentCoordinates
	mov ax, [SnakeWidth]
horizontal_snake_row:
	mov cx, [SnakeHeight]
horizontal_snake_column:
    push cx
	inc [CurrentPixelX]
	call DrawPixel
	pop cx
	loop horizontal_snake_column
	inc [CurrentPixelY]
	mov bx, [SnakeHeight]
	sub [CurrentPixelX], bx
	dec ax
	cmp ax, 0
	jne horizontal_snake_row
	mov bx, [SnakeWidth]
	sub [CurrentPixelY], bx
	popa
    ret
endp DrawHorizontalSnake

proc DrawVerticalSnake
    pusha
	call MoveSnakeCoordinatesToCurrentCoordinates
	mov ax, [SnakeWidth]
vertical_snake_row:
	mov cx, [SnakeHeight]
vertical_snake_column:
    push cx
	inc [CurrentPixelY]
	call DrawPixel
	pop cx
	loop vertical_snake_column
	inc [CurrentPixelX]
	mov bx, [SnakeHeight]
	sub [CurrentPixelY], bx
	dec ax
	cmp ax, 0
	jne vertical_snake_row
	mov bx, [SnakeWidth]
	sub [CurrentPixelX], bx
	popa
    ret
endp DrawVerticalSnake

proc DrawApple
    pusha
	call MoveAppleCoordinatesToCurrentCoordinates
	mov ax, [AppleHeight]
new_apple_row:
	mov cx, [AppleWidth]
new_apple_column:
	call DrawPixel
	inc [CurrentPixelY]
	loop new_apple_column
	inc [CurrentPixelX]
	mov bx, [AppleHeight]
	sub [CurrentPixelY], bx
	dec ax
	cmp ax, 0
	jne new_apple_row
	popa
    ret
endp DrawApple

; Clear a vertical rectangle
proc ClearVerticalOblong
    pusha
	mov al, [Black]
	mov [CurrentPixelColor], al
	call DrawVerticalSnake
	popa
	ret
endp ClearVerticalOblong

; Clear a horizontal rectangle
proc ClearHorizontalOblong
    pusha
	mov al, [Black]
	mov [CurrentPixelColor], al
	call DrawHorizontalSnake
	popa
	ret
endp ClearHorizontalOblong

; Draw a blue frame
proc DrawFrame
    pusha
	mov al, [Blue]
	mov [CurrentPixelColor], al
	mov ax, [StartingFrameX]
	mov bx, [StartingFramey]
	mov [CurrentPixelX], ax
	mov [CurrentPixelY], bx
    mov cx, [BoardWidth]
frame_upper_row:
    call DrawPixel
	inc [CurrentPixelX]
	loop frame_upper_row
	mov cx, [BoardHeight]
frame_right_column:
    call DrawPixel
	inc [CurrentPixelY]
	loop frame_right_column
	mov cx, [BoardWidth]
frame_bottom_row:
    call DrawPixel
	dec [CurrentPixelX]
	loop frame_bottom_row
	mov cx, [BoardHeight]
frame_left_column:
    call DrawPixel
	dec [CurrentPixelY]
	loop frame_left_column
	popa
    ret
endp DrawFrame

proc IncreaseSnake
	pusha
	mov ax, [SnakeIncreamentSize]
	add [SnakeHeight], ax
	popa
	ret
endp IncreaseSnake

proc MoveSnakeUp
    pusha
	call ClearVerticalOblong
	mov al, [Green]
	mov [CurrentPixelColor], al
	mov bx, [SnakeMovementDistance]
    sub [SnakeY], bx
	call DrawVerticalSnake
	popa
	ret
endp MoveSnakeUp

proc MoveSnakeDown
    pusha
	call ClearVerticalOblong
	mov al, [Green]
	mov [CurrentPixelColor], al
	mov bx, [SnakeMovementDistance]
	add [SnakeY], bx
	call DrawVerticalSnake
	popa
	ret
endp MoveSnakeDown

proc MoveSnakeRight
    pusha
	call ClearHorizontalOblong
	mov al, [Green]
	mov [CurrentPixelColor], al
	mov bx, [SnakeMovementDistance]
	add [SnakeX], bx
	call DrawHorizontalSnake
	popa
    ret
endp MoveSnakeRight

proc MoveSnakeLeft
    pusha
	call ClearHorizontalOblong
	mov al, [Green]
	mov [CurrentPixelColor], al
	mov bx, [SnakeMovementDistance]
	sub [SnakeX], bx
	call DrawHorizontalSnake
	popa
	ret
endp MoveSnakeLeft

proc FixUpMovement
	pusha
	mov ax, [SnakeHeight]
	cmp [IsLeft], 1
	jne fix_up_check_right
	sub [SnakeY], ax
fix_up_check_right:
	cmp [IsRight], 1
	jne exit_fix_up
	add [SnakeX], ax
	sub [SnakeY], ax
exit_fix_up:
	popa
	ret
endp FixUpMovement

proc FixDownMovement
	pusha
	cmp [IsRight], 1
	jne exit_fix_down
	mov ax, [SnakeHeight]
	add [SnakeX], ax
exit_fix_down:
	popa
	ret
endp FixDownMovement

proc FixRightMovement
	pusha
	mov ax, [SnakeHeight]
	cmp [IsUp], 1
	jne fix_right_check_down
	add [SnakeX], ax
fix_right_check_down:
	cmp [IsDown], 1
	jne exit_fix_right
	add [SnakeY], ax
exit_fix_right:
	popa
	ret
endp FixRightMovement

proc FixLeftMovement
	pusha
	mov ax, [SnakeHeight]
	sub [SnakeX], ax
fix_left_check_right:
	cmp [IsDown], 1
	jne exit_fix_left
	add [SnakeY], ax
exit_fix_left:
	popa
	ret
endp FixLeftMovement

proc PrintScoreGameOver
	pusha
	mov dl, 11
	mov dh, 4
	mov bx, 0
	mov ah, 2
	int 10h
	mov dx, offset ScoreMessegeGameOver
	mov ah, 9h
	int 21h
	mov dl, 26
	mov dh, 4
	mov bx, 0
	mov ah, 2
	int 10h
	mov dl, [CurrentScore]
    add dl, 30h 
    mov ah, 2
    int 21h
	popa
	ret
endp PrintScoreGameOver

; Prints the current score of the player in the left side down
proc PrintScore
	pusha
	mov dl, 4
	mov dh, 23
	mov bx, 0
	mov ah, 2
	int 10h
	mov dx, offset ScoreMessage
	mov ah, 9h
	int 21h
	mov dl, 10
	mov dh, 23
	mov bx, 0
	mov ah, 2
	int 10h
	mov dl, [CurrentScore]	
    add dl, 30h 
    mov ah, 2
    int 21h
	popa
	ret
endp PrintScore

; Prints apple in random location on the screen
proc DrawRandomApple
    pusha
	mov al, [Red]
	mov [CurrentPixelColor], al
	call GenerateRandomAppleY
	call GenerateRandomAppleX
	call DrawApple
	popa
	ret
endp DrawRandomApple

proc CheckApplePixel
	pusha
	call GetPixelColor
	mov al, [CurrentPixelColor]
	cmp al, [Red]
	je apple_pixel_is_red
	mov [AppleEaten], 1
apple_pixel_is_red:
	popa
	ret
endp CheckApplePixel

proc CheckAppleEaten
	pusha
	call MoveAppleCoordinatesToCurrentCoordinates
	mov ax, [AppleHeight]
check_apple_column:
	mov cx, [AppleWidth]
check_apple_row:
	call CheckApplePixel
	inc [CurrentPixelY]
	loop check_apple_row
	inc [CurrentPixelX]
	sub [CurrentPixelY], 5
	dec ax
	cmp ax, 0
	jne check_apple_column
	popa
    ret
endp CheckAppleEaten

proc CheckApple
	call CheckAppleEaten
	cmp [AppleEaten], 1
	jne apple_not_eaten
	call HandleAppleEaten
apple_not_eaten:
	ret
endp CheckApple

proc DeleteApple
	mov al, [Black]
	mov [CurrentPixelColor], al
	call DrawApple
	ret
endp DeleteApple

proc DeleteSnake
	cmp [IsUp], 1
	jne delete_snake_check_down
	call ClearVerticalOblong
delete_snake_check_down:
    cmp [IsDown], 1
	jne delete_snake_check_right
	call ClearVerticalOblong
delete_snake_check_right:
    cmp [IsRight], 1
	jne delete_snake_check_left
	call ClearHorizontalOblong
delete_snake_check_left:
    cmp [IsLeft], 1
	jne finish_delete_snake
	call ClearHorizontalOblong
finish_delete_snake:
	ret
endp DeleteSnake

proc MoveSnake
    pusha
check_up:
	cmp [IsUp], 1
	jne check_down
	call MoveSnakeUp
check_down:
    cmp [IsDown], 1
	jne check_right
	call MoveSnakeDown
check_right:
    cmp [IsRight], 1
	jne check_left
	call MoveSnakeRight
check_left:
    cmp [IsLeft], 1
	jne finish_move_snake
	call MoveSnakeLeft
finish_move_snake:
	popa
	ret
endp MoveSnake

proc HandleAppleEaten
	call DeleteApple
	call DrawRandomApple
	inc [CurrentScore]
	call IncreaseSnake
	mov [AppleEaten], 0
	ret
endp HandleAppleEaten

proc ResetDirections
	mov [IsRight], 0
	mov [IsDown], 0
	mov [IsLeft], 0
	mov [IsUp], 0
	ret
endp ResetDirections

proc CheckNonBlockInput
	; Checks if a key was pressed
	in al, 64h ; Read keyboard status port
    cmp al, 10b ; Data in buffer ?
	je key_not_pressed ; if no key was pressed, repeat
    in al, 60h ; AL = scan code pressed key
	mov [KeyPressed], 1
key_not_pressed:
	ret
endp 

proc GetSnakeMovementInput
	call CheckNonBlockInput
	cmp [KeyPressed], 1
	jne get_snake_movement_end
	mov [KeyPressed], 0
check_up_direction:
	cmp al, [UpKeyCode] ; Checks if key up is pressed
	jne check_left_direction
	call FixUpMovement
	cmp [IsDown], 1 ; Checks whether the snake is on his way down, and if it does, the program prevent it from going up
	je get_snake_movement_end
	call ResetDirections
	mov [IsUp], 1
check_left_direction:	
	cmp al, [LeftKeyCode] ; Checks if key left is pressed
	jne check_down_direction
	call FixLeftMovement
	cmp [IsRight], 1 ; Checks whether the snake is on his way right, and if it does, the program prevent it from going left
	je get_snake_movement_end
	call ResetDirections
	mov [IsLeft], 1
check_down_direction:
	cmp al, [DownKeyCode] ; Checks if key down is pressed
	jne check_right_direction
	call FixDownMovement
	cmp [IsUp], 1 ; Checks whether the snake is on his way up, and if it does, the program prevent it from going down
	je get_snake_movement_end
	call ResetDirections
	mov [IsDown], 1
check_right_direction:
	cmp al, [RightKeyCode] ; Checks if key right is pressed
	jne check_back_key
	call FixRightMovement
	cmp [IsLeft], 1 ; Checks whether the snake is on his way left, and if it does, the program prevent it from going right
	je get_snake_movement_end
	call ResetDirections
	mov [IsRight], 1
check_back_key:
	cmp al , [EKeyCode]
	jne get_snake_movement_end
	mov [BackToMenu], 1
get_snake_movement_end:
	ret
endp GetSnakeMovementInput

proc InitBoard
	pusha
	call SetGraphicMode
    call DrawFrame
	mov bl, [Green]
	mov [CurrentPixelColor], bl
	call DrawHorizontalSnake
	mov [IsRight], 1
	call DrawRandomApple
	popa
	ret	
endp InitBoard

proc InitGameVariables
	call ResetDirections
	call MoveSnakeBaseCoordinatesToCurrentCoordinates
	mov [BackToMenu], 0
	mov [CurrentScore], 0
	mov [IsGameOver], 0
	mov [SnakeX], 160
	mov [SnakeY], 100
	mov [AppleEaten], 0
	ret
endp InitGameVariables

proc Play
	call InitGameVariables
	call InitBoard
game_loop:
	call DeleteSnake
	call GetSnakeMovementInput
	call MoveSnake
	call CheckApple
	call CheckDisqualification
	call CheckWin
	call PrintScore
	call Sleep
	cmp [BackToMenu], 1
	jne game_loop
	ret
endp Play

proc GameOver
    pusha
	mov [BackToMenu], 1
	mov dx,offset GameOverImage
	call PrintImage
	call PrintScoreGameOver
    mov cx, 25
wait_3_sec:	
	call Sleep
	loop wait_3_sec
	popa
	ret
endp GameOver

proc GenerateRandomAppleX
    pusha
    mov ax, 40h
    mov es, ax
    mov cx, 10
    mov bx, 0
random_loop_apple_x:
    mov ax, [Clock] 
    mov ah, [byte cs:bx]
    xor al, ah 
    and al, 11111111b 
	xor ah, ah
	mov [AppleX], ax
	add [AppleX], 11
    loop random_loop_apple_x
	popa
	ret
endp GenerateRandomAppleX

proc GenerateRandomAppleY 
    pusha
    mov ax, 40h
    mov es, ax
    mov cx, 10
    mov bx, 0
random_loop_apple_y:
    mov ax, [Clock] 
    mov ah, [byte cs:bx]
    xor al, ah 
    and al, 10011111b
	xor ah, ah
	mov [AppleY], ax
	add [AppleY], 11
    loop random_loop_apple_y
	popa
	ret
endp GenerateRandomAppleY

proc PrintQuitImage
	mov dx,offset QuitImage
	call PrintImage
	call Sleep2Seconds
endp PrintQuitImage

proc CheckHighscore
	mov al, [CurrentScore]
	cmp al, [HighScore] ; Compare between the highscore and the current score
	jbe no_change
	mov [HighScore], al ; Insert the current score to the highscore variable
no_change:
	ret
endp CheckHighscore

proc InitMenu
	pusha
	call SetGraphicMode
	mov dx, offset MenuImage
	call PrintImage 
	mov ah, 2
	int 10h
	popa
	ret
endp InitMenu

proc Menu
menu_loop:
	call InitMenu
get_input_label:
	call GetInput
	cmp al, [PlayKey]
	je play_label
	cmp al, [InstructionsKey]
	je instructions_label
	cmp al, [HighScoreKey]
	je highscore_label
	cmp al, [QuitKey]
	je exit_label
	jmp get_input_label
play_label:
	call Play
	call CheckHighscore
	jmp menu_loop
highscore_label:
	call ShowHighscore
	jmp menu_loop
instructions_label:
	call Instructions
	jmp menu_loop
exit_label:
	call PrintQuitImage
	ret
endp Menu

start:
	mov ax, @data
	mov ds, ax	
	call Menu
	mov ax, 2
	int 10h
	mov ax, 4c00h
	int 21h
	ret
END start