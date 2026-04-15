include "../include/hardware.inc"
include "../include/include.inc"

SECTION "WRAM OAM", WRAM0, ALIGN[8]
    copiaOAM::
    DS 160

SECTION "RENDER SYSTEM", WRAM0
    decenas:: DS 2
    unidades:: DS 2
SECTION "DMA Routine", ROM0
    routineDMA:
        ld a, HIGH(copiaOAM) ; Obtiene el byte alto de la dirección
        ldh [$46], a ; Inicia una transferencia DMA inmediatamente tras la instrucción
        ld a, 40; Espera un total de 40x4 = 160 ciclos
        .espera
        dec a; 1 ciclo
        jr nz, .espera ; 3 ciclos
        ret
    routineDMAend:

    copiaroutineDMA::
        ld hl, routineDMA;Origen de datos
        ld b, routineDMAend - routineDMA ;Cantidad de bytes a copiar
        ld c, LOW(OAMDMA);Byte bajo de la dirección de destino
        .loop
            ld a, [hl+]
            ldh [c], a
            inc c
            dec b
        jr nz, .loop
    ret

SECTION "OAM DMA", HRAM
    OAMDMA::
    DS routineDMAend - routineDMA


SECTION "Render System", ROM0

sys_render_limpiar_pantalla:
    ld hl, $9800
    ld a, $90
    ld b, 32
    ld c, 32

    .total
        .pintar
            ld [hl], a
            inc hl
            dec b
        jr nz, .pintar
        dec c
    jr nz, .total
ret

sys_render_ActivarSpritesYPaleta:
    ld a, [$FF40]
    or %00000110
    ld [$FF40], a

    ld a, %11100100
    ld [$FF48], a

    ld a, %11100100
    ld [$FF47], a
ret

sys_render_cleanOAM:
    ld hl, $FE00    ; Dirección de la OAM
    ld b, 160       ; En la OAM caben 40 sprites * 4 bytes
    ld a, 0

    .limpiar
        ld [hl], a
        inc hl
        dec b
    jr nz, .limpiar

ret

; CARGAR SPRITES EN VRAM
; INPUT: HL (Etiqueta comienzo), BC (Longitud, final - comienzo), DE (Dirección VRAM)
sys_render_load_sprite:
    .loop
        ld a, [hl]
        ld [de], a
        inc hl
        inc de
        dec bc
        ld a, b
        or c
        jr nz, .loop
ret

;;------------------------------------------------------
;; Función que pinta cualquier escena que sea de 20x18
;; INPUT: HL -> Direccion inicio pantalla ($9800 para arriba izquierda)
;;        BC -> Direccion inicio timemap
;; DESTROYS: AF, HL, DE, BC
sys_render_drawTilemap20x18::
    ld d, 18
    .row
        ld e, 20
        .column
            ld a, [bc]
            ld [hl], a
            inc hl
            inc bc
            dec e
        jr nz, .column
        
        push bc
        ld bc, 12
        add hl, bc
        pop bc
        dec d
    jr nz, .row
ret

;;------------------------------------------------------
;; Función que pinta cualquier escena que sea de 4x8
;; INPUT: HL -> Direccion inicio pantalla ($98A5 primer num, $98AB segundo num)
;;        DE -> Direccion inicio timemap
;; DESTROYS: AF, HL, DE, BC
sys_render_drawTilemap4x8::
    ld b, 8
    .row
        ld c, 4
        .column
            ld a, [de]
            ld [hl], a
            inc hl
            inc de
            dec c
        jr nz, .column
        
        push de
        ld de, 28
        add hl, de
        pop de
        dec b
    jr nz, .row
ret

;; ---------------------------
;; Iniciamos todo lo que tenga ue ver con el pintado en pintalla
;;

sys_render_setUp:
    call LCDCoff

    call sys_render_limpiar_pantalla
    call sys_render_ActivarSpritesYPaleta
    call sys_render_cleanOAM

    call LCDCon

    call copiaroutineDMA
ret

;;------------------------------------------------------
;; Limpia toda la WOAM
;; MODIFIES: AF, BC, HL
;;
sys_render_clear_WOAM::
    ld hl, copiaOAM
    ld a, 0
    ld b, 160
    .loop   
        ld [hl+], a
        dec b
        jr nz, .loop
ret

;;------------------------------------------------------
;; Actualiza las posiciones de la WOAM de todas las entidades activas
;; MODIFIES: AF, BC, DE, HL
;;
sys_render_load_OAM:
    ld de, sys_render_entity
    call man_entity_for_each
