# Format Finder Animation Style Guide

## Animation Timeline & Choreography

### Complete Scroll Experience Timeline

```
Time (ms)    Component                       Action
---------    ---------                       ------
0            App Launch                      Initial fade-in (300ms)
100          Parallax Header                 Scale & position setup
200          Content Container               Begin progressive reveal
350          First Format Card               Slide in from right
500          Second Format Card              Slide in (150ms delay)
650          Third Format Card               Slide in (150ms delay)
800          Floating Action Button          Bounce in after 200pt scroll
1000         Scroll Progress Indicator       Fade in on right edge
```

## Core Animation Principles

### 1. Spring Animations (Primary)
- **Default Spring**: `response: 0.5, damping: 0.8`
- **Bouncy Spring**: `response: 0.6, damping: 0.6`
- **Snappy Spring**: `response: 0.3, damping: 0.8`

### 2. Ease Curves (Secondary)
- **Standard Ease**: `duration: 0.3, curve: easeInOut`
- **Quick Fade**: `duration: 0.2, curve: easeOut`
- **Smooth Transition**: `duration: 0.5, curve: easeInOut`

## Component-Specific Animations

### Parallax Header
```swift
// Compression formula
height = max(baseHeight - (scrollOffset * 0.5), minHeight)
opacity = 1.0 - (scrollOffset / 200)
scale = 1.0 + (scrollOffset * 0.001)
```

### Progressive Reveal
```swift
// Stagger timing
delay = itemIndex * 0.15
offset = 100 // Initial x-offset
springResponse = 0.5
springDamping = 0.8
```

### 3D Card Flip
```swift
// Rotation parameters
perspective = 0.5 (m34 = -1/500)
rotationAxis = (x: 0, y: 1, z: 0)
flipDuration = 0.6
shadowRadius = 10 + (10 * rotationProgress)
```

### Pull to Refresh
```swift
// Golf ball animation
rotationSpeed = 360° per second
elasticResistance = 0.5
maxStretch = 150pt
triggerThreshold = 80pt
```

### Floating Action Button
```swift
// Entrance animation
appearThreshold = 200pt
bounceScale = 0.1 → 1.0
springDamping = 0.6
hideDelay = 2 seconds (for indicator)
```

## Animation States

### Loading States
1. **Skeleton Shimmer**
   - Duration: 1.5s
   - Direction: Left to right, 30° angle
   - Opacity: 0 → 0.3 → 0

2. **Error Shake**
   - Rotation: ±5°
   - Repetitions: 3
   - Duration: 0.1s per shake

3. **Empty State Float**
   - Vertical offset: ±10pt
   - Duration: 2s
   - Easing: easeInOut

### Interactive Feedback
1. **Tap Response**
   - Scale: 0.95
   - Duration: 0.1s
   - Haptic: Light impact

2. **Long Press**
   - Scale: 1.05
   - Shadow expansion: 10pt → 20pt
   - Haptic: Heavy impact

3. **Swipe/Drag**
   - Follow finger with resistance
   - Snap back with spring
   - Rotation based on velocity

## Performance Guidelines

### Frame Rate Targets
- **Optimal**: 60 FPS
- **Acceptable**: 50+ FPS
- **Performance Mode**: 30+ FPS

### Optimization Thresholds
```
FPS < 30: Aggressive optimization (disable non-critical animations)
FPS < 50: Moderate optimization (reduce concurrent animations)
FPS > 50: Full animations enabled
```

### Memory Limits
- Image cache: 100MB default, 50MB under pressure
- View pool: 5 active cards maximum
- Animation batch: 3 concurrent tasks

## Accessibility Adaptations

### Reduced Motion
When `UIAccessibility.isReduceMotionEnabled`:
- Replace springs with 0.1s crossfade
- Disable parallax effects
- Remove progressive reveals
- Use opacity transitions only

### VoiceOver
- Announce section changes
- Provide haptic feedback at boundaries
- Skip decorative animations
- Focus on content updates

### Dynamic Type
Scale factors for animations:
```
xSmall:  0.8x duration
Small:   0.9x duration
Medium:  1.0x duration (default)
Large:   1.1x duration
xLarge:  1.2x duration
xxLarge: 1.3x duration
xxxLarge: 1.4x duration
```

## Color Transitions

### Adaptive Gradient Animation
```swift
// Scroll-based color interpolation
progress = scrollOffset / maxOffset
primaryColor = interpolate(startColor, endColor, progress)
transitionDuration = 0.3s
```

### Theme Transitions
- Duration: 0.3s
- All colors animate simultaneously
- Navigation bar updates in real-time
- Text color adjusts for WCAG AA contrast

## Debug Visualizations

### Animation Timeline
```
[0ms]    ━━━━━━━━━━ Header Parallax
[200ms]      ━━━━━━━━ Card 1 Reveal
[350ms]          ━━━━━━━━ Card 2 Reveal
[500ms]              ━━━━━━━━ Card 3 Reveal
[800ms]                      ━━━━ FAB Entrance
```

### Performance Metrics
- Active animations counter
- Frame time graph
- Memory usage indicator
- CPU utilization percentage

## Configuration Presets

### Smooth Experience
```json
{
  "globalSpeed": 1.0,
  "springResponse": 0.5,
  "springDamping": 0.8,
  "parallaxEnabled": true,
  "progressiveReveal": true
}
```

### Performance Mode
```json
{
  "globalSpeed": 1.5,
  "springResponse": 0.3,
  "springDamping": 0.9,
  "parallaxEnabled": false,
  "progressiveReveal": false
}
```

### Accessibility Mode
```json
{
  "globalSpeed": 0.7,
  "reducedMotion": true,
  "hapticFeedback": true,
  "highContrast": true
}
```

## Testing Checklist

### Animation Quality
- [ ] All animations run at 60 FPS
- [ ] No animation conflicts or overlaps
- [ ] Smooth interruption handling
- [ ] Proper cleanup on view dismissal

### Edge Cases
- [ ] Rapid scrolling stability
- [ ] Orientation change handling
- [ ] Memory pressure response
- [ ] Background/foreground transitions

### Device Testing
- [ ] iPhone SE (small screen)
- [ ] iPhone 16 Pro Max (large screen)
- [ ] iPad (tablet layout)
- [ ] Older devices (iPhone 11)

## Implementation Notes

### Critical Animations
These must always be smooth:
1. Scroll response
2. Card interactions
3. Navigation transitions

### Optional Enhancements
Can be disabled under load:
1. Shimmer effects
2. Parallax depth
3. Shadow animations
4. Background gradients

### Battery Optimization
- Pause animations when off-screen
- Reduce animation frequency on low battery
- Use Metal for complex transforms
- Cache calculated values

## Version History

### v3.0 (Production)
- Complete animation system
- Performance optimizations
- Accessibility support
- Remote configuration

### v2.0 (Phase 2)
- Interactive elements
- Progressive animations
- Haptic feedback
- Debug tools

### v1.0 (Phase 1)
- Basic scroll architecture
- Parallax header
- Simple transitions

---

*Last Updated: Phase 3 Completion*
*Total Animation Count: 24 unique animations*
*Performance Target: 60 FPS on iPhone 11 and newer*