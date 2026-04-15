include "../include/gbt_player.inc"

    export cancion_menu_data
SECTION "Scene menu", ROM0


scene_menu_init::
    call scene_menu_save_high_score

    call LCDCoff
    call gbt_stop
    call scene_menu_load_all_sprites_VRAM
    call sys_render_cleanOAM
    call scene_menu_draw_press_a
    call scene_menu_draw_high_score
    call LCDCon
    call scene_menu_load_song


    Delay:
    ld bc, $FFFF   ; duración (ajusta este valor)
    .wait:
        dec bc
        ld a, b
        or c
        jr nz, .wait
ret


scene_menu_buttons:
    .checkB
        ld a, [flancoAscendente]
        bit 0, a
        jr z, .checkA

    .checkA
        ld a, [flancoAscendente]
        bit 1, a
        jr z, .anyKey

        ld a, 2
        ld [do_change], a

    .anyKey
ret

scene_menu_update::
    call scene_menu_buttons
    call wait_VBLANK
    call gbt_update
ret


; Se llama con la pantalla apagada
scene_menu_load_all_sprites_VRAM:
    ld hl, Menu2
    ld bc, Menu2End - Menu2
    ld de, $8000
    call sys_render_load_sprite
    call scene_menu_pintar_menu
    call load_Fuente_VRAM
    
ret

scene_menu_pintar_menu:
    ld hl, $9800
    ld bc, fondoMenu2
    call sys_render_drawTilemap20x18
ret

scene_menu_save_high_score:
    ld a, $0A
    ld [$0000], a           ; Habilitar SRAM
    
    ld a, [loaded_high_score]
    ld [saved_high_score], a       ; Cargar el highScore

    ld a, $00
    ld [$0000], a          ; Deshabilitar SRAM
ret

scene_menu_draw_press_a:
    ld a, $CF   ; P
    ld hl, $9987
    ldi [hl], a

    ld a, $D1   ; R
    ldi [hl], a

    ld a, $C4   ; E
    ldi [hl], a

    ld a, $D2   ; S
    ldi [hl], a

    ld a, $D2   ; S
    ldi [hl], a


    inc hl

    ld a, $C0   ; A
    ldi [hl], a
    
ret
scene_menu_draw_high_score:
    ld a, $C7   ; H
    ld hl, $99C3
    ldi [hl], a

    ld a, $C8   ; I
    ldi [hl], a

    ld a, $C6   ; G
    ldi [hl], a

    ld a, $C7   ; H
    ldi [hl], a

    inc hl

    ld a, $D2   ; S
    ldi [hl], a
    
    ld a, $C2   ; C
    ldi [hl], a
    
    ld a, $CE   ; O
    ldi [hl], a
    
    ld a, $D1   ; R
    ldi [hl], a
    
    ld a, $C4   ; E
    ldi [hl], a
    
    ld a, $E8   ; :
    ldi [hl], a

    inc hl

    ;; NUMEROS
    ld a, [loaded_high_score]
    ld b, a
    ; ----- Calcular decenas -----
    ld c, 0

    .div10
        cp 10
        jr c, .done_div
        sub 10
        inc c
        jr .div10
    .done_div
        ; C = decenas, A = unidades

    push af
    ld a, $DA
    add c
    ldi [hl], a
    pop af

    ld b, $DA
    add b
    ldi [hl], a


ret

;; para los numeros, ponerse en el 0 y sumar la cantidad

scene_menu_load_song:
    ld de, cancion_menu_data
    ld bc, BANK(cancion_menu_data)
    ld a, $07
    call gbt_play
    ld a, $01
    call gbt_loop
ret