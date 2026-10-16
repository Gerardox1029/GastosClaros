# AGENT SKILLS & DESIGN SYSTEM FOR GASTOSCLAROS

## Skill 1: Flutter UI/UX Specialist
- Write modular, clean, and declarative Flutter code following modern UI standards.
- Prefer lightweight state management (Provider or Riverpod). Avoid deep widget nesting; extract reusable components into separate files.
- Apply smooth animations (FadeTransition, Hero, Blur effects using BackdropFilter) and maintain a dark purple design palette (`#1E1B2E`, `#2D2845`, `#A855F7`).
- Always handle loading states with dynamic spinners (`CircularProgressIndicator`) and present explicit error boundaries.
- Localize all UI strings, date pickers, and currency formatting to LATAM Spanish (`es_419`) and Peruvian Currency (`S/.`).

## Skill 2: Vision Prompt Engineer (Gemini API)
- When constructing prompts for Gemini Vision in the backend, mandate STRICT JSON output with no markdown syntax.
- Use prompt template: "Extract 'nombre', 'monto' (number), 'descripcion', and 'fecha' (ISO 8601) from this Yape screenshot. Return ONLY a valid JSON object without markdown formatting or code blocks."
- Enforce fallback parsers in Node.js to clean and parse responses safely (`JSON.parse` with regex sanitization).

## Skill 3: Serverless Node.js & MongoDB Specialist
- Optimize Netlify Serverless Functions for minimal cold-start latency.
- Cached database connection pattern: Declare `let cachedDb = null;` outside the function handler scope to reuse MongoDB connections across warm lambdas.
- Enforce parameterized queries / ODM schemes to prevent NoSQL injection.
- Implement basic AES payload encryption (`crypto` module) for sensitive string fields (`nombre`, `descripcion`) before saving to MongoDB Atlas.