import sqlite3
import unittest
from pathlib import Path

SCHEMA = Path(__file__).resolve().parents[1] / 'schema.sql'

class SchemaTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.execute('PRAGMA foreign_keys = ON')
        self.db.executescript(SCHEMA.read_text())
        self.db.executescript('''
            INSERT INTO Address(id,city,street) VALUES ('a','Athens','Main');
            INSERT INTO Pharmacy VALUES ('p',123,'p@example.com','Customer','a');
            INSERT INTO User VALUES ('u','Employee','password-hash',NULL);
            INSERT INTO Medicine VALUES (1,'A','pieces',10,1),(2,'B','pieces',10,1);
            INSERT INTO "Order"(id,submit_date,state,user_id,pharmacy_id)
                VALUES ('o','2026-11-11','new','u','p'),('other','2026-11-11','new','u','p');
            INSERT INTO Order_Items VALUES ('o',1,10,0,1),('other',1,10,0,2);
            INSERT INTO Batch VALUES (1,1,'2027-01-01',20,101),(2,2,'2027-01-01',20,102);
            INSERT INTO Delivery(id,state,address_id,order_id) VALUES ('d','pending','a','o');
        ''')

    def tearDown(self):
        self.db.close()

    def reject(self, sql):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(sql)

    def line(self, quantity=6):
        self.db.execute("INSERT INTO Delivery_Items VALUES (1,'d',?,'o',1)", (quantity,))

    def test_foreign_keys_and_customer(self):
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])
        self.reject("INSERT INTO Phones VALUES (123,'missing')")
        self.reject("INSERT INTO Medicine_Composition VALUES (1,'missing',10,'mg')")
        self.db.execute("INSERT INTO Active_Substances VALUES ('substance')")
        self.db.execute("INSERT INTO Medicine_Composition VALUES (1,'substance',10,'mg')")
        self.reject("UPDATE User SET employer_id='missing'")
        self.reject('UPDATE "Order" SET pharmacy_id=\'missing\'')

    def test_delivery_order_and_required_item(self):
        self.reject("INSERT INTO Delivery_Items VALUES (1,'d',1,'other',1)")
        self.reject("INSERT INTO Delivery_Items VALUES (1,'d',1,'o',NULL)")
        self.reject("INSERT INTO Delivery_Items VALUES (1,'missing',1,'o',1)")

    def test_batch_identity_and_medicine(self):
        self.line()
        self.reject("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',999,6)")
        self.reject("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',2,6)")
        self.db.execute("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,6)")
        self.reject("UPDATE Batch SET med_id=2 WHERE id=1")
        self.reject("UPDATE Order_Items SET medicine_id=2 WHERE order_id='o'")

    def test_quantity_bounds(self):
        self.reject("UPDATE Order_Items SET wanted_qty=-1")
        self.reject("UPDATE Order_Items SET refused_qty=11")
        self.reject("UPDATE Batch SET available_qty=-1")
        self.reject("UPDATE Batch SET available_qty=1.5")
        self.reject("INSERT INTO Commits VALUES ('o',1,-1)")
        self.reject("INSERT INTO Delivery_Items VALUES (1,'d',-1,'o',1)")
        self.line()
        self.reject("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,-1)")

    def test_delivery_totals_on_insert_update_and_order_edit(self):
        self.line()
        self.db.execute("INSERT INTO Delivery(id,state,address_id,order_id) VALUES ('d2','pending','a','o')")
        self.reject("INSERT INTO Delivery_Items VALUES (1,'d2',5,'o',1)")
        self.db.execute("INSERT INTO Delivery_Items VALUES (1,'d2',4,'o',1)")
        self.reject("UPDATE Delivery_Items SET quantity=5 WHERE delivery_id='d2'")
        self.reject("UPDATE Order_Items SET refused_qty=1 WHERE order_id='o'")
        self.reject("UPDATE Order_Items SET wanted_qty=9 WHERE order_id='o'")

    def test_reservations(self):
        self.db.execute("INSERT INTO Commits VALUES ('o',1,10)")
        self.reject("UPDATE Commits SET commited_qty=11")
        self.reject("UPDATE Batch SET available_qty=9 WHERE id=1")
        self.db.execute("INSERT INTO Order_Items VALUES ('other',2,20,0,1)")
        self.reject("INSERT INTO Commits VALUES ('other',2,11)")
        self.db.execute("INSERT INTO Commits VALUES ('other',2,10)")
        self.reject("DELETE FROM Batch WHERE id=1")

    def test_allocations_and_dispatch(self):
        self.line()
        self.reject("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,7)")
        self.reject("UPDATE Delivery SET state='dispatched',dispatch_date='2026-11-11' WHERE id='d'")
        self.db.execute("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,6)")
        self.reject("UPDATE Batch SET available_qty=5 WHERE id=1")
        self.reject("UPDATE Delivery SET state='delivered' WHERE id='d'")
        self.db.execute("UPDATE Delivery SET state='dispatched',dispatch_date='2026-11-11' WHERE id='d'")
        self.reject("DELETE FROM Selected_Delivery_Items_Batch WHERE delivery_id='d'")
        self.reject("UPDATE Delivery_Items SET quantity=5 WHERE delivery_id='d'")
        self.reject("INSERT INTO Commits VALUES ('o',1,5)")

    def test_pending_capacity_and_empty_dispatch(self):
        self.reject("UPDATE Delivery SET state='dispatched',dispatch_date='2026-11-11'")
        self.line(10)
        self.db.execute("INSERT INTO Order_Items VALUES ('other',2,20,0,1)")
        self.reject("INSERT INTO Commits VALUES ('other',2,11)")
        self.db.execute("INSERT INTO Commits VALUES ('o',1,10)")
        self.db.execute("INSERT INTO Commits VALUES ('other',2,10)")

    def test_cancel_pending_quantities(self):
        self.db.execute("INSERT INTO Commits VALUES ('o',1,10)")
        self.line()
        self.db.execute("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,6)")
        self.db.execute("DELETE FROM Selected_Delivery_Items_Batch WHERE delivery_id='d'")
        self.db.execute("DELETE FROM Delivery_Items WHERE delivery_id='d'")
        self.db.execute("DELETE FROM Commits WHERE order_id='o'")
        self.db.execute("UPDATE Order_Items SET refused_qty=10 WHERE order_id='o'")
        self.assertEqual(self.db.execute('SELECT * FROM Schema_Violations').fetchall(), [])

    def test_multiple_batches_and_deliveries(self):
        self.db.execute("INSERT INTO Batch VALUES (3,1,'2027-01-01',10,103)")
        self.line()
        self.db.execute("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,3),(1,'d',3,3)")
        self.db.execute("UPDATE Delivery SET state='dispatched',dispatch_date='2026-11-11' WHERE id='d'")
        self.db.execute("UPDATE Batch SET available_qty=available_qty-3 WHERE id IN (1,3)")
        self.db.execute("INSERT INTO Delivery(id,state,address_id,order_id) VALUES ('d2','pending','a','o')")
        self.db.execute("INSERT INTO Delivery_Items VALUES (1,'d2',4,'o',1)")
        self.db.execute("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d2',1,4)")
        self.db.execute("UPDATE Delivery SET state='dispatched',dispatch_date='2026-11-12' WHERE id='d2'")
        self.db.execute("UPDATE Batch SET available_qty=available_qty-4 WHERE id=1")
        self.reject("INSERT INTO Commits VALUES ('o',1,1)")
        self.assertEqual(self.db.execute("SELECT shipped_qty FROM Order_Item_Totals WHERE order_id='o'").fetchone()[0], 10)

    def test_failed_dispatch_transaction_rolls_back(self):
        self.line()
        self.db.execute("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,6)")
        self.db.commit()
        self.db.execute('BEGIN IMMEDIATE')
        self.db.execute("UPDATE Delivery SET state='dispatched',dispatch_date='2026-11-11' WHERE id='d'")
        self.reject("UPDATE Batch SET available_qty=-1 WHERE id=1")
        self.db.rollback()
        self.assertEqual(self.db.execute("SELECT state FROM Delivery WHERE id='d'").fetchone()[0], 'pending')
        self.assertEqual(self.db.execute('SELECT available_qty FROM Batch WHERE id=1').fetchone()[0], 20)

    def test_partial_delivery_workflow(self):
        self.db.execute("INSERT INTO Commits VALUES ('o',1,10)")
        self.line()
        self.db.execute("INSERT INTO Selected_Delivery_Items_Batch VALUES (1,'d',1,6)")
        # Dispatch in one transaction: release reservation, dispatch, deduct physical stock.
        self.db.execute("UPDATE Commits SET commited_qty=4 WHERE order_id='o'")
        self.db.execute("UPDATE Delivery SET state='dispatched',dispatch_date='2026-11-11' WHERE id='d'")
        self.db.execute("UPDATE Batch SET available_qty=available_qty-6 WHERE id=1")
        self.db.execute("UPDATE Delivery SET state='delivered',date_of_arrival='2026-11-12' WHERE id='d'")
        self.reject("UPDATE Delivery SET state='pending',dispatch_date=NULL,date_of_arrival=NULL WHERE id='d'")
        self.assertEqual(self.db.execute('SELECT available_qty FROM Batch WHERE id=1').fetchone()[0],14)
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(),[])

if __name__ == '__main__':
    unittest.main()
