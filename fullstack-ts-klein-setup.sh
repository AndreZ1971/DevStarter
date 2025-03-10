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
    echo "node_modules/" > .gitignore
    echo "dist/" >> .gitignore
    echo ".env" >> .gitignore
    echo "✅ .gitignore erstellt."

    # Ersten Commit machen
    git add .
    git commit -m "🚀 Initial commit: Fullstack Setup"

    # Repo auf GitHub erstellen (setzt voraus, dass `gh` CLI installiert ist)
    gh repo create "$github_repo" --private --source=. --push
    echo "✅ GitHub-Repository '$github_repo' erstellt & erster Commit gepusht!"
fi

# 4. Frontend-Ordner mit Vite & React + TypeScript einrichten
mkdir frontend && cd frontend
npm create vite@latest . -- --template react-ts
npm install

# Tailwind CSS (neueste Version) installieren & konfigurieren
npm install -D tailwindcss@latest postcss autoprefixer
npx tailwindcss init -p

# Tailwind Config anpassen
echo 'module.exports = { content: ["./src/**/*.{js,jsx,ts,tsx}"], theme: { extend: {} }, plugins: [], }' > tailwind.config.js

# ESLint & Prettier für Frontend installieren
npm install --save-dev eslint prettier eslint-config-prettier eslint-plugin-react eslint-plugin-jsx-a11y eslint-plugin-react-hooks @typescript-eslint/eslint-plugin @typescript-eslint/parser

# ESLint & Prettier Konfiguration erstellen
echo '{
  "extends": ["eslint:recommended", "plugin:react/recommended", "prettier", "plugin:@typescript-eslint/recommended"],
  "env": {
    "browser": true,
    "es2021": true
  }
}' > .eslintrc.json

echo '{
  "printWidth": 80,
  "singleQuote": true,
  "trailingComma": "es5"
}' > .prettierrc.json

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
echo '{
  "extends": ["eslint:recommended", "plugin:node/recommended", "plugin:security/recommended", "prettier"],
  "env": {
    "node": true,
    "es2021": true
  }
}' > .eslintrc.json

echo '{
  "printWidth": 80,
  "singleQuote": true,
  "trailingComma": "es5"
}' > .prettierrc.json

# Backend-Hauptdatei erstellen
cat <<EOL > backend/server.ts
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

# 6. Erstelle ein einfaches `start.sh`
cat <<EOL > start.sh
#!/bin/bash
echo "🚀 Starte Frontend & Backend in VS Code-Terminals..."

# Öffne VS Code
code .

# Starte Frontend
code --command workbench.action.terminal.new
sleep 1
code --command workbench.action.terminal.sendSequence --args "{\"text\":\"cd frontend && npm run dev\\n\"}"

# Starte Backend
code --command workbench.action.terminal.new
sleep 1
code --command workbench.action.terminal.sendSequence --args "{\"text\":\"cd backend && npm run dev\\n\"}"

# Öffne Browser automatisch
if [[ "\$OSTYPE" == "msys" || "\$OSTYPE" == "cygwin" ]]; then
    start "" "http://localhost:5173"
else
    xdg-open http://localhost:5173 2>/dev/null || open http://localhost:5173"
fi

echo "✅ Frontend & Backend in VS Code gestartet!"
EOL

# 7. Mache `start.sh` ausführbar
chmod +x start.sh
echo "✅ Start-Skript 'start.sh' wurde erstellt und ausführbar gemacht."

echo "🎉 Minimalistisches Fullstack-Projekt erfolgreich eingerichtet! Starte es mit './start.sh'"
