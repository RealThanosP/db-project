CREATE TABLE IF NOT EXISTS "User" (
	"id" VARCHAR NOT NULL UNIQUE,
	"name" VARCHAR NOT NULL,
	"password" VARCHAR NOT NULL,
	"employer_id" VARCHAR,
	PRIMARY KEY("id")
);

CREATE TABLE IF NOT EXISTS "Pharmacy" (
	"id" VARCHAR NOT NULL,
	"VAT" INTEGER NOT NULL,
	"email" VARCHAR,
	"name" VARCHAR NOT NULL,
	"address_id" VARCHAR NOT NULL,
	PRIMARY KEY("id"),
	FOREIGN KEY ("id") REFERENCES "Phones"("pharmacy_id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("address_id") REFERENCES "Address"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("id") REFERENCES "User"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Phones" (
	"phone" INTEGER NOT NULL,
	"pharmacy_id" VARCHAR NOT NULL,
	PRIMARY KEY("phone", "pharmacy_id")
);

CREATE TABLE IF NOT EXISTS "Address" (
	"id" VARCHAR NOT NULL,
	"city" VARCHAR NOT NULL,
	"street" VARCHAR NOT NULL,
	"st_number" INTEGER,
	"floor" INTEGER,
	PRIMARY KEY("id")
);

CREATE TABLE IF NOT EXISTS "Delivery" (
	"id" VARCHAR NOT NULL,
	"state" VARCHAR NOT NULL,
	"dispatch_date" DATETIME NOT NULL,
	"date_of_arrival" DATETIME NOT NULL,
	"address_id" VARCHAR NOT NULL,
	"order_id" VARCHAR NOT NULL,
	PRIMARY KEY("id"),
	FOREIGN KEY ("address_id") REFERENCES "Address"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("id") REFERENCES "Delivery_Items"("delivery_id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("order_id") REFERENCES "Order"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Delivery_Items" (
	"item_idx" INTEGER NOT NULL,
	"delivery_id" VARCHAR NOT NULL,
	"quantity" INTEGER NOT NULL,
	"order_id" VARCHAR NOT NULL,
	"order_item_idx" INTEGER,
	PRIMARY KEY("item_idx", "delivery_id"),
	FOREIGN KEY ("order_id", "order_item_idx") REFERENCES "Order_Items"("order_id", "idx")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Batch" (
	"id" INTEGER NOT NULL,
	"med_id" INTEGER NOT NULL,
	"exp_date" DATE NOT NULL,
	"available_qty" INTEGER NOT NULL,
	"number" INTEGER NOT NULL,
	PRIMARY KEY("id", "med_id"),
	FOREIGN KEY ("id") REFERENCES "Selected_Delivery_Items_Batch"("batch_id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("med_id") REFERENCES "Medicine"("barcode")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Selected_Delivery_Items_Batch" (
	"delivery_item_idx" INTEGER NOT NULL,
	"delivery_id" VARCHAR NOT NULL,
	"batch_id" INTEGER NOT NULL,
	"quantity_delivered_per_batch" INTEGER NOT NULL,
	PRIMARY KEY("delivery_item_idx", "delivery_id", "batch_id"),
	FOREIGN KEY ("delivery_item_idx", "delivery_id") REFERENCES "Delivery_Items"("item_idx", "delivery_id")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Order" (
	"id" VARCHAR NOT NULL,
	"exp_doa" DATE,
	"submit_date" DATETIME NOT NULL,
	"state" VARCHAR NOT NULL,
	"user_id" VARCHAR NOT NULL,
	PRIMARY KEY("id"),
	FOREIGN KEY ("id") REFERENCES "Order_Items"("order_id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("user_id") REFERENCES "User"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Order_Items" (
	"order_id" VARCHAR NOT NULL,
	"idx" INTEGER NOT NULL,
	"wanted_qty" INTEGER NOT NULL,
	"refused_qty" INTEGER NOT NULL,
	"medicine_id" INTEGER NOT NULL,
	PRIMARY KEY("order_id", "idx"),
	FOREIGN KEY ("medicine_id") REFERENCES "Medicine"("barcode")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Returns" (
	"batch_id" INTEGER NOT NULL,
	"med_id" INTEGER NOT NULL,
	"pharmacy_id" VARCHAR NOT NULL,
	"return_date" DATE NOT NULL,
	"return_reason" VARCHAR NOT NULL,
	"return_qty" INTEGER NOT NULL,
	PRIMARY KEY("batch_id", "med_id", "pharmacy_id", "return_date"),
	FOREIGN KEY ("batch_id", "med_id") REFERENCES "Batch"("id", "med_id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("pharmacy_id") REFERENCES "Pharmacy"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Commits" (
	"order_id" VARCHAR NOT NULL,
	"order_item_idx" INTEGER NOT NULL,
	"medicine_id" INTEGER NOT NULL,
	"commited_qty" INTEGER NOT NULL,
	PRIMARY KEY("order_id", "order_item_idx"),
	FOREIGN KEY ("order_item_idx", "order_id") REFERENCES "Order_Items"("idx", "order_id")
	ON UPDATE NO ACTION ON DELETE NO ACTION,
	FOREIGN KEY ("medicine_id") REFERENCES "Medicine"("barcode")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Medicine" (
	"barcode" INTEGER NOT NULL,
	"commercial_name" VARCHAR NOT NULL,
	"measure_unit" VARCHAR NOT NULL,
	"package_qty" INTEGER NOT NULL,
	"unit_price" REAL NOT NULL,
	PRIMARY KEY("barcode"),
	FOREIGN KEY ("barcode") REFERENCES "Medicine_Composition"("barcode")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Active_Substances" (
	"inn_name" VARCHAR NOT NULL,
	PRIMARY KEY("inn_name"),
	FOREIGN KEY ("inn_name") REFERENCES "Medicine_Composition"("substance_name")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "Medicine_Composition" (
	"barcode" INTEGER NOT NULL,
	"substance_name" VARCHAR NOT NULL,
	"content" REAL NOT NULL,
	"content_unit" VARCHAR NOT NULL,
	PRIMARY KEY("barcode", "substance_name")
);
