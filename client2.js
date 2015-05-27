var jackrabbit = require('jackrabbit');
var broker = jackrabbit('amqp://localhost');


function ask(res, callback) { 
  var stdin = process.stdin;
  var stdout = process.stdout;
  stdout.write(res);
 
  stdin.on('data', function (data) {
    data = data.toString().trim().toUpperCase();
    callback(data); 
  });
};

broker.on('connected', function () {
  broker.create('client.one', function () {
    broker.handle('client.one', function (job, ack) {
      ask(job.message, function (response) {
        ack(response);
      });
    });
  });
});
