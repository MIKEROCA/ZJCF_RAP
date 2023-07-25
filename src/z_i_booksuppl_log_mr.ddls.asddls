@AbapCatalog.sqlViewName: 'ZV_BOOK_LOG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface - Booking Supplement'
define view Z_I_BOOKSUPPL_LOG_MR
  as select from zbooksuppl_logmr as BookingSupplement
  association        to parent Z_I_BOOKING_LOG_MR as _Booking        on  $projection.travel_id  = _Booking.travel_id
                                                                     and $projection.booking_id = _Booking.booking_id
  association [1..1] to Z_I_TRAVEL_LOG_MR         as _Travel         on  $projection.travel_id = _Travel.travel_id
  association [1..1] to /DMO/I_Supplement         as _Product        on  $projection.supplement_id = _Product.SupplementID
  association [1..*] to /DMO/I_SupplementText     as _SupplementText on  $projection.supplement_id = _SupplementText.SupplementID
{
  key travel_id,
  key booking_id,
  key booking_supplement_id,
      supplement_id,
      @Semantics.amount.currencyCode : 'currency'
      price,
      @Semantics.currencyCode: true
      currency,
      @Semantics.systemDateTime.lastChangedAt: true
      _Travel.last_changed_at,
      _Booking,
      _Travel,
      _Product,
      _SupplementText
}
