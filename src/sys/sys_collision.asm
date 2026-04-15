
include "../include/include.inc"

SECTION "Collision System", ROM0

;; -------------------------------------------
;; Actualiza las colisiones de todas las entidades
;; MOD: AF; BC; DE; HL
;;
sys_collision_update::
    ld de, sys_collision_check_player
    ld b, PLAYER_TYPE
    call man_entity_for_each_by_type
ret

;;---------------------
;; Chequea las colisiones del jugador
;; INPUT: HL-> Direccion de memoria de la entidad
;; MOD: AF; BC; DE; HL
;;
sys_collision_check_player::
    ld d, 0
    ld e, ACCESS_POSY
    add hl, de              
    ;; LIMIT Y ---------------------------------
    ld a, [hl]              ;; Player posY
    dec a                   ;; Hay como un desajuste de 2 px d lo q se ve y el dato asique lo arreglo           
    dec a
    cp LIMIT_MAX_Y          ;; Limite inferior
    jr c, .noLimitInf       ;; No toca limite inferior, comprobar superior

    ;; Toca limite inferior
    push af
    push hl
    push de
    ld a, -4
    call sys_physics_change_velocity
    pop de
    pop hl
    pop af
    jr .axisX

    
    .noLimitInf
    cp LIMIT_MIN_Y          ;; Limite superior
    jr nc, .axisX           ;; No toca limite superior, pasar a ejeX

    ;; Toca limite superior
    push af
    push hl
    push de
    ld a, 4
    call sys_physics_change_velocity
    pop de
    pop hl
    pop af

    .limitY:
    ; call scene_game_player_dead
    
    ;; LIMIT X ---------------------------------
    ;; Le da la vuelta a tu velocidad.
    .axisX:
    inc hl
    ld a, [hl]
    cp LIMIT_MAX_X
    jr nc, .limitX    
    cp LIMIT_MIN_X
    jr c, .limitX
    jr .entities ;;Vamos a las entidades, en X estamos bien
    .limitX:
    inc hl
    inc hl
    ld a, [hl]
    cpl
    inc a
    ld [hl], a
    call scene_game_hit
    .entities
    ld de, sys_collision_check_entity
    ld b, SPIKE_TYPE
    call man_entity_for_each_by_type
    .end
ret

;; ---------------------------------------
;; Comprobamos si la entidad y el jugador han colisionado.
;; INPUT: HL-> entidad pincho a comprobar
;;
sys_collision_check_entity::
    ld bc, entity_array + ACCESS_POSY     ;; bc -> direccion de memoria POSY del player
    ld d, 0
    ld e, ACCESS_POSY
    add hl, de                             ;;hl -> direccion de memoria POSY del spike
    ;; COLISION EN Y----------------------------------
    ld d, LIMIT_Y_SPIKE
    ld a, [hl]              ;;PosY arriba spike 
    add a, 16               ;;PosY arriba spike + 16px = PosY abajo spike
    sub a, d                ;;PosY abajo spike - margen
    ld e, a                 ;; e-> Spike_posy + 16 - margen (abajo BoundingBox)
    ld d, LIMIT_Y_PLAYER
    ld a, [bc]              ;;PosY arriba player 
    add a, d                ;;PosY arriba player + margen, a-> Player_posy + margen (arriba BoundingBox)
    cp e
    jr nc, .end
    push af
    ld a, e                 
    sub a, 8                ;;a -> Bajo BB spike - 8px
    ld e, a                 ;;e -> Abajo bounding box spike - 8px (alto spike) = Alto BB spike
    pop af 
    add a, 8                ;;Arriba bounding box playter + 8px (alto player) = Bajo BB player
    cp e
    jr c, .end
    ;; COLISION EN X----------------------------------
    inc hl                              ;;hl -> direccion de memoria POSX del spike
    inc bc                              ;; bc -> direccion de memoria POSX del player
    ld d, LIMIT_X_SPIKE
    ld a, [hl]                          ;;PosX izq spike 
    add a, 16                           ;;PosX izq spike + 16px = PosY derecha spike
    sub a, d                            ;;PosX derecha spike - margen
    ld e, a                             ;; e-> Spike_posX + 16 - margen (Derecha BoundingBox)
    ld d, LIMIT_X_PLAYER
    ld a, [bc]                          ;;Posx izq player 
    add a, d                            ;;Posx izq player + margen, a-> Player_posx + margen (izq BoundingBox)
    cp e
    jr nc, .end
    push af
    ld a, e                 
    sub a, 16                              ;;a -> der BB spike - (16px-LimiteX_spike)
    ld e, a                                 ;;e -> der bounding box spike - 16px (ancho spike) = izquierda BB spike
    pop af 
    add a, 8                                 ;;izq bounding box playter + 8px (ancho player) = Derecha BB player
    cp e
    jr c, .end
    ;; HAY COLISION -------------------
    call scene_game_player_dead
.end
ret