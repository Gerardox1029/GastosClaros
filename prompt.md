# SYSTEM ROLE & BEHAVIOR
Act as an Expert Full-Stack Mobile Developer, specializing in Flutter (Frontend), Node.js/Serverless (Backend), MongoDB, and AI integration (Gemini API). Your primary objective is to build a micro-app called "GastosClaros".
Follow SOLID principles, write highly modular clean code, and use the Provider or Riverpod pattern for state management in Flutter. 
All UI text, dates, and times must be localized to LATAM Spanish (`es-419`) and Peruvian Time (UTC-5). 
Whenever processing, fetching, loading, or transitioning, implement a smooth dynamic loading spinner.

# PROJECT OVERVIEW
**App Name:** GastosClaros
**Purpose:** A simple, informative micro-app to manage expenses against a variable balance. Specifically tailored for "Ditox" to track daily expenses (food, gas) and provide evidence to "Financiera Gama".
**Architecture:** 
- **Frontend:** Flutter (Mobile App).
- **Backend:** Node.js API REST deployed on Netlify Functions (Serverless).
- **Database:** MongoDB Atlas (create specific collections for this app within the existing DB).
- **AI:** Google Gemini API (Vision) for extracting data from screenshots.

---

# PHASE 1: AGENT ENGINEERING (CONTEXT FILES)
Before writing application code, create the following markdown files in the project root to establish the environment context:

1. **`agents.md`**: Summarize the project architecture, frontend-backend connection flow, REST API endpoints, and database schemas (Collections: `gastosclaros_ingresos` and `gastosclaros_gastos`).
2. **`memory.md`**: Initialize a file to track common errors, frequently modified sections, and debugging logs during development.
3. **`design_system.md`**: Document the visual identity. 
   - **Vibe:** Simple, intuitive, modern.
   - **Colors:** Dark purple palette (Deep purple backgrounds, vibrant purple accents).
   - **Shapes:** Soft, rounded borders.
   - **Effects:** Background blur (Glassmorphism) for modals and pop-ups.
   - **Animations:** Smooth open/close transitions, staggered list animations.

---

# PHASE 2: FRONTEND REQUIREMENTS (FLUTTER)

## 1. Initial Screen (Splash/Lock Screen)
- Display the title: **GastosClaros**.
- Subtitle (italic, elegant font): *"Una micro-app simple que gestiona los gastos a partir de un saldo variable; enfocado en los gastos de Ditox en su día a día (comida, gasolina), mantener un control de estos para evidenciar a la financiera Gama."*
- Smooth fade-out transition to the main dashboard.

## 2. Navigation
- A Bottom Navigation Bar with 3 sections.
- The center item must be a prominent, elevated "+" button.
- Tapping the "+" button opens a fast bottom sheet or modal with 2 clear options: "Gasto" (Expense) and "Saldo" (Balance/Income). Selecting one redirects the user to the respective section and automatically opens the "Add" pop-up.

## 3. "Saldo" (Balance/Income) Section
- **Top Panel:** Displays "SALDO ACTUAL" (Total Income - Total Expenses) as a single large, prominent number.
- **Time Filter:** A subtle dropdown filter for calculations: 1D (Today), 7D, 14D, 1M.
- **History List:** An expandable list showing the last 3 incomes. Format: Green text for the amount (e.g., `+S/. 12.50`) and the description. Truncate descriptions longer than 10 characters with "...".
- **Action Button:** A full-width rectangular button with dashed borders, a "+" icon, and the text "Agregar Saldo" located below the history.

## 4. Pop-up Modal: "Agregar Saldo" & "Agregar Gasto"
- **UI:** Blurred background behind the modal. An "X" at the top right to close. A floating title ("Agregar Saldo" or "Agregar Gasto").
- **Smart Upload Area:** A prominent rectangular area at the top with an upload icon and text: "Subir captura YAPE". Allows multiple image selection.
- **Manual Form:** Below the upload area, include: Monto (Required, numeric), Nombre (Optional), Descripción (Required), Fecha y Hora (Required, default to `DateTime.now()`). Use the `omni_datetime_picker` package for date/time selection.

## 5. AI Extraction Feature (Subir Captura YAPE)
- When images are selected, show UI text: *"Extrayendo datos con IA..."*
- Display a progress queue for each image with an individual 0-100% progress bar.
- **Backend Flow:** Send images to Netlify Backend -> Backend queries Gemini API -> Backend parses JSON -> Backend saves to MongoDB -> Backend returns parsed data to Frontend.
- **Result UI:** Once extraction completes, populate the form automatically. Display the processed captures as horizontally scrollable cards (Modules titled "Captura 1", "Captura 2", etc.) containing the extracted details: Name, Amount, Description, Date/Time.

---

# PHASE 3: BACKEND & DATABASE (NETLIFY + MONGODB)

## 1. Database Schema
Create two distinct collections inside the existing MongoDB database:
- `gastosclaros_ingresos`
- `gastosclaros_gastos`
Fields required: `monto` (Number), `nombre` (String), `descripcion` (String), `fecha` (Date/Timestamp), `tipo_registro` (String: manual or ai_yape).

## 2. REST API (Netlify Functions)
Build independent serverless endpoints:
- `GET /api/balance` (Calculate total balance based on time filters)
- `GET /api/history/:type` (Fetch recent incomes or expenses)
- `POST /api/upload-yape` (Receives base64/multipart images, prompts Gemini to extract Name, Amount, Description, Date. Saves to DB and returns JSON).
- `POST /api/manual-entry` (Save manual form data).

## 3. Security & Best Practices
- **Environment Variables:** Store `MONGO_URI` and `GEMINI_API_KEY` in `.env`. Exclude `.env` via `.gitignore`.
- **Encryption:** Implement basic symmetric encryption (e.g., using `crypto` in Node.js) to encrypt the `descripcion` and `nombre` fields before saving to MongoDB, decrypting them on `GET` requests.
- **Anti-Injection:** Use Mongoose ODMs or parameterized queries to prevent NoSQL injection. Validate all incoming payload types and clean string inputs.

---

# INSTRUCTIONS FOR INITIALIZATION
1. Create the Agent Engineering `.md` files.
2. Provide the `package.json` for the Netlify Backend and `pubspec.yaml` for Flutter.
3. Write the initial Serverless functions and MongoDB connection utility.
4. Wait for my confirmation before building the Flutter UI.