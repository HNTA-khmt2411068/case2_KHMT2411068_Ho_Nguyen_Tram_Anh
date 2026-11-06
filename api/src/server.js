const app = require('./app');
const cors = require('cors');
require('dotenv').config();
const connectDB = require('./config/database');

app.use(cors());

app.use((req, res, next) => {
  console.log(`📩 [${req.method}] ${req.originalUrl}`);
  next();
});

connectDB();

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));