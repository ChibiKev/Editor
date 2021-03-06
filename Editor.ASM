;Text Editor, By Kevin Chen, 23365285
    
TITLE PGM: SCREEN EDITOR
.MODEL SMALL
.STACK 100H
.DATA
new_line db 0ah,0dh,"$"
title_str db "                            Kevin Chen's Text Editor","$"
Bottom_str db "Insert Key: Replace Function, CTRL + B: Box Function, Arrow: Move, ESC: Saves","$"
ins_flag db 1
box_flag db 0
PosX    dw 0
PosY    dw 0
handle  dw ?
filename db 25 DUP(?)
text    db  1600 DUP(' ')        ;25 lines each having length 80 chars
            
;--------------------------------------------
.CODE

    MAIN PROC 
    MOV AX,@DATA
    MOV DS,AX
    ;------ Read File Name from CMD Argument ------
    MOV SI,82h
    LEA DI,filename
READ:
    MOV AL,ES:[SI]
    CMP AL,0Dh
    JE ENDR
    MOV [DI],AL
    INC SI
    INC DI
    JMP READ
ENDR:
    ;MOV [DI],0
;================= Read Data From File =================
    mov AH,3Dh          ; 3Dh of DOS Services opens a file.
    mov AL,2            ; 0 - for reading. 1 - for writing. 2 - both
    LEA DX,filename     ; make a pointer to the filename
    int 21h             ; call DOS
    MOV handle,AX       ; Function 3Dh returns the file handle in AX, here we save it for later use.
    JNC READF
    JMP EXIT_MAIN

READF:
    ;DOS Service Function number 3Fh reads from a file.
    mov ah,3Fh
    mov cx,07D0H        ; I will assume ELMO.TXT has atleast 4 bytes in it. CX is how many bytes to read.
    mov dx,offset text  ; DOS Functions like DX having pointers for some reason.
    mov bx,handle       ; BX needs the file handle.
    int 21h             ; call DOS



