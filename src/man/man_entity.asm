include "../include/include.inc"
include "../include/hardware.inc"
;;------------------------------
;;WRAM SECTION------------------

SECTION "Entity Array", WRAM0
;;DATA
    RSRESET
    DEF Entity_Comp RB 1
    DEF Entity_Type RB 1
    DEF Entity_OAMID RB 1           ;;comienza la id en 0, y va de 1 en 1, cada 1 en id son 8 posiciones en OAM
    DEF Entity_PosY RB 1
    DEF Entity_PosX RB 1
    DEF Entity_VelY RB 1            ;;En pixels/s (primer bit es signo, 1 -> negativo)
    DEF Entity_VelX RB 1            ;;En pixels/s (primer bit es signo, 1 -> negativo)
    DEF Entity_Tile RB 1            ;;id del tile de la parte izquierda superior de la entidad
    DEF Entity_Attr RB 1
    DEF Entity_AnimID RB 1          
;;Space for entities
    entity_array: DS ENTITY_ARRAY_SIZE

    ;;Cantidad de puntos
    player_score: DS 1


SECTION "Entity Manager", ROM0

;;-------------------------------
;;ENTITY MANAGER-----------------
;;Struct player-------------------------------------------
struct_player:
    DB PLAYER_TYPE
    DB 1 ;OAM ID
    DB SPAWN_Y ;PosY
    DB SPAWN_X ;PosX
    DB 0 ;
    DB 1 ;
    DB SPRITE_PLAYER
    DB DEFAULT_ATR
    DB 0

;;Struct spike-------------------------------------------
struct_spike_r:
    DB SPIKE_TYPE
    DB 0 ;OAM ID
    DB 0 ;PosY
    DB 0 ;PosX
    DB 0 ;
    DB 0 ;
    DB SPRITE_SPIKE_R
    DB DEFAULT_ATR_SPIKES
    DB 0

struct_spike_l:
    DB SPIKE_TYPE
    DB 0 ;OAM ID
    DB 0 ;PosY
    DB 0 ;PosX
    DB 0 ;
    DB 0 ;
    DB SPRITE_SPIKE_L
    DB DEFAULT_ATR_SPIKES
    DB 0

;;Posiciones pinchos------------------------------------------------
position_spikes_left:   
    DB $02*8+16, $01*8+8 - 8 
    DB $04*8+16, $01*8+8 - 8
    DB $06*8+16, $01*8+8 - 8
    DB $08*8+16, $01*8+8 - 8
    DB $0A*8+16, $01*8+8 - 8
    DB $0C*8+16, $01*8+8 - 8
    DB $0E*8+16, $01*8+8 - 8

position_spikes_right:   
    DB $02*8+16, $11*8+8 +8
    DB $04*8+16, $11*8+8 +8
    DB $06*8+16, $11*8+8 +8
    DB $08*8+16, $11*8+8 +8
    DB $0A*8+16, $11*8+8 +8
    DB $0C*8+16, $11*8+8 +8
    DB $0E*8+16, $11*8+8 +8
;;CODE

;;--------------------------------------------------------
;; Inicializa el array de entidades.
;; - Limpia entity_array (sets all to 0’s)
;; WARNING: Solo funciona con arrays menores de 256 bytes
;; DESTROYS: AF, B, HL
;;
man_entity_init:
    ld a, 0
    ld hl, entity_array
    ld b, ENTITY_ARRAY_SIZE
    .loop
        ld [hl+], a
        dec b
        jr nz, .loop
    
    call man_entity_create_player
ret

;;-------------------------------------------------------
;; Encuentra el primer hueco libre
;; WARNING: Se pasa si el array esta lleno. (Asegurarse de que hay uno vacio antes)
;; DESTROYS: AF, HL, DE
;; OUTPUT:
;; - HL -> Primer hueco libre
;; - DE = SIZEOF_E
;;
man_entity_find_first_free_slot:
    ld de, SIZEOF_E
    ld hl, entity_array
    .loop
        ld a, [hl]
        cp 0
        jp z, .end
        add hl, de
        jp .loop
    .end
ret

;;-------------------------------------------------------
;; Reserva espacio en el array para una nueva entidad
;; - Reserva un espacio para una nueva entidad.
;; - Marca su byte 0 con DEFAULT_CMP para reservarla
;; WARNING: Se pasa si el array esta lleno. (Asegurarse de que hay uno vacio antes)
;; DESTROYS: AF, DE, HL
;; OUTPUT:
;; - HL -> Hueco +1 reservado para la entidad
;; - DE = SIZEOF_E
;;
man_entity_alloc:
    call man_entity_find_first_free_slot
    ld a, DEFAULT_CMP
    ld [hl+], a
ret

;;-------------------------------------------------------
;; Libera una entidad en entity_array, dejándola
;; disponible para nuevas entidades
;; - Marca la entidad como libre
;; WARNING: Asume que HL es un puntero a una entidad válida
;; INPUT:
;; - HL -> Entidad a liberar
;;
man_entity_free:
    ld [hl], $00
ret

