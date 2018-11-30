-- in psql

CREATE TABLE "test" (
  "id" bigint PRIMARY KEY,
  "data" varchar(255)
);

INSERT INTO test(id, data)
SELECT i, concat('data-', i)
FROM generate_series(0,100000) AS i;

-------------------------------------

DO $$
   const start = +new Date();

   let sum = 0;
   const plan = plv8.prepare( 'SELECT * FROM test WHERE id = $1', ['bigint'] );
   for (let id = 0; id < 10000; id++) {
     const rows = plan.execute( [id] );
     sum += rows[0].id
   }
   plan.free();

   const end = +new Date();
   plv8.elog(WARNING, `ms: ${end - start} sum: ${sum}`);
$$ LANGUAGE plv8;

-- 115 ms


DO $$
   const start = +new Date();

   let sum = 0;
   const plan = plv8.prepare( 'SELECT * FROM test WHERE id = ANY($1)', ['bigint[]'] );
   let ids = []
   for (let id = 0; id < 10000; id++) {
     ids.push(id);
   }
   const rows = plan.execute( [ids] );
   plan.free();

   for (let i = 0; i < rows.length; i++) {
     sum += rows[i].id;
   }

   const end = +new Date();
   plv8.elog(WARNING, `ms: ${end - start} sum: ${sum}`);
$$ LANGUAGE plv8;

-- 20 ms


DO $$
   const start = +new Date();

   const plan = plv8.prepare( 'SELECT sum(id) AS sum FROM test WHERE id = ANY($1)', ['bigint[]'] );
   let ids = []
   for (let id = 0; id < 10000; id++) {
     ids.push(id);
   }
   const rows = plan.execute( [ids] );
   plan.free();

   const end = +new Date();
   plv8.elog(WARNING, `ms: ${end - start} sum: ${rows[0].sum}`);
$$ LANGUAGE plv8;

-- 13 ms


DO $$
   const start = +new Date();

   const plan = plv8.prepare( 'SELECT sum(id) AS sum FROM test WHERE id < 10000', [] );
   const rows = plan.execute( [] );
   plan.free();

   const end = +new Date();
   plv8.elog(WARNING, `ms: ${end - start} sum: ${rows[0].sum}`);
$$ LANGUAGE plv8;

-- 2 ms
