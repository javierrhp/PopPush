include "../include/hardware.inc"
include "../include/include.inc"
SECTION "INPUT VARIABLES", HRAM
    estadoBotones:      DS 1
    flancoAscendente:   DS 1

SECTION "UTILS", ROM0

;;-------------------------------------------------------
;; Espera al inicio de VBLANK
;; DESTROYS: AF
;;
wait_VBLANK::
    ld a, [$FF44]
    cp 144
    jr nz, wait_VBLANK
ret

;;-------------------------------------------------------
;; Apaga LCDC, para la PPU
;; DESTROYS: AF, HL
;;
LCDCoff::
   ;;APAGAR LCDC
   call wait_VBLANK
   ld hl, $FF40
   res 7, [hl]
   ;;--------------
ret

;;-------------------------------------------------------
;; Enciende LCDC, vuelve a poner en marcha la PPU
;; DESTROYS: HL
;;
LCDCon::
   ;;ENCENDER LCDC
   ld hl, $FF40
   set 7, [hl]
   ;;------------
ret

utils_read_buttons:
    ld a, $20       ; 00100000, seleccionan los botones, desactiva las acciones y deja activado con 0 todo lo demás
    ldh [rP1], a    ; Se seleccionan del registro de entrada del joypad los botones
    ld a, [rP1]     ; Se lee el registro de entrada del Joypad

    cpl             ; Se invierten los bits ( 1 pulsado)
    and $0F         ; 0000 xxxx. Sin bits de posiciones
    swap a          ; xxxx 0000. Se cambian los nibbles ( los mueve a la izquierda, para poner a la derecha botones)

    ld b, a         ; Se guarda en B el valor de los botones de dirección

    ld a, $30
    ldh [rP1], a

    ld a, $10       ; 00010000, seleccionan las direcciones, desactiva las botones y deja activado con 0 todo lo demás
    ldh [rP1], a    ; Se seleccionan del registro de entrada del joypad las acciones
    ld a, [rP1]     ; Se lee el registro de entrada del joypad

    cpl 
    and $0F

    or b            ; xxxx 0000. Se combinan los bits de acción con los de dirección almacenados en b
                    ; 0000 xxxx
    ld b,a                      ;Se guarda en b el estado de los botones actual
    ldh a, [estadoBotones]      ;Se carga en a el estado de los botones anterior

    xor b           ; Se comparan si han cambiado ( si no ha cambiado 0)
    and b           ; Nos quedamos con los que sean 1, los que han cambiado

    ldh [flancoAscendente], a   ; Se guarda los que han cambiado

    ld a, b                 ; Se carga ek estado de los botones de ahora
    ldh [estadoBotones], a  ; Se carga en el estado de los botones el valor de los botones de ahora

    ld a, $30
    ldh [rP1], a

ret


SECTION "RANDOM_SIMPLE", WRAM0
    rand_simple_seed: DS 1  ; 1 byte de semilla (se modificará)


SECTION "RANDOM SIMPLE CODE", ROM0

; --------------------------------------
; Genera un número aleatorio del 0 al 7
; INPUT: NADA
; OUTPUT: A(numero del 0 al 7)
; MODIFICA: A
; --------------------------------------
generate_random_7:
    ld a, [rand_simple_seed]    ; cargar semilla act
    add a, $17                  ; sumar const rara
    xor $5C                     ; mezclar bits
    rlca                        ; rotar a la izq
    ld [rand_simple_seed], a    ; generar nueva semilla
    and %00000111               ; 0-7
    cp 7
    jr nz, .onRange
    sub 7
    .onRange
ret 

init_random_7:
    ld a, [$FF04]               ; leer el timer del sistema
    ld [rand_simple_seed], a    
ret

update_random_seed:
    ld a, [rand_simple_seed]
    ld b, a                  ; guardar semilla en B

    ld a, [$FF04]            ; leer timer DIV
    xor b                    ; mezclar con la semilla previa
    rlca                     ; rotar bits
    ld [rand_simple_seed], a ; guardar nueva semilla
ret

;; Recorre el entity array buscando un OAM_ID en 0, cuando lo encuentra returna el valor nuevo de OAM_ID
;; WARNING: Entrega la primera OAM ID que sea 0, hay que cuidar que sea la del objeto que estamos creando
;; llamando a este método justo tras crear el objeto
;; MODIFIES: AF, B , DE, HL
;; OUTPUT:
;; - B -> id de la OAM libre
;;
OAM_first_free_id::
    ld b, 0
    ld hl, entity_array - SIZEOF_E
    ld de, SIZEOF_E
    .loop
        inc b
        add hl, de
        ld a, [hl]
        cp 1
        jr nz, .loop
        inc hl
        inc hl
        ld a, [hl-]
        dec hl
        cp 0
        jr nz, .loop
ret