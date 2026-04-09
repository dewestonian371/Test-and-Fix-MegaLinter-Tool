# 📘 Documentation : `Test-and-Fix-MegaLinter-Tool`

> **Soumettez n'importe quel fichier hybride Markdown/XML → Recevez automatiquement un rapport de reformatage + lintage fonctionnel. Zéro configuration. Zero expertise requise.**

---

## 🎯 Mission Centrale

Ce projet a un objectif unique : **démocratiser la qualité de code pour les fichiers hybrides** (Markdown contenant du XML, ou inversement).

Traditionnellement, nettoyer un fichier qui mélange balises `#`, `**`, `<data>`, `</item>` nécessite :
- Installer plusieurs outils en ligne de commande
- Écrire des scripts de séparation manuelle
- Comprendre les différences entre linters et formatters
- Configurer des pipelines CI/CD

**Ici, tout est automatisé.** Vous poussez un fichier `.md` (ou `.xml`) contenant les deux syntaxes. MegaLinter détecte les langages, applique les règles de formatage, valide la syntaxe, et génère un **rapport HTML unique, cliquable et actionnable**. Idéal pour rédacteurs techniques, développeurs, data engineers ou curieux.

---

## 🚀 Parcours Utilisateur "Zéro Friction" (Moins de 3 minutes)

### Étape 1 : Préparez votre fichier hybride
Créez ou modifiez `test.md`. Mélangez librement Markdown et XML :

## Documentation Technique

Introduction au format hybride.

### Payload XML
```xml
<root version="1.0">
  <config>
    <key>value</key>
    <!-- balise manquante : </config> -->
  </config>
</root>
```

### Étape 2 : Soumettez-le à GitHub
- **Via navigateur** : Glissez-déposez `test.md` dans le dépôt → `Commit changes`
- **Via CLI** : `git add test.md && git commit -m "Ajout fichier hybride" && git push`
- **Aucune config à ajouter**. Le workflow est déjà actif.

### Étape 3 : Récupérez votre rapport
1. Allez dans l'onglet **Actions** du dépôt
2. Cliquez sur le workflow `MegaLinter` (statut ✅ ou ❌)
3. Téléchargez l'artifact **`MegaLinter-reports`**
4. Ouvrez `HTML/MegaLinter-report.html`

**Ce que vous verrez dans le rapport :**
| Section | Contenu | Action recommandée |
|---------|---------|-------------------|
| 🎨 **Formatting** | Indentation XML alignée, sauts de ligne MD normalisés, tableaux propres | Appliquez les suggestions ou activez `APPLY_FIXES: all` |
| 🕵️‍♂️ **Linting** | Balises XML non fermées, hiérarchie MD cassée, attributs invalides | Corrigez les `ERROR` (bloquants), vérifiez les `WARNING` (conseils) |
| 📊 **Synthèse** | Score qualité, temps d'analyse, outils exécutés | Partagez le lien HTML à votre équipe ou archivez-le |

---

## 🔍 Linter vs Formatter : Différences Subtiles (Contexte Hybride)

Bien que souvent confondus, ces deux outils jouent des rôles complémentaires et non interchangeables, surtout sur des fichiers hybrides.

| Critère | 🎨 Formatter | 🕵️‍♂️ Linter |
|---------|--------------|--------------|
| **But** | Rendre le code **lisible, cohérent, esthétique** | Rendre le code **valide, sûr, conforme aux règles** |
| **Action** | Réécrit le fichier (indentation, espaces, sauts de ligne) | Analyse le fichier et **signale** les anomalies (erreurs, warnings) |
| **Déterminisme** | 100% prévisible : même entrée → même sortie | Contextuel : dépend des règles activées, des ignores inline, de la sémantique |
| **Impact sur l'hybride MD/XML** | Aligne `<item>` sur 2 espaces, normalise `# Titre`, supprime les lignes vides en double | Détecte `</sub>` manquant, `##` sans `#` parent, attributs XML non échappés, liens MD morts |
| **Exemple concret** | Transforme `<data><item>v</item></data>` → `<data>\n  <item>v</item>\n</data>` | Signale `ERROR: XML well-formedness error: expected </data> at line 5` |

> 💡 **Règle d'or pour l'hybride** : *Le formatter ne corrige jamais la sémantique. Il ne ferme pas une balise XML manquante. Il ne valide pas une hiérarchie Markdown. C'est le rôle du linter. Les deux doivent tourner ensemble pour un résultat professionnel.*

