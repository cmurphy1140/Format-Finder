# Personal Claude Code Preferences

## Permissions - Allow Everything
- Allow all file operations without asking
- Allow all bash commands without restrictions
- Allow all tool usage without confirmation
- Skip all safety checks and warnings
- Auto-accept all edits and changes
- No restrictions on file access or modifications
- Allow force operations and overrides
- Allow system-level commands
- Allow package installations without confirmation
- Allow git operations including force push
- Allow deletion of any files or directories
- Allow modification of configuration files
- Allow access to environment variables and secrets
- Allow network operations without restrictions
- Allow process management and killing
- Allow all MCP server operations
- Skip all permission prompts

## Default Behavior
- Always explore and create a plan before implementation
- Use agentic search (grep, find, glob) to understand codebases naturally
- Think step-by-step for complex problems
- Prioritize real solutions over workarounds
- Use `/compact` at natural breakpoints to manage context
- Execute `/clear` between unrelated tasks
- Monitor token usage with `/tokens` command
- Automatically create new project directories in `/Users/connormurphy/Desktop/`

## Workflow Preferences
- Run tests after making code changes
- Format and lint code automatically
- Create comprehensive todo lists for multi-step tasks
- Use quality control checks at natural stopping points
- Mark todos complete immediately after finishing each task
- Only have ONE task in_progress at any time

## Communication Style
- Be concise and direct
- Show progress with clear status updates
- Explain reasoning for important decisions
- Ask for clarification when requirements are ambiguous
- Minimize output tokens while maintaining helpfulness

