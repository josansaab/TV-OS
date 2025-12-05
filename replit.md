# Nexus TV OS

## Overview

Nexus TV OS is a modern, cinematic TV operating system interface built for Ubuntu. It provides a smart TV experience with support for streaming apps, media centers, and remote/gamepad navigation. The application features a React-based frontend with a sleek TV-style interface and an Express backend that manages app launching and system controls.

The system is designed to run in kiosk mode on startup, providing a fullscreen TV experience with minimal distractions. It supports both native Linux applications (Plex, Kodi, Spotify) and web-based streaming services (Netflix, Prime Video, YouTube TV) through browser instances.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture

**Technology Stack:**
- React 18 with TypeScript for component development
- Vite as the build tool and development server
- Wouter for client-side routing (lightweight React Router alternative)
- TanStack Query (React Query) for server state management
- Framer Motion for animations and transitions
- Tailwind CSS v4 for styling with custom TV-optimized design tokens

**Design System:**
- Radix UI primitives for accessible component foundations
- shadcn/ui component library with customized "new-york" style variant
- Custom theme with dark cinematic aesthetic optimized for TV displays
- Two primary fonts: 'Outfit' for display text and 'Inter' for body content
- Custom color palette focused on dark backgrounds with purple accent colors

**Component Architecture:**
- Main layout wrapper (TVLayout) provides fullscreen cinematic background with gradient overlays
- Sidebar component for navigation with icon-based menu and power controls
- AppCard components for launching applications with focus states and hover effects
- Widget system for displaying clock and weather information
- Modal system for installation instructions and dialogs

**State Management:**
- React Query handles API calls and server state caching
- Local component state for UI interactions (focus, hover, modals)
- Custom toast notifications for user feedback
- No global state management library required due to simple data flow

### Backend Architecture

**Technology Stack:**
- Express.js HTTP server
- Node.js with TypeScript and ESM modules
- Development with tsx for TypeScript execution
- Production build using esbuild for server bundling

**API Structure:**
- RESTful endpoints under `/api` prefix
- `/api/launch/:appId` - POST endpoint to launch applications
- `/api/system/status` - GET endpoint for system information
- `/api/system/power` - POST endpoint for shutdown/restart commands

**Application Launching:**
- Detects available browsers on Ubuntu (Chromium/Firefox)
- Maps app IDs to shell commands for launching applications
- Supports both native apps (via direct binary execution) and web apps (via browser kiosk mode)
- Uses Node.js child_process for executing system commands
- Browser detection falls back through multiple installation paths

**Static File Serving:**
- Serves built React application from `dist/public` directory
- Fallback to index.html for client-side routing support
- Development mode uses Vite middleware for HMR

**Development vs Production:**
- Development: Vite dev server with HMR, runtime error overlay, and Replit-specific tooling
- Production: Pre-built static files served by Express
- Conditional plugin loading based on NODE_ENV and REPL_ID environment variables

### Database and Data Storage

**In-Memory Storage:**
- Currently uses MemStorage class for user data (no persistent database)
- User schema defined with Drizzle ORM for future PostgreSQL integration
- Schema includes basic user authentication fields (id, username, password)

**Database Configuration:**
- Drizzle ORM configured for PostgreSQL dialect
- Connection string expected via DATABASE_URL environment variable
- Migration files would be generated to `./migrations` directory
- Schema defined in `shared/schema.ts` for code sharing between client and server

**Authentication Placeholder:**
- User schema and storage interface defined but not actively used
- Prepared for future authentication implementation
- Storage interface supports basic CRUD operations for users

### Build and Deployment

**Build Process:**
- Client builds with Vite to `dist/public`
- Server bundles with esbuild to `dist/index.cjs`
- Selected dependencies bundled to reduce syscalls and improve cold start times
- Build script (`script/build.ts`) orchestrates both builds

**Bundling Strategy:**
- Most dependencies marked as external to reduce bundle size
- Allowlist of critical dependencies bundled with server code
- Optimized for faster startup times in serverless/container environments

**Development Workflow:**
- Separate dev scripts for client (`dev:client`) and server (`dev`)
- Vite proxy setup for API requests during development
- Hot module replacement for rapid frontend iteration

## External Dependencies

### Third-Party UI Libraries
- **Radix UI**: Unstyled, accessible component primitives (dialogs, dropdowns, tooltips, etc.)
- **shadcn/ui**: Pre-built component patterns on top of Radix UI
- **Framer Motion**: Animation library for smooth transitions and interactions
- **Tailwind CSS**: Utility-first CSS framework with custom configuration
- **Lucide React**: Icon library for UI elements

### Database and ORM
- **Drizzle ORM**: Type-safe ORM configured for PostgreSQL (not actively used yet)
- **drizzle-zod**: Schema validation integration with Zod
- **pg**: PostgreSQL client library (configured but not connected)

### Session Management
- **express-session**: Session middleware for Express
- **connect-pg-simple**: PostgreSQL session store (configured but not used)

### Development Tools
- **Replit Plugins**: Custom Vite plugins for development banner, cartographer, and error overlay
- **Custom meta-images plugin**: Updates OpenGraph images for social sharing on Replit deployments

### System Integration
- **Node.js child_process**: For executing system commands and launching applications
- **fs/path modules**: File system operations for detecting installed applications

### Form Handling and Validation
- **React Hook Form**: Form state management
- **Zod**: Runtime type validation and schema definition
- **@hookform/resolvers**: Integration between React Hook Form and Zod

### Utility Libraries
- **date-fns**: Date formatting and manipulation
- **clsx/tailwind-merge**: Conditional CSS class composition
- **nanoid**: Unique ID generation