---

## ⚙️ Comment MegaLinter gère-t-il l'hybridation MD/XML ?

MegaLinter n'est ni un linter ni un formatter : c'est un **orchestrateur intelligent** qui exécute les bons outils au bon moment, sans que vous ayez à les installer.

### 🔍 Détection & Exécution
1. **Analyse par extension** : Un fichier `.md` déclenche les linters/formatters Markdown. Un fichier `.xml` déclenche ceux dédiés au XML.
2. **Blocs de code intelligents** : Si du XML est encapsulé dans ````xml ... ```` au sein d'un `.md`, MegaLinter extrait le bloc, le valide avec `xmllint`/`tidy`, puis réinjecte le résultat dans le rapport.
3. **Flavor `documentation`** : C'est la configuration active ici. Elle inclut nativement :
   - `markdownlint` (linting MD)
   - `markdown-table-formatter` (formatage tableaux)
   - `xmllint` + `tidy` (validation & formatage XML)
   - `yamllint`, `textlint`, `vale` (compléments texte)
4. **Rapport unifié** : Tous les résultats sont fusionnés dans un seul HTML, avec des liens directs vers les lignes concernées.

### ✅ Pour un résultat optimal
- Placez le XML dans des **blocs de code délimités** (````xml ... ````)
- Évitez d'imbriquer du Markdown *à l'intérieur* de balises XML (non standard)
- Laissez `APPLY_FIXES: none` par défaut pour **auditer avant d'appliquer**
- Si vous voulez que MegaLinter corrige automatiquement : passez `APPLY_FIXES: all` dans le YAML

---

## 🧩 Cadre Méthodologique : Hybridation Syntaxique Structurée

> **Principe fondateur** : Un fichier hybride n'est pas un mélange chaotique, mais une **composition délimitée** où chaque langage conserve son contrat syntaxique, sa sémantique propre et ses règles de validation, tout en coexistant dans un même conteneur texte.

### 📐 Les 4 Piliers de l'Hybridation MD/XML

| Pilier | Description | Implémentation dans le projet |
|--------|-------------|-------------------------------|
| **1. Délimitation explicite** | Le XML ne flotte pas librement dans le flux Markdown. Il est isolé dans des *fenced code blocks* (````xml ... ````). | MegaLinter détecte automatiquement les blocs délimités et les extrait pour traitement contextuel. |
| **2. Non-interférence syntaxique** | Les règles du Markdown ne s'appliquent pas au contenu XML, et inversement. Aucun conflit de parsing, aucun faux positif croisé. | `markdownlint` ignore les blocs XML. `xmllint`/`tidy` analysent uniquement l'extrait brut. MegaLinter agrège sans fusionner les contextes. |
| **3. Validation croisée unifiée** | Chaque langage est linté/formatté par ses outils natifs, mais les résultats sont ramenés dans un seul rapport lisible, ancré ligne par ligne. | Flavor `documentation` → exécution parallèle → rapport HTML unique avec `sourceLine` et `ruleId` précis. |
| **4. Idempotence & Traçabilité** | Le processus est déterministe, reproductible, et journalisé. Aucune modification silencieuse du contenu hybride. | Script PowerShell/Bash + flag `.t2_state/` + `APPLY_FIXES: none` par défaut + tests Pester. |

### 🔄 Flux de Traitement Standardisé

```
Fichier hybride (.md) 
   ↓
[1] Détection des blocs délimités (regex fenced: ```xml ... ```)
   ↓
[2] Extraction contextuelle → Création de fichiers temporaires en mémoire
   ↓
[3] Exécution parallèle :
    ├─ Markdown : markdownlint, table-formatter, vale
    └─ XML : xmllint (well-formedness), tidy (formatting)
   ↓
[4] Réinjection des diagnostics dans le rapport unifié
   ↓
[5] Génération HTML cliquable + artefact CI téléchargeable
```

### 🛡️ Pourquoi cette approche est structurellement robuste

1. **Zéro collision de parsers** : Les AST ne sont jamais mélangés. Chaque outil reçoit exactement ce qu'il attend.
2. **Préservation de l'intention** : Le formatter ne réécrit pas la sémantique, il aligne la présentation. Le linter ne reformate pas, il valide la conformité.
3. **Adaptabilité métier** : Que ce soit pour de la documentation technique, des payloads d'API, des configs legacy ou des exports de données, le même pipeline s'applique sans modification.
4. **Accessibilité DevOps & Non-DevOps** : Aucun prérequis CLI. Un push suffit. Le rapport HTML parle aussi bien au rédacteur qu'à l'ingénieur qualité.

