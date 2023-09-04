CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS: get_instance_features       FOR INSTANCE FEATURES      IMPORTING keys REQUEST requested_features       FOR Travel RESULT result,
      get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS: acceptTravel           FOR MODIFY IMPORTING keys FOR ACTION Travel~acceptTravel           RESULT result,
      createTravelByTemplate FOR MODIFY IMPORTING keys FOR ACTION Travel~createTravelByTemplate RESULT result,
      rejectTravel           FOR MODIFY IMPORTING keys FOR ACTION Travel~rejectTravel           RESULT result.

    METHODS: validateCustomer FOR VALIDATE ON SAVE IMPORTING keys FOR Travel~validateCustomer,
      validateDates    FOR VALIDATE ON SAVE IMPORTING keys FOR Travel~validateDates,
      validateStatus   FOR VALIDATE ON SAVE IMPORTING keys FOR Travel~validateStatus.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.
*   Habilita o deshabilita acciones y campos.  Se llama antes y después de las acciones
    READ ENTITIES OF z_i_travel_log_mr
        ENTITY Travel
        FIELDS ( travel_id overall_status )
        WITH VALUE #( FOR key_row IN keys ( %key = key_row-%key ) )
        RESULT DATA(lt_travel_result).

    result = VALUE #( FOR ls_travel IN lt_travel_result (
                        %key                  = ls_travel-%key
                        %field-travel_id      = if_abap_behv=>fc-f-read_only
                        %field-overall_status = if_abap_behv=>fc-f-read_only
                        %action-acceptTravel  = COND #( WHEN ls_travel-overall_status = 'A'
                                                            THEN if_abap_behv=>fc-o-disabled
                                                            ELSE if_abap_behv=>fc-o-enabled )
                        %action-rejectTravel  = COND #( WHEN ls_travel-overall_status = 'X'
                                                            THEN if_abap_behv=>fc-o-disabled
                                                            ELSE if_abap_behv=>fc-o-enabled ) ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD acceptTravel.

*   Modify in local mode - BO - related updates there aree not relevant for autorization objects
    MODIFY ENTITIES OF z_i_travel_log_mr IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( overall_status )
        WITH VALUE #( FOR key_row IN keys ( travel_id      = key_row-travel_id
                                            overall_status = 'A' ) ) "Accepted
        FAILED failed
        REPORTED reported.

    READ ENTITIES OF z_i_travel_log_mr IN LOCAL MODE
        ENTITY Travel
        FIELDS ( agency_id
                 customer_id
                 begin_date
                 end_date
                 booking_fee
                 total_price
                 currency_code
                 overall_status
                 description
                 created_by
                 created_at
                 last_changed_by
                 last_changed_at )
        WITH VALUE #( FOR key_row1 IN keys ( travel_id = key_row1-travel_id ) )
        RESULT DATA(lt_travel).

    result = VALUE #( FOR ls_travel IN lt_travel ( travel_id = ls_travel-travel_id
                                                   %param    = ls_travel ) ).

  ENDMETHOD.

  METHOD createTravelByTemplate.
*   keys[ 1 ]
*   result[ 1 ]
*   mapped-
*   failed-
*   reported-

    " se lee el objeto de negocio, la entidad travel
    READ ENTITIES OF z_i_travel_log_mr
        ENTITY Travel
        FIELDS ( travel_id agency_id customer_id booking_fee total_price currency_code )
        WITH VALUE #( FOR row_key IN keys ( %key = row_key-%key ) )
        RESULT DATA(lt_entity_travel)
        FAILED failed
        REPORTED reported.