;;-------------------------------------------------------
;; Comprueba si la entidad dada es del tipo dado
;; WARNING: Asume que HL es un puntero a una entidad válida
;; INPUT:
;; - HL -> Entidad a comprobar
;; - B  -> Tipo a comparar
;;MODIFIES: AF
;; OUTPUT:
;; - Flag Z -> Activado (1) si la entidad es de tipo B
man_entity_is_type_b:
    inc hl
    ld a, [hl]
    dec hl
    cp b
ret

;;-------------------------------------------------------
;; Comprueba si la entidad dada es del tipo dado
;; WARNING: Asume que B es un tipo valido
;; INPUT:
;; - B  -> Tipo a encontrar
;;MODIFIES: AF, DE, HL
;; OUTPUT:
;; - HL -> Puntero a la entidad encontrada (hl -> $0000 si no hay ninguno)
   man_entity_first_by_type:
    ld hl, entity_array
    ld de, SIZEOF_E
    ld c, MAX_ENTITIES
    .loop
        ld a, [hl]
        cp 0
        jr z, .next
        call man_entity_is_type_b
        ret z
        .next
            add hl, de
            dec c
            jr nz, .loop
    ld hl, 0
ret

;;-------------------------------------------------------
;; Hace una operacion en todas las entidades válidas (reservadas)
;; del entity_array:
;; - Itera por todas las entidades
;; - Por cada entidad válida, llama a la función
;;   pasada por parámetro (la operación).
;; - Al llamar a la función (operacion), HL
;;   debe ser la dirección de la entidad válida siendo
;;   iterada.
;; DESTROYS: AF, BC, DE, HL
;; INPUT:
;; - DE -> Puntero a la función (operación) a
;;   realizar en todas las entidades válidas una a una.
;;   Esta función espera en HL una dirección valida
;;   a una entidad.
;;  OUTPUT:
;;  - HL -> direccion de memoria de la entidad válida
;;
man_entity_for_each:
   ld hl, entity_array
   ld a, 0
   .loop
        push af
        push de
        push hl
        ld a, [hl]
        cp 0
        jr z, .back
        ld bc, .back
        push bc
        push de
        ret
        .back
        pop hl
        pop de
        pop af
        add SIZEOF_E
        ld bc, SIZEOF_E
        add hl, bc
        cp ENTITY_ARRAY_SIZE
      jp nz, .loop
ret

;;-------------------------------------------------------
;; Hace la operacion pasada por parámetro en las entidades válidas del tipo
;; también pasado por parámetro de entity_array.
;; DESTROYS: AF, BC, DE, HL
;; INPUT:
;; - DE -> Puntero a la función (operación) a
;;   realizar en todas las entidades válidas una a una.
;;   Esta función espera en HL una dirección valida
;;   a una entidad.
;; - B -> Tipo de la entidad a iterar
;;
man_entity_for_each_by_type::
   ;;Recorreria todas las entidades y devolveria las que correspondan al type pasado por input
   ld hl, entity_array
   ld a, 0
   .loop
        push af
        push bc
        push de
        push hl
        ld a, [hl]
        cp 0
        jr z, .back
        call man_entity_is_type_b
        jr nz, .back
        ld bc, .back
        push bc
        push de
        ret
        .back
        pop hl
        pop de
        pop bc
        pop af
        add SIZEOF_E
        push bc
        ld bc, SIZEOF_E
        add hl, bc
        cp ENTITY_ARRAY_SIZE
        pop bc
      jp nz, .loop
ret

;;-------------------------------------------------------
;; Llama a entity update single por cada una de las entidades activas
;; DESTROYS: AF, BC, DE, HL
;;
man_entity_update::
    ld de, man_entity_update_single
    call man_entity_for_each
ret

;;-------------------------------------------------------
;; Actualiza los valores de la entidad pasada en HL
;; DESTROYS: AF, DE, HL
;; INPUT:
;; - HL -> dirección de una entidad válida del entity_sarray
;;
man_entity_update_single::
    inc hl                  ;;Colocamos HL en Entity_Type
    ld a, [hl]              ;;Guardamos el tipo en A


    ld d, 1                 ;;Si es un player escribimos 1 en D para usarlo mas tarde en las animaciones


    cp DEAD_TYPE            ;;//
    jp z, .playerDead      ;;\\Comprobamos si la entidad es un player muerto

    cp SPIKE_TYPE           ;;\\Comprobamos si es un Player u otra cosa
    jp nz, .player          ;;//

    

    jp .vamos_con_el_quesillo

    .player
    ld d, 0
    jp .vamos_con_el_quesillo

    .playerDead
    ld d, 2
    jp .vamos_con_el_quesillo
    

    .vamos_con_el_quesillo
    call quesito
ret