ret

;; ---------------------------
;; Actualizamos todas las entidades del entity array y se copian en la OAM DMA
;;
sys_render_update:
    call sys_render_clear_WOAM
    call sys_render_load_OAM;;Repintar las entidades (Cambiar posiciones, tiles o atributos en la OAM)
    call sys_render_calculate_numbers
    
    call wait_VBLANK;;Esperar a VBLANK start
    call sys_render_paint_numbers
    ld a, HIGH(copiaOAM)
    call OAMDMA
ret

;; --------------------------------------------------
;; Pinta la entidad contenida en hl en la OAM
;; INPUT: HL -> direccion de la entidad
sys_render_entity::
    inc hl
    inc hl
    ld a, [hl+]     ;;HL -> Entity_PosY, a -> Entity_OAMid
    push hl
    dec a
    sla a
    sla a
    sla a                ;; A = A * 8
    ld de, copiaOAM
    ld e, a         ;;DE -> OAM_DMA Posicion Y

;;PRIMERA MITAD DEL SPRITE-----------------

    ;;PosX y PosY
    ld a, [hl+]     ;;HL -> Entiy_PosX, a -> Entity_PosY
    ld [de], a      ;;DE -> OAM_DMA Posicion Y = Entity_PosY
    inc de          ;;DE -> OAM_DMA Posicion X
    ld a, [hl+]     ;;HL -> Entiy_PosYF, a -> Entity_PosX
    ld [de], a      ;;DE -> OAM_DMA Posicion X = Entity_PosX

    ;;Tile y atributo
    inc de          ;;DE -> OAM_DMA Tile
    inc hl          ;;HL -> Entiy_PosXF
    inc hl          ;;HL -> Entity_Tile
    ld a, [hl+]     ;;HL -> Entity_Atributo, a -> Entity_Tile
    ld [de], a      ;;DE -> OAM_DMA Tile = Entity_tile
    inc de          ;;DE -> OAM_DMA Atributo
    ld a, [hl]      ;;a -> Entity_Atributo
    ld [de], a      ;;DE -> OAM_DMA Atributo = Entity_Atributo

;;SEGUNDA MITAD DEL SPRITE-----------------

    inc de          ;;DE -> segundo sprite, pos y
    pop hl          ;;HL -> Entity_Posy

    ;;PosX y PosY
    ld a, [hl+]     ;;HL -> Entiy_PosX, a -> Entity_PosY
    ld [de], a      ;;DE -> OAM_DMA Posicion Y = Entity_PosY
    inc de          ;;DE -> Posicion X
    ld a, [hl+]     ;;HL -> Entiy_PosYF, a -> Entity_PosX
    add 8           ;;a -> Entity_PosX + 8  (descuadre por ser segundo sprite)
    ld [de], a      ;;DE -> OAM_DMA Posicion X = Entity_PosX + 8 (descuadre por ser segundo sprite)

    ;;Tile y atributo
    inc de          ;;DE -> OAM_DMA Tile
    inc hl          ;;HL -> Entiy_PosXF
    inc hl          ;;HL -> Entity_Tile
    ld a, [hl+]     ;;HL -> Entity_Atributo, a -> Entity_Tile
    inc a
    inc a           ;;A -> Sprite parte derecha
    ld [de], a      ;;DE -> OAM_DMA Tile = Entity_tile + 2 posiciones por ser el segundo
    inc de          ;;DE -> OAM_DMA Atributo
    ld a, [hl]      ;;a -> Entity_Atributo
    ld [de], a      ;;DE -> OAM_DMA Atributo = Entity_Atributo
ret

;; -----------------------------------------
;; Lee el player_score y pinta en la pantalla los numeros pertinentes
;; DESTROYS: AF, BC, DE, HL
;;
sys_render_paint_numbers:
    ld hl, $98A5                        ;; Primer numero (decenas)
    ld a, [decenas]
    ld d, a
    ld a, [decenas+1]
    ld e, a
    call sys_render_drawTilemap4x8

    ld hl, $98AB                        ;; Segundo numero (unidades)
    ld a, [unidades]
    ld d, a
    ld a, [unidades+1]
    ld e, a
    call sys_render_drawTilemap4x8

ret


