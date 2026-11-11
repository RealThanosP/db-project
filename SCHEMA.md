# Database contract

`schema.sql` is the executable **SQLite** schema for a new database.
`pharmaDB.dbml` describes the same tables, keys, references and row checks.
DBML does not include the SQLite views and triggers; exporting it alone will
not reproduce the cross-row checks in `schema.sql`.

The schema files do not migrate an existing database. `CREATE TABLE IF NOT
EXISTS` leaves existing definitions untouched. Use a fresh development database,
or write a data migration before applying these changes to an existing database.
Enable `PRAGMA foreign_keys = ON` on **every connection**, before any transaction.

## Relationships and quantities

- `Order.pharmacy_id` identifies the customer; `user_id` identifies the creator.
  `Pharmacy` is the existing customer table and can hold the customer organizations
  in the design. Customer classification is not currently modeled.
- `User.employer_id` optionally identifies a customer employer. Warehouse staff
  can leave it null. `password` stores a password hash, never plaintext.
- `Batch.id` is globally unique. The redundant `(id, med_id)` unique key supports
  the existing composite reference from `Returns`.
- `Batch.available_qty` means **physical on-hand packages**, before reservations.
  All order, delivery, reservation and batch quantities use whole packages of the
  corresponding medicine. It is not the quantity available to promise.
- `Commits` stores outstanding reservations per order item. Its medicine is derived
  from that item. A zero reservation is permitted; deleting it also releases it.
- `Order_Items.refused_qty` is the quantity refused or cancelled without shipping.
  Preserve `wanted_qty` when cancelling part of an order.
- Delivery states are `pending`, `dispatched`, `delivered`. Actual timestamps are
  null until the corresponding event. Use sortable ISO 8601 timestamps in a
  consistent timezone. Arrival must not precede dispatch.

The triggers validate inserts, updates and deletes on either side of the quantity
relationships. They reject wrong-medicine allocations, excessive allocations,
reservations exceeding physical stock, over-fulfillment and incomplete dispatches.
Pending deliveries count against capacity: for each order item, capacity held is
`max(outstanding reservation, pending delivery quantity)`, avoiding double counting
when a reserved item is prepared for dispatch. Sum this over a medicine and subtract
it from physical stock to calculate availability for a new order.

`Order_Item_Totals` exposes pending, shipped and reserved quantities. The internal
`Schema_Violations` view should always be empty. Checks are immediate, after each
statement, rather than deferred until commit. They scan aggregate state and are
intended for the initial small application; benchmark representative data before
scaling and replace broad validation with targeted checks if needed.

## Application transactions

The schema enforces bounds but does **not** automatically move stock, release
reservations, or derive `Order.state`. The application owns those operations.
Use `BEGIN IMMEDIATE` for workflows that read availability and then change it,
commit all steps together, and roll back on any failure.

1. Create an order with its customer, creator and items. Reject an empty submitted
   order in the application. Add reservations only after checking availability.
2. Create a pending delivery, add its order items and select matching batches.
   Partial batch allocation is allowed during preparation; allocation totals must
   equal each item's quantity before dispatch. Pending deliveries consume capacity
   even if there is no explicit `Commits` row.
3. To dispatch, verify the delivery is still pending. Release the outstanding
   reservations for the quantities being sent, change the delivery to dispatched
   with its timestamp, then subtract each batch's allocated quantity from physical
   stock. All three operations belong in the same transaction. Repeated dispatch
   requests must return the existing result without deducting stock again.
4. To confirm arrival, set `state = 'delivered'` and `date_of_arrival`. Do not
   deduct stock again. Update the order's status based on its delivered and
   cancelled quantities. Delivery states cannot move backwards.
5. To cancel unshipped quantities, remove/reduce their pending batch allocations
   and delivery items, release the reservations, then increase `refused_qty`.
   Remove an empty pending delivery if appropriate. Shipped quantities cannot
   be cancelled through this workflow.

The application must also protect shipped records from arbitrary editing, select
usable/unexpired batches, validate permitted order-state transitions, and authorize
staff actions. Stock adjustment auditing is not implemented by these schema fixes:
add an adjustment history with reason and actor before exposing manual stock edits.
The existing returns tables are retained, but return processing remains outside
this application's current scope and does not automatically restock batches.

## Verification

Run `python -m unittest discover -s tests -v`. Tests use isolated in-memory SQLite
databases with foreign keys enabled and cover normal setup, partial dispatch,
arrival, invalid references, quantity bounds, and mutations of related records.