*    READ ENTITY z_i_travel_log_mr
*        FIELDS ( travel_id agency_id customer_id booking_fee total_price currency_code )
*        WITH VALUE #( FOR row_key IN keys ( %key = row_key-%key ) )
*        RESULT lt_read_entity_travel
*        FAILED failed
*        REPORTED reported.

    " se declara una tabla interna de tipo travel
    DATA lt_create_travel TYPE TABLE FOR CREATE z_i_travel_log_mr\\Travel.

    " se obtiene el travel_id maximo de la tabla
    SELECT MAX( travel_id ) FROM ztravel_log_mr INTO @DATA(lv_travel_id).

    " se obtiene la fecha del sistema
    DATA(lv_today) = cl_abap_context_info=>get_system_date(  ).

    " se completa la tabla con la información leida más el id + 1 y fecha ini y fin
    lt_create_travel = VALUE #( FOR create_row IN lt_entity_travel INDEX INTO idx
                                ( travel_id      = lv_travel_id + idx
                                  agency_id      = create_row-agency_id
                                  customer_id    = create_row-customer_id
                                  begin_date     = lv_today
                                  end_date       = lv_today + 30
                                  booking_fee    = create_row-booking_fee
                                  total_price    = create_row-total_price
                                  currency_code  = create_row-currency_code
                                  description    = 'Add comments'
                                  overall_status = 'O' ) ).

    " se modifica la entidad hasta la capa de persistencia
    MODIFY ENTITIES OF z_i_travel_log_mr
           IN LOCAL MODE ENTITY travel
           CREATE FIELDS ( travel_id
                           agency_id
                           customer_id
                           begin_date
                           end_date
                           booking_fee
                           total_price
                           currency_code
                           description
                           overall_status )
           WITH lt_create_travel
           MAPPED mapped
           FAILED failed
           REPORTED reported.

    " se devuelve los resultados a la capa de la interfaz de usuario
    result = VALUE #( FOR result_row IN lt_create_travel INDEX INTO idx
                        ( %cid_ref = keys[ idx ]-%cid_ref
                          %key     = keys[ idx ]-%key
                          %param   = CORRESPONDING #( result_row ) ) ).

    CHECK failed IS INITIAL.

  ENDMETHOD.

  METHOD rejectTravel.


*   Modify in local mode - BO - related updates there aree not relevant for autorization objects
    MODIFY ENTITIES OF z_i_travel_log_mr IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( overall_status )
        WITH VALUE #( FOR key_row IN keys ( travel_id      = key_row-travel_id
                                            overall_status = 'X' ) ) "Reject
        FAILED failed
        REPORTED reported.

    READ ENTITIES OF z_i_travel_log_mr IN LOCAL MODE
        ENTITY Travel
        FIELDS ( agency_id
                 customer_id
                 begin_date
                 end_date
                 booking_fee
                 total_price
                 currency_code
                 overall_status
                 description
                 created_by
                 created_at
                 last_changed_by
                 last_changed_at )
        WITH VALUE #( FOR key_row1 IN keys ( travel_id = key_row1-travel_id ) )
        RESULT DATA(lt_travel).

    result = VALUE #( FOR ls_travel IN lt_travel ( travel_id = ls_travel-travel_id
                                                   %param    = ls_travel ) ).

  ENDMETHOD.

  METHOD validateCustomer.

    " se leen los customer_id de la entidad
    READ ENTITIES OF z_i_travel_log_mr IN LOCAL MODE
        ENTITY Travel
        FIELDS ( customer_id )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel).

    DATA lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " se mueven los customer_id a una tabla ordenada y se eliminan duplicados
    lt_customer = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = customer_id EXCEPT * ).
    " se eliminan customer_id vacios
    DELETE lt_customer WHERE customer_id IS INITIAL.

    "se obtienen los customer_id de la DB
    SELECT FROM /dmo/customer FIELDS customer_id
        FOR ALL ENTRIES IN @lt_customer
        WHERE customer_id EQ @lt_customer-customer_id
        INTO TABLE @DATA(lt_customer_db).

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      IF <ls_travel>-customer_id IS INITIAL OR
         NOT line_exists( lt_customer_db[ customer_id = <ls_travel>-customer_id ] ).

        APPEND VALUE #( travel_id = <ls_travel>-travel_id ) TO failed-travel.

        APPEND VALUE #( travel_id = <ls_travel>-travel_id
                        %msg      = new_message( id = 'Z_MC_TRAVEL_LOG_MR'
                        number    = 001
                        v1        = <ls_travel>-travel_id
                        severity  = if_abap_behv_message=>severity-error )
                        %element-customer_id = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.
  ENDMETHOD.

  METHOD validateStatus.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z_I_TRAVEL_LOG_MR DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z_I_TRAVEL_LOG_MR IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
