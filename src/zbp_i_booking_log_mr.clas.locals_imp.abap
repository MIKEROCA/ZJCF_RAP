CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalFlightPrice FOR DETERMINE ON MODIFY IMPORTING keys FOR Booking~calculateTotalFlightPrice.

    METHODS validateStatus            FOR VALIDATE ON SAVE IMPORTING keys FOR Booking~validateStatus.

    METHODS get_instance_features     FOR INSTANCE FEATURES      IMPORTING keys REQUEST requested_features FOR Booking RESULT result.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calculateTotalFlightPrice.
  ENDMETHOD.

  METHOD validateStatus.

    READ ENTITY z_i_travel_log_mr\\Booking
        FIELDS ( booking_status )
        WITH VALUE #( FOR <row_key> IN keys ( %key = <row_key>-%key ) )
        RESULT DATA(lt_booking_result).

    LOOP AT lt_booking_result INTO DATA(ls_booking_result).
      CASE ls_booking_result-booking_status.
        WHEN 'N'. "New
        WHEN 'X'. "Cancelled
        WHEN 'B'. "booked
        WHEN OTHERS.
          APPEND VALUE #( %key = ls_booking_result-%key ) TO failed-booking.

          APPEND VALUE #( %key = ls_booking_result-%key
                          %msg = new_message( id        = 'Z_MC_TRAVEL_LOG_MR'
                                              number    = 007
                                              v1        = ls_booking_result-booking_id
                                              severity  = if_abap_behv_message=>severity-error )
                        %element-booking_status = if_abap_behv=>mk-on ) TO reported-booking.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.

*   Habilita o deshabilita acciones y campos.  Se llama antes y después de las acciones
    READ ENTITIES OF z_i_travel_log_mr
        ENTITY Booking
        FIELDS ( booking_id booking_date customer_id booking_status )
        WITH VALUE #( FOR key_row IN keys ( %key = key_row-%key ) )
        RESULT DATA(lt_booking_result).

    result = VALUE #( FOR ls_booking IN lt_booking_result (
                        %key                        = ls_booking-%key
                        %assoc-_BookingSupplement   = if_abap_behv=>fc-o-enabled ) ).

  ENDMETHOD.

ENDCLASS.