;================================ Editor Page =======================================
SSS:  ; Text editor

    ; set video mode
    MOV AH, 0 ; set mode function
    MOV AL, 03h ; 25x80 text mode
    INT 10H ; set mode
    
    ;enable underline cursor
    mov ah,01H ;cursor shape
    MOV CX,0607H ;underline cursor
    INT 10H
    
    ;============== Display Text from File =================
    CALL DISP_MEM
    ;=======================================================
    ;initilize variables again
    MOV PosX,0
    MOV PosY,0
    ;move cursor to upper left corner
    MOV AH,2h ;move cursor function.
    MOV DH,1
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    ;=======================================================
    ;get key stroke
    MOV AH,0    ;keyboard input function
    INT 16H     ;AH= scan code, AL= ASCII code
    
    WHILE_: 
    CMP AL, 0dh ; comparing the enter key
    JNE Check_bks
    ;------------------ Enter Key --------------
    LEA DX,new_line
    MOV AH,09h
    int 21H
    INC PosY
    MOV PosX,0
    jmp NEXT_KEY
    ;----------------- Backspace key -----------
    Check_bks:
    CMP AL,08h
    JNE Check_del
    CALL UPDATE_BKS_MEM
    CALL DISP_MEM
    MOV AX,PosX
    CMP AX,0
    JE LBKS1
    DEC PosX
    JMP LBKS2
    LBKS1:
    MOV AX,79
    MOV PosX,AX
    DEC PosY
    LBKS2:
    MOV DX,PosX
    MOV AX,PosY
    MOV DH,AL
    MOV AH,2 ;cursor move function
    MOV BH,0 
    INT 10H ;move cursor
    jmp NEXT_KEY
    
    ;----------------- Delete key -----------
    Check_del:
    CMP AX,5300h
    JNE Check_ins
    CALL UPDATE_DEL_MEM
    CALL DISP_MEM
    MOV AX,PosX
    CMP AX,0
    JE LDEL1
    DEC PosX
    JMP LDEL2
    LDEL1:
    MOV AX,79
    MOV PosX,AX
    DEC PosY
    LDEL2:
    MOV DX,PosX
    MOV AX,PosY
    MOV DH,AL
    MOV AH,2 ;cursor move function
    MOV BH,0 
    INT 10H ;move cursor
    jmp NEXT_KEY
    
    ;----------------- Insert Key  ----------------
    Check_ins:
    CMP AX,5200h
    JNE check_ctrlb
    MOV AL,ins_flag
    CMP AL,0
    JE set_ins
    MOV AL,0
    MOV ins_flag,AL
    JMP NEXT_KEY
    set_ins:
    MOV AL,1
    MOV ins_flag,AL
    JMP NEXT_KEY
    
    ;---------------- CTRL+B Key ------------------
    check_ctrlb:
    CMP AX,3002h
    JNE press
    MOV AL,box_flag
    CMP AL,0
    JE set_boxf
    MOV AL,0
    MOV box_flag,AL
    JMP NEXT_KEY
    set_boxf:
    MOV AL,1
    MOV box_flag,AL
    JMP NEXT_KEY
    ;----------------- function key or character key ----------
    press: 
    CMP AL,1BH      ;ESC (exit character)?
    JNE NESC
    JMP END_WHILE    ;yes, exit >>> line 68
    
    NESC:
    ;if function key
    CMP AL,0        ;AL=0;
    JNE ELSE_       ;no, character key
    ;then, function key
    CALL DO_FUNCTION ;execute function
    JMP NEXT_KEY ;get Next keystrokes
    
    ;------------------ Character key ------------------------
    ELSE_: ;Display character
    PUSH AX
    MOV AL,ins_flag
    CMP AL,0
    JNE INS_MODE
    ;Insert mode off
    POP AX
    CALL UPDATE_MEM
    MOV AH,2  ;Display character func
    MOV DL,AL ;get character
    INT 21H ;Display character
    MOV BX,PosX
    CMP BX,79
    JE N_Line
    INC PosX
    JMP NEXT_KEY
    N_Line:
    MOV PosX,0
    INC PosY
    JMP NEXT_KEY
    
    INS_MODE:
    ;Insert mode on
    POP AX
    ;MOV AX,PosX
    ;PUSH AX
    ;MOV AX,PosY
    ;PUSH AX
    CALL UPDATE_INS_MEM
    CALL DISP_MEM
    ;POP AX
    ;MOV PosY,AX
    ;POP AX
    ;MOV PosX,AX
    MOV BX,PosX
    CMP BX,79
    JE N_Line1
    INC PosX
    JMP INSML1
    N_Line1:
    MOV PosX,0
    INC PosY
    INSML1:
    MOV DX,PosX
    MOV AX,PosY
    MOV DH,AL
    INC DH
    MOV AH,2 ;cursor move function
    MOV BH,0 
    INT 10H ;move cursor
    ;------------------ Get User input ----------------------
    NEXT_KEY:
    MOV AH,0 ;get keystroke function 
    INT 16H  ;AH=scan code, AL=ASCII code
    JMP WHILE_ 

    END_WHILE:
    CALL DISP_MEM
    ;dos Exit
    EXIT_MAIN:
    ;======================== Write Data to file ========================
    ;set file poisiton as start of file
    MOV AH,42H
    MOV AL,0
    XOR CX,CX
    XOR DX,DX
    MOV BX,handle
    int 21h
    ;DOS Service Function number 3Fh reads from a file.
    mov ah,40h
    mov cx,0640H   ; CX is how many bytes to write.
    mov dx,offset text  ; DX contains address of data to write
    mov bx,handle    ; BX needs the file handle.
    int 21h   ; call DOS
    ;CLOSE FILE (OR DATA WILL BE LOST).
    mov  ah, 3eh
    int  21h
    ;Exit the program
    MOV AH, 4CH 
    INT 21H
MAIN ENDP

