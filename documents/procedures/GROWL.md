# GROWL — Genesis Radio Commit Style Guide

---

## 🛡️ Purpose

To keep our Git commit history **clean, calm, and clear** —  
even during chaos, downtime, or tired late-night edits.

Every commit should **GROWL**:

| Letter | Meaning |
|:---|:---|
| **G** | Good |
| **R** | Readable |
| **O** | Obvious |
| **W** | Well-Scoped |
| **L** | Logical |

---

## 🧠 GROWL Principles

### **G — Good**

Write clear, helpful commit messages.  
Imagine your future self — tired, panicked — trying to understand what you did.

**Bad:**  
`update`

**Good:**  
`Fix retry logic for mount guardian script`

---

### **R — Readable**

Use short, plain English sentences.  
No cryptic shorthand. No weird abbreviations.

**Bad:**  
`fx psh scrpt`

**Good:**  
`Fix powershell script argument passing error`

---

### **O — Obvious**

The commit message should explain what changed without needing a diff.

**Bad:**  
`misc`

**Good:**  
`Add dark mode CSS to healthcheck dashboard`

---

### **W — Well-Scoped**

One logical change per commit.  
Don't fix five things at once unless they're tightly related.

**Bad:**  
`fix mount issues, added healthcheck, tweaked retry`

**Good:**  
`Fix asset mount detection timing issue`

(And then a separate commit for healthcheck tweaks.)

---

### **L — Logical**

Commits should build logically.  
Each one should bring the repo to a **better, deployable state** — not leave it broken.

**Bad:**  
Commit partial broken code just because "I need to leave soon."

**Good:**  
Finish a working block, then commit.

---

## 📋 Quick GROWL Checklist Before You Push:

- [ ] Is my message clear to a stranger?
- [ ] Did I only change one logical thing?
- [ ] Can I tell from the commit what changed, without a diff?
- [ ] Would sleepy me at 3AM thank me for writing this?

---

## 🎙️ Why We GROWL

Because panic, fatigue, or adrenaline can't be avoided —  
but **good habits under pressure can save a system** (and a future you) every time.

Stay calm.  
Make it obvious.  
Let it GROWL.

---

# 🐺 Genesis Radio Operations
*Built with pride. Built to last.*