;;-------------------------------------------------------
;; Crea en la primera posicion libre del entity_array, la entidad spike
;; WARNING: No lo coloca en la OAM, se debe hacer fuera
;; INPUT: - B -> Indice de posicion (7-1)
;; DESTROYS: AF, HL, BC, DE
;; OUTPUT: -HL -> posición de memoria de la entidad creada
;;
;;
man_entity_create_spike_left::
    call man_entity_alloc
    dec hl

    ld a,7
    sub b
    ld b,a              ;; b ahora esta de 0 a 6

    push hl

    inc hl

    ld de, struct_spike_l

    ld c, SIZEOF_E - 1
    .loop
        ld a, [de]
        ld [hl+], a
        inc de
        dec c
        jr nz, .loop
    pop hl
    ;;Coloco la posicion que le toque
    push hl
    ld hl, position_spikes_left
    ld d, 0
    ld a, b
    sla a
    ld e, a
    add hl, de
    push hl
    pop de          ;;DE -> Position_spike_left Y
    pop hl
    push hl
    inc hl
    inc hl
    inc hl              ;; hl -> Entity_PosY
    push hl
    ld h, d
    ld l, e
    ld a, [hl]
    pop hl
    ld [hl], a
    inc hl              ;; hl -> Entity_PosX
    inc de              ;; de -> Position_spike_left X
    push hl
    ld h, d
    ld l, e
    ld a, [hl]
    pop hl
    ld [hl], a
    pop hl
ret

;;-------------------------------------------------------
;; Crea en la primera posicion libre del entity_array, la entidad spike
;; WARNING: No lo coloca en la OAM, se debe hacer fuera
;; DESTROYS: AF, HL, BC, DE
;; OUTPUT: -HL -> posición de memoria de la entidad creada
;;
;;
man_entity_create_spike_right::
    call man_entity_alloc
    dec hl

    ld a,7
    sub b
    ld b,a              ;; b ahora esta de 0 a 6

    push hl

    inc hl

    ld de, struct_spike_r

    ld c, SIZEOF_E - 1
    .loop
        ld a, [de]
        ld [hl+], a
        inc de
        dec c
        jr nz, .loop
    pop hl
    ;;Coloco la posicion que le toque
    push hl
    ld hl, position_spikes_right
    ld d, 0
    ld a, b
    sla a
    ld e, a
    add hl, de
    push hl
    pop de          ;;DE -> Position_spike_right Y
    pop hl
    push hl
    inc hl
    inc hl
    inc hl              ;; hl -> Entity_PosY
    push hl
    ld h, d
    ld l, e
    ld a, [hl]
    pop hl
    ld [hl], a
    inc hl              ;; hl -> Entity_PosX
    inc de              ;; de -> Position_spike_right X
    push hl
    ld h, d
    ld l, e
    ld a, [hl]
    pop hl
    ld [hl], a
    pop hl
ret

;;-------------------------------------------------------
;; Crea todas los pinchos contenidos en vector_spikes_left y en vector_spikes_right
;; DESTROYS: AF, HL, BC, DE
;;
man_entity_create_spikes::
    call man_entity_delete_spikes
    ld hl, vector_spikes_left
    ld b, 7
    .loop
        ld a,[hl+]  ;;primer valor
        cp 1
        jr z, .leftSpikes
        dec b
    jr nz, .loop

    .rightSpikes
        ld hl, vector_spikes_right
        ld b, 8
        .loopR
        dec b
        jr z, .end
        ld a, [hl+]
        cp 1
        jr nz, .loopR
        ;;Hay pincho
        push hl
        push bc
        call man_entity_create_spike_right          ;;hl -> direccion del pincho creado
        push hl
        call OAM_first_free_id
        pop hl
        inc hl
        inc hl                                      ;;hl -> OAM_id
        ld a, b
        ld [hl], a                                  ;;EntityOAM_ID -> OAM_first_free_id
        pop bc
        pop hl
        jr .loopR

    .leftSpikes
        ld hl, vector_spikes_left
        ld b, 8
        .loopL
        dec b
        jr z, .end
        ld a, [hl+]
        cp 1
        jr nz, .loopL
        ;;Hay pincho
        push hl
        push bc
        call man_entity_create_spike_left          ;;hl -> direccion del pincho creado
        push hl
        call OAM_first_free_id
        pop hl
        inc hl
        inc hl                                      ;;hl -> OAM_id
        ld a, b
        ld [hl], a                                  ;;EntityOAM_ID -> OAM_first_free_id
        pop bc
        pop hl
        jr .loopL

    .end
ret

;;-------------------------------------------------------
;; Elimina todos los pinchos entidades
;;
man_entity_delete_spikes:
    ld de, man_entity_free
    ld b, SPIKE_TYPE
    call man_entity_for_each_by_type
ret
;;-------------------------------------------------------
;; Crea en la primera posicion libre del entity_array, la entidad spike
;; WARNING: No lo coloca en la OAM, se debe hacer fuera
;; DESTROYS: AF, HL, BC, DE
;; OUTPUT: -HL -> posición de memoria de la entidad creada
;;
;;
man_entity_create_player::
    call man_entity_alloc
    dec hl

    push hl

    inc hl

    ld de, struct_player

    ld b, SIZEOF_E - 1
    .loop
        ld a, [de]
        ld [hl+], a
        inc de
        dec b
        jr nz, .loop

    pop hl
ret