;==================== function key handler method ==============
DO_FUNCTION PROC
;Operates the arrow keys
;input: AH=scan code
;output: none
    
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH AX ;save scan code
    ;locate  cursor 
    MOV AX,PosY
    MOV DX,PosX
    MOV DH,AL
    INC DH
    POP AX
    MOV AL,box_flag
    ;------------- switch ------------
    ;case scan code of 
    CMP AH, 48h ;up arrow?
    JNE DFS1
    CMP AL,0
    JNE DFS11
    JMP CURSOR_UP ;yes, execute
    DFS11:
    JMP CURSOR_B_UP
    DFS1:
    CMP AH,4Bh ;left arrow?
    JNE DFS2
    CMP AL,0
    JNE DFS22
    JMP CURSOR_LEFT ;yes, execute
    DFS22:
    JMP CURSOR_B_LEFT
    DFS2:
    CMP AH, 4Dh ;right arrow?
    JNE DFS3
    CMP AL,0
    JNE DFS33
    JMP CURSOR_RIGHT ; yes, execute
    DFS33:
    JMP CURSOR_B_RIGHT
    DFS3:
    CMP AH, 50h ;down arrow?
    JNE DFSD
    CMP AL,0
    JNE DFSD1
    JMP CURSOR_DOWN ; yes, execute
    DFSD1:
    JMP CURSOR_B_DOWN
    DFSD:
    JMP DF_EXIT ; other function key 
    
    CURSOR_UP:
    CMP DH, 1  ; row 1?
    JNE GO_UP ;YES,MOV DOWN
    JMP DF_EXIT     ;do nothing, at first line of first page
    GO_UP:
    DEC DH ;no, row=row-1
    DEC PosY
    JMP EXECUTE ;go to exceute
    
    CURSOR_DOWN:
    CMP DH,20 ;last row?
    JNE  GO_DOWN ; yes, scroll up
    JMP DF_EXIT ;Last line of last page
    GO_DOWN:
    INC DH ;no, row=row+1;
    INC PosY
    JMP EXECUTE ;go to execute 
    
    CURSOR_LEFT:
    CMP DL,0  ; column 0?
    JNE GO_LEFT ;no, move to left
    CMP DH,1 ;row 0?
    JNE GO_BACK
    JMP DF_EXIT
    GO_BACK: 
    DEC DH ; row=row-1
    MOV DL,79 ; last column
    MOV PosX,79 
    DEC PosY
    JMP EXECUTE ;go to execute
    
    GO_LEFT:
    DEC DL ;col=col-1;
    DEC PosX
    JMP EXECUTE ;go to execute
    
    CURSOR_RIGHT:
    CMP DL,79 
    JNE GO_RIGHT ;no, move to right
    CMP DH,20 ;last row?
    JNE GO_FARWARD
    JMP DF_EXIT
    GO_FARWARD:
    INC DH ;row= row+1 
    MOV DL,0 ;col=0
    MOV PosX,0
    INC PosY
    JMP EXECUTE ;go to execute
    
    GO_RIGHT:
    INC DL ;col=col+1
    INC PosX
    JMP EXECUTE ;go to execute
    
    CURSOR_B_UP:
    CMP DH,1
    JNE CBUPL1
    JMP DF_EXIT
    CBUPL1:
    DEC DH
    MOV AH,2 ;cursor move function
    MOV BH,0 
    INT 10H ;move cursor
    DEC PosY
    MOV AL,179
    CALL UPDATE_MEM
    MOV AH,2  ;Display character func
    MOV DL,AL ;get character
    INT 21H ;Display character
    MOV DL,8
    MOV AH,2
    INT 21h
    JMP DF_EXIT
    
    CURSOR_B_DOWN:
    CMP DH,20
    JE DF_EXIT
    INC DH
    MOV AH,2 ;cursor move function
    MOV BH,0 
    INT 10H ;move cursor
    INC PosY
    MOV AL,179
    CALL UPDATE_MEM
    MOV AH,2  ;Display character func
    MOV DL,AL ;get character
    INT 21H ;Display character
    MOV DL,8
    MOV AH,2
    INT 21h
    JMP DF_EXIT
    
    CURSOR_B_LEFT:
    CMP DL,0 
    JE DF_EXIT
    MOV DL,8
    MOV AH,2
    INT 21H
    DEC PosX
    MOV AL,196
    CALL UPDATE_MEM
    MOV AH,2  ;Display character func
    MOV DL,AL ;get character
    INT 21H ;Display character
    MOV DL,8
    MOV AH,2
    INT 21h
    JMP DF_EXIT
    
    CURSOR_B_RIGHT:
    CMP DL,79 
    JE DF_EXIT
    MOV AL,196
    CALL UPDATE_MEM
    MOV AH,2  ;Display character func
    MOV DL,AL ;get character
    INT 21H ;Display character
    INC PosX
    JMP DF_EXIT

    EXECUTE:
    MOV AH,2 ;cursor move function
    MOV BH,0 
    INT 10H ;move cursor

    DF_EXIT:
    POP DX
    POP CX
    POP BX
    RET 
