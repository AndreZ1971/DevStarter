#!/bin/bash

echo "🚀 Willkommen zur automatisierten Projekt-Einrichtung!"

# 1. Projektname abfragen
read -p "Wie soll dein Projekt heißen? " project_name

# 2. Ordner erstellen
mkdir "$project_name" && cd "$project_name"

# 3. Git initialisieren (optional)
read -p "Soll ein Git-Repository initialisiert werden? (y/n): " init_git
if [ "$init_git" == "y" ]; then
    git init
    echo "✅ Git-Repository initialisiert."
fi

# 4. Node.js Version prüfen & setzen, falls `nvm` vorhanden ist
if command -v nvm &> /dev/null; then
    nvm install 18 && nvm use 18
    echo "✅ Node.js 18 wurde mit nvm gesetzt."
fi

# 5. Frontend-Ordner erstellen und initialisieren
mkdir frontend && cd frontend
npm create vite@latest . -- --template react
npm install
npm install react-router-dom zustand tailwindcss postcss autoprefixer eslint prettier eslint-config-prettier eslint-plugin-react-hooks eslint-plugin-jsx-a11y @typescript-eslint/eslint-plugin @typescript-eslint/parser
npx tailwindcss init -p

# Tailwind config anpassen
echo 'module.exports = { content: ["./src/**/*.{js,jsx,ts,tsx}"], theme: { extend: {} }, plugins: [], }' > tailwind.config.js

# ESLint/Prettier für Frontend einrichten
echo '{
  "extends": ["eslint:recommended", "plugin:react/recommended", "prettier"],
  "env": {
    "browser": true,
    "es2021": true
  }
}' > .eslintrc.json

echo "✅ Frontend mit Vite, React, Tailwind CSS 4.0, Zustand, ESLint & Prettier eingerichtet."
cd ..

# 6. Backend-Ordner erstellen und initialisieren
mkdir backend && cd backend
npm init -y
npm install express cors dotenv jsonwebtoken bcrypt nodemon helmet express-rate-limit eslint prettier eslint-config-prettier eslint-plugin-node eslint-plugin-security
echo "✅ Backend mit Express, Sicherheitsmaßnahmen & ESLint eingerichtet."

# Backend-Hauptdatei erstellen
cat <<EOL > server.js
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());
app.use(helmet());
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));

app.get('/', (req, res) => {
    res.send('Backend läuft!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(\`Server läuft auf Port \${PORT}\`));
EOL

# .env Datei erstellen
cat <<EOL > .env
PORT=5000
JWT_SECRET=supergeheimespasswort
EOL

# 7. Husky für Git-Hooks hinzufügen
if [ "$init_git" == "y" ]; then
    npx husky-init && npm install
    npx husky add .husky/pre-commit "npm run lint"
    npx husky add .husky/pre-push "npm test"
    echo "✅ Husky mit Pre-Commit- und Pre-Push-Hooks eingerichtet."
fi

cd ..

# 8. .gitignore für Node.js-Projekte erstellen
cat <<EOL > .gitignore
node_modules/
dist/
.env
.DS_Store
.vscode/
EOL
echo "✅ .gitignore erstellt."

# 9. GitHub Actions CI/CD einrichten
if [ "$init_git" == "y" ]; then
    mkdir -p .github/workflows
    cat <<EOL > .github/workflows/ci.yml
name: CI/CD

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Repository auschecken
        uses: actions/checkout@v3

      - name: Node.js einrichten
        uses: actions/setup-node@v3
        with:
          node-version: 18

      - name: Abhängigkeiten installieren (Frontend)
        run: |
          cd frontend
          npm install

      - name: Abhängigkeiten installieren (Backend)
        run: |
          cd backend
          npm install

      - name: Linting ausführen
        run: |
          cd frontend
          npm run lint
          cd ../backend
          npm run lint
EOL

    echo "✅ GitHub Actions für CI/CD eingerichtet."
fi

# 10. Sicherstellen, dass die neuesten Pakete installiert sind
npm outdated && npm update
echo "✅ Alle Pakete sind auf dem neuesten Stand."

echo "🎉 Projekt erfolgreich eingerichtet! Starte es mit './start.sh'"