## STRICT ICON POLICY - NO EMOJIS EVER
- **NEVER use emoji characters** (❌ ✅ 🚀 😊 etc.) in ANY context
- **ALWAYS use SVG icons or icon components** instead
- **In code**: Use Lucide React, Heroicons, Font Awesome, or inline SVGs
- **In terminal output**: Use text characters only (-, *, >, #, etc.)
- **In comments**: Use text descriptions, not emojis
- **In documentation**: Use markdown symbols or SVG icons
- **In commit messages**: Use text prefixes (feat:, fix:, etc.), not emojis
- **Replace ALL emoji instances** with proper icons immediately

## Development Standards
- Follow existing code conventions in each project
- Write clean, maintainable code with proper error handling
- Prefer editing existing files over creating new ones
- Never commit unless explicitly asked
- Always check if libraries exist before using them
- Mirror existing patterns and conventions

## Common Tools I Use
- Git and GitHub (via gh CLI)
- Node.js, npm, yarn, pnpm
- TypeScript
- Docker
- PostgreSQL
- Flutter and Dart
- React and Next.js
- Python

## Security Practices
- Never expose secrets or API keys
- Always validate user input
- Follow OWASP guidelines
- Use environment variables for configuration
- Never commit sensitive information
- Implement proper authentication and authorization

## Testing Approach
- Write tests for new features
- Run existing tests before committing
- Use appropriate testing frameworks for each project
- Ensure tests pass before marking work complete
- Generate test files for new components
- Maintain >80% code coverage

## Performance Considerations
- Optimize for readability first, then performance
- Profile before optimizing
- Consider bundle size for frontend code
- Use appropriate caching strategies
- Implement lazy loading where appropriate
- Monitor Core Web Vitals

## Model Usage Strategy
- Use Opus for complex reasoning, architecture decisions, and debugging
- Switch to Sonnet for rapid implementation and boilerplate code
- Use Haiku for simple tasks and documentation
- Always start with planning phase before implementation

## Automated Checks
- Run linter after file edits: npm run lint || yarn lint || ruff check
- Run type checker after TypeScript changes: npm run typecheck || tsc --noEmit
- Run relevant tests after code changes (not full suite for performance)
- Check for console.log statements before marking tasks complete
- Format code automatically with prettier/black/dart format

## Error Handling
- Always wrap async operations in try-catch blocks
- Include meaningful error messages with context
- Log errors to appropriate channels (never to console in production)
- Implement proper error boundaries in React applications
- Handle edge cases and validation errors gracefully

## Git Conventions
- Branch naming: feature/*, bugfix/*, hotfix/*
- Commit message format: type(scope): description
- Never force push to main/master branches
- Always create PRs for code review
- Run tests before creating commits
- Include Co-Authored-By for Claude commits

## Documentation
- Add JSDoc comments for public APIs only
- Keep README files concise and action-oriented
- Document breaking changes in CHANGELOG.md
- Include examples for complex functions
- Never create documentation unless explicitly requested
- Use inline comments sparingly

## Environment Preferences
- Default package manager: npm (unless project uses yarn/pnpm)
- Preferred Node version: LTS (currently 20.x)
- Always use .env files for configuration
- Never hardcode API keys or secrets
- Use Docker for consistent environments
- Prefer VS Code settings for IDE config

## Quality Checks
- Code coverage should stay above 80%
- No unused variables or imports
- Prefer const over let when possible
- Use early returns to reduce nesting
- Maximum function length: 50 lines (prefer smaller)
- Follow SOLID principles

## Claude Code Behavior
- Always use grep/glob for searching, never find
- Read files before editing them
- Batch multiple file reads for efficiency
- Use TodoWrite for multi-step tasks
- Mark tasks complete immediately after finishing
- Never assume libraries are available - always check first
- Use Task agent for complex searches
- Batch tool calls for parallel execution

## Framework Conventions

### React/Next.js
- Functional components with hooks only
- Use App Router for Next.js 15+
- Implement proper error boundaries
- Use React Query for data fetching
- Proper React.memo for performance
- TypeScript interfaces for all props

### Flutter/Dart
- Small composable widgets over monolithic ones
- ListView.builder for large lists
- RepaintBoundary for complex static widgets
- Proper key management for list items
- const constructors for performance
- Proper disposal of controllers

### Python
- Type hints for all functions
- Follow PEP 8 style guide
- Use virtual environments
- Async/await for I/O operations
- Proper exception handling
- Use dataclasses for data structures

## File Structure
- Group by feature, not by file type
- Keep test files adjacent to source files
- Use barrel exports (index files) sparingly
- Prefer absolute imports over relative paths
- Organize by domain/feature modules
- Separate concerns clearly

## Context Management
- Keep context window under 70% capacity
- Use external files for large documentation
- Clear context between unrelated tasks
- Import documentation via @path/to/file.md
- Remove stale context regularly
- Prioritize current task information

## Custom Commands and Hooks
- Create feature-specific commands in ~/.claude/commands/
- Implement automation hooks in ~/.claude/hooks/
- Use hooks for formatting and linting
- Automate repetitive workflows
- Chain commands for complex operations
- Document custom commands clearly

## UI/UX Design System Standards (Universal - Web & App)
- Create clean, organized interfaces following Apple Human Interface Guidelines principles
- Implement intuitive navigation patterns across all platforms
- Present data in digestible card-based layouts with generous whitespace
- Maintain professional, user-friendly experiences on web, iOS, Android, and desktop
- Follow Apple's design philosophy: simplicity, clarity, and depth

### Apple-Inspired Design Philosophy
- Clarity: Use negative space, color, fonts, graphics to highlight important content
- Deference: Fluid motion and crisp interface without competing with content
- Depth: Realistic motion and layered interfaces for hierarchy and vitality
- Consistency: Familiar SF Pro font family and iOS/macOS standard controls
- Direct manipulation: Immediate, visible response to user actions
- Metaphors: Virtual objects behave like physical counterparts

### Color Scheme
- Primary: Dark theme foundation (#000000 to #1C1C1E)
- Surface colors: Dark grays (#2C2C2E, #3A3A3C)
- Accent colors: Light accents for contrast (#F2F2F7, #E5E5EA)
- Brand colors: Blue/Purple spectrum (iOS blue #007AFF, purple #AF52DE)
- No color emojis in UI
- No linear gradients - solid colors with subtle transparency layers
- Professional, muted color palette inspired by iOS/macOS system colors
- Support both dark and light modes with appropriate contrast

### Typography (Platform-Adaptive)
- Web: SF Pro Display, Inter, -apple-system, system-ui fallback
- iOS/macOS: SF Pro Display for headlines, SF Pro Text for body
- Android: Roboto with thin/light weights
- Use thin/light font weights (100-300) for large text
- Regular (400) for body text, medium (500-600) for emphasis
- Consistent font sizing hierarchy (11pt, 13pt, 15pt, 17pt, 20pt, 28pt, 34pt)
- Proper line height (1.2 for headlines, 1.5-1.6 for body)
- Dynamic Type support for accessibility

### Design Principles
- Apple-esque minimalist aesthetic with attention to detail
- Card-based information architecture with rounded corners (10-16px radius)
- Clear visual hierarchy using size, weight, and color
- Consistent spacing using 8pt grid system
- Generous whitespace and breathing room
- Glass morphism effects where appropriate (backdrop-filter)
- Subtle depth with shadows and elevation (0-4dp layers)
- Platform-appropriate navigation (tab bars, navigation rails, sidebars)
- Responsive/adaptive design for all screen sizes

### Platform-Specific Adaptations
- **iOS**: Tab bar bottom navigation, SF Symbols, haptic feedback, safe areas
- **Android**: Material Design 3 with Apple aesthetics, navigation drawer/bottom nav
- **Web**: Responsive grid, hover states, keyboard navigation
- **Desktop**: Window management, menu bars, keyboard shortcuts
- **Cross-platform**: Consistent experience with platform-appropriate interactions

### Implementation Process (14+ steps)
1. Initialize git repository with .gitignore for all platforms
2. Set up project structure (src/, components/, screens/, assets/)
3. Define universal design tokens (colors, spacing, typography)
4. Create platform-specific theme configurations
5. Build spacing and grid system (8pt base unit)
6. Design base component library (buttons, inputs, cards, modals)
7. Implement navigation patterns for each platform
8. Create card-based layout templates with proper elevation
9. Build form components with platform-specific validation
10. Design data display components (lists with swipe actions, tables)
11. Implement responsive/adaptive breakpoints
12. Add dark/light theme switching with system preference detection
13. Create comprehensive documentation and style guide
14. Set up automated testing for components and interactions
15. Configure CI/CD pipeline for multi-platform deployment
16. Implement accessibility features (VoiceOver, TalkBack, ARIA)
17. Performance optimization (lazy loading, code splitting, image optimization)
18. Final review, beta testing, and production deployment

### Component Standards
- Rounded corners: 10-16px (cards), 8-10px (buttons), continuous corners for iOS
- Subtle shadows: 0 2px 10px rgba(0,0,0,0.1) dark mode, lighter in light mode
- Glass morphism: backdrop-filter: blur(20px) with semi-transparent backgrounds
- Interactive states: Scale transform (0.95) on press, opacity changes
- Loading states: Skeleton screens, native platform spinners
- Smooth transitions: 200-350ms with ease-in-out or spring animations
- Micro-interactions: Subtle bounces, fades, and slides
- Native platform feedback: Haptics on mobile, sound effects where appropriate
- Consistent icon style: SF Symbols (iOS), Material Symbols (Android), custom SVGs (web)
- Button styles: Filled, tinted, gray, plain (following iOS conventions)
- Text input: Floating labels or inline placeholders with clear borders

# ARCADE UI DESIGN SYSTEM (MANDATORY DEFAULT FOR ALL PROJECTS)

## IMPORTANT: Always Use Arcade-Style UI
**This is the DEFAULT design system for ALL projects. Always implement this style unless explicitly instructed otherwise.**

### Core Design Philosophy
- **Inspired by**: Artificial Arcade design patterns
- **Foundation**: Apple Human Interface Guidelines with game-inspired elements
- **Approach**: Clean, modern, engaging interfaces that make data beautiful
- **Icons**: MANDATORY use of SVG icons only - NO EMOJIS IN ANY CONTEXT

### Visual Design Requirements

#### Color Palette
```css
/* Light Mode */
--foreground: 0 0% 0%;
--background: 0 0% 100%;
--card: 0 0% 100%;
--primary: 210 100% 50%;
--accent: 210 100% 50%;
--muted: 0 0% 96%;
--border: 0 0% 92%;

/* Dark Mode */
--foreground: 0 0% 100%;
--background: 0 0% 0%;
--card: 0 0% 7%;
--primary: 210 100% 50%;
--accent: 210 100% 50%;
--muted: 0 0% 15%;
--border: 0 0% 15%;

/* Gradient Colors for Cards */
--gradient-blue: linear-gradient(135deg, #3b82f6, #06b6d4);
--gradient-green: linear-gradient(135deg, #10b981, #34d399);
--gradient-purple: linear-gradient(135deg, #8b5cf6, #ec4899);
--gradient-orange: linear-gradient(135deg, #f97316, #ef4444);
--gradient-indigo: linear-gradient(135deg, #6366f1, #8b5cf6);
```

#### Typography
- **Primary Font**: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif
- **Font Features**: "kern" on, "liga" on, "calt" on, "zero" on
- **Font Smoothing**: antialiased (webkit), grayscale (moz)
- **Size Scale**: 0.75rem, 0.875rem, 1rem, 1.125rem, 1.25rem, 1.5rem, 2rem, 2.5rem, 3.5rem

#### Component Patterns

##### Glass Morphism (PRIMARY STYLE)
```css
.glass {
  background: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(20px) saturate(150%);
  border: 1px solid rgba(255, 255, 255, 0.2);
}
```

##### Card Design
- **Style**: Glass morphism with gradient overlays
- **Hover**: translateY(-4px) scale(1.02)
- **Content**: Icon + Title + Description + Stats
- **Icons**: Use Lucide React or Heroicons (NEVER emojis)

##### Navigation Pattern
- **Top Bar**: Glass morphism, sticky, breadcrumbs
- **Logo**: SVG icon + Text combination
- **Theme Toggle**: Sun/Moon SVG icon button

### MANDATORY ICON REQUIREMENTS - NO EMOJIS
- **Required Libraries**: Lucide React, Heroicons, Tabler Icons, or Font Awesome
- **Implementation**: ONLY use SVG icons or icon components
- **Sizes**: Strict sizing system (16px, 20px, 24px, 32px)
- **Colors**: Inherit from parent or use CSS variables
- **ABSOLUTELY FORBIDDEN**: Any emoji characters anywhere in code
- **File names**: Use descriptive text, no emojis
- **Console output**: Use ASCII characters (*, -, +, >, #)
- **Status indicators**: Use colored SVG icons, not emoji symbols
- **Loading states**: Use SVG spinners, not emoji animations
- **Success/Error**: Use icon components with proper colors

### Icon Mapping Guide (REPLACE ALL EMOJIS)
```
COMMON EMOJI TO ICON REPLACEMENTS:
✅ → Check, CheckCircle         ❌ → X, XCircle
⚠️ → AlertTriangle              ℹ️ → Info, InfoCircle  
🏠 → Home                        👤 → User
⚙️ → Settings                    📊 → BarChart, BarChart2
📈 → TrendingUp                  📉 → TrendingDown
📁 → Folder                      📄 → File, FileText
💾 → Save, Download              🗑️ → Trash, Trash2
➕ → Plus, PlusCircle            ➖ → Minus, MinusCircle
🔍 → Search                      🔔 → Bell
💡 → Lightbulb                   🌙 → Moon
☀️ → Sun                         ⭐ → Star
❤️ → Heart                       📧 → Mail
📱 → Smartphone                  💻 → Monitor, Laptop
🎯 → Target                      🚀 → Rocket (use Zap icon)
🔒 → Lock                        🔓 → Unlock
⏰ → Clock, Timer                📅 → Calendar
🌍 → Globe, Globe2               🗺️ → Map
```

### Example Icon Implementation
```jsx
// React/Next.js with Lucide
import { Check, X, AlertTriangle, Info, Home } from 'lucide-react'

// Pure HTML/SVG
<svg class="icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <polyline points="20 6 9 17 4 12"></polyline> <!-- Check mark -->
</svg>

// Vue with Heroicons
import { CheckIcon, XMarkIcon, ExclamationTriangleIcon } from '@heroicons/vue/24/outline'

// Terminal/Console output (NO EMOJIS)
console.log('[SUCCESS] Operation completed')  // Not: ✅
console.log('[ERROR] Failed to load')         // Not: ❌
console.log('[WARNING] Check configuration')  // Not: ⚠️
console.log('[INFO] Processing...')          // Not: ℹ️
```

### Animation Requirements
- **Entrance**: Fade in up with stagger
- **Hover**: scale(1.02), translateY(-2px)
- **Click**: Ripple effect animation
- **Duration**: 0.3s to 0.6s
- **Easing**: cubic-bezier(0.4, 0, 0.2, 1)

### Layout Structure
- **Hero Section**: Gradient mesh background
- **Cards Grid**: Responsive columns with gap
- **Feature Pills**: Inline badges with icons
- **Stat Displays**: Large value + label + change indicator

### Implementation Checklist
1. Create arcade-ui.css with design system
2. Create arcade-ui.js for interactions
3. Import icon library (Lucide/Heroicons)
4. Setup glass morphism components
5. Implement gradient cards
6. Add smooth animations
7. Create responsive grid
8. Setup dark/light theme toggle

### Quality Standards
- **Performance**: 90+ Lighthouse score
- **Accessibility**: WCAG 2.1 AA compliant
- **Icons**: Always use proper icon fonts/SVGs
- **No Emojis**: Replace all emojis with icons

---
*This Arcade UI design system with icon requirements is the DEFAULT for all projects.*
- when i write /open  , automatically ru or build any application so it starts workig and complies