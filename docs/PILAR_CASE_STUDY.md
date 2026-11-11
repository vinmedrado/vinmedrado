# Pilar — Private language-learning PWA | Technical overview

*Public overview of a private project · English / Español*

## The problem

Language learning requires consistent practice, independent progress for each language and a reliable way to revisit forgotten content. Learning tools also need to work on mobile devices and remain useful when the connection is interrupted.

## The solution

**Pilar** is a progressive Spanish/English study application with structured A1 guided lessons, spaced repetition, checkpoints, practice activities and skill-focused evaluations. Spanish and English track progress separately.

### Architecture at a glance

```text
SvelteKit / TypeScript PWA
        |
        +-- IndexedDB: on-device profiles, lessons and review progress
        +-- Service worker: cached application assets and offline navigation
        +-- Optional Supabase Auth / PostgreSQL: account and sync workflows
        +-- Edge Functions: authenticated AI-assisted practice and feedback
```

The curriculum contains **10 A1 modules and 37 guided lessons per language**. Evaluation and review logic are organized into testable domain modules. The public description intentionally does not include database identifiers, private endpoints, secrets or student information.

## Technical decisions and evidence

- **Offline-first UX:** the app can create a local profile and use cached assets without cloud configuration.
- **Separate learning paths:** the two languages have independent progress, while spaced-repetition review rules prevent skipping essential practice.
- **Cloud boundary:** the browser uses public client credentials; AI credentials remain on the server. Code-level Supabase policies define ownership-based access.
- **Automated quality:** the private CI passed **62 Vitest cases**, additional domain/content/learning suites, Svelte/TypeScript validation and a production build.
- **Browser checks:** local-profile creation, responsive mobile menu and offline reload were exercised in Chrome at desktop and mobile viewport sizes.

## Limitations and scope

This is a learning support tool, **not an official language certificate**. AI feedback is supplemental. The code-level security review did not independently confirm the deployed Supabase project or its live RLS policies. The repository and students' progress remain private.

**Repository access:** private; architecture and relevant technical decisions can be discussed during an interview.

---

## Resumen en español

**Pilar** es una aplicación PWA de aprendizaje progresivo de español e inglés con itinerarios independientes, clases guiadas A1, repaso espaciado, evaluaciones y funcionamiento sin conexión.

Está desarrollada con **SvelteKit, TypeScript e IndexedDB**, con sincronización opcional mediante **Supabase/PostgreSQL** e integración de IA a través de funciones de servidor.

Las pruebas automatizadas cubren la lógica de aprendizaje, las evaluaciones, la compilación y la navegación offline en ordenador y móvil. El código y los datos de estudiantes **no son públicos**.

**Alcance:** es una herramienta educativa, no una certificación oficial. Las políticas de seguridad del entorno Supabase de producción requieren validación independiente.

[Return to GitHub profile](../README.md) · [Professional portfolio (ES)](https://vinmedrado.com/index-es.html)
