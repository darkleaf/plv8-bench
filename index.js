const Client = require('pg-native');
const client = new Client();
client.connectSync("postgres://postgres@pg");


function A() {
  const start = +new Date();

  let sum = 0;
  client.prepareSync("a", "SELECT * FROM test WHERE id = $1::bigint", 1);
  for (let id = 0; id < 10000; id++) {
    const rows = client.executeSync("a", [id]);
    sum += parseInt( rows[0].id );
  }

  const end = +new Date();

  console.log( `ms: ${end - start} sum: ${sum}` );
}

// A();
// 1691 ms


function B() {
  const start = +new Date();

  let sum = 0;
  client.prepareSync("b", "SELECT * FROM test WHERE id = ANY($1::bigint[])", 1);
  let ids = [];
  for (let id = 0; id < 10000; id++) {
    ids.push(id);
  }
  const rows = client.executeSync("b", ['{' + ids.join(',') + '}']);

  for (let i = 0; i < rows.length; i++) {
    sum += parseInt( rows[i].id );
  }

  const end = +new Date();

  console.log( `ms: ${end - start} sum: ${sum}` );
}

// B();
// 36 ms


function D() {
  const start = +new Date();

  client.prepareSync("d", "SELECT sum(id) as sum FROM test WHERE id < 10000", 0);
  const rows = client.executeSync("d", []);

  const end = +new Date();

  console.log( `ms: ${end - start} sum: ${rows[0].sum}` );
}

D();
// 4 ms
