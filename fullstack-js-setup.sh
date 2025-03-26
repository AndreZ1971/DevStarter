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
echo -e "${GREEN}🚀 Willkommen zur automatisierten FullStack-JS-Projekteinrichtung!${NC}"

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

# --- 3. Git initialisieren ---
read -p "Soll ein Git-Repository initialisiert werden? (y/n) [y]: " init_git
init_git=${init_git:-y}

if [[ "$init_git" == "y" ]]; then
  git init
  echo -e "${GREEN}✅ Git-Repository initialisiert.${NC}"
fi

# --- 4. Node.js-Version prüfen & setzen ---
setup_node() {
  if command -v nvm &> /dev/null; then
    echo -e "${YELLOW}⚡ NVM gefunden. Setze Node.js 18...${NC}"
    bash -i -c "nvm install 18 && nvm use 18"
  else
    echo -e "${YELLOW}⚠️ NVM nicht gefunden. Stelle sicher, dass Node.js 18 installiert ist.${NC}"
  fi
}
setup_node

# --- 5. Paketmanager auswählen ---
read -p "Welchen Paketmanager möchtest du verwenden? (npm/yarn/pnpm) [npm]: " pkg_manager
pkg_manager=${pkg_manager:-npm}

case "$pkg_manager" in
  npm|yarn|pnpm) ;;
  *) echo -e "${RED}❌ Ungültiger Paketmanager. Verwende npm.${NC}"; pkg_manager=npm ;;
esac

# --- 6. Frontend einrichten ---
setup_frontend() {
  echo -e "${GREEN}🛠️ Richte Frontend mit Vite + React ein...${NC}"
  mkdir -p frontend && cd frontend

  # Vite-Projekt erstellen
  $pkg_manager create vite@latest . -- --template react

  # Abhängigkeiten installieren
  echo -e "${YELLOW}📦 Installiere Frontend-Abhängigkeiten...${NC}"
  $pkg_manager install react-router-dom zustand tailwindcss postcss autoprefixer \
    eslint prettier eslint-config-prettier eslint-plugin-react-hooks \
    eslint-plugin-jsx-a11y @typescript-eslint/eslint-plugin @typescript-eslint/parser

  # Tailwind CSS konfigurieren
  npx tailwindcss init -p
  cat <<EOL > tailwind.config.js
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: { extend: {} },
  plugins: [],
}
EOL

  # ESLint konfigurieren
  cat <<EOL > .eslintrc.json
{
  "extends": ["eslint:recommended", "plugin:react/recommended", "prettier"],
  "env": {
    "browser": true,
    "es2021": true
  }
}
EOL

  echo -e "${GREEN}✅ Frontend eingerichtet!${NC}"
  cd ..
}
setup_frontend

# --- 7. Backend einrichten ---
setup_backend() {
  echo -e "${GREEN}🛠️ Richte Backend mit Express ein...${NC}"
  mkdir -p backend && cd backend

  # package.json erstellen
  $pkg_manager init -y

  # Abhängigkeiten installieren
  echo -e "${YELLOW}📦 Installiere Backend-Abhängigkeiten...${NC}"
  $pkg_manager install express cors dotenv jsonwebtoken bcrypt nodemon \
    helmet express-rate-limit eslint prettier eslint-config-prettier \
    eslint-plugin-node eslint-plugin-security

  # server.js erstellen
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

  # .env mit zufälligem JWT_SECRET erstellen
  JWT_SECRET=$(openssl rand -hex 32 || echo "fallback-secret")
  cat <<EOL > .env
PORT=5000
JWT_SECRET=$JWT_SECRET
EOL

  echo -e "${GREEN}✅ Backend eingerichtet!${NC}"
  cd ..
}
setup_backend

# --- 8. Husky für Git-Hooks ---
setup_husky() {
  if [[ "$init_git" == "y" && -d ".git" ]]; then
    echo -e "${GREEN}🐶 Richte Husky für Git-Hooks ein...${NC}"
    $pkg_manager install husky --save-dev
    npx husky install
    npx husky add .husky/pre-commit "npm run lint"
    npx husky add .husky/pre-push "npm test"
    echo -e "${GREEN}✅ Husky eingerichtet!${NC}"
  fi
}
setup_husky

# --- 9. .gitignore erstellen ---
echo -e "${GREEN}📋 Erstelle .gitignore...${NC}"
cat <<EOL > .gitignore
node_modules/
dist/
.env
.DS_Store
.vscode/
EOL

# --- 10. CI/CD mit GitHub Actions ---
setup_ci() {
  if [[ "$init_git" == "y" ]]; then
    echo -e "${GREEN}⚙️ Richte GitHub Actions CI/CD ein...${NC}"
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
          $pkg_manager install

      - name: Abhängigkeiten installieren (Backend)
        run: |
          cd backend
          $pkg_manager install

      - name: Linting ausführen
        run: |
          cd frontend
          $pkg_manager run lint
          cd ../backend
          $pkg_manager run lint
EOL
    echo -e "${GREEN}✅ GitHub Actions eingerichtet!${NC}"
  fi
}
setup_ci

# --- Fertig! ---
echo -e "${GREEN}🎉 Projekt erfolgreich eingerichtet!${NC}"
echo -e "Nächste Schritte:"
echo -e "1. ${YELLOW}cd $project_name${NC}"
echo -e "2. ${YELLOW}cd frontend && $pkg_manager run dev${NC} (für das Frontend)"
echo -e "3. ${YELLOW}cd backend && $pkg_manager run start${NC} (für das Backend)"