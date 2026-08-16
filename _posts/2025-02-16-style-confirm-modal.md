---
layout: post
title: "Turbo confirmation dialogs: native by default, custom when needed"
author: Yaroslav Shmarov
tags: javascript turbo rails
thumbnail: /assets/thumbnails/javascript.png
last_modified_at: 2026-08-16
modified_date: 2026-08-16
---

Rails and Turbo make destructive-action confirmations pleasantly boring:

```erb
<%= button_to "Delete", post_path(@post), method: :delete,
      form: { data: { turbo_confirm: "Delete this post?" } } %>
```

Turbo calls the browser's native `window.confirm()`. That is still my default
recommendation.

This post originally recommended replacing it with a styled Tailwind dialog.
After running that approach in a real Turbo application, fixing its lifecycle
bugs, adding richer options, and eventually removing it, my conclusion changed:
**keep the native dialog unless the confirmation genuinely needs more than a
question and two buttons.**

## The best default: do nothing

The native dialog gives you, for free:

- correct promise handling by Turbo;
- keyboard and focus behavior maintained by the browser;
- no listeners to leak between confirmations;
- no stale DOM references after Turbo replaces the `<body>`;
- a working fallback in every Rails layout and native shell.

For `button_to`, put `data-turbo-confirm` on the generated form with
`form: { data: ... }`, as above. For non-GET actions, prefer a real button and
form over a link. The [Turbo handbook](https://turbo.hotwired.dev/handbook/drive#performing-visits-with-a-different-method)
makes the same accessibility recommendation.

If a normal confirmation is all the product needs, stop here.

## Why the styled version was not drop-in

My first implementation followed the common pattern of rendering one
`<dialog>` in the layout and assigning a custom function to
`Turbo.config.forms.confirm`. It worked on the first page load, then accumulated
all the edge cases hidden by the short examples:

1. **Turbo navigation replaces the body.** DOM nodes cached when the module was
   imported pointed to detached elements after navigation. Every lookup must
   happen inside the confirmation callback.
2. **Every Turbo-enabled layout needs the dialog.** Missing markup must fall
   back to `window.confirm()`, never silently resolve `true`.
3. **Listeners accumulate.** A `{ once: true }` close handler is not enough once
   input, keyboard, backdrop, and cancel handlers are added. Tear down the whole
   group after every close.
4. **Text inserted with HTML is unsafe.** Confirmation messages and descriptions
   must be assigned with `textContent`, not interpolated into an HTML string.
5. **The dialog has state.** Button labels, disabled state, input value,
   `aria-describedby`, and `returnValue` must be reset on every opening.
6. **Focus is a product decision.** Focusing the destructive button makes an
   accidental Enter press dangerous. Focus Cancel by default; focus the input
   only for typed confirmation.
7. **Escape and backdrop clicks mean Cancel.** The promise must resolve `false`
   on every dismissal path.

The hook itself remains supported. Turbo's current API is
[`Turbo.config.forms.confirm`](https://turbo.hotwired.dev/reference/drive#turbo.config.forms.confirm),
and the function must return a promise resolving to `true` or `false`.

## When a custom dialog earns its keep

Use one when you have a concrete requirement such as:

- explaining an irreversible consequence;
- requiring the user to type a record name;
- using action-specific button labels;
- presenting information that does not fit in a browser confirmation.

Do not build it merely to make the confirmation match the rest of the UI.

If you do need it, this is the complete pattern I would use now.

### 1. Render one dialog in every relevant layout

```erb
<%# app/views/shared/_turbo_confirm_dialog.html.erb %>
<dialog id="turbo-confirm-dialog"
        class="w-full max-w-md rounded-lg p-0 backdrop:bg-black/50"
        aria-labelledby="turbo-confirm-title">
  <form method="dialog" class="space-y-4 p-6">
    <h2 id="turbo-confirm-title" class="text-lg font-semibold"></h2>

    <p id="turbo-confirm-description" class="text-sm text-gray-600" hidden></p>

    <div id="turbo-confirm-text-wrapper" class="space-y-2" hidden>
      <label for="turbo-confirm-text-input" class="block text-sm">
        Type <code id="turbo-confirm-required-text"></code> to confirm
      </label>
      <input id="turbo-confirm-text-input"
             type="text"
             class="w-full rounded border px-3 py-2"
             autocomplete="off">
    </div>

    <div class="flex justify-end gap-2">
      <button id="turbo-confirm-reject"
              type="submit"
              value="cancel"
              class="rounded px-4 py-2"
              autofocus>
        Cancel
      </button>
      <button id="turbo-confirm-accept"
              type="submit"
              value="confirm"
              class="rounded bg-red-600 px-4 py-2 text-white">
        Confirm
      </button>
    </div>
  </form>
</dialog>
```

Render it near the end of `<body>`:

```erb
<%= render "shared/turbo_confirm_dialog" %>
```

Keep the markup in a partial, but remember that the partial must be rendered by
every layout that can submit a Turbo-confirmed form.

### 2. Override Turbo's confirmation function

```js
// app/javascript/turbo_confirm.js
import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message, element, submitter) => {
  // Query on every call. Turbo navigation may have replaced the entire body.
  const dialog = document.getElementById("turbo-confirm-dialog")
  const title = document.getElementById("turbo-confirm-title")
  const description = document.getElementById("turbo-confirm-description")
  const textWrapper = document.getElementById("turbo-confirm-text-wrapper")
  const requiredTextElement = document.getElementById("turbo-confirm-required-text")
  const textInput = document.getElementById("turbo-confirm-text-input")
  const acceptButton = document.getElementById("turbo-confirm-accept")
  const rejectButton = document.getElementById("turbo-confirm-reject")

  const requiredElements = [
    dialog,
    title,
    description,
    textWrapper,
    requiredTextElement,
    textInput,
    acceptButton,
    rejectButton
  ]

  // Missing or incomplete markup must not bypass confirmation.
  if (!(dialog instanceof HTMLDialogElement) || !requiredElements.every(Boolean)) {
    return Promise.resolve(window.confirm(message))
  }

  const submitterData = submitter?.dataset || {}
  const elementData = element?.dataset || {}
  const data = { ...elementData, ...submitterData }

  const detail = data.turboConfirmDescription || ""
  const requiredText = data.turboConfirmText || ""
  const acceptLabel = data.turboConfirmAccept || ""
  const rejectLabel = data.turboConfirmReject || ""

  const defaultAcceptLabel = acceptButton.textContent.trim()
  const defaultRejectLabel = rejectButton.textContent.trim()
  const controller = new AbortController()
  const { signal } = controller

  // Use textContent: these values may contain user-controlled record names.
  title.textContent = message
  description.textContent = detail
  description.hidden = !detail
  dialog.toggleAttribute("aria-describedby", Boolean(detail))
  if (detail) dialog.setAttribute("aria-describedby", description.id)

  requiredTextElement.textContent = requiredText
  textInput.value = ""
  textWrapper.hidden = !requiredText
  acceptButton.disabled = Boolean(requiredText)
  acceptButton.textContent = acceptLabel || defaultAcceptLabel
  rejectButton.textContent = rejectLabel || defaultRejectLabel

  // Escape should always resolve as Cancel, even if a previous use confirmed.
  dialog.returnValue = "cancel"

  if (requiredText) {
    textInput.addEventListener("input", () => {
      acceptButton.disabled = textInput.value !== requiredText
    }, { signal })

    textInput.addEventListener("keydown", event => {
      if (event.key !== "Enter") return

      event.preventDefault()
      if (!acceptButton.disabled) dialog.close("confirm")
    }, { signal })
  }

  dialog.addEventListener("click", event => {
    if (event.target === dialog) dialog.close("cancel")
  }, { signal })

  dialog.showModal()
  requiredText ? textInput.focus() : rejectButton.focus()

  return new Promise(resolve => {
    dialog.addEventListener("close", () => {
      const confirmed = dialog.returnValue === "confirm"

      controller.abort()
      textInput.value = ""
      acceptButton.disabled = false
      acceptButton.textContent = defaultAcceptLabel
      rejectButton.textContent = defaultRejectLabel

      resolve(confirmed)
    }, { once: true })
  })
}
```

Import it after Turbo:

```js
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "turbo_confirm"
```

With importmap:

```ruby
# config/importmap.rb
pin "turbo_confirm"
```

### 3. Put the options on the form

```erb
<%= button_to "Delete account", account_path, method: :delete,
      form: {
        data: {
          turbo_confirm: "Delete this account permanently?",
          turbo_confirm_description: "This removes the account and its data.",
          turbo_confirm_text: account.name,
          turbo_confirm_accept: "Delete account",
          turbo_confirm_reject: "Keep account"
        }
      } %>
```

The callback checks the clicked submitter first and then the form, so the same
implementation also supports forms with multiple submit buttons.

## Verification checklist

Before calling a custom confirmation complete, test all of these:

- initial page load;
- after at least one Turbo navigation;
- every layout that contains a destructive action;
- Cancel, Escape, backdrop click, Confirm, and repeated openings;
- required-text mismatch, match, and Enter-key submission;
- custom labels followed by a normal confirmation, proving state was reset;
- the missing-dialog fallback;
- any Hotwire Native shell that can reach the action.

The implementation is much longer than the first version of this post. That is
the point: the browser dialog is the best practice for the ordinary case because
the browser already owns this complexity.

Inspired by the [Boring Rails dialog pattern](https://boringrails.com/articles/data-turbo-confirm-beautiful-dialog/),
[Rails Designer](https://dev.to/railsdesigner/custom-confirm-dialog-for-turbo-and-rails-3n96),
and the bugs found while operating the pattern in production.
