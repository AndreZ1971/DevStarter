#!/bin/bash

echo "🚀 Willkommen zur automatisierten TypeScript Fullstack-Einrichtung!"

# 1. Projektname abfragen
read -p "Wie soll dein Projekt heißen? " project_name

# 2. Ordner erstellen
mkdir "$project_name" && cd "$project_name"

# 3. Git initialisieren (optional)
read -p "Soll ein Git-Repository initialisiert werden? (y/n): " init_git
if [ "$init_git" == "y" ]; then
    git init
    git commit --allow-empty -m "Initial commit"
    echo "✅ Git-Repository initialisiert."
fi

# 4. Stelle sicher, dass nvm installiert ist
if command -v nvm &> /dev/null; then
    # Prüfe verfügbare LTS-Versionen
    echo "🔍 Prüfe verfügbare LTS-Versionen..."
    LTS_VERSION=$(nvm ls-remote --lts | tail -1 | awk '{print $1}')

    # Falls keine LTS-Version gefunden wurde, Standardwert setzen (20.x)
    if [ -z "$LTS_VERSION" ]; then
        LTS_VERSION="20"
    fi

    echo "📥 Installiere stabile Node.js LTS-Version: $LTS_VERSION"
    nvm install $LTS_VERSION
    nvm use $LTS_VERSION
    echo "✅ Node.js Version gesetzt: $(node -v)"
else
    echo "⚠️ NVM nicht gefunden. Falls du eine alte Node.js-Version hast, solltest du manuell auf LTS downgraden."
fi

# 5. Frontend-Ordner erstellen und initialisieren
mkdir frontend && cd frontend
npm create vite@latest . -- --template react-ts
npm install
npm rebuild  # 🔥 Behebt "could not determine executable to run"

npm install react-router-dom zustand tailwindcss postcss autoprefixer eslint prettier eslint-config-prettier eslint-plugin-react-hooks eslint-plugin-jsx-a11y @typescript-eslint/eslint-plugin @typescript-eslint/parser
npx tailwindcss init -p

# Tailwind config anpassen
echo 'module.exports = { content: ["./src/**/*.{js,jsx,ts,tsx}"], theme: { extend: {} }, plugins: [], }' > tailwind.config.js

# ESLint/Prettier für Frontend einrichten
echo '{
  "extends": ["eslint:recommended", "plugin:react/recommended", "prettier", "plugin:@typescript-eslint/recommended"],
  "env": {
    "browser": true,
    "es2021": true
  }
}' > .eslintrc.json

echo "✅ Frontend mit Vite, React, TypeScript, Tailwind CSS 4.0, Zustand, ESLint & Prettier eingerichtet."
cd ..

# 6. Backend-Ordner erstellen und initialisieren
mkdir backend && cd backend
npm init -y
npm install express cors dotenv jsonwebtoken bcrypt nodemon helmet express-rate-limit eslint prettier eslint-config-prettier eslint-plugin-node eslint-plugin-security

# TypeScript installieren
npm install --save-dev typescript @types/node @types/express ts-node
npx tsc --init

echo "✅ Backend mit Express, TypeScript, Sicherheitsmaßnahmen & ESLint eingerichtet."

# Backend-Hauptdatei erstellen
cat <<EOL > server.ts
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

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

cd ..

# 7. Husky für Git-Hooks hinzufügen
if [ "$init_git" == "y" ]; then
    echo "✅ Stelle sicher, dass sich `.git` im richtigen Verzeichnis befindet."
    npm install husky --save-dev
    npx husky install
    git add .husky

    echo "#!/bin/sh" > .husky/pre-commit
    echo "npm run lint" >> .husky/pre-commit
    chmod +x .husky/pre-commit

    echo "#!/bin/sh" > .husky/pre-push
    echo "npm test" >> .husky/pre-push
    chmod +x .husky/pre-push

    echo "✅ Husky mit Pre-Commit- und Pre-Push-Hooks eingerichtet."
fi

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

# 10. Optional: Update auf die neueste Node.js-Version anbieten
read -p "Möchtest du am Ende auf die neueste Node.js-Version aktualisieren? (y/n): " update_node
if [ "$update_node" == "y" ]; then
    LATEST_VERSION=$(nvm ls-remote | tail -1 | awk '{print $1}')
    echo "📥 Aktualisiere auf die neueste Node.js-Version: $LATEST_VERSION"
    nvm install $LATEST_VERSION
    nvm use $LATEST_VERSION
    echo "✅ Node.js aktualisiert auf: $(node -v)"
else
    echo "ℹ️ Bleibe bei der stabilen LTS-Version: $(node -v)"
fi

# 11. Sicherstellen, dass die neuesten Pakete installiert sind
npm outdated && npm update
echo "✅ Alle Pakete sind auf dem neuesten Stand."

echo "🎉 TypeScript Fullstack-Projekt erfolgreich eingerichtet! Starte es mit './start.sh'"
