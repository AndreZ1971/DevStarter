#!/bin/bash
set -euo pipefail  # Stoppt bei Fehlern oder undefinierten Variablen

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funktion zur Überprüfung von Abhängigkeiten
check_dependency() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo -e "${RED}❌ '$1' ist nicht installiert. Bitte installiere es zuerst.${NC}"
    exit 1
  fi
}

# Willkommensnachricht
echo -e "${GREEN}🚀 Minimalistisches Fullstack-Setup mit JavaScript, Vite, React & Express${NC}"

# --- 1. Projektname abfragen ---
read -p "Wie soll dein Projekt heißen? [mein-projekt]: " project_name
project_name=${project_name:-mein-projekt}

# Validierung des Projektnamens
if [[ ! "$project_name" =~ ^[a-z0-9-]+$ ]]; then
  echo -e "${RED}❌ Ungültiger Name. Nur Kleinbuchstaben, Zahlen und Bindestriche erlaubt.${NC}"
  exit 1
fi

# --- 2. Ordner erstellen ---
mkdir -p "$project_name" || { echo -e "${RED}❌ Konnte Ordner nicht erstellen.${NC}"; exit 1; }
cd "$project_name" || exit 1

# --- 3. GitHub-Repository erstellen (optional) ---
setup_github() {
  read -p "Möchtest du dieses Projekt als GitHub-Repository anlegen? (y/n) [n]: " create_github
  create_github=${create_github:-n}

  if [[ "$create_github" == "y" ]]; then
    check_dependency "gh"  # Prüfe GitHub CLI

    read -p "GitHub-Repo-Name [${project_name}]: " github_repo
    github_repo=${github_repo:-$project_name}

    git init
    echo -e "${GREEN}✅ Lokales Git-Repository initialisiert.${NC}"

    # .gitignore erstellen
    cat <<EOL > .gitignore
node_modules/
dist/
.env
.vscode/
*.log
EOL
    echo -e "${GREEN}✅ .gitignore erstellt.${NC}"

    # Ersten Commit machen
    git add .
    git commit -m "🚀 Initial commit: JavaScript Fullstack Setup"

    # Repo auf GitHub erstellen
    gh repo create "$github_repo" --private --source=. --push
    echo -e "${GREEN}✅ GitHub-Repository '$github_repo' erstellt & Code gepusht!${NC}"
  fi
}
setup_github

# --- 4. Frontend mit Vite + React einrichten ---
setup_frontend() {
  echo -e "${GREEN}🛠️ Richte Frontend mit Vite + React ein...${NC}"
  mkdir -p frontend && cd frontend

  # Vite-Projekt erstellen
  npm create vite@latest . -- --template react
  npm install

  # Tailwind CSS installieren
  echo -e "${YELLOW}📦 Installiere Tailwind CSS...${NC}"
  npm install -D tailwindcss@latest postcss autoprefixer
  npx tailwindcss init -p

  # Tailwind konfigurieren
  cat <<EOL > tailwind.config.js
module.exports = {
  content: ["./src/**/*.{js,jsx}"],
  theme: { extend: {} },
  plugins: [],
}
EOL

  # ESLint & Prettier installieren
  echo -e "${YELLOW}📦 Installiere ESLint & Prettier...${NC}"
  npm install -D eslint prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks

  # ESLint-Konfiguration
  cat <<EOL > .eslintrc.json
{
  "extends": ["eslint:recommended", "plugin:react/recommended", "prettier"],
  "env": { "browser": true, "es2021": true }
}
EOL

  # Prettier-Konfiguration
  cat <<EOL > .prettierrc.json
{
  "printWidth": 80,
  "singleQuote": true,
  "trailingComma": "es5"
}
EOL

  echo -e "${GREEN}✅ Frontend eingerichtet!${NC}"
  cd ..
}
setup_frontend

# --- 5. Backend mit Express einrichten ---
setup_backend() {
  echo -e "${GREEN}🛠️ Richte Backend mit Express ein...${NC}"
  mkdir -p backend && cd backend

  # package.json erstellen
  npm init -y

  # Abhängigkeiten installieren
  echo -e "${YELLOW}📦 Installiere Backend-Abhängigkeiten...${NC}"
  npm install express cors dotenv
  npm install -D nodemon

  # ESLint & Prettier installieren
  npm install -D eslint prettier eslint-config-prettier eslint-plugin-node

  # ESLint-Konfiguration
  cat <<EOL > .eslintrc.json
{
  "extends": ["eslint:recommended", "plugin:node/recommended", "prettier"],
  "env": { "node": true, "es2021": true }
}
EOL

  # Prettier-Konfiguration
  cat <<EOL > .prettierrc.json
{
  "printWidth": 80,
  "singleQuote": true,
  "trailingComma": "es5"
}
EOL

  # server.js erstellen
  cat <<EOL > server.js
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

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

  # Skripte in package.json hinzufügen
  npm pkg set scripts.start="node server.js"
  npm pkg set scripts.dev="nodemon server.js"

  echo -e "${GREEN}✅ Backend eingerichtet!${NC}"
  cd ..
}
setup_backend

# --- 6. Abhängigkeiten aktualisieren (optional) ---
read -p "Möchtest du alle Abhängigkeiten aktualisieren? (y/n) [n]: " update_deps
update_deps=${update_deps:-n}

if [[ "$update_deps" == "y" ]]; then
  echo -e "${YELLOW}📦 Aktualisiere Abhängigkeiten...${NC}"
  (cd frontend && npm update)
  (cd backend && npm update)
  echo -e "${GREEN}✅ Alle Pakete aktualisiert!${NC}"
fi

# --- Fertig! ---
echo -e "${GREEN}🎉 JavaScript-Fullstack-Projekt erfolgreich eingerichtet!${NC}"
echo -e "Nächste Schritte:"
echo -e "1. ${YELLOW}cd $project_name${NC}"
echo -e "2. ${YELLOW}cd frontend && npm run dev${NC} (Frontend starten)"
echo -e "3. ${YELLOW}cd backend && npm run dev${NC} (Backend starten)"