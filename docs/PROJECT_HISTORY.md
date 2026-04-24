# Helpi App - Project History

> Timeline of key technical decisions for the unified app.

## 2026-04-24 - Coordinate (lat/lng) Profile Fix

- Fixed profile edit flows that previously updated address text but not coordinates.
- Both customer and student profile screens now pass selected coordinates to backend.
- Contact update API now accepts optional latitude/longitude parameters.
- Registration coordinate validation logic corrected.

## 2026-04-18 - CouponType Simplification

- App coupon rendering aligned with reduced coupon type set.
- Removed legacy percentage/fixed-per-session label paths in UI mapping.

## 2026-04-01 - Real-Time Refresh Scope Tightening

- Notification-driven refresh now triggers on known state-changing events.
- System fallback full refresh remains available for safety.

## 2026-04-01 - Payment Test-Card Fallback Strategy

- Test card flow uses existing payment-method endpoints for non-production scenarios.
- Checkout remains unblocked when full Stripe production setup is not present.

## 2026-03-14 - Merge from Two Apps to One

- Replaced separate role apps with one unified codebase.
- Reduced duplicated UI/business flow code and simplified maintenance.
- Preserved role-specific UX through shell-level separation.