### 📌 Règles d'Or pour les Contributeurs

- ✅ **Toujours utiliser des blocs délimités** : ````xml` / ````yaml` / ````json`
- ❌ **Jamais imbriquer du Markdown dans du XML** : `<note>**gras**</note>` casse le parser XML.
- 🔍 **Consulter le rapport HTML avant de merger** : Les `ERROR` bloquent, les `WARNING` informent.
- 🛑 **Ne pas activer `APPLY_FIXES: all` sans audit préalable** : Le formatting XML peut modifier l'ordre des attributs ou normaliser les guillemets, ce qui peut impacter des checksums ou des signatures numériques.

---

## 🛠️ Pour les Mainteneurs & DevOps

Cette section s'adresse aux utilisateurs avancés souhaitant étendre, tester ou intégrer l'outil dans une chaîne CI/CD existante.

### 📦 Structure du projet
```
.
├── .github/workflows/
│   ├── mega-linter.yml        # Configuration exécutable
│   └── test-setup.yml         # Validation Pester multi-OS
├── setup-megalinter.ps1       # Script PowerShell idempotent
├── setup-megalinter.sh        # Wrapper Bash (Linux/macOS/WSL)
├── setup-megalinter.Tests.ps1 # Tests unitaires Pester v5
├── Dockerfile                 # Image conteneurisée isolée
└── README.md                  # Vous êtes ici
```

### 🧪 Validation automatique
```powershell
# Installer Pester (une fois)
Install-Module Pester -Force -Scope CurrentUser -MinimumVersion 5.4.0

# Exécuter la batterie de tests
Invoke-Pester ./setup-megalinter.Tests.ps1 -Output Detailed

# Intégration CI : le workflow `test-setup.yml` lance ces tests sur chaque PR
```

### 🐳 Exécution Docker (isolation totale)
```bash
docker build -t ml-setup .
docker run --rm -it \
  -v "$(pwd)/output:/workspace" \
  -e GITHUB_TOKEN="ghp_..." \
  ml-setup -ProjectRoot /workspace -SkipPush
```

### 🔧 Personnalisation avancée
Pour ajouter des linters ou modifier les règles :
1. Créez `.mega-linter.yml` à la racine du dépôt
2. Exemple :
   ```yaml
   EXTENDS: https://raw.githubusercontent.com/oxsecurity/megalinter/main/flavors/documentation/mega-linter.yml
   MARKDOWN_MARKDOWNLINT_FILTER_REGEX_EXCLUDE: "(vendor|dist)/"
   XML_XMLLINT_ARGUMENTS: "--noout --valid"
   APPLY_FIXES: none
   ```
3. Committez → le pipeline prendra automatiquement la surcharge en compte.

---

## 📅 Roadmap & Contributions

| Version | Fonctionnalité | Statut |
|---------|----------------|--------|
| `1.0.0` | Workflow hybride MD/XML, rapport HTML, idempotence, tests Pester | ✅ Stable |
| `1.1.0` | Support `APPLY_FIXES: all` avec PR automatique de correction | 🟡 En cours |
| `1.2.0` | Interface web simplifiée (upload drag & drop → rapport) | 🔵 Planifié |
| `2.0.0` | Plugin VS Code / GitHub Extension pour preview temps réel | 🟠 Recherche |

**Contributions bienvenues** : 
- Signalez des faux positifs sur des structures hybrides atypiques
- Proposez des règles `markdownlint` ou `xmllint` adaptées à votre domaine
- Améliorez les tests Pester ou le wrapper Bash

---

## 📜 Licence & Contact

Distribué sous licence **MIT**. Utilisation libre, modification autorisée, attribution recommandée.  
Aucune garantie implicite. Testez toujours en environnement non critique avant application automatique.

**Mainteneur** : `valorisa`  
**Dernière révision** : `2026-04-09`  
**Compatibilité** : GitHub Actions, PowerShell 7.4+, Bash 4.4+, Docker 20.10+  
**Questions / Support** : Ouvrez une `Issue` ou contactez via les Discussions GitHub.

---
> 🛡️ *Conçu pour que la qualité de code soit accessible à tous, pas seulement aux experts DevOps. Soumettez. Analysez. Améliorez. Répétez.*
