#!/bin/bash

echo "🚀 Starte minimales Fullstack-Setup mit Vite, React, Node.js, Tailwind CSS & GitHub-Repo"

# 1. Projektname abfragen
read -p "Wie soll dein Projekt heißen? " project_name

# 2. Ordner erstellen
mkdir "$project_name" && cd "$project_name"

# 3. GitHub-Repository erstellen (optional)
read -p "Möchtest du dieses Projekt als GitHub-Repository anlegen? (y/n): " create_github
if [ "$create_github" == "y" ]; then
    read -p "Bitte gib den GitHub-Repo-Namen ein (z. B. $project_name): " github_repo
    git init
    echo "✅ Lokales Git-Repository initialisiert."

    # Standard .gitignore erstellen
    cat <<EOL > .gitignore
node_modules/
dist/
.env
.vscode/
EOL
    echo "✅ .gitignore erstellt."

    # Ersten Commit machen
    git add .
    git commit -m "🚀 Initial commit: Fullstack Setup"

    # Repo auf GitHub erstellen (setzt `gh` CLI voraus)
    gh repo create "$github_repo" --private --source=. --push
    echo "✅ GitHub-Repository '$github_repo' erstellt & erster Commit gepusht!"
fi

# 4. Frontend-Ordner mit Vite & React + TypeScript einrichten
mkdir frontend && cd frontend
npm create vite@latest . -- --template react-ts
npm install

# Tailwind CSS (nur stabile Version) installieren & konfigurieren
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Tailwind Config anpassen
cat <<EOL > tailwind.config.js
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: { extend: {} },
  plugins: [],
};
EOL

# ESLint & Prettier für Frontend installieren
npm install --save-dev eslint prettier eslint-config-prettier eslint-plugin-react eslint-plugin-jsx-a11y eslint-plugin-react-hooks @typescript-eslint/eslint-plugin @typescript-eslint/parser

# ESLint & Prettier Konfiguration erstellen
cat <<EOL > .eslintrc.json
{
  "extends": ["eslint:recommended", "plugin:react/recommended", "prettier", "plugin:@typescript-eslint/recommended"],
  "env": { "browser": true, "es2021": true }
}
EOL

cat <<EOL > .prettierrc.json
{
  "printWidth": 80,
  "singleQuote": true,
  "trailingComma": "es5"
}
EOL

echo "✅ Frontend eingerichtet."
cd ..

# 5. Backend-Ordner mit Express + TypeScript einrichten
mkdir backend && cd backend
npm init -y
npm install express cors dotenv
npm install --save-dev typescript @types/node @types/express ts-node nodemon eslint prettier eslint-config-prettier eslint-plugin-node eslint-plugin-security

# TypeScript konfigurieren
npx tsc --init

# ESLint & Prettier für Backend konfigurieren
cat <<EOL > .eslintrc.json
{
  "extends": ["eslint:recommended", "plugin:node/recommended", "plugin:security/recommended", "prettier"],
  "env": { "node": true, "es2021": true }
}
EOL

cat <<EOL > .prettierrc.json
{
  "printWidth": 80,
  "singleQuote": true,
  "trailingComma": "es5"
}
EOL

# Backend-Hauptdatei erstellen
mkdir -p backend
cat <<EOL > server.ts
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Backend läuft!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(\`Server läuft auf Port \${PORT}\`));
EOL

echo "✅ Backend eingerichtet."
cd ..

# 6. Fragt am Ende, ob npm-Abhängigkeiten aktualisiert werden sollen
read -p "Möchtest du jetzt alle Abhängigkeiten auf die neueste stabile Version aktualisieren? (y/n): " update_deps
if [ "$update_deps" == "y" ]; then
    echo "📦 Aktualisiere npm-Abhängigkeiten..."
    (cd frontend && npm update)
    (cd backend && npm update)
    echo "✅ Alle Pakete wurden aktualisiert!"
else
    echo "ℹ️ Abhängigkeiten wurden nicht aktualisiert."
fi

echo "🎉 Minimalistisches Fullstack-Projekt erfolgreich eingerichtet! 🚀"
