# Dark Mode Testing Quick Guide

## Quick Start

### Switch to Dark Mode
**Option 1: In App Settings**
1. Open app
2. Go to Settings/Profile
3. Find "Theme" or "Appearance" toggle
4. Select "Dark Mode"

**Option 2: Use System Setting** (if app follows system theme)
- On Android: Settings → Display → Dark theme
- On iOS: Settings → Display & Brightness → Dark
- On Windows: Settings → Personalization → Colors → Choose your mode

**Option 3: Using ThemeProvider directly** (for developers)
```dart
// In any screen with access to Provider
Provider.of<ThemeProvider>(context, listen: false).setTheme('dark');
```

## What to Test - Screenshots Before/After

### 1. Messages List Screen
**Path**: Main menu → Messages

**What to Check**:
- [ ] Search bar background is dark (not bright white)
- [ ] Conversation cards have dark background
- [ ] Text is readable
- [ ] No bright white flashes

**Expected**:
- Search bar: Dark grey card color
- Conversation cards: Dark grey card color
- Text: Light colored for good contrast

---

### 2. Chat Screen
**Path**: Messages → Select any conversation

**What to Check**:
- [ ] Main background is dark
- [ ] Your messages (blue bubbles) still visible
- [ ] Received messages (grey bubbles) are dark grey, not light grey
- [ ] Text in both bubble types is readable
- [ ] Search bar (if opened) is dark
- [ ] Message input area at bottom is dark
- [ ] AppBar icons are visible

**Expected**:
- Background: Dark scaffold color
- Sent bubbles: Blue (primary color)
- Received bubbles: Dark grey surface
- All text: Good contrast

**Test Different Message Types**:
- [ ] Text messages
- [ ] Image messages (and broken image state)
- [ ] Video previews
- [ ] File attachments
- [ ] Open info panel (top right icon)

---

### 3. Announcement Detail Screen
**Path**: Course → Stream tab → Select announcement

**What to Check**:
- [ ] Scroll to bottom
- [ ] Comment input area has dark background (not white)

**Expected**:
- Comment box: Dark card color

---

### 4. Create Topic Screen
**Path**: Course → Groups/Forum → Create new topic button

**What to Check**:
- [ ] POST button is visible (top right)
- [ ] All input fields visible
- [ ] No harsh white backgrounds anywhere

**Expected**:
- POST button: Visible with proper contrast
- Form fields: Follow theme
- Background: Dark

---

## Visual Comparison

### Before Fix (Dark Mode)
❌ **Problem**: Harsh white backgrounds
- Messages list: White search bar
- Chat: White background, light grey received messages
- Announcement: White comment box
- Create topic: White POST button

### After Fix (Dark Mode)
✅ **Fixed**: All dark with good contrast
- Messages list: Dark search bar blends naturally
- Chat: Dark background, dark surface received messages
- Announcement: Dark comment box
- Create topic: Subtle POST button

---

## Color Contrast Check

All screens should have **WCAG AA** compliant contrast ratios:

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Background → Text | ~21:1 (black on white) | ~21:1 (white on dark) |
| Primary Button → Text | ~4.5:1+ | ~4.5:1+ |
| Card → Text | ~7:1+ | ~7:1+ |

### How to Verify Contrast
1. Take screenshot of dark mode
2. Use online tool: https://webaim.org/resources/contrastchecker/
3. Check background color vs text color
4. Should be at least 4.5:1 for normal text

---

## Common Issues to Look For

### ❌ Bad Dark Mode (Things to Report)
- Bright white backgrounds that hurt eyes
- Grey text on grey background (can't read)
- Invisible icons or buttons
- Harsh transitions between sections
- Text bleeding into background

### ✅ Good Dark Mode (What We Want)
- Comfortable dark backgrounds
- Clear text with good contrast
- Visible icons and buttons
- Smooth visual hierarchy
- Easy on the eyes for extended use

---

## Testing Checklist

### Basic Flow Test
- [ ] 1. Switch to dark mode
- [ ] 2. Navigate to Messages
- [ ] 3. Open a conversation
- [ ] 4. Send a test message
- [ ] 5. Scroll through chat
- [ ] 6. Open an announcement
- [ ] 7. Navigate to forum/create topic
- [ ] 8. Switch back to light mode
- [ ] 9. Verify light mode still looks good

### Edge Cases
- [ ] Very long messages (wrapping)
- [ ] Messages with emojis
- [ ] Failed image loads
- [ ] Empty conversations
- [ ] Many unread badges

---

## Performance Check

Dark mode should NOT affect performance:
- [ ] Scrolling is smooth in Messages list
- [ ] Chat loads quickly
- [ ] No lag when typing
- [ ] Theme switches instantly (within 1 frame)

---

## Reporting Issues

If you find dark mode issues:

1. **Take screenshot** showing the problem
2. **Note the screen** (exact path to reach it)
3. **Describe issue**: "This section is still white" or "Can't read this text"
4. **Include device/platform**: Android/iOS/Web

Example Report:
```
Screen: Messages → Chat → Info Panel
Issue: User avatar background is still white
Platform: Android
Screenshot: [attached]
```

---

## Quick Toggle Code (For Developers)

Add this floating button to any screen for quick testing:

```dart
FloatingActionButton(
  mini: true,
  onPressed: () {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    provider.toggleTheme(); // Switches between light/dark
  },
  child: Icon(Icons.brightness_6),
)
```

---

## Expected Results Summary

After this fix, all 4 screens should:
1. ✅ Have dark backgrounds in dark mode (no white)
2. ✅ Have readable text with good contrast
3. ✅ Feel comfortable to look at in low light
4. ✅ Match Material Design dark mode guidelines
5. ✅ Look professional and polished

**Status**: Ready for user acceptance testing!
