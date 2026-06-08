const path = require("path");

const express = require("express");
const mysql = require("mysql2/promise");

require("dotenv").config();

const app = express();
const port = Number(process.env.PORT || 8000);
const localNotes = [];

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, "public")));

let pool;

function dbConfigured() {
  return Boolean(
    process.env.MYSQL_HOST &&
    process.env.MYSQL_USER &&
    process.env.MYSQL_PASSWORD &&
    process.env.MYSQL_DATABASE,
  );
}

function getPool() {
  if (!dbConfigured()) {
    return null;
  }

  if (!pool) {
    pool = mysql.createPool({
      host: process.env.MYSQL_HOST,
      user: process.env.MYSQL_USER,
      password: process.env.MYSQL_PASSWORD,
      database: process.env.MYSQL_DATABASE,
      port: Number(process.env.MYSQL_PORT || 3306),
      waitForConnections: true,
      connectionLimit: 5,
      queueLimit: 0,
    });
  }

  return pool;
}

async function ensureSchema() {
  const db = getPool();

  if (!db) {
    return;
  }

  await db.query(`
    CREATE TABLE IF NOT EXISTS notes (
      id INT AUTO_INCREMENT PRIMARY KEY,
      content VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

async function loadNotes() {
  const db = getPool();

  if (db) {
    await ensureSchema();
    const [rows] = await db.query(
      "SELECT id, content, created_at FROM notes ORDER BY id DESC LIMIT 20",
    );

    return rows;
  }

  return [...localNotes].reverse();
}

async function addNote(content) {
  const db = getPool();

  if (db) {
    await ensureSchema();
    const [result] = await db.query("INSERT INTO notes (content) VALUES (?)", [
      content,
    ]);

    return {
      id: result.insertId,
      content,
      created_at: new Date(),
    };
  }

  const note = {
    id: localNotes.length + 1,
    content,
    created_at: new Date(),
  };

  localNotes.push(note);
  return note;
}

app.get("/api/meta", async (req, res) => {
  res.json({
    appName: process.env.APP_NAME || "Mentor Web Demo",
    s3Bucket: process.env.S3_BUCKET_NAME || "not configured",
    dbReady: Boolean(getPool()),
    fallbackMode: !dbConfigured(),
  });
});

app.get("/api/notes", async (req, res, next) => {
  try {
    const notes = await loadNotes();
    res.json({ notes });
  } catch (error) {
    next(error);
  }
});

app.post("/api/notes", async (req, res, next) => {
  try {
    const content = String(req.body.content || "").trim();

    if (!content) {
      return res.status(400).json({ message: "Content is required" });
    }

    const note = await addNote(content);
    res.status(201).json({ note });
  } catch (error) {
    next(error);
  }
});

app.get("/api/health", async (req, res) => {
  res.json({ status: "ok" });
});

app.use((error, req, res, next) => {
  console.error(error);
  res.status(500).json({ message: "Internal server error" });
});

app.listen(port, async () => {
  try {
    await ensureSchema();
  } catch (error) {
    console.error("Failed to prepare database schema:", error.message);
  }

  console.log(`Mentor Web Demo running on http://127.0.0.1:${port}`);
});
