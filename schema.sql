CREATE TABLE IF NOT EXISTS "User" (
    "id" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "password" VARCHAR(255) NOT NULL,
    "employer_id" VARCHAR(255),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("employer_id") REFERENCES "Pharmacy" ("id")
);

CREATE TABLE IF NOT EXISTS "Pharmacy" (
    "id" VARCHAR(255) NOT NULL,
    "VAT" INTEGER NOT NULL,
    "email" VARCHAR(255),
    "name" VARCHAR(255) NOT NULL,
    "address_id" VARCHAR(255) NOT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("address_id") REFERENCES "Address" ("id")
);

CREATE TABLE IF NOT EXISTS "Phones" (
    "phone" INTEGER NOT NULL,
    "pharmacy_id" VARCHAR(255) NOT NULL,
    PRIMARY KEY ("phone", "pharmacy_id"),
    FOREIGN KEY ("pharmacy_id") REFERENCES "Pharmacy" ("id")
);

CREATE TABLE IF NOT EXISTS "Address" (
    "id" VARCHAR(255) NOT NULL,
    "city" VARCHAR(255) NOT NULL,
    "street" VARCHAR(255) NOT NULL,
    "st_number" INTEGER,
    "floor" INTEGER,
    PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "Delivery" (
    "id" VARCHAR(255) NOT NULL,
    "state" VARCHAR(255) NOT NULL,
    "dispatch_date" DATETIME,
    "date_of_arrival" DATETIME,
    "address_id" VARCHAR(255) NOT NULL,
    "order_id" VARCHAR(255) NOT NULL,
    PRIMARY KEY ("id"),
    UNIQUE ("id", "order_id"),
    CHECK (state IN ('pending', 'dispatched', 'delivered')),
    CHECK ((state = 'pending' AND dispatch_date IS NULL AND date_of_arrival IS NULL) OR (state = 'dispatched' AND dispatch_date IS NOT NULL AND date_of_arrival IS NULL) OR (state = 'delivered' AND dispatch_date IS NOT NULL AND date_of_arrival IS NOT NULL)),
    CHECK (date_of_arrival IS NULL OR date_of_arrival >= dispatch_date),
    FOREIGN KEY ("address_id") REFERENCES "Address" ("id"),
    FOREIGN KEY ("order_id") REFERENCES "Order" ("id")
);

CREATE TABLE IF NOT EXISTS "Delivery_Items" (
    "item_idx" INTEGER NOT NULL,
    "delivery_id" VARCHAR(255) NOT NULL,
    "quantity" INTEGER NOT NULL,
    "order_id" VARCHAR(255) NOT NULL,
    "order_item_idx" INTEGER NOT NULL,
    PRIMARY KEY ("item_idx", "delivery_id"),
    CHECK (typeof(quantity) = 'integer' AND quantity > 0),
    FOREIGN KEY ("delivery_id", "order_id") REFERENCES "Delivery" ("id", "order_id"),
    FOREIGN KEY ("order_id", "order_item_idx") REFERENCES "Order_Items" ("order_id", "idx")
);

CREATE TABLE IF NOT EXISTS "Batch" (
    "id" INTEGER NOT NULL,
    "med_id" INTEGER NOT NULL,
    "exp_date" DATE NOT NULL,
    "available_qty" INTEGER NOT NULL,
    "number" INTEGER NOT NULL,
    PRIMARY KEY ("id"),
    UNIQUE ("id", "med_id"),
    CHECK (typeof(available_qty) = 'integer' AND available_qty >= 0),
    FOREIGN KEY ("med_id") REFERENCES "Medicine" ("barcode")
);

CREATE TABLE IF NOT EXISTS "Selected_Delivery_Items_Batch" (
    "delivery_item_idx" INTEGER NOT NULL,
    "delivery_id" VARCHAR(255) NOT NULL,
    "batch_id" INTEGER NOT NULL,
    "quantity_delivered_per_batch" INTEGER NOT NULL,
    PRIMARY KEY ("delivery_item_idx", "delivery_id", "batch_id"),
    CHECK (typeof(quantity_delivered_per_batch) = 'integer' AND quantity_delivered_per_batch > 0),
    FOREIGN KEY ("delivery_item_idx", "delivery_id") REFERENCES "Delivery_Items" ("item_idx", "delivery_id"),
    FOREIGN KEY ("batch_id") REFERENCES "Batch" ("id")
);

CREATE TABLE IF NOT EXISTS "Order" (
    "id" VARCHAR(255) NOT NULL,
    "exp_doa" DATE,
    "submit_date" DATETIME NOT NULL,
    "state" VARCHAR(255) NOT NULL,
    "user_id" VARCHAR(255) NOT NULL,
    "pharmacy_id" VARCHAR(255) NOT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("user_id") REFERENCES "User" ("id"),
    FOREIGN KEY ("pharmacy_id") REFERENCES "Pharmacy" ("id")
);

CREATE TABLE IF NOT EXISTS "Order_Items" (
    "order_id" VARCHAR(255) NOT NULL,
    "idx" INTEGER NOT NULL,
    "wanted_qty" INTEGER NOT NULL,
    "refused_qty" INTEGER NOT NULL,
    "medicine_id" INTEGER NOT NULL,
    PRIMARY KEY ("order_id", "idx"),
    CHECK (typeof(wanted_qty) = 'integer' AND wanted_qty > 0),
    CHECK (typeof(refused_qty) = 'integer' AND refused_qty >= 0 AND refused_qty <= wanted_qty),
    FOREIGN KEY ("order_id") REFERENCES "Order" ("id"),
    FOREIGN KEY ("medicine_id") REFERENCES "Medicine" ("barcode")
);

CREATE TABLE IF NOT EXISTS "Returns" (
    "batch_id" INTEGER NOT NULL,
    "med_id" INTEGER NOT NULL,
    "pharmacy_id" VARCHAR(255) NOT NULL,
    "return_date" DATE NOT NULL,
    "return_reason" VARCHAR(255) NOT NULL,
    "return_qty" INTEGER NOT NULL,
    PRIMARY KEY ("batch_id", "med_id", "pharmacy_id", "return_date"),
    CHECK (typeof(return_qty) = 'integer' AND return_qty > 0),
    FOREIGN KEY ("batch_id", "med_id") REFERENCES "Batch" ("id", "med_id"),
    FOREIGN KEY ("pharmacy_id") REFERENCES "Pharmacy" ("id")
);

CREATE TABLE IF NOT EXISTS "Commits" (
    "order_id" VARCHAR(255) NOT NULL,
    "order_item_idx" INTEGER NOT NULL,
    "commited_qty" INTEGER NOT NULL,
    PRIMARY KEY ("order_id", "order_item_idx"),
    CHECK (typeof(commited_qty) = 'integer' AND commited_qty >= 0),
    FOREIGN KEY ("order_id", "order_item_idx") REFERENCES "Order_Items" ("order_id", "idx")
);

CREATE TABLE IF NOT EXISTS "Medicine" (
    "barcode" INTEGER NOT NULL,
    "commercial_name" VARCHAR(255) NOT NULL,
    "measure_unit" VARCHAR(255) NOT NULL,
    "package_qty" INTEGER NOT NULL,
    "unit_price" REAL NOT NULL,
    PRIMARY KEY ("barcode"),
    CHECK (package_qty > 0),
    CHECK (unit_price >= 0)
);

CREATE TABLE IF NOT EXISTS "Active_Substances" (
    "inn_name" VARCHAR(255) NOT NULL,
    PRIMARY KEY ("inn_name")
);

CREATE TABLE IF NOT EXISTS "Medicine_Composition" (
    "barcode" INTEGER NOT NULL,
    "substance_name" VARCHAR(255) NOT NULL,
    "content" REAL NOT NULL,
    "content_unit" VARCHAR(255) NOT NULL,
    PRIMARY KEY ("barcode", "substance_name"),
    CHECK (content > 0),
    FOREIGN KEY ("barcode") REFERENCES "Medicine" ("barcode"),
    FOREIGN KEY ("substance_name") REFERENCES "Active_Substances" ("inn_name")
);

CREATE INDEX IF NOT EXISTS "ix_User_employer_id" ON "User" ("employer_id");
CREATE INDEX IF NOT EXISTS "ix_Pharmacy_address_id" ON "Pharmacy" ("address_id");
CREATE INDEX IF NOT EXISTS "ix_Phones_pharmacy_id" ON "Phones" ("pharmacy_id");
CREATE INDEX IF NOT EXISTS "ix_Delivery_address_id" ON "Delivery" ("address_id");
CREATE INDEX IF NOT EXISTS "ix_Delivery_order_id" ON "Delivery" ("order_id");
CREATE INDEX IF NOT EXISTS "ix_Delivery_Items_delivery_id_order_id" ON "Delivery_Items" ("delivery_id", "order_id");
CREATE INDEX IF NOT EXISTS "ix_Delivery_Items_order_id_order_item_idx" ON "Delivery_Items" ("order_id", "order_item_idx");
CREATE INDEX IF NOT EXISTS "ix_Batch_med_id" ON "Batch" ("med_id");
CREATE INDEX IF NOT EXISTS "ix_Selected_Delivery_Items_Batch_delivery_item_idx_delivery_id" ON "Selected_Delivery_Items_Batch" ("delivery_item_idx", "delivery_id");
CREATE INDEX IF NOT EXISTS "ix_Selected_Delivery_Items_Batch_batch_id" ON "Selected_Delivery_Items_Batch" ("batch_id");
CREATE INDEX IF NOT EXISTS "ix_Order_user_id" ON "Order" ("user_id");
CREATE INDEX IF NOT EXISTS "ix_Order_pharmacy_id" ON "Order" ("pharmacy_id");
CREATE INDEX IF NOT EXISTS "ix_Order_Items_order_id" ON "Order_Items" ("order_id");
CREATE INDEX IF NOT EXISTS "ix_Order_Items_medicine_id" ON "Order_Items" ("medicine_id");
CREATE INDEX IF NOT EXISTS "ix_Returns_batch_id_med_id" ON "Returns" ("batch_id", "med_id");
CREATE INDEX IF NOT EXISTS "ix_Returns_pharmacy_id" ON "Returns" ("pharmacy_id");
CREATE INDEX IF NOT EXISTS "ix_Commits_order_id_order_item_idx" ON "Commits" ("order_id", "order_item_idx");
CREATE INDEX IF NOT EXISTS "ix_Medicine_Composition_barcode" ON "Medicine_Composition" ("barcode");
CREATE INDEX IF NOT EXISTS "ix_Medicine_Composition_substance_name" ON "Medicine_Composition" ("substance_name");

-- Cross-row invariants are centralized so edits to either side are checked.
-- Pending delivery quantities consume capacity even without an explicit reservation.
CREATE VIEW IF NOT EXISTS "Order_Item_Totals" AS
SELECT oi.order_id, oi.idx, oi.medicine_id, oi.wanted_qty, oi.refused_qty,
       COALESCE(c.commited_qty, 0) AS reserved_qty,
       COALESCE((SELECT SUM(di.quantity) FROM Delivery_Items di
                 JOIN Delivery d ON d.id = di.delivery_id
                 WHERE di.order_id = oi.order_id AND di.order_item_idx = oi.idx
                   AND d.state = 'pending'), 0) AS pending_qty,
       COALESCE((SELECT SUM(di.quantity) FROM Delivery_Items di
                 JOIN Delivery d ON d.id = di.delivery_id
                 WHERE di.order_id = oi.order_id AND di.order_item_idx = oi.idx
                   AND d.state IN ('dispatched', 'delivered')), 0) AS shipped_qty
FROM Order_Items oi
LEFT JOIN Commits c ON c.order_id = oi.order_id AND c.order_item_idx = oi.idx;

CREATE VIEW IF NOT EXISTS "Schema_Violations" AS
SELECT 'Order quantities exceed the unrefused quantity' AS reason
FROM Order_Item_Totals
WHERE shipped_qty + MAX(reserved_qty, pending_qty) > wanted_qty - refused_qty
UNION ALL
SELECT 'Reservations or pending deliveries exceed physical stock'
FROM Order_Item_Totals t
GROUP BY medicine_id
HAVING SUM(MAX(reserved_qty, pending_qty)) >
       COALESCE((SELECT SUM(b.available_qty) FROM Batch b WHERE b.med_id = t.medicine_id), 0)
UNION ALL
SELECT 'Allocated batch contains a different medicine'
FROM Selected_Delivery_Items_Batch a
JOIN Batch b ON b.id = a.batch_id
JOIN Delivery_Items di ON di.delivery_id = a.delivery_id AND di.item_idx = a.delivery_item_idx
JOIN Order_Items oi ON oi.order_id = di.order_id AND oi.idx = di.order_item_idx
WHERE b.med_id <> oi.medicine_id
UNION ALL
SELECT 'Batch allocation exceeds delivery item quantity'
FROM Selected_Delivery_Items_Batch a
JOIN Delivery_Items di ON di.delivery_id = a.delivery_id AND di.item_idx = a.delivery_item_idx
GROUP BY a.delivery_id, a.delivery_item_idx
HAVING SUM(a.quantity_delivered_per_batch) > di.quantity
UNION ALL
SELECT 'Pending batch allocations exceed physical stock'
FROM Selected_Delivery_Items_Batch a
JOIN Delivery d ON d.id = a.delivery_id
JOIN Batch b ON b.id = a.batch_id
WHERE d.state = 'pending'
GROUP BY a.batch_id
HAVING SUM(a.quantity_delivered_per_batch) > b.available_qty
UNION ALL
SELECT 'Dispatched delivery requires items and complete batch allocations'
FROM Delivery d
WHERE d.state IN ('dispatched', 'delivered') AND (
    NOT EXISTS (SELECT 1 FROM Delivery_Items di WHERE di.delivery_id = d.id)
    OR EXISTS (
        SELECT 1 FROM Delivery_Items di WHERE di.delivery_id = d.id
        AND di.quantity <> COALESCE((
            SELECT SUM(a.quantity_delivered_per_batch)
            FROM Selected_Delivery_Items_Batch a
            WHERE a.delivery_id = di.delivery_id AND a.delivery_item_idx = di.item_idx
        ), 0)
    )
);

CREATE TRIGGER IF NOT EXISTS "validate_Order_Items_insert"
AFTER INSERT ON "Order_Items"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Order_Items_update"
AFTER UPDATE ON "Order_Items"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Order_Items_delete"
AFTER DELETE ON "Order_Items"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Commits_insert"
AFTER INSERT ON "Commits"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Commits_update"
AFTER UPDATE ON "Commits"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Commits_delete"
AFTER DELETE ON "Commits"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Delivery_insert"
AFTER INSERT ON "Delivery"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Delivery_update"
AFTER UPDATE ON "Delivery"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Delivery_delete"
AFTER DELETE ON "Delivery"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Delivery_Items_insert"
AFTER INSERT ON "Delivery_Items"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Delivery_Items_update"
AFTER UPDATE ON "Delivery_Items"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Delivery_Items_delete"
AFTER DELETE ON "Delivery_Items"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Batch_insert"
AFTER INSERT ON "Batch"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Batch_update"
AFTER UPDATE ON "Batch"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Batch_delete"
AFTER DELETE ON "Batch"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Selected_Delivery_Items_Batch_insert"
AFTER INSERT ON "Selected_Delivery_Items_Batch"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Selected_Delivery_Items_Batch_update"
AFTER UPDATE ON "Selected_Delivery_Items_Batch"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

CREATE TRIGGER IF NOT EXISTS "validate_Selected_Delivery_Items_Batch_delete"
AFTER DELETE ON "Selected_Delivery_Items_Batch"
BEGIN
    SELECT RAISE(ABORT, 'Order, reservation or batch allocation invariant violated')
    WHERE EXISTS (SELECT 1 FROM Schema_Violations);
END;

-- Shipping is a forward-only operation. Returns use the separate Returns table.
CREATE TRIGGER IF NOT EXISTS delivery_forward_only
BEFORE UPDATE ON Delivery
WHEN (OLD.state = 'dispatched' AND NEW.state NOT IN ('dispatched', 'delivered'))
  OR (OLD.state = 'delivered' AND NEW.state <> 'delivered')
  OR (OLD.state <> 'pending' AND (
      NEW.dispatch_date IS NOT OLD.dispatch_date
      OR NEW.order_id IS NOT OLD.order_id
      OR NEW.address_id IS NOT OLD.address_id))
  OR (OLD.state = 'delivered' AND NEW.date_of_arrival IS NOT OLD.date_of_arrival)
BEGIN
    SELECT RAISE(ABORT, 'Dispatched deliveries cannot be reverted or reassigned');
END;