sys_render_calculate_numbers::
    ld a,[player_score]
    .centenas
    ld b, 0          ; contador = cociente = 0
    ld c, 10         ; divisor = 10
    div_loop:
        cp c          ; ¿A < 10?
        jr c, div_end ; si A < 10, termina
        sub c         ; A = A - 10
        inc b         ; cociente++
        jr div_loop
    div_end:
    ld a, b

    push af
    ld a, [player_score]
    ld b, a
    pop af

    cp 0
    jr z, .is_zero
    cp 1
    jr z, .is_one
    cp 2
    jr z, .is_two
    cp 3
    jr z, .is_three
    cp 4
    jr z, .is_four
    cp 5
    jr z, .is_five
    cp 6
    jr z, .is_six
    cp 7
    jr z, .is_seven
    cp 8
    jr z, .is_eight
    cp 9
    jr z, .is_nine

    .is_zero:
    ld de, tilemap_0
    ld a, b
    jr .finCentenas

    .is_one:
    ld de, tilemap_1
    ld a, b
    sub 10
    jr .finCentenas

    .is_two:
    ld de, tilemap_2
    ld a, b
    sub 20
    jr .finCentenas

    .is_three:
    ld de, tilemap_3
    ld a, b
    sub 30
    jr .finCentenas

    .is_four:
    ld de, tilemap_4
    ld a, b
    sub 40
    jr .finCentenas

    .is_five:
    ld de, tilemap_5
    ld a, b
    sub 50
    jr .finCentenas

    .is_six:
    ld de, tilemap_6
    ld a, b
    sub 60
    jr .finCentenas

    .is_seven:
    ld de, tilemap_7
    ld a, b
    sub 70
    jr .finCentenas

    .is_eight:
    ld de, tilemap_8
    ld a, b
    sub 80
    jr .finCentenas

    .is_nine:
    ld de, tilemap_9
    ld a, b
    sub 90
    jr .finCentenas

    .finCentenas
    push af
    ld hl, decenas
    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl], a
    pop af
    .unidades:

    cp 0
    jr z, .is_zero1
    cp 1
    jr z, .is_one1
    cp 2
    jr z, .is_two1
    cp 3
    jr z, .is_three1
    cp 4
    jr z, .is_four1
    cp 5
    jr z, .is_five1
    cp 6
    jr z, .is_six1
    cp 7
    jr z, .is_seven1
    cp 8
    jr z, .is_eight1
    cp 9
    jr z, .is_nine1

    .is_zero1:
    ld de, tilemap_0
    jr .finUnidades

    .is_one1:
    ld de, tilemap_1
    jr .finUnidades

    .is_two1:
    ld de, tilemap_2
    jr .finUnidades

    .is_three1:
    ld de, tilemap_3
    jr .finUnidades

    .is_four1:
    ld de, tilemap_4
    jr .finUnidades

    .is_five1:
    ld de, tilemap_5
    jr .finUnidades

    .is_six1:
    ld de, tilemap_6
    jr .finUnidades

    .is_seven1:
    ld de, tilemap_7
    jr .finUnidades

    .is_eight1:
    ld de, tilemap_8
    jr .finUnidades

    .is_nine1:
    ld de, tilemap_9
    jr .finUnidades
    .finUnidades
    push af
    ld hl, unidades
    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl], a
    pop af
ret

;; LOAD DE MIERDA DE ESCUTIA

load_background_sprites_VRAM:
    ld hl, Mapa
    ld bc, MapaEnd - Mapa
    ld de, $8000
    call sys_render_load_sprite
ret

load_mazorca_sprites_VRAM:
    ld hl, MazorcaFront
    ld bc, MazorcaSide2FEnd - MazorcaFront
    ld de, $8200
    call sys_render_load_sprite
ret

load_spikeRight_sprites_VRAM:
    ld hl, FuegoRight0
    ld bc, FuegoRight4End - FuegoRight0
    ld de, $8400
    call sys_render_load_sprite
ret

load_spikeLeft_sprites_VRAM:
    ld hl, FuegoLeft0
    ld bc, FuegoLeft4End - FuegoLeft0
    ld de, $8600
    call sys_render_load_sprite
ret

load_mazorcaDead_sprites_VRAM:
    ld hl, MazorcaDead
    ld bc, MazorcaDeadEnd - MazorcaDead
    ld de, $8800
    call sys_render_load_sprite
ret

load_Fuente_VRAM:
    ld hl, Fuente
    ld bc, TILE_SIZE
    ld de, $8C00
    call sys_render_load_sprite
ret
