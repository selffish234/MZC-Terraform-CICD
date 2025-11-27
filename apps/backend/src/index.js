const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

let stats = { visits: 0, requests: 0 };

app.use((req, res, next) => {
  if (req.path !== '/') stats.requests++;
  next();
});

app.get('/', (req, res) => res.status(200).send('Joon Backend Health Check OK'));

app.get('/api/status', (req, res) => {
  res.json({ 
    service: "Joon ECS Backend", 
    region: "eu-west-1", 
    status: "Active",
    env: process.env.NODE_ENV || "development"
  });
});

app.post('/api/counter/increment', (req, res) => {
  stats.visits++;
  res.status(200).json({ message: "Counter incremented", visits: stats.visits });
});

app.get('/api/counter', (req, res) => {
  res.status(200).json(stats);
});

if (require.main === module) {
  app.listen(port, () => console.log(`Server running on port ${port}`));
}

module.exports = app;
