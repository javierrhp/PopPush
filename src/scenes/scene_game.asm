include "../include/include.inc"

include "../include/gbt_player.inc"

    export flap_data
    export boing_data
    export dead_data

SECTION "Scene game", ROM0

scene_game_init::
    call LCDCoff
    call gbt_stop
    call sys_render_cleanOAM
    call scene_game_load_all_sprites_VRAM
    call scene_game_draw_background    
    call LCDCon
    call man_entity_init

    ; Inicializar la semilla de aleatorio
    call init_random_7
    ;; ld hl, vector_spikes_left
    ;; call sys_spikes_generate    

    ; Poner a 0 el score
    ld a, 0
    ld [player_score], a
    
    ld a, 1
    ld [max_spikes], a

    ld a, 1
    ld [animation_time], a
ret

scene_game_buttons: 
    .checkA
        ld a, [flancoAscendente]
        bit 1, a
        jr z, .anyKey

        ld a, -3
        call sys_physics_change_velocity
    .anyKey

ret

scene_game_update::
    call gbt_update
    call sys_render_update
    call scene_game_buttons
    call sys_collision_update
    call sys_physics_update
    call man_entity_update
    call sys_spikes_update
ret


; scene_game_load_all_sprites_VRAM:
;     ld hl, Mapa
;     ld bc, MapaEnd - Mapa
;     ld de, $8000
;     call sys_render_load_sprite
; ret

scene_game_draw_background:
    ld hl, $9800
    ld bc, fondo
    call sys_render_drawTilemap20x18
ret



scene_game_load_all_sprites_VRAM:
    call load_background_sprites_VRAM
    call load_mazorca_sprites_VRAM
    call load_spikeRight_sprites_VRAM
    call load_spikeLeft_sprites_VRAM
    call load_mazorcaDead_sprites_VRAM
    call load_Fuente_VRAM
ret

scene_game_hit::
    push af
    call scene_game_boing_sound
    pop af
    bit 7, a
    jr nz, .negativo
    .positivo
    call man_entity_delete_spikes
    ld hl, vector_spikes_right
    ld a, 0
    ld [spikes_is_left], a
    call sys_spikes_generate
    call man_entity_create_spikes
    jr .score
    .negativo
    call man_entity_delete_spikes
    ld hl, vector_spikes_left
    ld a, 1
    ld [spikes_is_left], a
    call sys_spikes_generate
    call man_entity_create_spikes
    .score
    ld a, [player_score]
    inc a
    ld [player_score], a
    
ret

scene_game_player_dead::
    call scene_game_check_high_score

    ld a, 1
    ld [animation_going], a

    ld hl, entity_array
    inc hl

    ld [hl], DEAD_TYPE      ;;Cargamos que la entidad es el cron muerto para la animacion
    inc hl
    inc hl                  ;;//
    inc hl                  ;;\\LLevamos HL hasta el contador de animacion (Entity_AnimID)
    inc hl                  ;;//
    inc hl
    inc hl
    inc hl
    inc hl

    ld [hl], 0      ;;Reiniciamos el contador de la animacion

    ; jp scene_game_update:
    ;;Hay que hacer el call hacia qui desde el final de la animacion.
    call gbt_stop
    call scene_game_dead_sound
    .loop
        call sys_render_update
        call man_entity_update
        call gbt_update
        ld a, [animation_going]
        cp 0
    jr nz, .loop

    dead_animation_finish:
    ld a, 0
    ld [player_score], a

    ld a, 1
    ld [do_change], a

    ld b, $FF
    .loop1
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        dec b
    jr nz, .loop1    
ret

scene_game_check_high_score::
    ld a, [player_score]
    ld b, a
    ld a, [loaded_high_score]
    cp b
    jr nc, .end
    ld a, b
    ld [loaded_high_score], a
    .end
ret

scene_game_flap_sound:
    ld de, flap_data
    ld bc, BANK(flap_data)
    ld a, $07
    call gbt_play
ret

scene_game_dead_sound:
    ld de, dead_data
    ld bc, BANK(dead_data)
    ld a, $07
    call gbt_play
ret

scene_game_boing_sound:
    ld de, boing_data
    ld bc, BANK(boing_data)
    ld a, $07
    call gbt_play
ret
