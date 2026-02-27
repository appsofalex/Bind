# Bind Pro – What You Need To Do Before App Store Submit

The app now uses **StoreKit 2** for the Pro subscription: purchase, restore, and entitlement checks are implemented in code. The following steps must be done by you in **App Store Connect** and **Xcode**.

---

## 1. App Store Connect – Create the subscription

1. In [App Store Connect](https://appstoreconnect.apple.com), open your app **Bind**.
2. Go to **Features** → **In-App Purchases** (or **Subscriptions** if using a subscription group).
3. Create a **Subscription Group** (e.g. name: **Bind Pro**).
4. Add a **Subscription** to that group:
   - **Reference name:** e.g. `Bind Pro Yearly`
   - **Product ID:** **`com.AlexCo.Bind.pro.subscription.yearly`** (must match exactly – this is used in code).
   - **Subscription duration:** 1 year.
5. Set **pricing** for each territory:
   - **United Kingdom:** £9.99
   - **United States:** $9.99
   - **Euro zone:** €9.99
   - **Other territories:** Use App Store Connect’s price matrix (it suggests converted prices; you can adjust).
6. Add **localisation** (name and description) for the subscription in the locales you support.
7. Submit the in-app purchase for review with your app (or with the next version you submit).

---

## 2. Xcode – In-App Purchase capability

You said you’ve already added the **In-App Purchase** capability. Confirm in Xcode:

- Select the **Bind** target → **Signing & Capabilities**.
- **In-App Purchase** is listed. If not, click **+ Capability** and add it.

No need to add anything to the entitlements file manually if you added it via the Capabilities tab.

---

## 3. Xcode – StoreKit Configuration (for local testing)

To test purchases **without** App Store Connect (simulator or device with a StoreKit config):

1. Add the StoreKit config to the project:
   - In Xcode, **File** → **New** → **File…**
   - Search for **“StoreKit Configuration File”** and create one, **or**
   - Drag the existing **`Configuration.storekit`** (in the project root) into the Xcode project navigator (e.g. into the **Bind** group).
2. Enable it for the **Bind** scheme:
   - **Product** → **Scheme** → **Edit Scheme…**
   - Select **Run** → **Options**
   - Under **StoreKit Configuration**, choose **Configuration.storekit** (or whatever you named it).
3. Run the app; purchases will use the local config. The product in **Configuration.storekit** uses product ID **`com.AlexCo.Bind.pro.subscription.yearly`** and a test price of **9.99** (no currency symbol in the file – the system will show a suitable test price).

When you’re ready for **real** purchases (TestFlight or production), either clear the StoreKit Configuration in the scheme or run without it so the app uses the App Store.

---

## 4. Replace placeholder URLs (optional but recommended)

In **SettingsView.swift** the following still point at placeholders. Replace with your real values before or soon after launch:

- **Terms of Service:** `https://www.example.com/terms`
- **Support:** `mailto:support@example.com`
- **Recommend the App (ShareLink):** `https://apps.apple.com/app/idXXXXXXXX` → use your real App Store app ID.
- **Privacy Policy:** `https://www.example.com/privacy`

Search for `example.com` and `idXXXXXXXX` in **SettingsView.swift** to find the exact lines.

---

## 5. Summary of what’s implemented in code

| Item | Status |
|------|--------|
| StoreKit 2 product loading | ✅ Product ID `com.AlexCo.Bind.pro.subscription.yearly` |
| Purchase flow | ✅ Triggers system pay sheet; on success, Pro is granted and upgrade animation shown |
| Restore purchases | ✅ In **ProUpgradeView** and **Settings → Bind Pro → Restore Purchases** |
| Manage subscription | ✅ Link to `https://apps.apple.com/account/subscriptions` in **Bind Pro** screen |
| Pro status from entitlements | ✅ On launch and when transactions update (renewals, expiry, revocation) |
| Price in UI | ✅ Uses product’s `displayPrice` when available (e.g. £9.99 / $9.99); fallback “£9.99” |
| Test-only “Demote to Free” | ✅ Shown only in **DEBUG** builds |
| StoreKit config for local testing | ✅ **Configuration.storekit** in project root (add to project and set in Scheme) |

---

## 6. Pricing note

You asked for **£9.99, $9.99, €9.99** and other currencies scaled by conversion. That is configured **only in App Store Connect** when you set the subscription’s price per territory. The app just shows whatever **displayPrice** StoreKit returns for the product (so it will show the correct currency and amount for the user’s store). No code change is required for different currencies.

---

After you complete steps 1–2 (and optionally 3 for testing and 4 for links), you’re ready to archive and submit. If you use the local **Configuration.storekit**, ensure the product ID stays **`com.AlexCo.Bind.pro.subscription.yearly`** so it matches the code and, when you create it, the App Store Connect subscription.