DO_FUNCTION ENDP

;=========== Method to update entered character in memory =============
UPDATE_MEM PROC
;position of character in memory is PosX, PosY
;Character in AL
    PUSH AX
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    POP AX
    MOV text[BX],AL
    RET
UPDATE_MEM ENDP

;========== Method to insert entered character in memory =========
UPDATE_INS_MEM PROC
;position of character in memory is PosX,PosY
;Character in AL
    PUSH AX
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    PUSH BX
    MOV AX,1600
    SUB AX,BX
    MOV CX,AX
    MOV BX,1599
    ML1:
        DEC BX
        MOV AL,text[BX]
        INC BX
        MOV text[BX],AL
        DEC BX
        LOOP ML1
    POP BX
    POP AX
    MOV text[BX],AL
    RET
UPDATE_INS_MEM ENDP

;========== Method to insert entered character in memory =========
UPDATE_BKS_MEM PROC
;position of character in memory is PosX,PosY
;Character in AL
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    PUSH BX
    MOV AX,1600
    SUB AX,BX
    MOV CX,AX
    POP BX
    MBL1:
        MOV AL,text[BX]
        DEC BX
        MOV text[BX],AL
        INC BX
        INC BX
        LOOP MBL1
    RET
UPDATE_BKS_MEM ENDP

;========== Method to insert entered character in memory =========
UPDATE_DEL_MEM PROC
;position of character in memory is PosX,PosY
;Character in AL
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    PUSH BX
    MOV AX,1600
    SUB AX,BX
    MOV CX,AX
    POP BX
    MDL1:
        INC BX
        MOV AL,text[BX]
        DEC BX
        MOV text[BX],AL
        INC BX
        LOOP MDL1
    RET
    UPDATE_DEL_MEM ENDP

;======== GET From memory ==============================
GET_MEM PROC
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    MOV DL,text[BX]
    RET
GET_MEM ENDP

;====== Display memory contents on screen ==============
DISP_MEM PROC
    MOV AX,PosX
    PUSH AX
    MOV AX,PosY
    PUSH AX
    ;move cursor to upper left corner
    MOV AH,2h ;move cursor function.
    MOV DH,0
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    LEA DX,title_str
    MOV AH,09h
    int 21H
    MOV AH,2h ;move cursor function.
    MOV DH,1
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    
    MOV PosX,0
    MOV PosY,0
    MOV CX,20
    dLoop1:
    PUSH CX
    MOV CX,80
    dLoop2:
    PUSH CX
    CALL GET_MEM
    MOV AH,2
    INT 21H
    MOV BX,PosX
    CMP BX,79
    JE dL2
    INC BX
    MOV PosX,BX
    JMP dL3
    dL2:
    MOV PosX,0
    INC PosY
    dL3:
    POP CX
    LOOP dLoop2
    POP CX
    LOOP dLoop1
    POP AX
    MOV PosY,AX
    POP AX
    MOV PosX,AX
    
    MOV AH,2h ;move cursor function.
    MOV DH,23
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    LEA DX,bottom_str
    MOV AH,09h
    int 21H
    RET
DISP_MEM ENDP

END MAIN