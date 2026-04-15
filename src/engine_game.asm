SECTION "Actual scene", WRAM0
    loaded_high_score: ds 1
    act_scene: DS 1 ;; 0 -> escena menú
                    ;; 1 -> escena gameplay

    do_change: DS 1 ;;Cuando sea 0 no cambiará
                    ;;cuando sea 1 cambiará a la escena del menu
                    ;;cuando sea 2 cambiará a la escena del juego

SECTION "SRAM Data", SRAM[$A000]
   save_signature: ds 2
   saved_high_score: ds 1


SECTION "ENGINE GAME", ROM0

engine_game_check_inputs_scene_menu:

    call utils_read_buttons

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

;;-------------------------------------------------------
;; Comprueba en la escena actual que este y dependiendo de 
;; cual sea llama a su update correspondiente
;; DESTROYS: AF
gameng_current_scene_update::
    ld a, [act_scene]
    cp 0                            ;;escena del menú
    jr nz, .comprobar_escena_game
    call scene_menu_update
    jr .exit

    .comprobar_escena_game
    cp 1
    jr nz, .comprobar_escena_x
    call scene_game_update
    jr .exit

    .comprobar_escena_x
    .exit:
ret


;;-------------------------------------------------------
;; Realiza los cambios de escena inicializando la escena a la que se vaya a transicionar
;; DESTROYS: AF, [act_scene], [do_change]
;; INPUT: [do_change]
gameng_change_scene::
    ;;Solo hará algo cuando [do_change] sea distinto de 0

    ld a, [do_change]
    cp 0
    jp z, .exit

    cp 1    ;;si [do_change] es 1
    jr nz, .is_not_one
    ld a, 0
    ld [do_change], a
    ld a, 0
    ld [act_scene], a
    call scene_menu_init
    jr .exit

    .is_not_one:
    cp 2    ;;si [do_change] es 2
    jr nz, .is_not_two
    ld a, 0
    ld [do_change], a
    ld a, 1
    ld [act_scene], a
    call scene_game_init
    jr .exit

    .is_not_two
    .exit:
ret

gameng_init::
    call sys_render_setUp
    call load_high_score

    ld a, 0
    ld [act_scene], a   ;;inicializo [act_scene] a 0 (menu)
    ld [do_change], a   ;;inicializo [do_change] a 0 (no cambiar a nada)
ret

gameng_run::
    call scene_menu_init
    ; call scene_game_initc
    .gameloop
        call utils_read_buttons
        call gameng_current_scene_update
        call gameng_change_scene
    jr .gameloop
ret

load_high_score::
    ld a, $0A
    ld [$0000], a           ; Habilitar SRAM
    
    ; Comprobar firma
    ld hl, save_signature
    ld a, [hl]
    cp $48              ;; H
    jr nz, .noSave
    inc hl
    ld a, [hl]
    cp $53              ;; S
    jr nz, .noSave

    .LoadHighScore
    ld a, [saved_high_score]
    ld [loaded_high_score], a       ; Cargar el highScore
    jr .end

    .noSave
    ; Si no hay firma válida, inicializar a 0
    ld hl, saved_high_score
    xor a
    ld [hl], a
    ; Guardar firma y valor inicial
    ld hl, save_signature
    ld a, $48           ;; H
    ld [hl+], a
    ld a, $53           ;; S
    ld [hl], a

    ld a, 0
    ld [loaded_high_score], a

    .end
    ld a, $00
    ld [$0000], a          ; Deshabilitar SRAM
ret
    